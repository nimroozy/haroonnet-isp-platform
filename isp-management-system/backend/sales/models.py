from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid

User = get_user_model()


class Lead(models.Model):
    """Sales leads and prospects"""
    LEAD_STATUS_CHOICES = (
        ('new', 'New'),
        ('contacted', 'Contacted'),
        ('qualified', 'Qualified'),
        ('proposal', 'Proposal'),
        ('negotiation', 'Negotiation'),
        ('won', 'Won'),
        ('lost', 'Lost'),
    )
    
    LEAD_SOURCE_CHOICES = (
        ('website', 'Website'),
        ('referral', 'Referral'),
        ('social_media', 'Social Media'),
        ('advertisement', 'Advertisement'),
        ('cold_call', 'Cold Call'),
        ('event', 'Event'),
        ('other', 'Other'),
    )
    
    PRIORITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Contact Information
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField()
    phone = models.CharField(max_length=20)
    alternate_phone = models.CharField(max_length=20, blank=True)
    
    # Company Information
    company_name = models.CharField(max_length=200, blank=True)
    job_title = models.CharField(max_length=100, blank=True)
    
    # Address
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)
    
    # Lead Details
    status = models.CharField(max_length=20, choices=LEAD_STATUS_CHOICES, default='new')
    source = models.CharField(max_length=20, choices=LEAD_SOURCE_CHOICES)
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    
    # Assignment
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_leads')
    
    # Interest
    interested_services = models.JSONField(default=list, blank=True)
    estimated_value = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Notes and Communication
    notes = models.TextField(blank=True)
    last_contact_date = models.DateTimeField(null=True, blank=True)
    next_follow_up = models.DateTimeField(null=True, blank=True)
    
    # Conversion
    converted_to_customer = models.BooleanField(default=False)
    converted_date = models.DateTimeField(null=True, blank=True)
    customer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='lead_profile')
    
    # Metadata
    tags = models.JSONField(default=list, blank=True)
    custom_fields = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_leads')
    
    class Meta:
        db_table = 'leads'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'priority']),
            models.Index(fields=['assigned_to', 'status']),
        ]
    
    def __str__(self):
        return f"{self.first_name} {self.last_name} - {self.company_name or 'Individual'}"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"


