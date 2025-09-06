"""
HaroonNet ISP Platform - Celery Configuration
Handles background tasks for billing, notifications, and system operations
"""

import os
from celery import Celery
from celery.schedules import crontab
from app.config import settings

# Create Celery instance
celery = Celery(
    'haroonnet_worker',
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        'app.tasks.billing',
        'app.tasks.notifications',
        'app.tasks.radius',
        'app.tasks.reports',
        'app.tasks.system',
    ]
)

# Celery configuration
celery.conf.update(
    # Task routing
    task_routes={
        'app.tasks.billing.*': {'queue': 'billing'},
        'app.tasks.notifications.*': {'queue': 'notifications'},
        'app.tasks.radius.*': {'queue': 'radius'},
        'app.tasks.reports.*': {'queue': 'reports'},
        'app.tasks.system.*': {'queue': 'system'},
    },

    # Task execution
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    result_expires=3600,
    timezone='UTC',
    enable_utc=True,

    # Worker configuration
    worker_prefetch_multiplier=1,
    task_acks_late=True,
    worker_max_tasks_per_child=1000,

    # Task retry configuration
    task_default_retry_delay=60,
    task_max_retries=3,

    # Monitoring
    worker_send_task_events=True,
    task_send_sent_event=True,

    # Beat schedule for periodic tasks
    beat_schedule={
        # Billing tasks
        'generate-monthly-invoices': {
            'task': 'app.tasks.billing.generate_monthly_invoices',
            'schedule': crontab(hour=2, minute=0, day_of_month=1),  # 1st day of month at 2 AM
        },
        'process-overdue-accounts': {
            'task': 'app.tasks.billing.process_overdue_accounts',
            'schedule': crontab(hour=6, minute=0),  # Daily at 6 AM
        },
        'send-payment-reminders': {
            'task': 'app.tasks.billing.send_payment_reminders',
            'schedule': crontab(hour=10, minute=0),  # Daily at 10 AM
        },

        # Usage and quota tasks
        'update-usage-aggregates': {
            'task': 'app.tasks.radius.update_usage_aggregates',
            'schedule': crontab(minute='*/15'),  # Every 15 minutes
        },
        'check-quota-limits': {
            'task': 'app.tasks.radius.check_quota_limits',
            'schedule': crontab(minute='*/30'),  # Every 30 minutes
        },
        'reset-monthly-quotas': {
            'task': 'app.tasks.radius.reset_monthly_quotas',
            'schedule': crontab(hour=0, minute=0, day_of_month=1),  # 1st day of month
        },

        # System maintenance
        'cleanup-old-logs': {
            'task': 'app.tasks.system.cleanup_old_logs',
            'schedule': crontab(hour=3, minute=0),  # Daily at 3 AM
        },
        'backup-database': {
            'task': 'app.tasks.system.backup_database',
            'schedule': crontab(hour=1, minute=0),  # Daily at 1 AM
        },
        'system-health-check': {
            'task': 'app.tasks.system.system_health_check',
            'schedule': crontab(minute='*/5'),  # Every 5 minutes
        },

        # Reports
        'generate-daily-reports': {
            'task': 'app.tasks.reports.generate_daily_reports',
            'schedule': crontab(hour=7, minute=0),  # Daily at 7 AM
        },
        'generate-weekly-reports': {
            'task': 'app.tasks.reports.generate_weekly_reports',
            'schedule': crontab(hour=8, minute=0, day_of_week=1),  # Monday at 8 AM
        },
        'generate-monthly-reports': {
            'task': 'app.tasks.reports.generate_monthly_reports',
            'schedule': crontab(hour=9, minute=0, day_of_month=1),  # 1st day of month at 9 AM
        },

        # Notifications
        'send-pending-notifications': {
            'task': 'app.tasks.notifications.send_pending_notifications',
            'schedule': crontab(minute='*/5'),  # Every 5 minutes
        },
        'cleanup-sent-notifications': {
            'task': 'app.tasks.notifications.cleanup_sent_notifications',
            'schedule': crontab(hour=4, minute=0),  # Daily at 4 AM
        },
    },

    # Queue configuration
    task_default_queue='default',
    task_create_missing_queues=True,
)

# Auto-discover tasks
celery.autodiscover_tasks()

if __name__ == '__main__':
    celery.start()
