"""
HaroonNet ISP Platform - System Tasks
Background tasks for system maintenance, backups, and health checks
"""

import os
import subprocess
from datetime import datetime, timedelta
import logging
import psutil
import redis
from celery import Task
from sqlalchemy.orm import Session
from app.celery import celery
from app.database import get_app_db, get_radius_db
from app.config import settings

logger = logging.getLogger(__name__)


class DatabaseTask(Task):
    """Base task class with database session management"""

    def __call__(self, *args, **kwargs):
        db = next(get_app_db())
        try:
            return self.run_with_db(db, *args, **kwargs)
        finally:
            db.close()

    def run_with_db(self, db: Session, *args, **kwargs):
        return self.run(*args, **kwargs)


@celery.task(bind=True, base=DatabaseTask)
def backup_database(self, db: Session):
    """Create database backups"""
    logger.info("Starting database backup")

    try:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_dir = '/app/backups'
        os.makedirs(backup_dir, exist_ok=True)

        # Backup application database
        app_backup_file = f"{backup_dir}/haroonnet_backup_{timestamp}.sql"
        app_backup_cmd = [
            'mysqldump',
            f'--host={settings.DB_HOST}',
            f'--port={settings.DB_PORT}',
            f'--user={settings.DB_USER}',
            f'--password={settings.DB_PASSWORD}',
            '--single-transaction',
            '--routines',
            '--triggers',
            settings.DB_NAME
        ]

        with open(app_backup_file, 'w') as f:
            result = subprocess.run(app_backup_cmd, stdout=f, stderr=subprocess.PIPE, text=True)
            if result.returncode != 0:
                raise Exception(f"App database backup failed: {result.stderr}")

        # Backup RADIUS database
        radius_backup_file = f"{backup_dir}/radius_backup_{timestamp}.sql"
        radius_backup_cmd = [
            'mysqldump',
            f'--host={settings.RADIUS_DB_HOST}',
            f'--port={settings.RADIUS_DB_PORT}',
            f'--user={settings.RADIUS_DB_USER}',
            f'--password={settings.RADIUS_DB_PASSWORD}',
            '--single-transaction',
            '--routines',
            '--triggers',
            settings.RADIUS_DB_NAME
        ]

        with open(radius_backup_file, 'w') as f:
            result = subprocess.run(radius_backup_cmd, stdout=f, stderr=subprocess.PIPE, text=True)
            if result.returncode != 0:
                raise Exception(f"RADIUS database backup failed: {result.stderr}")

        # Get file sizes
        app_backup_size = os.path.getsize(app_backup_file)
        radius_backup_size = os.path.getsize(radius_backup_file)

        # Log backup to database
        log_query = """
        INSERT INTO system_backups (
            backup_type, file_path, file_size, status, created_at
        ) VALUES (%s, %s, %s, %s, %s)
        """

        db.execute(log_query, (
            'application', app_backup_file, app_backup_size, 'completed', datetime.now()
        ))

        db.execute(log_query, (
            'radius', radius_backup_file, radius_backup_size, 'completed', datetime.now()
        ))

        db.commit()

        # Clean up old backups
        self._cleanup_old_backups(backup_dir)

        logger.info(f"Database backup completed: {app_backup_file}, {radius_backup_file}")

        return {
            'status': 'completed',
            'app_backup': app_backup_file,
            'radius_backup': radius_backup_file,
            'app_size': app_backup_size,
            'radius_size': radius_backup_size,
            'timestamp': timestamp
        }

    except Exception as e:
        logger.error(f"Database backup failed: {str(e)}")

        # Log failure
        try:
            log_query = """
            INSERT INTO system_backups (
                backup_type, file_path, file_size, status, error_message, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s)
            """
            db.execute(log_query, (
                'failed', '', 0, 'failed', str(e), datetime.now()
            ))
            db.commit()
        except:
            pass

        raise

    def _cleanup_old_backups(self, backup_dir: str):
        """Remove old backup files"""
        try:
            cutoff_date = datetime.now() - timedelta(days=settings.BACKUP_RETENTION_DAYS)

            for filename in os.listdir(backup_dir):
                if filename.endswith('.sql'):
                    file_path = os.path.join(backup_dir, filename)
                    file_mtime = datetime.fromtimestamp(os.path.getmtime(file_path))

                    if file_mtime < cutoff_date:
                        os.remove(file_path)
                        logger.info(f"Removed old backup: {filename}")

        except Exception as e:
            logger.warning(f"Failed to cleanup old backups: {str(e)}")


