from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal
import uuid

User = get_user_model()


class ServicePlan(models.Model):
    """Internet service plans offered by the ISP"""
    PLAN_TYPE_CHOICES = (
        ('residential', 'Residential'),
        ('business', 'Business'),
        ('dedicated', 'Dedicated'),
        ('custom', 'Custom'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    plan_type = models.CharField(max_length=20, choices=PLAN_TYPE_CHOICES)
    description = models.TextField(blank=True)
    
    # Speed settings
    download_speed = models.IntegerField(help_text="Download speed in Mbps")
    upload_speed = models.IntegerField(help_text="Upload speed in Mbps")
    
    # Pricing
    monthly_price = models.DecimalField(max_digits=10, decimal_places=2)
    setup_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Data limits
    data_limit = models.BigIntegerField(null=True, blank=True, help_text="Data limit in GB, null for unlimited")
    
    # RADIUS attributes
    radius_group = models.CharField(max_length=100, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'service_plans'
        ordering = ['plan_type', 'monthly_price']
    
    def __str__(self):
        return f"{self.name} - {self.download_speed}/{self.upload_speed} Mbps"


class Subscription(models.Model):
    """Customer subscriptions to service plans"""
    STATUS_CHOICES = (
        ('active', 'Active'),
        ('suspended', 'Suspended'),
        ('terminated', 'Terminated'),
        ('pending', 'Pending Activation'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='subscriptions')
    plan = models.ForeignKey(ServicePlan, on_delete=models.PROTECT)
    
    # Subscription details
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField(null=True, blank=True)
    next_billing_date = models.DateField()
    
    # Pricing override
    custom_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    suspension_reason = models.TextField(blank=True)
    
    # Technical details
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    mac_address = models.CharField(max_length=17, blank=True)
    nas_identifier = models.CharField(max_length=100, blank=True)
    
    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'subscriptions'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.customer.email} - {self.plan.name}"
    
    @property
    def monthly_amount(self):
        if self.custom_price:
            return self.custom_price
        discount = self.plan.monthly_price * (self.discount_percentage / 100)
        return self.plan.monthly_price - discount


class Invoice(models.Model):
    """Monthly invoices for customers"""
    STATUS_CHOICES = (
        ('draft', 'Draft'),
        ('sent', 'Sent'),
        ('paid', 'Paid'),
        ('partially_paid', 'Partially Paid'),
        ('overdue', 'Overdue'),
        ('cancelled', 'Cancelled'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    invoice_number = models.CharField(max_length=50, unique=True)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='invoices')
    subscription = models.ForeignKey(Subscription, on_delete=models.SET_NULL, null=True)
    
    # Dates
    issue_date = models.DateField(default=timezone.now)
    due_date = models.DateField()
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Amounts
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    paid_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # Additional info
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'invoices'
        ordering = ['-issue_date', '-invoice_number']
    
    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.customer.email}"
    
    @property
    def balance_due(self):
        return self.total_amount - self.paid_amount
    
    def mark_as_paid(self):
        self.status = 'paid'
        self.paid_amount = self.total_amount
        self.save()


class InvoiceItem(models.Model):
    """Line items on invoices"""
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='items')
    description = models.CharField(max_length=500)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    class Meta:
        db_table = 'invoice_items'
    
    def __str__(self):
        return f"{self.description} - {self.total_price}"
    
    def save(self, *args, **kwargs):
        self.total_price = self.quantity * self.unit_price
        super().save(*args, **kwargs)


class Payment(models.Model):
    """Payment records"""
    PAYMENT_METHOD_CHOICES = (
        ('cash', 'Cash'),
        ('bank_transfer', 'Bank Transfer'),
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('mobile_money', 'Mobile Money'),
        ('check', 'Check'),
        ('online', 'Online Payment'),
    )
    
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment_id = models.CharField(max_length=50, unique=True)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payments')
    invoice = models.ForeignKey(Invoice, on_delete=models.SET_NULL, null=True, related_name='payments')
    
    # Payment details
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES)
    payment_date = models.DateTimeField(default=timezone.now)
    
    # Transaction details
    transaction_id = models.CharField(max_length=200, blank=True)
    reference_number = models.CharField(max_length=100, blank=True)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Additional info
    notes = models.TextField(blank=True)
    processed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='processed_payments')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'payments'
        ordering = ['-payment_date']
    
    def __str__(self):
        return f"Payment {self.payment_id} - {self.amount}"


class UsageRecord(models.Model):
    """Track customer bandwidth usage"""
    subscription = models.ForeignKey(Subscription, on_delete=models.CASCADE, related_name='usage_records')
    date = models.DateField()
    
    # Usage in bytes
    download_bytes = models.BigIntegerField(default=0)
    upload_bytes = models.BigIntegerField(default=0)
    total_bytes = models.BigIntegerField(default=0)
    
    # Session info
    session_count = models.IntegerField(default=0)
    session_time = models.IntegerField(default=0, help_text="Total session time in seconds")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'usage_records'
        unique_together = ('subscription', 'date')
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.subscription.customer.email} - {self.date}"
    
    def save(self, *args, **kwargs):
        self.total_bytes = self.download_bytes + self.upload_bytes
        super().save(*args, **kwargs)