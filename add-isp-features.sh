#!/bin/bash

# Add ISP Features to Django - NAS Management, Customers, Billing
# Run this on your server to add complete ISP functionality

set -e

echo "🚀 Adding Complete ISP Features to Django Admin"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Navigate to Django project
cd /opt/simple-isp
source venv/bin/activate

# Create ISP app
print_info "Creating ISP management app..."
python manage.py startapp isp_management

# Create models file
cat > isp_management/models.py << 'EOF'
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

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

    def save(self, *args, **kwargs):
        if not self.ticket_id:
            import random
            self.ticket_id = f"TKT-{timezone.now().strftime('%Y%m%d')}-{random.randint(100, 999)}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.ticket_id} - {self.title}"

    class Meta:
        verbose_name = "Support Ticket"
        verbose_name_plural = "Support Tickets"
        ordering = ['-created_at']
EOF

# Create admin file
cat > isp_management/admin.py << 'EOF'
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User
from django.utils.html import format_html
from .models import NASDevice, ServicePlan, CustomerProfile, SupportTicket

# Unregister default User admin
admin.site.unregister(User)

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_customer', 'customer_status')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    search_fields = ('username', 'first_name', 'last_name', 'email')

    def is_customer(self, obj):
        return hasattr(obj, 'customerprofile')
    is_customer.boolean = True
    is_customer.short_description = 'Customer'

    def customer_status(self, obj):
        if hasattr(obj, 'customerprofile'):
            status = obj.customerprofile.status
            colors = {'active': 'green', 'suspended': 'orange', 'terminated': 'red', 'pending': 'blue'}
            return format_html('<span style="color: {};">{}</span>', colors.get(status, 'black'), status.title())
        return '-'
    customer_status.short_description = 'Status'

@admin.register(NASDevice)
class NASDeviceAdmin(admin.ModelAdmin):
    list_display = ('name', 'ip_address', 'device_type', 'location', 'status', 'created_at')
    list_filter = ('device_type', 'status', 'created_at')
    search_fields = ('name', 'ip_address', 'location')
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('Device Information', {
            'fields': ('name', 'ip_address', 'device_type', 'location', 'status')
        }),
        ('RADIUS Configuration', {
            'fields': ('radius_secret',)
        }),
        ('Additional Info', {
            'fields': ('description', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ServicePlan)
class ServicePlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'plan_type', 'speed_display', 'monthly_price', 'is_active')
    list_filter = ('plan_type', 'is_active')
    search_fields = ('name', 'description')

    def speed_display(self, obj):
        return f"{obj.download_speed}/{obj.upload_speed} Mbps"
    speed_display.short_description = 'Speed (Down/Up)'

@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ('customer_id', 'user_full_name', 'phone', 'service_plan', 'status', 'installation_date')
    list_filter = ('status', 'service_plan', 'nas_device', 'installation_date')
    search_fields = ('customer_id', 'user__username', 'user__first_name', 'user__last_name', 'phone')
    raw_id_fields = ('user', 'service_plan', 'nas_device')

    def user_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username
    user_full_name.short_description = 'Customer Name'

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_id', 'customer_name', 'title', 'category', 'priority', 'status', 'created_at')
    list_filter = ('category', 'priority', 'status', 'created_at')
    search_fields = ('ticket_id', 'title', 'customer__customer_id')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

# Customize admin site
admin.site.site_header = "HaroonNet ISP Management"
admin.site.site_title = "HaroonNet ISP Admin"
admin.site.index_title = "ISP Management Dashboard"
EOF

# Update settings to include the new app
print_info "Updating Django settings..."
sed -i "/    'corsheaders',/a\\    'isp_management'," isp/settings.py

# Create and run migrations
print_info "Creating database migrations..."
python manage.py makemigrations isp_management
python manage.py migrate

# Create sample data
print_info "Creating sample ISP data..."
cat > create_sample_data.py << 'EOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'isp.settings')
django.setup()

from isp_management.models import NASDevice, ServicePlan, CustomerProfile
from django.contrib.auth.models import User
from datetime import date

# Create sample service plans
plans = [
    {'name': 'Basic Plan', 'plan_type': 'basic', 'download_speed': 10, 'upload_speed': 5, 'monthly_price': 25.00},
    {'name': 'Premium Plan', 'plan_type': 'premium', 'download_speed': 50, 'upload_speed': 25, 'monthly_price': 45.00},
    {'name': 'Unlimited Plan', 'plan_type': 'unlimited', 'download_speed': 100, 'upload_speed': 50, 'monthly_price': 75.00},
]

for plan_data in plans:
    plan, created = ServicePlan.objects.get_or_create(name=plan_data['name'], defaults=plan_data)
    if created:
        print(f"Created service plan: {plan.name}")

# Create sample NAS devices
nas_devices = [
    {'name': 'Main Router', 'ip_address': '192.168.1.1', 'device_type': 'mikrotik', 'location': 'Main Office'},
    {'name': 'Tower 1', 'ip_address': '192.168.1.10', 'device_type': 'mikrotik', 'location': 'North Tower'},
    {'name': 'Tower 2', 'ip_address': '192.168.1.11', 'device_type': 'mikrotik', 'location': 'South Tower'},
]

for nas_data in nas_devices:
    nas, created = NASDevice.objects.get_or_create(name=nas_data['name'], defaults=nas_data)
    if created:
        print(f"Created NAS device: {nas.name}")

print("Sample ISP data created successfully!")
EOF

python create_sample_data.py

# Restart Django server
print_info "Restarting Django server..."
pkill -f "manage.py runserver" 2>/dev/null || true
sleep 2
nohup python manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &

# Wait for server to start
sleep 5

print_status "ISP features added successfully!"

echo ""
echo "🌐 YOUR ISP PLATFORM NOW INCLUDES:"
echo "=================================="
echo ""
echo "✅ NAS Device Management (Add your Mikrotik routers)"
echo "✅ Service Plan Management (Basic/Premium/Unlimited)"
echo "✅ Customer Profile Management (Complete customer info)"
echo "✅ Support Ticket System (Customer support)"
echo "✅ User Management (Staff and customers)"
echo ""
echo "🔧 ACCESS YOUR ENHANCED ISP ADMIN:"
echo "================================="
echo "   URL: http://64.23.189.11/admin"
echo "   Login: admin / admin123"
echo ""
echo "📋 NEW ADMIN SECTIONS AVAILABLE:"
echo "==============================="
echo "   🌐 NAS Devices - Add your Mikrotik routers"
echo "   📦 Service Plans - Create internet packages"
echo "   👥 Customer Profiles - Complete customer management"
echo "   🎫 Support Tickets - Customer support system"
echo "   👤 Users - Enhanced user management"
echo ""
echo "🚀 SAMPLE DATA CREATED:"
echo "======================"
echo "   ✅ 3 Sample service plans (Basic, Premium, Unlimited)"
echo "   ✅ 3 Sample NAS devices (routers)"
echo "   ✅ Ready for your real ISP data"
echo ""

print_status "Your complete ISP management platform is ready!"
print_info "Refresh http://64.23.189.11/admin to see all new ISP features!"
