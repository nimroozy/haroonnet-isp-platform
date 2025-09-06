"""
HaroonNet ISP Platform - Billing Tasks
Background tasks for invoice generation, payment processing, and billing automation
"""

from datetime import datetime, timedelta
from typing import List
import logging
from celery import Task
from sqlalchemy.orm import Session
from app.celery import celery
from app.database import get_app_db
from app.config import settings
from app.tasks.notifications import send_email_notification, send_sms_notification

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


# ---------------------------------------------------------------------------
# Helper functions (moved out of Celery task scope)
# ---------------------------------------------------------------------------


def _generate_invoice_number(db: Session) -> str:
    """Generate a unique invoice number using the current year/month and a sequence."""
    now = datetime.now()
    prefix = f"INV-{now.year}{now.month:02d}-"

    query = """
    SELECT COUNT(*) + 1 as next_num
    FROM invoices
    WHERE invoice_number LIKE %s
    """

    result = db.execute(query, (f"{prefix}%",))
    next_num = result.fetchone().next_num

    return f"{prefix}{next_num:04d}"


def _create_invoice(db: Session, subscription, billing_month, next_month):
    """Create an invoice for a subscription and return the newly-created invoice ID."""
    try:
        invoice_number = _generate_invoice_number(db)

        issue_date = datetime.now().date()
        due_date = issue_date + timedelta(days=30)

        invoice_query = """
        INSERT INTO invoices (
            invoice_number, customer_id, issue_date, due_date,
            subtotal, tax_amount, total_amount, balance,
            status, currency, created_at
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        subtotal = float(subscription.monthly_fee)
        tax_amount = subtotal * 0.0  # Configure tax rate as needed
        total_amount = subtotal + tax_amount

        result = db.execute(
            invoice_query,
            (
                invoice_number,
                subscription.customer_id,
                issue_date,
                due_date,
                subtotal,
                tax_amount,
                total_amount,
                total_amount,  # balance = total initially
                'sent',
                settings.DEFAULT_CURRENCY,
                datetime.now(),
            ),
        )

        invoice_id = result.lastrowid

        # Create invoice item
        item_query = """
        INSERT INTO invoice_items (
            invoice_id, subscription_id, description, quantity,
            unit_price, line_total, period_start, period_end,
            item_type, created_at
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        db.execute(
            item_query,
            (
                invoice_id,
                subscription.id,
                f"{subscription.plan_name} - Monthly Service",
                1.0,
                subtotal,
                subtotal,
                billing_month,
                next_month - timedelta(days=1),
                'subscription',
                datetime.now(),
            ),
        )

        return invoice_id

    except Exception as e:
        logger.error(f"Failed to create invoice: {str(e)}")
        return None


def _suspend_customer_services(db: Session, customer_id: int):
    """Suspend all active subscriptions for a customer."""
    try:
        update_query = """
        UPDATE subscriptions
        SET status = 'suspended', suspension_date = CURDATE()
        WHERE customer_id = %s AND status = 'active'
        """
        db.execute(update_query, (customer_id,))

        # Retrieve suspended usernames for CoA disconnect
        username_query = """
        SELECT username FROM subscriptions
        WHERE customer_id = %s AND status = 'suspended'
        """
        result = db.execute(username_query, (customer_id,))
        usernames = [row.username for row in result.fetchall()]

        from app.tasks.radius import send_coa_disconnect

        for username in usernames:
            send_coa_disconnect.delay(username)

    except Exception as e:
        logger.error(f"Failed to suspend customer {customer_id}: {str(e)}")
        raise


def _reactivate_customer_services(db: Session, customer_id: int):
    """Reactivate suspended subscriptions for a customer once payment is complete."""
    try:
        update_query = """
        UPDATE subscriptions
        SET status = 'active', suspension_date = NULL
        WHERE customer_id = %s AND status = 'suspended'
        """
        db.execute(update_query, (customer_id,))
        logger.info(f"Reactivated services for customer {customer_id}")
    except Exception as e:
        logger.error(f"Failed to reactivate customer {customer_id}: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def generate_monthly_invoices(self, db: Session):
    """Generate monthly invoices for all active subscriptions"""
    logger.info("Starting monthly invoice generation")

    try:
        # Get current date and billing period
        today = datetime.now().date()
        billing_month = today.replace(day=1)
        next_month = (billing_month + timedelta(days=32)).replace(day=1)

        # Query active subscriptions due for billing
        query = """
        SELECT s.id, s.customer_id, s.plan_id, s.username, s.next_billing_date,
               c.first_name, c.last_name, c.email, c.company_name,
               p.name as plan_name, p.monthly_fee
        FROM subscriptions s
        JOIN customers c ON s.customer_id = c.id
        JOIN service_plans p ON s.plan_id = p.id
        WHERE s.status = 'active'
        AND s.next_billing_date <= %s
        AND s.billing_cycle = 'monthly'
        """

        result = db.execute(query, (today,))
        subscriptions = result.fetchall()

        invoice_count = 0
        total_amount = 0

        for subscription in subscriptions:
            try:
                # Generate invoice
                invoice_id = _create_invoice(db, subscription, billing_month, next_month)

                if invoice_id:
                    invoice_count += 1
                    total_amount += float(subscription.monthly_fee)

                    # Update next billing date
                    update_query = """
                    UPDATE subscriptions
                    SET next_billing_date = %s
                    WHERE id = %s
                    """
                    db.execute(update_query, (next_month, subscription.id))

                    # Schedule email notification
                    send_email_notification.delay(
                        subscription.email,
                        'invoice_generated',
                        {
                            'customer_name': subscription.first_name or subscription.company_name,
                            'plan_name': subscription.plan_name,
                            'amount': subscription.monthly_fee,
                            'invoice_id': invoice_id,
                            'due_date': (today + timedelta(days=30)).strftime('%Y-%m-%d')
                        }
                    )

            except Exception as e:
                logger.error(f"Failed to generate invoice for subscription {subscription.id}: {str(e)}")
                continue

        db.commit()

        logger.info(f"Generated {invoice_count} invoices, total amount: {total_amount}")

        return {
            'status': 'completed',
            'invoices_generated': invoice_count,
            'total_amount': total_amount,
            'billing_period': billing_month.strftime('%Y-%m')
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Monthly invoice generation failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def process_overdue_accounts(self, db: Session):
    """Process overdue accounts and apply policies"""
    logger.info("Processing overdue accounts")

    try:
        # Get overdue invoices
        query = """
        SELECT i.id, i.customer_id, i.invoice_number, i.total_amount, i.due_date,
               c.first_name, c.last_name, c.email, c.company_name,
               DATEDIFF(CURDATE(), i.due_date) as days_overdue
        FROM invoices i
        JOIN customers c ON i.customer_id = c.id
        WHERE i.status IN ('sent', 'partial')
        AND i.due_date < CURDATE()
        AND i.balance > 0
        ORDER BY i.due_date
        """

        result = db.execute(query)
        overdue_invoices = result.fetchall()

        processed_count = 0
        suspended_count = 0

        for invoice in overdue_invoices:
            try:
                days_overdue = invoice.days_overdue

                # Apply policies based on days overdue
                if days_overdue >= settings.OVERDUE_GRACE_DAYS:
                    # Suspend services for this customer
                    _suspend_customer_services(db, invoice.customer_id)
                    suspended_count += 1

                    # Send suspension notice
                    send_email_notification.delay(
                        invoice.email,
                        'service_suspended',
                        {
                            'customer_name': invoice.first_name or invoice.company_name,
                            'invoice_number': invoice.invoice_number,
                            'amount': invoice.total_amount,
                            'days_overdue': days_overdue
                        }
                    )

                processed_count += 1

            except Exception as e:
                logger.error(f"Failed to process overdue invoice {invoice.id}: {str(e)}")
                continue

        db.commit()

        logger.info(f"Processed {processed_count} overdue accounts, suspended {suspended_count}")

        return {
            'status': 'completed',
            'processed_count': processed_count,
            'suspended_count': suspended_count
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Overdue account processing failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def send_payment_reminders(self, db: Session):
    """Send payment reminders for upcoming due dates"""
    logger.info("Sending payment reminders")

    try:
        reminder_count = 0

        for days_before in settings.PAYMENT_REMINDER_DAYS:
            reminder_date = datetime.now().date() + timedelta(days=days_before)

            # Get invoices due on reminder date
            query = """
            SELECT i.id, i.customer_id, i.invoice_number, i.total_amount, i.due_date,
                   c.first_name, c.last_name, c.email, c.company_name
            FROM invoices i
            JOIN customers c ON i.customer_id = c.id
            WHERE i.status = 'sent'
            AND i.due_date = %s
            AND i.balance > 0
            """

            result = db.execute(query, (reminder_date,))
            invoices = result.fetchall()

            for invoice in invoices:
                try:
                    # Send email reminder
                    send_email_notification.delay(
                        invoice.email,
                        'payment_reminder',
                        {
                            'customer_name': invoice.first_name or invoice.company_name,
                            'invoice_number': invoice.invoice_number,
                            'amount': invoice.total_amount,
                            'due_date': invoice.due_date.strftime('%Y-%m-%d'),
                            'days_until_due': days_before
                        }
                    )

                    reminder_count += 1

                except Exception as e:
                    logger.error(f"Failed to send reminder for invoice {invoice.id}: {str(e)}")
                    continue

        logger.info(f"Sent {reminder_count} payment reminders")

        return {
            'status': 'completed',
            'reminders_sent': reminder_count
        }

    except Exception as e:
        logger.error(f"Payment reminder task failed: {str(e)}")
        raise


@celery.task(bind=True, base=DatabaseTask)
def process_payment(self, db: Session, payment_data: dict):
    """Process a payment and update invoice status"""
    logger.info(f"Processing payment: {payment_data}")

    try:
        invoice_id = payment_data['invoice_id']
        amount = float(payment_data['amount'])
        payment_method = payment_data['method']
        transaction_id = payment_data.get('transaction_id')

        # Get invoice details
        invoice_query = """
        SELECT id, customer_id, balance, total_amount, status
        FROM invoices WHERE id = %s
        """
        result = db.execute(invoice_query, (invoice_id,))
        invoice = result.fetchone()

        if not invoice:
            raise ValueError(f"Invoice {invoice_id} not found")

        # Create payment record
        payment_number = self._generate_payment_number(db)

        payment_query = """
        INSERT INTO payments (
            payment_number, customer_id, invoice_id, amount,
            currency, payment_date, method, transaction_id,
            status, created_at
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        db.execute(payment_query, (
            payment_number,
            invoice.customer_id,
            invoice_id,
            amount,
            settings.DEFAULT_CURRENCY,
            datetime.now().date(),
            payment_method,
            transaction_id,
            'completed',
            datetime.now()
        ))

        # Update invoice
        new_balance = float(invoice.balance) - amount
        new_status = 'paid' if new_balance <= 0 else 'partial'

        update_query = """
        UPDATE invoices
        SET paid_amount = paid_amount + %s, balance = %s, status = %s
        WHERE id = %s
        """
        db.execute(update_query, (amount, new_balance, new_status, invoice_id))

        # If fully paid, reactivate suspended services
        if new_status == 'paid':
            _reactivate_customer_services(db, invoice.customer_id)

        db.commit()

        logger.info(f"Payment processed successfully: {payment_number}")

        return {
            'status': 'completed',
            'payment_number': payment_number,
            'new_balance': new_balance,
            'invoice_status': new_status
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Payment processing failed: {str(e)}")
        raise

    def _generate_payment_number(self, db: Session):
        """Generate unique payment number"""
        now = datetime.now()
        prefix = f"PAY-{now.year}{now.month:02d}-"

        query = """
        SELECT COUNT(*) + 1 as next_num
        FROM payments
        WHERE payment_number LIKE %s
        """

        result = db.execute(query, (f"{prefix}%",))
        next_num = result.fetchone().next_num

        return f"{prefix}{next_num:04d}"