class LeadActivity(models.Model):
    """Activity log for leads"""
    ACTIVITY_TYPE_CHOICES = (
        ('call', 'Phone Call'),
        ('email', 'Email'),
        ('meeting', 'Meeting'),
        ('demo', 'Demo'),
        ('note', 'Note'),
        ('status_change', 'Status Change'),
        ('assignment', 'Assignment'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lead = models.ForeignKey(Lead, on_delete=models.CASCADE, related_name='activities')
    
    activity_type = models.CharField(max_length=20, choices=ACTIVITY_TYPE_CHOICES)
    subject = models.CharField(max_length=500)
    description = models.TextField()
    
    # For calls and meetings
    duration = models.IntegerField(null=True, blank=True, help_text="Duration in minutes")
    outcome = models.CharField(max_length=200, blank=True)
    
    # Participants
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    participants = models.ManyToManyField(User, related_name='lead_activities', blank=True)
    
    # Timestamps
    activity_date = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Attachments
    attachments = models.JSONField(default=list, blank=True)
    
    class Meta:
        db_table = 'lead_activities'
        ordering = ['-activity_date']
        verbose_name_plural = 'Lead Activities'
    
    def __str__(self):
        return f"{self.lead.full_name} - {self.activity_type}: {self.subject}"


class Quote(models.Model):
    """Sales quotes/proposals"""
    STATUS_CHOICES = (
        ('draft', 'Draft'),
        ('sent', 'Sent'),
        ('viewed', 'Viewed'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('expired', 'Expired'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    quote_number = models.CharField(max_length=50, unique=True)
    
    # Relations
    lead = models.ForeignKey(Lead, on_delete=models.SET_NULL, null=True, blank=True, related_name='quotes')
    customer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='quotes')
    
    # Quote Details
    title = models.CharField(max_length=500)
    description = models.TextField(blank=True)
    
    # Validity
    issue_date = models.DateField(default=timezone.now)
    valid_until = models.DateField()
    
    # Amounts
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # Terms
    terms_and_conditions = models.TextField(blank=True)
    payment_terms = models.CharField(max_length=200, blank=True)
    
    # Sales info
    prepared_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prepared_quotes')
    
    # Tracking
    sent_at = models.DateTimeField(null=True, blank=True)
    viewed_at = models.DateTimeField(null=True, blank=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    rejected_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'quotes'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Quote {self.quote_number} - {self.title}"


class QuoteItem(models.Model):
    """Line items in quotes"""
    quote = models.ForeignKey(Quote, on_delete=models.CASCADE, related_name='items')
    
    # Item details
    item_type = models.CharField(max_length=50, choices=(
        ('service', 'Service'),
        ('product', 'Product'),
        ('setup', 'Setup Fee'),
        ('custom', 'Custom'),
    ))
    name = models.CharField(max_length=500)
    description = models.TextField(blank=True)
    
    # Pricing
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    # For services
    service_plan = models.ForeignKey('billing.ServicePlan', on_delete=models.SET_NULL, null=True, blank=True)
    
    order = models.IntegerField(default=0)
    
    class Meta:
        db_table = 'quote_items'
        ordering = ['order']
    
    def __str__(self):
        return f"{self.name} - {self.total_price}"
    
    def save(self, *args, **kwargs):
        discount = self.unit_price * self.quantity * (self.discount_percentage / 100)
        self.total_price = (self.unit_price * self.quantity) - discount
        super().save(*args, **kwargs)


class SalesTarget(models.Model):
    """Sales targets for team members"""
    TARGET_TYPE_CHOICES = (
        ('revenue', 'Revenue'),
        ('new_customers', 'New Customers'),
        ('subscriptions', 'Subscriptions'),
        ('calls', 'Calls'),
        ('meetings', 'Meetings'),
    )
    
    PERIOD_CHOICES = (
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Assignment
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sales_targets')
    
    # Target details
    target_type = models.CharField(max_length=20, choices=TARGET_TYPE_CHOICES)
    target_value = models.DecimalField(max_digits=10, decimal_places=2)
    achieved_value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Period
    period = models.CharField(max_length=20, choices=PERIOD_CHOICES)
    start_date = models.DateField()
    end_date = models.DateField()
    
    # Status
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_targets')
    
    class Meta:
        db_table = 'sales_targets'
        unique_together = ('user', 'target_type', 'start_date', 'end_date')
        ordering = ['-start_date']
    
    def __str__(self):
        return f"{self.user.email} - {self.target_type}: {self.target_value}"
    
    @property
    def achievement_percentage(self):
        if self.target_value > 0:
            return (self.achieved_value / self.target_value) * 100
        return 0


class Commission(models.Model):
    """Sales commission tracking"""
    COMMISSION_TYPE_CHOICES = (
        ('new_customer', 'New Customer'),
        ('renewal', 'Renewal'),
        ('upgrade', 'Upgrade'),
        ('referral', 'Referral'),
    )
    
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('paid', 'Paid'),
        ('cancelled', 'Cancelled'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Sales person
    sales_person = models.ForeignKey(User, on_delete=models.CASCADE, related_name='commissions')
    
    # Commission details
    commission_type = models.CharField(max_length=20, choices=COMMISSION_TYPE_CHOICES)
    description = models.CharField(max_length=500)
    
    # Related records
    lead = models.ForeignKey(Lead, on_delete=models.SET_NULL, null=True, blank=True)
    customer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='related_commissions')
    subscription = models.ForeignKey('billing.Subscription', on_delete=models.SET_NULL, null=True, blank=True)
    
    # Amounts
    sale_amount = models.DecimalField(max_digits=10, decimal_places=2)
    commission_percentage = models.DecimalField(max_digits=5, decimal_places=2)
    commission_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Payment info
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_commissions')
    approved_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    payment_reference = models.CharField(max_length=200, blank=True)
    
    # Dates
    sale_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'commissions'
        ordering = ['-sale_date']
    
    def __str__(self):
        return f"{self.sales_person.email} - {self.commission_type}: {self.commission_amount}"
    
    def save(self, *args, **kwargs):
        if not self.commission_amount:
            self.commission_amount = self.sale_amount * (self.commission_percentage / 100)
        super().save(*args, **kwargs)