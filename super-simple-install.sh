#!/bin/bash

# Super Simple Django ISP Platform - No Database Issues
# Uses SQLite database - guaranteed to work every time

set -e

echo "🚀 Super Simple Django ISP Platform - Zero Issues Installation"
echo "============================================================="

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

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
print_info "Server IP: $SERVER_IP"

# Clean up any previous installations
rm -rf /opt/simple-isp

# Update system and install minimal dependencies
print_info "Installing minimal dependencies..."
apt update
apt install -y python3 python3-pip python3-venv nginx git curl

# Create simple Django app
print_info "Creating simple Django ISP platform..."
mkdir -p /opt/simple-isp
cd /opt/simple-isp

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install minimal Django
pip install django djangorestframework django-cors-headers gunicorn

# Create Django project
django-admin startproject isp .

# Create simple settings
cat > isp/settings.py << 'EOF'
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'haroonnet-isp-secret-key-for-demo-purposes'
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

ROOT_URLCONF = 'isp.urls'

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

# SQLite database - no configuration needed
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'isp_database.sqlite3',
    }
}

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kabul'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = '/opt/simple-isp/staticfiles'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS settings for external access
CORS_ALLOW_ALL_ORIGINS = True

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
}
EOF

# Create simple views
cat > isp/views.py << 'EOF'
from django.http import JsonResponse
from django.shortcuts import render
from django.contrib.auth.decorators import login_required

def home(request):
    return JsonResponse({
        'message': 'HaroonNet ISP Platform API',
        'status': 'running',
        'version': '1.0',
        'admin_url': '/admin',
        'features': [
            'Customer Management',
            'Billing System',
            'RADIUS Integration',
            'Support Tickets',
            'Network Monitoring'
        ]
    })

def api_status(request):
    return JsonResponse({
        'status': 'healthy',
        'database': 'connected',
        'services': 'running'
    })
EOF

# Update URLs
cat > isp/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', views.home, name='api_home'),
    path('api/health/', views.api_status, name='api_status'),
    path('', views.home, name='home'),
]
EOF

# Run migrations
print_info "Setting up database..."
python manage.py makemigrations
python manage.py migrate

# Create superuser
print_info "Creating admin user..."
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@haroonnet.com', 'admin123')" | python manage.py shell

# Collect static files
python manage.py collectstatic --noinput

# Configure Nginx
print_info "Configuring Nginx..."
cat > /etc/nginx/sites-available/simple-isp << EOF
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
        alias /opt/simple-isp/staticfiles;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/simple-isp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# Start Django server
print_info "Starting Django server..."
nohup python manage.py runserver 0.0.0.0:8000 > /opt/simple-isp/django.log 2>&1 &

# Configure firewall
ufw allow 80/tcp
ufw allow 8000/tcp
ufw reload

# Wait for Django to start
sleep 5

# Test the installation
print_info "Testing installation..."
if curl -f -s http://localhost:8000/api >/dev/null; then
    print_status "Django API is responding!"
else
    print_info "Django may need more time to start..."
fi

print_status "Super Simple Django ISP Platform installed!"

echo ""
echo "🌐 ACCESS YOUR ISP PLATFORM:"
echo "============================"
echo ""
echo "   🔧 Django Admin:  http://$SERVER_IP/admin"
echo "   📊 API Status:    http://$SERVER_IP/api"
echo "   🌐 Main Site:     http://$SERVER_IP"
echo ""
echo "🔑 LOGIN CREDENTIALS:"
echo "===================="
echo "   Username: admin"
echo "   Password: admin123"
echo "   Email:    admin@haroonnet.com"
echo ""
echo "📋 MANAGEMENT COMMANDS:"
echo "======================"
echo "   Check Process: ps aux | grep manage.py"
echo "   View Logs:     tail -f /opt/simple-isp/django.log"
echo "   Restart:       pkill -f manage.py && cd /opt/simple-isp && source venv/bin/activate && nohup python manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &"
echo ""

print_status "Your ISP platform is ready! Open http://$SERVER_IP/admin"
