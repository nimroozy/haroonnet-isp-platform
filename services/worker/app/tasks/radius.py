"""
HaroonNet ISP Platform - RADIUS Tasks
Background tasks for CoA, usage tracking, and quota management
"""

from datetime import datetime, timedelta
from typing import List, Dict
import logging
from pyrad import dictionary, packet
from pyrad.client import Client
from pyrad.dictionary import Dictionary
from celery import Task
from sqlalchemy.orm import Session
from app.celery import celery
from app.database import get_app_db, get_radius_db
from app.config import settings

logger = logging.getLogger(__name__)


class DatabaseTask(Task):
    """Base task class with database session management"""

    def __call__(self, *args, **kwargs):
        app_db = next(get_app_db())
        radius_db = next(get_radius_db())
        try:
            return self.run_with_db(app_db, radius_db, *args, **kwargs)
        finally:
            app_db.close()
            radius_db.close()

    def run_with_db(self, app_db: Session, radius_db: Session, *args, **kwargs):
        return self.run(*args, **kwargs)


@celery.task(bind=True, base=DatabaseTask)
def update_usage_aggregates(self, app_db: Session, radius_db: Session):
    """Update usage aggregates from RADIUS accounting data"""
    logger.info("Updating usage aggregates")

    try:
        # Get the last update time
        last_update_query = """
        SELECT MAX(created_at) as last_update
        FROM usage_aggregates
        """
        result = app_db.execute(last_update_query)
        last_update = result.fetchone().last_update

        if not last_update:
            # First run - go back 1 day
            last_update = datetime.now() - timedelta(days=1)

        # Get accounting data since last update
        accounting_query = """
        SELECT username,
               DATE(acctstarttime) as usage_date,
               SUM(acctinputoctets) as input_octets,
               SUM(acctoutputoctets) as output_octets,
               SUM(acctinputoctets + acctoutputoctets) as total_octets,
               SUM(acctsessiontime) as session_time,
               COUNT(*) as session_count
        FROM radacct
        WHERE acctstarttime > %s
        AND acctstoptime IS NOT NULL
        GROUP BY username, DATE(acctstarttime)
        """

        result = radius_db.execute(accounting_query, (last_update,))
        usage_data = result.fetchall()

        updated_count = 0

        for usage in usage_data:
            try:
                # Get customer and subscription info
                customer_query = """
                SELECT s.id as subscription_id, s.customer_id
                FROM subscriptions s
                WHERE s.username = %s
                """
                result = app_db.execute(customer_query, (usage.username,))
                subscription = result.fetchone()

                if not subscription:
                    logger.warning(f"No subscription found for username: {usage.username}")
                    continue

                # Insert or update usage aggregate
                upsert_query = """
                INSERT INTO usage_aggregates (
                    customer_id, subscription_id, date, input_octets,
                    output_octets, total_octets, session_time, session_count,
                    created_at
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    input_octets = input_octets + VALUES(input_octets),
                    output_octets = output_octets + VALUES(output_octets),
                    total_octets = total_octets + VALUES(total_octets),
                    session_time = session_time + VALUES(session_time),
                    session_count = session_count + VALUES(session_count)
                """

                app_db.execute(upsert_query, (
                    subscription.customer_id,
                    subscription.subscription_id,
                    usage.usage_date,
                    usage.input_octets or 0,
                    usage.output_octets or 0,
                    usage.total_octets or 0,
                    usage.session_time or 0,
                    usage.session_count or 0,
                    datetime.now()
                ))

                updated_count += 1

            except Exception as e:
                logger.error(f"Failed to update usage for {usage.username}: {str(e)}")
                continue

        app_db.commit()

        logger.info(f"Updated {updated_count} usage aggregates")

        return {
            'status': 'completed',
            'updated_count': updated_count,
            'last_update': last_update.isoformat()
        }

    except Exception as e:
        app_db.rollback()
        logger.error(f"Usage aggregate update failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def check_quota_limits(self, app_db: Session, radius_db: Session):
    """Check quota limits and apply FUP or suspension"""
    logger.info("Checking quota limits")

    try:
        # Get subscriptions with quotas
        quota_query = """
        SELECT s.id, s.customer_id, s.username, s.monthly_quota, s.used_quota,
               p.name as plan_name, p.fup_enabled, p.fup_limit, p.fup_speed_down, p.fup_speed_up,
               c.email, c.first_name, c.last_name
        FROM subscriptions s
        JOIN service_plans p ON s.plan_id = p.id
        JOIN customers c ON s.customer_id = c.id
        WHERE s.status = 'active'
        AND s.monthly_quota IS NOT NULL
        AND s.monthly_quota > 0
        """

        result = app_db.execute(quota_query)
        subscriptions = result.fetchall()

        quota_warnings = 0
        quota_exceeded = 0
        fup_applied = 0

        for subscription in subscriptions:
            try:
                quota_used_percent = (subscription.used_quota or 0) / subscription.monthly_quota

                # Check if quota warning threshold reached
                if quota_used_percent >= settings.QUOTA_WARNING_THRESHOLD:
                    if quota_used_percent < 1.0:  # Not yet exceeded
                        # Send quota warning
                        from app.tasks.notifications import send_email_notification
                        send_email_notification.delay(
                            subscription.email,
                            'quota_warning',
                            {
                                'customer_name': subscription.first_name,
                                'plan_name': subscription.plan_name,
                                'used_quota': self._format_bytes(subscription.used_quota),
                                'total_quota': self._format_bytes(subscription.monthly_quota),
                                'percentage': int(quota_used_percent * 100)
                            }
                        )
                        quota_warnings += 1

                # Check if quota exceeded
                if quota_used_percent >= 1.0:
                    quota_exceeded += 1

                    if subscription.fup_enabled and subscription.fup_limit:
                        # Apply FUP (throttling)
                        fup_rate_limit = f"{subscription.fup_speed_down}M/{subscription.fup_speed_up}M"
                        send_coa_rate_limit.delay(subscription.username, fup_rate_limit)
                        fup_applied += 1

                        # Send FUP notification
                        from app.tasks.notifications import send_email_notification
                        send_email_notification.delay(
                            subscription.email,
                            'fup_applied',
                            {
                                'customer_name': subscription.first_name,
                                'plan_name': subscription.plan_name,
                                'new_speed': f"{subscription.fup_speed_down}Mbps"
                            }
                        )
                    else:
                        # Suspend service
                        send_coa_disconnect.delay(subscription.username)

                        # Update subscription status
                        suspend_query = """
                        UPDATE subscriptions
                        SET status = 'suspended', suspension_date = CURDATE()
                        WHERE id = %s
                        """
                        app_db.execute(suspend_query, (subscription.id,))

                        # Send suspension notification
                        from app.tasks.notifications import send_email_notification
                        send_email_notification.delay(
                            subscription.email,
                            'quota_exceeded',
                            {
                                'customer_name': subscription.first_name,
                                'plan_name': subscription.plan_name,
                                'used_quota': self._format_bytes(subscription.used_quota),
                                'total_quota': self._format_bytes(subscription.monthly_quota)
                            }
                        )

            except Exception as e:
                logger.error(f"Failed to check quota for subscription {subscription.id}: {str(e)}")
                continue

        app_db.commit()

        logger.info(f"Quota check completed: {quota_warnings} warnings, {quota_exceeded} exceeded, {fup_applied} FUP applied")

        return {
            'status': 'completed',
            'quota_warnings': quota_warnings,
            'quota_exceeded': quota_exceeded,
            'fup_applied': fup_applied
        }

    except Exception as e:
        app_db.rollback()
        logger.error(f"Quota check failed: {str(e)}")
        raise

    def _format_bytes(self, bytes_value):
        """Format bytes to human readable format"""
        if not bytes_value:
            return "0 B"

        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.1f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.1f} PB"