@celery.task(bind=True, base=DatabaseTask)
def cleanup_old_logs(self, db: Session):
    """Clean up old log entries"""
    logger.info("Cleaning up old logs")

    try:
        # Clean up old audit logs (keep for 1 year)
        audit_cutoff = datetime.now() - timedelta(days=365)
        audit_query = "DELETE FROM audit_logs WHERE created_at < %s"
        result = db.execute(audit_query, (audit_cutoff,))
        deleted_audit = result.rowcount

        # Clean up old RADIUS accounting (keep for 2 years)
        radius_db = next(get_radius_db())
        try:
            radius_cutoff = datetime.now() - timedelta(days=730)
            radius_query = "DELETE FROM radacct WHERE acctstarttime < %s"
            result = radius_db.execute(radius_query, (radius_cutoff,))
            deleted_radius = result.rowcount
            radius_db.commit()
        finally:
            radius_db.close()

        # Clean up old post-auth logs (keep for 6 months)
        radius_db = next(get_radius_db())
        try:
            postauth_cutoff = datetime.now() - timedelta(days=180)
            postauth_query = "DELETE FROM radpostauth WHERE authdate < %s"
            result = radius_db.execute(postauth_query, (postauth_cutoff,))
            deleted_postauth = result.rowcount
            radius_db.commit()
        finally:
            radius_db.close()

        # Clean up old usage aggregates (keep for 2 years)
        usage_cutoff = datetime.now() - timedelta(days=730)
        usage_query = "DELETE FROM usage_aggregates WHERE date < %s"
        result = db.execute(usage_query, (usage_cutoff,))
        deleted_usage = result.rowcount

        db.commit()

        logger.info(f"Log cleanup completed: {deleted_audit} audit, {deleted_radius} radius, {deleted_postauth} postauth, {deleted_usage} usage")

        return {
            'status': 'completed',
            'deleted_audit_logs': deleted_audit,
            'deleted_radius_logs': deleted_radius,
            'deleted_postauth_logs': deleted_postauth,
            'deleted_usage_logs': deleted_usage
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Log cleanup failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def system_health_check(self, db: Session):
    """Perform system health checks"""
    logger.info("Performing system health check")

    try:
        health_data = {}
        issues = []

        # Check system resources
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        cpu_percent = psutil.cpu_percent(interval=1)

        health_data['memory'] = {
            'total': memory.total,
            'available': memory.available,
            'percent': memory.percent
        }

        health_data['disk'] = {
            'total': disk.total,
            'free': disk.free,
            'percent': (disk.used / disk.total) * 100
        }

        health_data['cpu'] = {
            'percent': cpu_percent
        }

        # Check for resource issues
        if memory.percent > 90:
            issues.append(f"High memory usage: {memory.percent}%")

        if (disk.used / disk.total) * 100 > 90:
            issues.append(f"High disk usage: {(disk.used / disk.total) * 100:.1f}%")

        if cpu_percent > 90:
            issues.append(f"High CPU usage: {cpu_percent}%")

        # Check database connections
        try:
            db.execute("SELECT 1")
            health_data['database'] = 'healthy'
        except Exception as e:
            health_data['database'] = 'unhealthy'
            issues.append(f"Database connection issue: {str(e)}")

        # Check RADIUS database
        try:
            radius_db = next(get_radius_db())
            try:
                radius_db.execute("SELECT 1")
                health_data['radius_database'] = 'healthy'
            finally:
                radius_db.close()
        except Exception as e:
            health_data['radius_database'] = 'unhealthy'
            issues.append(f"RADIUS database connection issue: {str(e)}")

        # Check Redis
        try:
            r = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                password=settings.REDIS_PASSWORD,
                db=settings.REDIS_DB
            )
            r.ping()
            health_data['redis'] = 'healthy'
        except Exception as e:
            health_data['redis'] = 'unhealthy'
            issues.append(f"Redis connection issue: {str(e)}")

        # Check active sessions
        try:
            radius_db = next(get_radius_db())
            try:
                session_query = "SELECT COUNT(*) as active_sessions FROM radacct WHERE acctstoptime IS NULL"
                result = radius_db.execute(session_query)
                active_sessions = result.fetchone().active_sessions
                health_data['active_sessions'] = active_sessions
            finally:
                radius_db.close()
        except Exception as e:
            health_data['active_sessions'] = 0
            issues.append(f"Failed to get active sessions: {str(e)}")

        # Log health check
        health_status = 'healthy' if not issues else 'warning'

        log_query = """
        INSERT INTO system_health_logs (
            status, data, issues, created_at
        ) VALUES (%s, %s, %s, %s)
        """

        import json
        db.execute(log_query, (
            health_status,
            json.dumps(health_data),
            json.dumps(issues),
            datetime.now()
        ))

        db.commit()

        # Send alerts if there are critical issues
        if issues:
            logger.warning(f"System health issues detected: {issues}")

            # Send alert notification
            from app.tasks.notifications import send_email_notification
            send_email_notification.delay(
                settings.COMPANY_EMAIL,
                'system_alert',
                {
                    'issues': issues,
                    'health_data': health_data,
                    'timestamp': datetime.now().isoformat()
                }
            )

        logger.info(f"System health check completed: {health_status}")

        return {
            'status': health_status,
            'data': health_data,
            'issues': issues,
            'timestamp': datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"System health check failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def optimize_database(self, db: Session):
    """Optimize database tables"""
    logger.info("Optimizing database tables")

    try:
        # Get list of tables to optimize
        tables_query = """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = %s
        AND table_type = 'BASE TABLE'
        """

        result = db.execute(tables_query, (settings.DB_NAME,))
        tables = [row.table_name for row in result.fetchall()]

        optimized_tables = []

        for table in tables:
            try:
                # Optimize table
                optimize_query = f"OPTIMIZE TABLE {table}"
                db.execute(optimize_query)
                optimized_tables.append(table)
                logger.info(f"Optimized table: {table}")
            except Exception as e:
                logger.warning(f"Failed to optimize table {table}: {str(e)}")
                continue

        # Optimize RADIUS tables
        radius_db = next(get_radius_db())
        try:
            radius_tables = ['radacct', 'radcheck', 'radreply', 'radusergroup', 'radgroupcheck', 'radgroupreply', 'radpostauth']

            for table in radius_tables:
                try:
                    optimize_query = f"OPTIMIZE TABLE {table}"
                    radius_db.execute(optimize_query)
                    optimized_tables.append(f"radius.{table}")
                    logger.info(f"Optimized RADIUS table: {table}")
                except Exception as e:
                    logger.warning(f"Failed to optimize RADIUS table {table}: {str(e)}")
                    continue

            radius_db.commit()
        finally:
            radius_db.close()

        db.commit()

        logger.info(f"Database optimization completed: {len(optimized_tables)} tables optimized")

        return {
            'status': 'completed',
            'optimized_tables': optimized_tables,
            'total_tables': len(optimized_tables)
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Database optimization failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def update_system_statistics(self, db: Session):
    """Update system statistics for monitoring"""
    logger.info("Updating system statistics")

    try:
        stats = {}

        # Customer statistics
        customer_query = """
        SELECT
            COUNT(*) as total_customers,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_customers,
            COUNT(CASE WHEN status = 'suspended' THEN 1 END) as suspended_customers
        FROM customers
        """
        result = db.execute(customer_query)
        customer_stats = result.fetchone()
        stats['customers'] = dict(customer_stats)

        # Subscription statistics
        subscription_query = """
        SELECT
            COUNT(*) as total_subscriptions,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_subscriptions,
            COUNT(CASE WHEN status = 'suspended' THEN 1 END) as suspended_subscriptions,
            SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as revenue_generating
        FROM subscriptions
        """
        result = db.execute(subscription_query)
        subscription_stats = result.fetchone()
        stats['subscriptions'] = dict(subscription_stats)

        # Financial statistics
        financial_query = """
        SELECT
            COUNT(*) as total_invoices,
            COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_invoices,
            COUNT(CASE WHEN status = 'overdue' THEN 1 END) as overdue_invoices,
            SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END) as total_revenue,
            SUM(CASE WHEN status != 'paid' THEN balance ELSE 0 END) as outstanding_balance
        FROM invoices
        WHERE MONTH(issue_date) = MONTH(CURDATE())
        AND YEAR(issue_date) = YEAR(CURDATE())
        """
        result = db.execute(financial_query)
        financial_stats = result.fetchone()
        stats['financials'] = dict(financial_stats)

        # Active sessions from RADIUS
        radius_db = next(get_radius_db())
        try:
            session_query = """
            SELECT
                COUNT(*) as active_sessions,
                COUNT(DISTINCT nasipaddress) as active_nas
            FROM radacct
            WHERE acctstoptime IS NULL
            """
            result = radius_db.execute(session_query)
            session_stats = result.fetchone()
            stats['sessions'] = dict(session_stats)
        finally:
            radius_db.close()

        # Update statistics table
        import json
        update_query = """
        INSERT INTO system_statistics (
            stats_date, data, created_at
        ) VALUES (%s, %s, %s)
        ON DUPLICATE KEY UPDATE
            data = VALUES(data),
            updated_at = VALUES(created_at)
        """

        db.execute(update_query, (
            datetime.now().date(),
            json.dumps(stats),
            datetime.now()
        ))

        db.commit()

        logger.info("System statistics updated successfully")

        return {
            'status': 'completed',
            'statistics': stats,
            'timestamp': datetime.now().isoformat()
        }

    except Exception as e:
        db.rollback()
        logger.error(f"System statistics update failed: {str(e)}")
        raise
