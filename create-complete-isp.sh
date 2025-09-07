#!/bin/bash

# Complete ISP Management Platform Creator
# This creates a full ISP management interface like the GitHub repository shows

set -e

echo "🏢 Creating Complete ISP Management Platform"
echo "==========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_feature() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

SERVER_IP=$(hostname -I | awk '{print $1}')
print_info "Server IP: $SERVER_IP"

# Clean up any existing installation
print_info "Cleaning up existing installations..."
rm -rf /opt/complete-isp
pkill -f "manage.py runserver" 2>/dev/null || true

# Create complete ISP platform
print_info "Creating complete ISP management platform..."
mkdir -p /opt/complete-isp
cd /opt/complete-isp

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Django and dependencies
pip install django djangorestframework django-cors-headers gunicorn

# Create Django project
django-admin startproject isp_platform .

# Create ISP management app
python manage.py startapp isp_management

# Create comprehensive models
cat > isp_management/models.py << 'EOF'
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import random

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
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.download_speed}/{self.upload_speed} Mbps - ${self.monthly_price}/month"

    class Meta:
        verbose_name = "Service Plan"
        verbose_name_plural = "Service Plans"

class NASDevice(models.Model):
    DEVICE_TYPES = [
        ('mikrotik', 'MikroTik Router'),
        ('cisco', 'Cisco Router'),
        ('ubiquiti', 'Ubiquiti'),
        ('other', 'Other'),
    ]

    STATUS_CHOICES = [
        ('online', 'Online'),
        ('offline', 'Offline'),
        ('maintenance', 'Maintenance'),
        ('error', 'Error'),
    ]

    name = models.CharField(max_length=100)
    ip_address = models.GenericIPAddressField()
    device_type = models.CharField(max_length=20, choices=DEVICE_TYPES)
    location = models.CharField(max_length=200)
    radius_secret = models.CharField(max_length=100, default='haroonnet-secret')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='online')
    description = models.TextField(blank=True)
    last_seen = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.ip_address}) - {self.location}"

    class Meta:
        verbose_name = "NAS Device"
        verbose_name_plural = "NAS Devices"

