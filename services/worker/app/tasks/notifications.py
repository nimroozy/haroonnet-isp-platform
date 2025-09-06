"""
HaroonNet ISP Platform - Notification Tasks
Background tasks for email, SMS, and other notifications
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any
import logging
from jinja2 import Environment, FileSystemLoader
from twilio.rest import Client as TwilioClient
from celery import Task
from sqlalchemy.orm import Session
from app.celery import celery
from app.database import get_app_db
from app.config import settings

logger = logging.getLogger(__name__)

# Initialize Jinja2 environment for email templates
template_env = Environment(loader=FileSystemLoader('templates'))


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
def send_email_notification(self, db: Session, email: str, template_name: str, context: Dict[str, Any]):
    """Send email notification using template"""
    logger.info(f"Sending email notification: {template_name} to {email}")

    try:
        # Get email template
        template_query = """
        SELECT subject, body_html, body_text
        FROM notification_templates
        WHERE name = %s AND type = 'email' AND is_active = 1
        """
        result = db.execute(template_query, (template_name,))
        template_data = result.fetchone()

        if not template_data:
            # Use default templates
            template_data = self._get_default_email_template(template_name)

        if not template_data:
            logger.error(f"Email template not found: {template_name}")
            return {'status': 'template_not_found', 'template': template_name}

        # Render template with context
        subject = self._render_template(template_data.subject, context)
        body_html = self._render_template(template_data.body_html, context) if template_data.body_html else None
        body_text = self._render_template(template_data.body_text, context)

        # Create email message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = settings.COMPANY_EMAIL
        msg['To'] = email

        # Add text part
        text_part = MIMEText(body_text, 'plain', 'utf-8')
        msg.attach(text_part)

        # Add HTML part if available
        if body_html:
            html_part = MIMEText(body_html, 'html', 'utf-8')
            msg.attach(html_part)

        # Send email
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            if settings.SMTP_USE_TLS:
                server.starttls()

            if settings.SMTP_USER and settings.SMTP_PASSWORD:
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)

            server.send_message(msg)

        # Log notification
        self._log_notification(db, email, 'email', template_name, 'sent', context)

        logger.info(f"Email sent successfully: {template_name} to {email}")

        return {
            'status': 'sent',
            'email': email,
            'template': template_name,
            'subject': subject
        }

    except Exception as e:
        logger.error(f"Failed to send email {template_name} to {email}: {str(e)}")
        self._log_notification(db, email, 'email', template_name, 'failed', context, str(e))
        raise

    def _get_default_email_template(self, template_name: str):
        """Get default email templates"""
        templates = {
            'invoice_generated': {
                'subject': 'New Invoice - {{invoice_id}}',
                'body_html': None,
                'body_text': '''Dear {{customer_name}},

A new invoice has been generated for your {{plan_name}} service.

Invoice ID: {{invoice_id}}
Amount: {{amount}} {{currency}}
Due Date: {{due_date}}

Please make payment before the due date to avoid service interruption.

Thank you for choosing {{company_name}}.

Best regards,
{{company_name}} Team'''
            },
            'payment_reminder': {
                'subject': 'Payment Reminder - Invoice {{invoice_number}}',
                'body_html': None,
                'body_text': '''Dear {{customer_name}},

This is a friendly reminder that your invoice {{invoice_number}} is due in {{days_until_due}} days.

Amount: {{amount}} {{currency}}
Due Date: {{due_date}}

Please make payment to avoid service interruption.

Thank you,
{{company_name}} Team'''
            },
            'service_suspended': {
                'subject': 'Service Suspended - Overdue Payment',
                'body_html': None,
                'body_text': '''Dear {{customer_name}},

Your service has been suspended due to overdue payment.

Invoice: {{invoice_number}}
Amount: {{amount}} {{currency}}
Days Overdue: {{days_overdue}}

Please make payment immediately to restore your service.

Contact us for assistance: {{company_phone}}

{{company_name}} Team'''
            },
            'quota_warning': {
                'subject': 'Data Usage Warning - {{percentage}}% Used',
                'body_html': None,
                'body_text': '''Dear {{customer_name}},

You have used {{percentage}}% of your monthly data quota for {{plan_name}}.

Used: {{used_quota}}
Total: {{total_quota}}

Consider upgrading your plan to avoid speed reduction.

{{company_name}} Team'''
            },
            'quota_exceeded': {
                'subject': 'Data Quota Exceeded - Service Suspended',
                'body_html': None,
                'body_text': '''Dear {{customer_name}},

Your monthly data quota has been exceeded and your service has been suspended.

Plan: {{plan_name}}
Used: {{used_quota}}
Quota: {{total_quota}}

Please upgrade your plan or wait for next month's reset.

{{company_name}} Team'''
            },
            'fup_applied': {
                'subject': 'Fair Usage Policy Applied',
                'body_html': None,
                'body_text': '''Dear {{customer_name}},

You have exceeded your data quota for {{plan_name}}. Your speed has been reduced to {{new_speed}} as per our Fair Usage Policy.

Your speed will be restored at the beginning of next month.

{{company_name}} Team'''
            }
        }

        template_data = templates.get(template_name)
        if template_data:
            # Convert to object-like structure
            class TemplateData:
                def __init__(self, data):
                    self.subject = data['subject']
                    self.body_html = data['body_html']
                    self.body_text = data['body_text']
            return TemplateData(template_data)

        return None

    def _render_template(self, template_str: str, context: Dict[str, Any]) -> str:
        """Render Jinja2 template string with context"""
        if not template_str:
            return ""

        # Add company info to context
        context.update({
            'company_name': settings.COMPANY_NAME,
            'company_email': settings.COMPANY_EMAIL,
            'company_phone': settings.COMPANY_PHONE,
            'currency': settings.DEFAULT_CURRENCY
        })

        template = template_env.from_string(template_str)
        return template.render(**context)

    def _log_notification(self, db: Session, recipient: str, type: str, template: str,
                         status: str, context: Dict[str, Any], error: str = None):
        """Log notification to database"""
        try:
            log_query = """
            INSERT INTO notification_logs (
                recipient, type, template, status, context, error_message, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            db.execute(log_query, (
                recipient, type, template, status,
                str(context), error, datetime.now()
            ))
            db.commit()
        except Exception as e:
            logger.error(f"Failed to log notification: {str(e)}")


@celery.task(bind=True, base=DatabaseTask)
def send_sms_notification(self, db: Session, phone: str, template_name: str, context: Dict[str, Any]):
    """Send SMS notification using template"""
    logger.info(f"Sending SMS notification: {template_name} to {phone}")

    try:
        # Check if SMS is configured
        if not all([settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN, settings.TWILIO_FROM_NUMBER]):
            logger.warning("SMS not configured - skipping SMS notification")
            return {'status': 'not_configured', 'phone': phone}

        # Get SMS template
        template_query = """
        SELECT message
        FROM notification_templates
        WHERE name = %s AND type = 'sms' AND is_active = 1
        """
        result = db.execute(template_query, (template_name,))
        template_data = result.fetchone()

        if not template_data:
            # Use default templates
            message = self._get_default_sms_template(template_name, context)
        else:
            message = self._render_template(template_data.message, context)

        if not message:
            logger.error(f"SMS template not found: {template_name}")
            return {'status': 'template_not_found', 'template': template_name}

        # Send SMS via Twilio
        client = TwilioClient(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)

        message_obj = client.messages.create(
            body=message,
            from_=settings.TWILIO_FROM_NUMBER,
            to=phone
        )

        # Log notification
        self._log_notification(db, phone, 'sms', template_name, 'sent', context)

        logger.info(f"SMS sent successfully: {template_name} to {phone}")

        return {
            'status': 'sent',
            'phone': phone,
            'template': template_name,
            'message_sid': message_obj.sid
        }

    except Exception as e:
        logger.error(f"Failed to send SMS {template_name} to {phone}: {str(e)}")
        self._log_notification(db, phone, 'sms', template_name, 'failed', context, str(e))
        raise

    def _get_default_sms_template(self, template_name: str, context: Dict[str, Any]) -> str:
        """Get default SMS templates"""
        templates = {
            'payment_reminder': 'Payment reminder: Invoice {{invoice_number}} due {{due_date}}. Amount: {{amount}}. Pay now to avoid suspension.',
            'service_suspended': 'Service suspended due to overdue payment. Invoice {{invoice_number}}: {{amount}}. Pay now to restore service.',
            'quota_warning': 'Data usage warning: {{percentage}}% used. Plan: {{plan_name}}. Upgrade to avoid speed reduction.',
            'quota_exceeded': 'Data quota exceeded. Service suspended. Plan: {{plan_name}}. Upgrade or wait for reset.',
        }

        template_str = templates.get(template_name)
        if template_str:
            return self._render_template(template_str, context)

        return None


@celery.task(bind=True, base=DatabaseTask)
def send_pending_notifications(self, db: Session):
    """Send pending notifications from the queue"""
    logger.info("Processing pending notifications")

    try:
        # Get pending notifications
        pending_query = """
        SELECT id, recipient, type, template, context, retry_count
        FROM notification_queue
        WHERE status = 'pending'
        AND (scheduled_at IS NULL OR scheduled_at <= NOW())
        AND retry_count < 3
        ORDER BY created_at
        LIMIT 100
        """

        result = db.execute(pending_query)
        notifications = result.fetchall()

        processed_count = 0

        for notification in notifications:
            try:
                # Parse context
                import json
                context = json.loads(notification.context) if notification.context else {}

                # Mark as processing
                update_query = """
                UPDATE notification_queue
                SET status = 'processing', processed_at = NOW()
                WHERE id = %s
                """
                db.execute(update_query, (notification.id,))
                db.commit()

                # Send notification
                if notification.type == 'email':
                    result = send_email_notification.delay(
                        notification.recipient,
                        notification.template,
                        context
                    )
                elif notification.type == 'sms':
                    result = send_sms_notification.delay(
                        notification.recipient,
                        notification.template,
                        context
                    )
                else:
                    logger.warning(f"Unknown notification type: {notification.type}")
                    continue

                # Update status based on result
                if result.successful():
                    final_status = 'sent'
                else:
                    final_status = 'failed'

                update_final_query = """
                UPDATE notification_queue
                SET status = %s, retry_count = retry_count + 1
                WHERE id = %s
                """
                db.execute(update_final_query, (final_status, notification.id))
                db.commit()

                processed_count += 1

            except Exception as e:
                logger.error(f"Failed to process notification {notification.id}: {str(e)}")

                # Update retry count
                retry_query = """
                UPDATE notification_queue
                SET status = 'failed', retry_count = retry_count + 1, error_message = %s
                WHERE id = %s
                """
                db.execute(retry_query, (str(e), notification.id))
                db.commit()

                continue

        logger.info(f"Processed {processed_count} pending notifications")

        return {
            'status': 'completed',
            'processed_count': processed_count
        }

    except Exception as e:
        logger.error(f"Failed to process pending notifications: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def cleanup_sent_notifications(self, db: Session):
    """Clean up old sent notifications"""
    logger.info("Cleaning up old notifications")

    try:
        # Delete old notification logs (keep for 90 days)
        cleanup_date = datetime.now() - timedelta(days=90)

        cleanup_query = """
        DELETE FROM notification_logs
        WHERE created_at < %s
        """
        result = db.execute(cleanup_query, (cleanup_date,))
        deleted_logs = result.rowcount

        # Delete old sent notifications from queue (keep for 30 days)
        queue_cleanup_date = datetime.now() - timedelta(days=30)

        queue_cleanup_query = """
        DELETE FROM notification_queue
        WHERE status IN ('sent', 'failed')
        AND created_at < %s
        """
        result = db.execute(queue_cleanup_query, (queue_cleanup_date,))
        deleted_queue = result.rowcount

        db.commit()

        logger.info(f"Cleaned up {deleted_logs} notification logs and {deleted_queue} queue items")

        return {
            'status': 'completed',
            'deleted_logs': deleted_logs,
            'deleted_queue': deleted_queue
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Notification cleanup failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def queue_notification(self, db: Session, recipient: str, notification_type: str,
                      template: str, context: Dict[str, Any], scheduled_at=None):
    """Queue a notification for later processing"""
    logger.info(f"Queueing notification: {template} for {recipient}")

    try:
        import json

        queue_query = """
        INSERT INTO notification_queue (
            recipient, type, template, context, status,
            scheduled_at, created_at
        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
        """

        db.execute(queue_query, (
            recipient,
            notification_type,
            template,
            json.dumps(context),
            'pending',
            scheduled_at,
            datetime.now()
        ))

        db.commit()

        return {
            'status': 'queued',
            'recipient': recipient,
            'type': notification_type,
            'template': template
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Failed to queue notification: {str(e)}")
        raise
