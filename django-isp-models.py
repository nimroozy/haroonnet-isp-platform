# ISP Management Models for Django
# Add these to your Django app to get complete ISP functionality

from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

# NAS Device Management
class NASDevice(models.Model):
    DEVICE_TYPES = [
        ('mikrotik', 'MikroTik Router'),
        ('cisco', 'Cisco Router'),
        ('ubiquiti', 'Ubiquiti'),
        ('other', 'Other'),
    ]

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Maintenance'),
        ('error', 'Error'),
    ]

    name = models.CharField(max_length=100)
    ip_address = models.GenericIPAddressField()
    device_type = models.CharField(max_length=20, choices=DEVICE_TYPES)
    location = models.CharField(max_length=200)
    radius_secret = models.CharField(max_length=100, default='haroonnet-secret')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.ip_address})"

    class Meta:
        verbose_name = "NAS Device"
        verbose_name_plural = "NAS Devices"

# Service Plans
class ServicePlan(models.Model):
    PLAN_TYPES = [
        ('basic', 'Basic Plan'),
        ('premium', 'Premium Plan'),
        ('unlimited', 'Unlimited Plan'),
        ('business', 'Business Plan'),
    ]

    name = models.CharField(max_length=100)
    plan_type = models.CharField(max_length=20, choices=PLAN_TYPES)
    download_speed = models.IntegerField(help_text="Download speed in Mbps")
    upload_speed = models.IntegerField(help_text="Upload speed in Mbps")
    data_limit = models.IntegerField(null=True, blank=True, help_text="Data limit in GB (null for unlimited)")
    monthly_price = models.DecimalField(max_digits=10, decimal_places=2)
    setup_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return f"{self.name} - {self.download_speed}/{self.upload_speed} Mbps"

    class Meta:
        verbose_name = "Service Plan"
        verbose_name_plural = "Service Plans"

# Customer Profile (extends User model)
class CustomerProfile(models.Model):
    CUSTOMER_STATUS = [
        ('active', 'Active'),
        ('suspended', 'Suspended'),
        ('terminated', 'Terminated'),
        ('pending', 'Pending'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    customer_id = models.CharField(max_length=50, unique=True)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    service_plan = models.ForeignKey(ServicePlan, on_delete=models.SET_NULL, null=True)
    nas_device = models.ForeignKey(NASDevice, on_delete=models.SET_NULL, null=True)
    static_ip = models.GenericIPAddressField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=CUSTOMER_STATUS, default='active')
    installation_date = models.DateField()
    last_payment_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.customer_id})"

    class Meta:
        verbose_name = "Customer Profile"
        verbose_name_plural = "Customer Profiles"

# Billing and Invoices
class Invoice(models.Model):
    INVOICE_STATUS = [
        ('draft', 'Draft'),
        ('sent', 'Sent'),
        ('paid', 'Paid'),
        ('overdue', 'Overdue'),
        ('cancelled', 'Cancelled'),
    ]

    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE)
    invoice_number = models.CharField(max_length=50, unique=True)
    invoice_date = models.DateField(auto_now_add=True)
    due_date = models.DateField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=INVOICE_STATUS, default='draft')
    description = models.TextField()
    paid_date = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.customer.user.get_full_name()}"

    class Meta:
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"
        ordering = ['-invoice_date']

# Support Tickets
class SupportTicket(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]

    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    CATEGORY_CHOICES = [
        ('technical', 'Technical Issue'),
        ('billing', 'Billing Issue'),
        ('service', 'Service Request'),
        ('complaint', 'Complaint'),
        ('other', 'Other'),
    ]

    ticket_id = models.CharField(max_length=20, unique=True)
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.TextField()
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tickets')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.ticket_id:
            self.ticket_id = f"TKT-{timezone.now().strftime('%Y%m%d')}-{self.pk or '001'}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.ticket_id} - {self.title}"

    class Meta:
        verbose_name = "Support Ticket"
        verbose_name_plural = "Support Tickets"
        ordering = ['-created_at']

# Usage Tracking
class UsageRecord(models.Model):
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE)
    nas_device = models.ForeignKey(NASDevice, on_delete=models.CASCADE)
    session_start = models.DateTimeField()
    session_end = models.DateTimeField(null=True, blank=True)
    bytes_downloaded = models.BigIntegerField(default=0)
    bytes_uploaded = models.BigIntegerField(default=0)
    session_duration = models.IntegerField(default=0, help_text="Duration in seconds")

    def __str__(self):
        return f"{self.customer.user.username} - {self.session_start.date()}"

    class Meta:
        verbose_name = "Usage Record"
        verbose_name_plural = "Usage Records"
        ordering = ['-session_start']

# Payment Records
class Payment(models.Model):
    PAYMENT_METHODS = [
        ('cash', 'Cash'),
        ('bank_transfer', 'Bank Transfer'),
        ('mobile_money', 'Mobile Money'),
        ('credit_card', 'Credit Card'),
        ('other', 'Other'),
    ]

    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE)
    invoice = models.ForeignKey(Invoice, on_delete=models.SET_NULL, null=True, blank=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHODS)
    payment_date = models.DateTimeField(auto_now_add=True)
    reference_number = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"{self.customer.user.get_full_name()} - ${self.amount}"

    class Meta:
        verbose_name = "Payment"
        verbose_name_plural = "Payments"
        ordering = ['-payment_date']