class CustomerProfile(models.Model):
    CUSTOMER_STATUS = [
        ('active', 'Active'),
        ('suspended', 'Suspended'),
        ('terminated', 'Terminated'),
        ('pending', 'Pending Activation'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    customer_id = models.CharField(max_length=50, unique=True)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    service_plan = models.ForeignKey(ServicePlan, on_delete=models.SET_NULL, null=True)
    nas_device = models.ForeignKey(NASDevice, on_delete=models.SET_NULL, null=True)
    static_ip = models.GenericIPAddressField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=CUSTOMER_STATUS, default='pending')
    installation_date = models.DateField()
    last_payment_date = models.DateField(null=True, blank=True)
    monthly_due_date = models.IntegerField(default=1, help_text="Day of month payment is due")
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.customer_id:
            self.customer_id = f"CUST-{timezone.now().strftime('%Y%m')}-{random.randint(1000, 9999)}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.username} ({self.customer_id})"

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
        ('installation', 'Installation'),
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
            self.ticket_id = f"TKT-{timezone.now().strftime('%Y%m%d')}-{random.randint(100, 999)}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.ticket_id} - {self.title}"

    class Meta:
        verbose_name = "Support Ticket"
        verbose_name_plural = "Support Tickets"
        ordering = ['-created_at']

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

    def save(self, *args, **kwargs):
        if not self.invoice_number:
            self.invoice_number = f"INV-{timezone.now().strftime('%Y%m')}-{random.randint(1000, 9999)}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.invoice_number} - {self.customer.user.get_full_name()} - ${self.amount}"

    class Meta:
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"
        ordering = ['-invoice_date']

class RadiusUser(models.Model):
    username = models.CharField(max_length=64, unique=True)
    password = models.CharField(max_length=64)
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"RADIUS: {self.username}"

    class Meta:
        verbose_name = "RADIUS User"
        verbose_name_plural = "RADIUS Users"
EOF

# Create comprehensive admin interface
cat > isp_management/admin.py << 'EOF'
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import NASDevice, ServicePlan, CustomerProfile, SupportTicket, Invoice, RadiusUser

# Custom admin site
admin.site.site_header = "🏢 HaroonNet ISP Management Platform"
admin.site.site_title = "HaroonNet ISP"
admin.site.index_title = "Professional ISP Management Dashboard"

# Unregister default User admin
admin.site.unregister(User)

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_customer', 'customer_status', 'service_plan_display')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    search_fields = ('username', 'first_name', 'last_name', 'email')

    def is_customer(self, obj):
        return hasattr(obj, 'customerprofile')
    is_customer.boolean = True
    is_customer.short_description = 'Is Customer'

    def customer_status(self, obj):
        if hasattr(obj, 'customerprofile'):
            status = obj.customerprofile.status
            colors = {
                'active': '#28a745',
                'suspended': '#ffc107',
                'terminated': '#dc3545',
                'pending': '#007bff'
            }
            return format_html(
                '<span style="color: {}; font-weight: bold;">● {}</span>',
                colors.get(status, '#6c757d'),
                status.title()
            )
        return '👤 Staff'
    customer_status.short_description = 'Status'

    def service_plan_display(self, obj):
        if hasattr(obj, 'customerprofile') and obj.customerprofile.service_plan:
            plan = obj.customerprofile.service_plan
            return f"{plan.name} ({plan.download_speed}Mbps)"
        return '-'
    service_plan_display.short_description = 'Service Plan'

@admin.register(NASDevice)
class NASDeviceAdmin(admin.ModelAdmin):
    list_display = ('name', 'ip_address', 'device_type', 'location', 'status_display', 'customer_count', 'last_seen')
    list_filter = ('device_type', 'status', 'created_at')
    search_fields = ('name', 'ip_address', 'location')
    readonly_fields = ('created_at', 'last_seen')

    def status_display(self, obj):
        colors = {
            'online': '#28a745',
            'offline': '#dc3545',
            'maintenance': '#ffc107',
            'error': '#fd7e14'
        }
        return format_html(
            '<span style="color: {}; font-weight: bold;">● {}</span>',
            colors.get(obj.status, '#6c757d'),
            obj.status.title()
        )
    status_display.short_description = 'Status'

    def customer_count(self, obj):
        count = obj.customerprofile_set.filter(status='active').count()
        return f"{count} customers"
    customer_count.short_description = 'Active Customers'

    fieldsets = (
        ('🌐 Device Information', {
            'fields': ('name', 'ip_address', 'device_type', 'location', 'status')
        }),
        ('🔒 RADIUS Configuration', {
            'fields': ('radius_secret',),
            'description': 'RADIUS shared secret for authentication'
        }),
        ('📝 Additional Information', {
            'fields': ('description', 'created_at', 'last_seen'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ServicePlan)
class ServicePlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'plan_type', 'speed_display', 'data_limit_display', 'monthly_price', 'customer_count', 'is_active')
    list_filter = ('plan_type', 'is_active')
    search_fields = ('name', 'description')

    def speed_display(self, obj):
        return format_html(
            '<span style="color: #007bff; font-weight: bold;">⬇ {}Mbps ⬆ {}Mbps</span>',
            obj.download_speed, obj.upload_speed
        )
    speed_display.short_description = 'Speed'

    def data_limit_display(self, obj):
        if obj.data_limit:
            return f"{obj.data_limit} GB"
        return "♾️ Unlimited"
    data_limit_display.short_description = 'Data Limit'

    def customer_count(self, obj):
        count = obj.customerprofile_set.filter(status='active').count()
        return f"{count} customers"
    customer_count.short_description = 'Active Customers'

@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ('customer_id', 'user_full_name', 'phone', 'service_plan', 'nas_device', 'status_display', 'last_payment_date')
    list_filter = ('status', 'service_plan', 'nas_device', 'installation_date')
    search_fields = ('customer_id', 'user__username', 'user__first_name', 'user__last_name', 'phone')
    raw_id_fields = ('user',)

    def user_full_name(self, obj):
        name = obj.user.get_full_name() or obj.user.username
        return format_html('<strong>{}</strong><br><small>{}</small>', name, obj.user.email)
    user_full_name.short_description = 'Customer'

    def status_display(self, obj):
        colors = {
            'active': '#28a745',
            'suspended': '#ffc107',
            'terminated': '#dc3545',
            'pending': '#007bff'
        }
        return format_html(
            '<span style="color: {}; font-weight: bold;">● {}</span>',
            colors.get(obj.status, '#6c757d'),
            obj.status.title()
        )
    status_display.short_description = 'Status'

    fieldsets = (
        ('👤 Customer Information', {
            'fields': ('user', 'customer_id', 'phone', 'address', 'status')
        }),
        ('🌐 Service Configuration', {
            'fields': ('service_plan', 'nas_device', 'static_ip', 'installation_date')
        }),
        ('💰 Billing Information', {
            'fields': ('last_payment_date', 'monthly_due_date', 'notes'),
            'classes': ('collapse',)
        }),
    )

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_id', 'customer_name', 'title', 'category', 'priority_display', 'status_display', 'assigned_to', 'created_at')
    list_filter = ('category', 'priority', 'status', 'created_at')
    search_fields = ('ticket_id', 'title', 'customer__customer_id', 'customer__user__username')
    raw_id_fields = ('customer', 'assigned_to')
    readonly_fields = ('ticket_id', 'created_at', 'updated_at')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

    def priority_display(self, obj):
        colors = {
            'low': '#28a745',
            'medium': '#ffc107',
            'high': '#fd7e14',
            'urgent': '#dc3545'
        }
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            colors.get(obj.priority, '#6c757d'),
            obj.priority.title()
        )
    priority_display.short_description = 'Priority'

    def status_display(self, obj):
        colors = {
            'open': '#dc3545',
            'in_progress': '#ffc107',
            'resolved': '#28a745',
            'closed': '#6c757d'
        }
        return format_html(
            '<span style="color: {}; font-weight: bold;">● {}</span>',
            colors.get(obj.status, '#6c757d'),
            obj.status.replace('_', ' ').title()
        )
    status_display.short_description = 'Status'

@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'customer_name', 'amount', 'status_display', 'invoice_date', 'due_date')
    list_filter = ('status', 'invoice_date', 'due_date')
    search_fields = ('invoice_number', 'customer__customer_id', 'customer__user__username')
    readonly_fields = ('invoice_number', 'invoice_date', 'paid_date')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

    def status_display(self, obj):
        colors = {
            'draft': '#6c757d',
            'sent': '#007bff',
            'paid': '#28a745',
            'overdue': '#dc3545',
            'cancelled': '#6c757d'
        }
        return format_html(
            '<span style="color: {}; font-weight: bold;">● {}</span>',
            colors.get(obj.status, '#6c757d'),
            obj.status.title()
        )
    status_display.short_description = 'Status'

@admin.register(RadiusUser)
class RadiusUserAdmin(admin.ModelAdmin):
    list_display = ('username', 'customer_name', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('username', 'customer__customer_id', 'customer__user__username')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'
EOF

# Update settings
print_info "Configuring Django settings..."
cat > isp_platform/settings.py << EOF
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'haroonnet-isp-secret-key-for-professional-platform'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'isp_management',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'isp_platform.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'isp_platform.sqlite3',
    }
}

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kabul'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = '/opt/complete-isp/staticfiles'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