@celery.task(bind=True, base=DatabaseTask)
def reset_monthly_quotas(self, app_db: Session, radius_db: Session):
    """Reset monthly quotas at the beginning of each month"""
    logger.info("Resetting monthly quotas")

    try:
        # Reset used quotas
        reset_query = """
        UPDATE subscriptions
        SET used_quota = 0, quota_reset_date = CURDATE()
        WHERE monthly_quota IS NOT NULL
        AND monthly_quota > 0
        """

        result = app_db.execute(reset_query)
        reset_count = result.rowcount

        # Reactivate FUP subscriptions
        reactivate_query = """
        SELECT s.id, s.username, p.mikrotik_rate_limit
        FROM subscriptions s
        JOIN service_plans p ON s.plan_id = p.id
        WHERE s.status = 'active'
        AND p.fup_enabled = 1
        """

        result = app_db.execute(reactivate_query)
        subscriptions = result.fetchall()

        reactivated_count = 0

        for subscription in subscriptions:
            try:
                # Restore original rate limit
                if subscription.mikrotik_rate_limit:
                    send_coa_rate_limit.delay(subscription.username, subscription.mikrotik_rate_limit)
                    reactivated_count += 1
            except Exception as e:
                logger.error(f"Failed to reactivate subscription {subscription.id}: {str(e)}")
                continue

        app_db.commit()

        logger.info(f"Reset {reset_count} quotas, reactivated {reactivated_count} FUP subscriptions")

        return {
            'status': 'completed',
            'reset_count': reset_count,
            'reactivated_count': reactivated_count
        }

    except Exception as e:
        app_db.rollback()
        logger.error(f"Monthly quota reset failed: {str(e)}")
        raise


