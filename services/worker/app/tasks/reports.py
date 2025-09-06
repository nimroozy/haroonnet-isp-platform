"""
HaroonNet ISP Platform - Report Generation Tasks
Background tasks for generating various business and operational reports
"""

from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging
import json
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
def generate_daily_reports(self, app_db: Session, radius_db: Session):
    """Generate daily operational reports"""
    logger.info("Generating daily reports")

    try:
        report_date = datetime.now().date()
        reports = {}

        # Daily revenue report
        revenue_query = """
        SELECT
            COUNT(*) as invoices_generated,
            SUM(total_amount) as total_invoiced,
            COUNT(CASE WHEN status = 'paid' THEN 1 END) as invoices_paid,
            SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END) as total_collected
        FROM invoices
        WHERE DATE(created_at) = %s
        """
        result = app_db.execute(revenue_query, (report_date,))
        reports['revenue'] = dict(result.fetchone())

        # Daily customer activity
        customer_query = """
        SELECT
            COUNT(CASE WHEN DATE(created_at) = %s THEN 1 END) as new_customers,
            COUNT(CASE WHEN status = 'active' AND DATE(updated_at) = %s THEN 1 END) as activated_customers,
            COUNT(CASE WHEN status = 'suspended' AND DATE(updated_at) = %s THEN 1 END) as suspended_customers
        FROM customers
        """
        result = app_db.execute(customer_query, (report_date, report_date, report_date))
        reports['customers'] = dict(result.fetchone())

        # Daily usage statistics
        usage_query = """
        SELECT
            COUNT(DISTINCT customer_id) as active_users,
            SUM(total_octets) as total_data_used,
            AVG(total_octets) as avg_data_per_user,
            SUM(session_time) as total_session_time
        FROM usage_aggregates
        WHERE date = %s
        """
        result = app_db.execute(usage_query, (report_date,))
        reports['usage'] = dict(result.fetchone())

        # Daily authentication statistics from RADIUS
        auth_query = """
        SELECT
            COUNT(*) as total_auth_attempts,
            COUNT(CASE WHEN reply = 'Access-Accept' THEN 1 END) as successful_auths,
            COUNT(CASE WHEN reply = 'Access-Reject' THEN 1 END) as failed_auths,
            COUNT(DISTINCT username) as unique_users
        FROM radpostauth
        WHERE DATE(authdate) = %s
        """
        result = radius_db.execute(auth_query, (report_date,))
        reports['authentication'] = dict(result.fetchone())

        # Daily session statistics
        session_query = """
        SELECT
            COUNT(*) as sessions_started,
            COUNT(CASE WHEN acctstoptime IS NOT NULL THEN 1 END) as sessions_ended,
            AVG(acctsessiontime) as avg_session_duration,
            SUM(acctinputoctets + acctoutputoctets) as total_traffic
        FROM radacct
        WHERE DATE(acctstarttime) = %s
        """
        result = radius_db.execute(session_query, (report_date,))
        reports['sessions'] = dict(result.fetchone())

        # Daily support ticket statistics
        ticket_query = """
        SELECT
            COUNT(CASE WHEN DATE(created_at) = %s THEN 1 END) as new_tickets,
            COUNT(CASE WHEN DATE(resolved_at) = %s THEN 1 END) as resolved_tickets,
            COUNT(CASE WHEN status = 'open' THEN 1 END) as open_tickets,
            AVG(CASE WHEN resolved_at IS NOT NULL THEN
                TIMESTAMPDIFF(HOUR, created_at, resolved_at)
            END) as avg_resolution_time_hours
        FROM tickets
        """
        result = app_db.execute(ticket_query, (report_date, report_date))
        reports['support'] = dict(result.fetchone())

        # Save daily report
        self._save_report(app_db, 'daily', report_date, reports)

        # Send report via email if configured
        self._send_daily_report_email(reports, report_date)

        logger.info(f"Daily reports generated for {report_date}")

        return {
            'status': 'completed',
            'report_date': report_date.isoformat(),
            'reports': reports
        }

    except Exception as e:
        logger.error(f"Daily report generation failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def generate_weekly_reports(self, app_db: Session, radius_db: Session):
    """Generate weekly summary reports"""
    logger.info("Generating weekly reports")

    try:
        # Get week range (Monday to Sunday)
        today = datetime.now().date()
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=6)

        reports = {}

        # Weekly revenue summary
        revenue_query = """
        SELECT
            COUNT(*) as total_invoices,
            SUM(total_amount) as total_invoiced,
            SUM(paid_amount) as total_collected,
            COUNT(CASE WHEN status = 'overdue' THEN 1 END) as overdue_invoices,
            SUM(CASE WHEN status = 'overdue' THEN balance ELSE 0 END) as overdue_amount
        FROM invoices
        WHERE DATE(created_at) BETWEEN %s AND %s
        """
        result = app_db.execute(revenue_query, (week_start, week_end))
        reports['revenue'] = dict(result.fetchone())

        # Weekly customer growth
        growth_query = """
        SELECT
            COUNT(CASE WHEN DATE(created_at) BETWEEN %s AND %s THEN 1 END) as new_customers,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as total_active,
            COUNT(CASE WHEN status = 'suspended' THEN 1 END) as total_suspended,
            COUNT(CASE WHEN status = 'terminated' AND DATE(updated_at) BETWEEN %s AND %s THEN 1 END) as churned_customers
        FROM customers
        """
        result = app_db.execute(growth_query, (week_start, week_end, week_start, week_end))
        reports['customer_growth'] = dict(result.fetchone())

        # Weekly usage trends
        usage_query = """
        SELECT
            SUM(total_octets) as total_data_usage,
            AVG(total_octets) as avg_daily_usage,
            MAX(total_octets) as peak_daily_usage,
            COUNT(DISTINCT customer_id) as active_users
        FROM usage_aggregates
        WHERE date BETWEEN %s AND %s
        """
        result = app_db.execute(usage_query, (week_start, week_end))
        reports['usage_trends'] = dict(result.fetchone())

        # Top plans by revenue
        plan_revenue_query = """
        SELECT
            p.name as plan_name,
            COUNT(s.id) as active_subscriptions,
            SUM(p.monthly_fee) as monthly_revenue
        FROM service_plans p
        JOIN subscriptions s ON p.id = s.plan_id
        WHERE s.status = 'active'
        GROUP BY p.id, p.name
        ORDER BY monthly_revenue DESC
        LIMIT 10
        """
        result = app_db.execute(plan_revenue_query)
        reports['top_plans'] = [dict(row) for row in result.fetchall()]

        # Weekly support metrics
        support_query = """
        SELECT
            COUNT(CASE WHEN DATE(created_at) BETWEEN %s AND %s THEN 1 END) as new_tickets,
            COUNT(CASE WHEN DATE(resolved_at) BETWEEN %s AND %s THEN 1 END) as resolved_tickets,
            AVG(CASE WHEN resolved_at IS NOT NULL AND DATE(resolved_at) BETWEEN %s AND %s THEN
                TIMESTAMPDIFF(HOUR, created_at, resolved_at)
            END) as avg_resolution_time,
            COUNT(CASE WHEN status = 'open' THEN 1 END) as open_tickets
        FROM tickets
        """
        result = app_db.execute(support_query, (week_start, week_end, week_start, week_end, week_start, week_end))
        reports['support_metrics'] = dict(result.fetchone())

        # Network performance metrics
        network_query = """
        SELECT
            COUNT(DISTINCT nasipaddress) as active_nas,
            AVG(acctsessiontime) as avg_session_duration,
            COUNT(*) as total_sessions,
            SUM(acctinputoctets + acctoutputoctets) as total_traffic
        FROM radacct
        WHERE DATE(acctstarttime) BETWEEN %s AND %s
        """
        result = radius_db.execute(network_query, (week_start, week_end))
        reports['network_performance'] = dict(result.fetchone())

        # Save weekly report
        self._save_report(app_db, 'weekly', week_start, reports)

        logger.info(f"Weekly reports generated for week {week_start} to {week_end}")

        return {
            'status': 'completed',
            'week_start': week_start.isoformat(),
            'week_end': week_end.isoformat(),
            'reports': reports
        }

    except Exception as e:
        logger.error(f"Weekly report generation failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def generate_monthly_reports(self, app_db: Session, radius_db: Session):
    """Generate comprehensive monthly reports"""
    logger.info("Generating monthly reports")

    try:
        # Get previous month
        today = datetime.now().date()
        first_day_current = today.replace(day=1)
        last_day_previous = first_day_current - timedelta(days=1)
        first_day_previous = last_day_previous.replace(day=1)

        reports = {}

        # Monthly financial summary
        financial_query = """
        SELECT
            COUNT(*) as total_invoices,
            SUM(total_amount) as total_invoiced,
            SUM(paid_amount) as total_collected,
            SUM(balance) as outstanding_balance,
            AVG(total_amount) as avg_invoice_amount,
            COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_invoices,
            COUNT(CASE WHEN status = 'overdue' THEN 1 END) as overdue_invoices
        FROM invoices
        WHERE DATE(issue_date) BETWEEN %s AND %s
        """
        result = app_db.execute(financial_query, (first_day_previous, last_day_previous))
        reports['financial_summary'] = dict(result.fetchone())

        # Monthly customer metrics
        customer_metrics_query = """
        SELECT
            COUNT(CASE WHEN DATE(created_at) BETWEEN %s AND %s THEN 1 END) as new_customers,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_customers,
            COUNT(CASE WHEN status = 'suspended' THEN 1 END) as suspended_customers,
            COUNT(CASE WHEN status = 'terminated' AND DATE(updated_at) BETWEEN %s AND %s THEN 1 END) as churned_customers
        FROM customers
        """
        result = app_db.execute(customer_metrics_query, (first_day_previous, last_day_previous, first_day_previous, last_day_previous))
        customer_metrics = dict(result.fetchone())

        # Calculate churn rate
        if customer_metrics['active_customers'] > 0:
            customer_metrics['churn_rate'] = (customer_metrics['churned_customers'] / customer_metrics['active_customers']) * 100
        else:
            customer_metrics['churn_rate'] = 0

        reports['customer_metrics'] = customer_metrics

        # Monthly usage statistics
        usage_stats_query = """
        SELECT
            SUM(total_octets) as total_data_usage,
            AVG(total_octets) as avg_user_usage,
            MAX(total_octets) as peak_user_usage,
            COUNT(DISTINCT customer_id) as active_users,
            SUM(session_time) as total_session_time
        FROM usage_aggregates
        WHERE date BETWEEN %s AND %s
        """
        result = app_db.execute(usage_stats_query, (first_day_previous, last_day_previous))
        reports['usage_statistics'] = dict(result.fetchone())

        # Plan performance analysis
        plan_analysis_query = """
        SELECT
            p.name as plan_name,
            p.monthly_fee,
            COUNT(s.id) as total_subscribers,
            COUNT(CASE WHEN s.status = 'active' THEN 1 END) as active_subscribers,
            SUM(CASE WHEN s.status = 'active' THEN p.monthly_fee ELSE 0 END) as monthly_revenue,
            AVG(ua.total_octets) as avg_usage_per_user
        FROM service_plans p
        LEFT JOIN subscriptions s ON p.id = s.plan_id
        LEFT JOIN usage_aggregates ua ON s.customer_id = ua.customer_id
            AND ua.date BETWEEN %s AND %s
        GROUP BY p.id, p.name, p.monthly_fee
        ORDER BY monthly_revenue DESC
        """
        result = app_db.execute(plan_analysis_query, (first_day_previous, last_day_previous))
        reports['plan_analysis'] = [dict(row) for row in result.fetchall()]

        # Network performance summary
        network_summary_query = """
        SELECT
            COUNT(*) as total_sessions,
            COUNT(DISTINCT username) as unique_users,
            COUNT(DISTINCT nasipaddress) as active_nas,
            AVG(acctsessiontime) as avg_session_duration,
            SUM(acctinputoctets + acctoutputoctets) as total_traffic,
            MAX(acctinputoctets + acctoutputoctets) as peak_user_traffic
        FROM radacct
        WHERE DATE(acctstarttime) BETWEEN %s AND %s
        """
        result = radius_db.execute(network_summary_query, (first_day_previous, last_day_previous))
        reports['network_summary'] = dict(result.fetchone())

        # Support ticket analysis
        support_analysis_query = """
        SELECT
            COUNT(*) as total_tickets,
            COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_tickets,
            COUNT(CASE WHEN status = 'open' THEN 1 END) as open_tickets,
            AVG(CASE WHEN resolved_at IS NOT NULL THEN
                TIMESTAMPDIFF(HOUR, created_at, resolved_at)
            END) as avg_resolution_time,
            tc.name as top_category
        FROM tickets t
        LEFT JOIN ticket_categories tc ON t.category_id = tc.id
        WHERE DATE(t.created_at) BETWEEN %s AND %s
        GROUP BY tc.name
        ORDER BY COUNT(*) DESC
        LIMIT 1
        """
        result = app_db.execute(support_analysis_query, (first_day_previous, last_day_previous))
        support_data = result.fetchone()
        reports['support_analysis'] = dict(support_data) if support_data else {}

        # Calculate key metrics
        reports['key_metrics'] = self._calculate_key_metrics(reports)

        # Save monthly report
        self._save_report(app_db, 'monthly', first_day_previous, reports)

        # Send monthly report email
        self._send_monthly_report_email(reports, first_day_previous, last_day_previous)

        logger.info(f"Monthly reports generated for {first_day_previous} to {last_day_previous}")

        return {
            'status': 'completed',
            'month_start': first_day_previous.isoformat(),
            'month_end': last_day_previous.isoformat(),
            'reports': reports
        }

    except Exception as e:
        logger.error(f"Monthly report generation failed: {str(e)}")
        raise

    def _calculate_key_metrics(self, reports: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate key business metrics"""
        metrics = {}

        # ARPU (Average Revenue Per User)
        if reports['customer_metrics']['active_customers'] > 0:
            metrics['arpu'] = reports['financial_summary']['total_collected'] / reports['customer_metrics']['active_customers']
        else:
            metrics['arpu'] = 0

        # Collection efficiency
        if reports['financial_summary']['total_invoiced'] > 0:
            metrics['collection_efficiency'] = (reports['financial_summary']['total_collected'] / reports['financial_summary']['total_invoiced']) * 100
        else:
            metrics['collection_efficiency'] = 0

        # Average data usage per user (in GB)
        if reports['usage_statistics']['active_users'] > 0:
            metrics['avg_data_usage_gb'] = (reports['usage_statistics']['total_data_usage'] or 0) / (1024**3) / reports['usage_statistics']['active_users']
        else:
            metrics['avg_data_usage_gb'] = 0

        # Session success rate
        if reports['network_summary']['total_sessions'] > 0:
            # This would need authentication data to be accurate
            metrics['session_success_rate'] = 95.0  # Placeholder
        else:
            metrics['session_success_rate'] = 0

        return metrics


@celery.task(bind=True, base=DatabaseTask)
def generate_custom_report(self, app_db: Session, radius_db: Session, report_config: Dict[str, Any]):
    """Generate custom report based on configuration"""
    logger.info(f"Generating custom report: {report_config.get('name', 'Unnamed')}")

    try:
        report_name = report_config['name']
        date_range = report_config['date_range']
        metrics = report_config['metrics']

        start_date = datetime.strptime(date_range['start'], '%Y-%m-%d').date()
        end_date = datetime.strptime(date_range['end'], '%Y-%m-%d').date()

        report_data = {}

        # Process each requested metric
        for metric in metrics:
            if metric == 'revenue':
                query = """
                SELECT
                    DATE(created_at) as date,
                    COUNT(*) as invoices,
                    SUM(total_amount) as total_amount,
                    SUM(paid_amount) as paid_amount
                FROM invoices
                WHERE DATE(created_at) BETWEEN %s AND %s
                GROUP BY DATE(created_at)
                ORDER BY date
                """
                result = app_db.execute(query, (start_date, end_date))
                report_data['revenue'] = [dict(row) for row in result.fetchall()]

            elif metric == 'usage':
                query = """
                SELECT
                    date,
                    COUNT(DISTINCT customer_id) as active_users,
                    SUM(total_octets) as total_usage,
                    AVG(total_octets) as avg_usage
                FROM usage_aggregates
                WHERE date BETWEEN %s AND %s
                GROUP BY date
                ORDER BY date
                """
                result = app_db.execute(query, (start_date, end_date))
                report_data['usage'] = [dict(row) for row in result.fetchall()]

            elif metric == 'sessions':
                query = """
                SELECT
                    DATE(acctstarttime) as date,
                    COUNT(*) as total_sessions,
                    COUNT(DISTINCT username) as unique_users,
                    AVG(acctsessiontime) as avg_duration
                FROM radacct
                WHERE DATE(acctstarttime) BETWEEN %s AND %s
                GROUP BY DATE(acctstarttime)
                ORDER BY date
                """
                result = radius_db.execute(query, (start_date, end_date))
                report_data['sessions'] = [dict(row) for row in result.fetchall()]

        # Save custom report
        self._save_report(app_db, 'custom', start_date, {
            'config': report_config,
            'data': report_data
        })

        logger.info(f"Custom report '{report_name}' generated successfully")

        return {
            'status': 'completed',
            'report_name': report_name,
            'date_range': date_range,
            'data': report_data
        }

    except Exception as e:
        logger.error(f"Custom report generation failed: {str(e)}")
        raise


def _save_report(self, db: Session, report_type: str, report_date: datetime.date, data: Dict[str, Any]):
    """Save report to database"""
    try:
        save_query = """
        INSERT INTO generated_reports (
            report_type, report_date, data, created_at
        ) VALUES (%s, %s, %s, %s)
        """

        db.execute(save_query, (
            report_type,
            report_date,
            json.dumps(data, default=str),
            datetime.now()
        ))

        db.commit()

    except Exception as e:
        logger.error(f"Failed to save report: {str(e)}")


def _send_daily_report_email(self, reports: Dict[str, Any], report_date: datetime.date):
    """Send daily report via email"""
    try:
        from app.tasks.notifications import send_email_notification

        send_email_notification.delay(
            settings.COMPANY_EMAIL,
            'daily_report',
            {
                'report_date': report_date.strftime('%Y-%m-%d'),
                'reports': reports
            }
        )

    except Exception as e:
        logger.warning(f"Failed to send daily report email: {str(e)}")


def _send_monthly_report_email(self, reports: Dict[str, Any], start_date: datetime.date, end_date: datetime.date):
    """Send monthly report via email"""
    try:
        from app.tasks.notifications import send_email_notification

        send_email_notification.delay(
            settings.COMPANY_EMAIL,
            'monthly_report',
            {
                'month_start': start_date.strftime('%Y-%m-%d'),
                'month_end': end_date.strftime('%Y-%m-%d'),
                'reports': reports
            }
        )

    except Exception as e:
        logger.warning(f"Failed to send monthly report email: {str(e)}")