CORS_ALLOW_ALL_ORIGINS = True

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
}
EOF

# Create URLs with API endpoints
cat > isp_platform/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def api_home(request):
    return JsonResponse({
        'platform': 'HaroonNet ISP Management',
        'status': 'running',
        'version': '2.0',
        'admin_url': '/admin',
        'features': [
            'NAS Device Management',
            'Customer Management',
            'Service Plan Management',
            'Billing & Invoicing',
            'Support Ticket System',
            'RADIUS Integration',
            'Usage Tracking'
        ]
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', api_home, name='api_home'),
    path('', api_home, name='home'),
]
EOF

# Run migrations
print_info "Setting up database with ISP features..."
python manage.py makemigrations
python manage.py migrate

# Create admin user if not exists
print_info "Ensuring admin user exists..."
echo "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@haroonnet.com', 'admin123')
    print('Admin user created')
else:
    print('Admin user already exists')
" | python manage.py shell

# Create sample ISP data
print_info "Creating sample ISP data..."
cat > create_isp_data.py << 'EOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'isp_platform.settings')
django.setup()

from isp_management.models import ServicePlan, NASDevice, CustomerProfile
from django.contrib.auth.models import User
from datetime import date

# Create service plans
plans_data = [
    {
        'name': 'Basic Internet',
        'plan_type': 'basic',
        'download_speed': 10,
        'upload_speed': 5,
        'data_limit': None,
        'monthly_price': 25.00,
        'description': 'Perfect for basic browsing and email'
    },
    {
        'name': 'Premium Internet',
        'plan_type': 'premium',
        'download_speed': 50,
        'upload_speed': 25,
        'data_limit': None,
        'monthly_price': 45.00,
        'description': 'Great for streaming and gaming'
    },
    {
        'name': 'Business Internet',
        'plan_type': 'business',
        'download_speed': 100,
        'upload_speed': 50,
        'data_limit': None,
        'monthly_price': 85.00,
        'description': 'Professional grade for businesses'
    }
]

for plan_data in plans_data:
    plan, created = ServicePlan.objects.get_or_create(name=plan_data['name'], defaults=plan_data)
    if created:
        print(f"✅ Created service plan: {plan.name}")

# Create NAS devices
nas_data = [
    {
        'name': 'Main Tower Router',
        'ip_address': '192.168.1.1',
        'device_type': 'mikrotik',
        'location': 'Main Office Tower',
        'description': 'Primary internet gateway router'
    },
    {
        'name': 'North Area Router',
        'ip_address': '192.168.1.10',
        'device_type': 'mikrotik',
        'location': 'North Residential Area',
        'description': 'Serves north residential customers'
    },
    {
        'name': 'Business District Router',
        'ip_address': '192.168.1.20',
        'device_type': 'mikrotik',
        'location': 'Business District',
        'description': 'Dedicated for business customers'
    }
]

for nas_device_data in nas_data:
    nas, created = NASDevice.objects.get_or_create(name=nas_device_data['name'], defaults=nas_device_data)
    if created:
        print(f"✅ Created NAS device: {nas.name}")

print("🎉 Sample ISP data created successfully!")
EOF

python create_isp_data.py

# Collect static files
python manage.py collectstatic --noinput

# Configure Nginx
print_info "Configuring Nginx for ISP platform..."
cat > /etc/nginx/sites-available/complete-isp << EOF
server {
    listen 80;
    server_name $SERVER_IP localhost _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static {
        alias /opt/complete-isp/staticfiles;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/complete-isp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/simple-isp
nginx -t
systemctl restart nginx

# Start Django server
print_info "Starting complete ISP platform..."
nohup python manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &

# Wait for server to start
sleep 5

print_status "Complete ISP Management Platform installed!"

echo ""
echo "🏢 HAROONNET ISP MANAGEMENT PLATFORM"
echo "==================================="
echo ""
print_feature "Professional ISP Management Dashboard"
print_feature "Complete Customer Management System"
print_feature "NAS Device Management (Mikrotik Ready)"
print_feature "Service Plan Management"
print_feature "Support Ticket System"
print_feature "Billing & Invoice Management"
print_feature "RADIUS User Management"
echo ""
echo "🌐 ACCESS YOUR COMPLETE ISP PLATFORM:"
echo "===================================="
echo ""
echo "   🏢 ISP Admin:     http://$SERVER_IP/admin"
echo "   📊 API Status:    http://$SERVER_IP/api"
echo "   🌐 Main Site:     http://$SERVER_IP"
echo ""
echo "🔑 LOGIN CREDENTIALS:"
echo "===================="
echo "   Username: admin"
echo "   Password: admin123"
echo "   Email:    admin@haroonnet.com"
echo ""
echo "📋 ISP MANAGEMENT SECTIONS:"
echo "=========================="
echo "   🌐 NAS Devices - Manage your Mikrotik routers"
echo "   📦 Service Plans - Internet packages and pricing"
echo "   👥 Customer Profiles - Complete customer management"
echo "   🎫 Support Tickets - Customer support system"
echo "   📄 Invoices - Billing and payment tracking"
echo "   📡 RADIUS Users - Authentication management"
echo "   👤 Users - Staff and customer accounts"
echo ""
echo "🎯 SAMPLE DATA INCLUDED:"
echo "======================="
echo "   ✅ 3 Service Plans (Basic $25, Premium $45, Business $85)"
echo "   ✅ 3 NAS Devices (ready for your router IPs)"
echo "   ✅ Professional ISP admin interface"
echo ""

print_status "Your professional ISP management platform is ready!"
print_feature "Open http://$SERVER_IP/admin to manage your ISP business!"