@celery.task
def send_coa_disconnect(username: str):
    """Send CoA Disconnect-Request to terminate user session"""
    logger.info(f"Sending CoA disconnect for user: {username}")

    try:
        # Get NAS information for the user
        app_db = next(get_app_db())
        radius_db = next(get_radius_db())

        try:
            # Find active session
            session_query = """
            SELECT nasipaddress, acctsessionid, framedipaddress
            FROM radacct
            WHERE username = %s
            AND acctstoptime IS NULL
            ORDER BY acctstarttime DESC
            LIMIT 1
            """

            result = radius_db.execute(session_query, (username,))
            session = result.fetchone()

            if not session:
                logger.warning(f"No active session found for user: {username}")
                return {'status': 'no_session', 'username': username}

            # Get NAS secret
            nas_query = """
            SELECT secret FROM nas WHERE nasname = %s
            """
            result = radius_db.execute(nas_query, (session.nasipaddress,))
            nas = result.fetchone()

            if not nas:
                logger.error(f"NAS not found: {session.nasipaddress}")
                return {'status': 'nas_not_found', 'nas_ip': session.nasipaddress}

            # Create RADIUS client
            client = Client(
                server=session.nasipaddress,
                secret=nas.secret.encode(),
                dict=Dictionary("dictionary")
            )

            # Create Disconnect-Request packet
            req = client.CreateCoAPacket(code=packet.DisconnectRequest)
            req["User-Name"] = username
            req["Acct-Session-Id"] = session.acctsessionid
            if session.framedipaddress:
                req["Framed-IP-Address"] = session.framedipaddress

            # Send CoA request
            reply = client.SendPacket(req)

            if reply.code == packet.DisconnectACK:
                logger.info(f"CoA disconnect successful for user: {username}")
                return {'status': 'success', 'username': username}
            else:
                logger.error(f"CoA disconnect failed for user: {username}")
                return {'status': 'failed', 'username': username}

        finally:
            app_db.close()
            radius_db.close()

    except Exception as e:
        logger.error(f"CoA disconnect error for user {username}: {str(e)}")
        return {'status': 'error', 'username': username, 'error': str(e)}


@celery.task
def send_coa_rate_limit(username: str, rate_limit: str):
    """Send CoA request to change user's rate limit"""
    logger.info(f"Sending CoA rate limit change for user: {username} to {rate_limit}")

    try:
        # Get NAS information for the user
        app_db = next(get_app_db())
        radius_db = next(get_radius_db())

        try:
            # Find active session
            session_query = """
            SELECT nasipaddress, acctsessionid, framedipaddress
            FROM radacct
            WHERE username = %s
            AND acctstoptime IS NULL
            ORDER BY acctstarttime DESC
            LIMIT 1
            """

            result = radius_db.execute(session_query, (username,))
            session = result.fetchone()

            if not session:
                logger.warning(f"No active session found for user: {username}")
                return {'status': 'no_session', 'username': username}

            # Get NAS secret
            nas_query = """
            SELECT secret FROM nas WHERE nasname = %s
            """
            result = radius_db.execute(nas_query, (session.nasipaddress,))
            nas = result.fetchone()

            if not nas:
                logger.error(f"NAS not found: {session.nasipaddress}")
                return {'status': 'nas_not_found', 'nas_ip': session.nasipaddress}

            # Create RADIUS client
            client = Client(
                server=session.nasipaddress,
                secret=nas.secret.encode(),
                dict=Dictionary("dictionary")
            )

            # Create CoA-Request packet
            req = client.CreateCoAPacket(code=packet.CoARequest)
            req["User-Name"] = username
            req["Acct-Session-Id"] = session.acctsessionid
            req["Mikrotik-Rate-Limit"] = rate_limit

            # Send CoA request
            reply = client.SendPacket(req)

            if reply.code == packet.CoAACK:
                logger.info(f"CoA rate limit change successful for user: {username}")
                return {'status': 'success', 'username': username, 'rate_limit': rate_limit}
            else:
                logger.error(f"CoA rate limit change failed for user: {username}")
                return {'status': 'failed', 'username': username}

        finally:
            app_db.close()
            radius_db.close()

    except Exception as e:
        logger.error(f"CoA rate limit error for user {username}: {str(e)}")
        return {'status': 'error', 'username': username, 'error': str(e)}
