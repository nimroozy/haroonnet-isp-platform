from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid

User = get_user_model()


class TicketCategory(models.Model):
    """Categories for organizing tickets"""
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=7, default='#000000', help_text="Hex color code")
    icon = models.CharField(max_length=50, blank=True, help_text="Icon class name")
    is_active = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'ticket_categories'
        verbose_name_plural = 'Ticket Categories'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Ticket(models.Model):
    """Support tickets from customers"""
    PRIORITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    )
    
    STATUS_CHOICES = (
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('waiting_customer', 'Waiting for Customer'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
        ('cancelled', 'Cancelled'),
    )
    
    TICKET_TYPE_CHOICES = (
        ('technical', 'Technical Support'),
        ('billing', 'Billing Issue'),
        ('service', 'Service Request'),
        ('complaint', 'Complaint'),
        ('inquiry', 'General Inquiry'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket_number = models.CharField(max_length=20, unique=True)
    
    # Relations
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='customer_tickets')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tickets')
    category = models.ForeignKey(TicketCategory, on_delete=models.SET_NULL, null=True)
    
    # Ticket details
    subject = models.CharField(max_length=500)
    description = models.TextField()
    ticket_type = models.CharField(max_length=20, choices=TICKET_TYPE_CHOICES)
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    closed_at = models.DateTimeField(null=True, blank=True)
    
    # SLA tracking
    sla_due_date = models.DateTimeField(null=True, blank=True)
    first_response_at = models.DateTimeField(null=True, blank=True)
    
    # Additional fields
    is_escalated = models.BooleanField(default=False)
    escalation_reason = models.TextField(blank=True)
    satisfaction_rating = models.IntegerField(null=True, blank=True, help_text="1-5 star rating")
    
    # Metadata
    tags = models.JSONField(default=list, blank=True)
    custom_fields = models.JSONField(default=dict, blank=True)
    
    class Meta:
        db_table = 'tickets'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'priority']),
            models.Index(fields=['customer', 'status']),
        ]
    
    def __str__(self):
        return f"{self.ticket_number} - {self.subject}"
    
    def calculate_sla_due_date(self):
        """Calculate SLA due date based on priority"""
        from datetime import timedelta
        
        sla_hours = {
            'critical': 2,
            'high': 4,
            'medium': 24,
            'low': 48,
        }
        
        hours = sla_hours.get(self.priority, 24)
        self.sla_due_date = self.created_at + timedelta(hours=hours)
        return self.sla_due_date


class TicketComment(models.Model):
    """Comments on tickets"""
    COMMENT_TYPE_CHOICES = (
        ('customer', 'Customer Comment'),
        ('staff', 'Staff Comment'),
        ('internal', 'Internal Note'),
        ('system', 'System Message'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    
    # Comment details
    content = models.TextField()
    comment_type = models.CharField(max_length=20, choices=COMMENT_TYPE_CHOICES, default='staff')
    is_public = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'ticket_comments'
        ordering = ['created_at']
    
    def __str__(self):
        return f"Comment on {self.ticket.ticket_number} by {self.author.email}"


class TicketAttachment(models.Model):
    """File attachments for tickets"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='attachments')
    comment = models.ForeignKey(TicketComment, on_delete=models.CASCADE, null=True, blank=True, related_name='attachments')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE)
    
    # File details
    file = models.FileField(upload_to='ticket_attachments/%Y/%m/')
    filename = models.CharField(max_length=255)
    file_size = models.IntegerField(help_text="File size in bytes")
    mime_type = models.CharField(max_length=100)
    
    # Timestamps
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'ticket_attachments'
        ordering = ['-uploaded_at']
    
    def __str__(self):
        return f"{self.filename} - {self.ticket.ticket_number}"


class TicketTemplate(models.Model):
    """Predefined responses for common issues"""
    name = models.CharField(max_length=200, unique=True)
    category = models.ForeignKey(TicketCategory, on_delete=models.SET_NULL, null=True)
    subject = models.CharField(max_length=500)
    content = models.TextField()
    
    # Usage tracking
    usage_count = models.IntegerField(default=0)
    last_used = models.DateTimeField(null=True, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'ticket_templates'
        ordering = ['-usage_count', 'name']
    
    def __str__(self):
        return self.name


class TicketWorkflow(models.Model):
    """Workflow rules for automatic ticket handling"""
    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True)
    
    # Conditions (stored as JSON)
    conditions = models.JSONField(help_text="Conditions for triggering this workflow")
    
    # Actions (stored as JSON)
    actions = models.JSONField(help_text="Actions to perform when conditions are met")
    
    # Status
    is_active = models.BooleanField(default=True)
    priority = models.IntegerField(default=0, help_text="Higher priority workflows execute first")
    
    # Tracking
    execution_count = models.IntegerField(default=0)
    last_executed = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'ticket_workflows'
        ordering = ['-priority', 'name']
    
    def __str__(self):
        return self.name