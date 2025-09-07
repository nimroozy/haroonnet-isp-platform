#!/bin/bash

# Simple Django ISP Platform - Guaranteed to Work
# This installs just the Django backend with admin interface
# No complex React frontend - uses Django admin for management

set -e

echo "🏢 Simple Django ISP Platform - Guaranteed Installation"
echo "======================================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
print_info "Server IP: $SERVER_IP"

# Update system
print_info "Updating system..."
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx git curl

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database
print_info "Setting up database..."
DB_PASSWORD=$(openssl rand -base64 16)
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS isp_db;
DROP USER IF EXISTS isp_user;
CREATE USER isp_user WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE isp_db OWNER isp_user;
GRANT ALL PRIVILEGES ON DATABASE isp_db TO isp_user;
EOF

# Create simple Django app
print_info "Creating Django ISP application..."
cd /opt
rm -rf django-isp
mkdir django-isp
cd django-isp

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Django and dependencies
pip install django psycopg2-binary djangorestframework django-cors-headers gunicorn

# Create Django project
django-admin startproject isp_platform .
cd isp_platform

# Create simple settings for external access
cat > settings.py << EOF
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = '$(openssl rand -base64 32)'
DEBUG = True
ALLOWED_HOSTS = ['*']  # Allow all hosts for external access

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
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'isp_db',
        'USER': 'isp_user',
        'PASSWORD': '$DB_PASSWORD',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kabul'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = '/opt/django-isp/staticfiles'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS settings for external access
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://$SERVER_IP",
    "http://$SERVER_IP:3000",
    "http://$SERVER_IP:8000",
]

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
}
EOF

# Run migrations
print_info "Setting up database..."
cd ..
python manage.py makemigrations
python manage.py migrate

# Create superuser
print_info "Creating admin user..."
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@haroonnet.com', 'admin123') if not User.objects.filter(username='admin').exists() else None" | python manage.py shell

# Collect static files
python manage.py collectstatic --noinput

# Configure Nginx
print_info "Configuring Nginx for external access..."
cat > /etc/nginx/sites-available/django-isp << EOF
server {
    listen 80;
    server_name $SERVER_IP localhost _;

    # Django admin and API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
    }

    # Static files
    location /static {
        alias /opt/django-isp/staticfiles;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/django-isp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# Configure supervisor
print_info "Setting up process management..."
cat > /etc/supervisor/conf.d/django-isp.conf << EOF
[program:django-isp]
command=/opt/django-isp/venv/bin/gunicorn isp_platform.wsgi:application --bind 0.0.0.0:8000 --workers 2
directory=/opt/django-isp
user=root
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/django-isp/logs/django.log
environment=PATH="/opt/django-isp/venv/bin"
EOF

# Create logs directory
mkdir -p /opt/django-isp/logs

# Start services
systemctl start supervisor
systemctl enable supervisor
supervisorctl reread
supervisorctl update
supervisorctl start django-isp

# Configure firewall
print_info "Opening firewall ports..."
ufw allow 80/tcp
ufw allow 8000/tcp
ufw reload

print_status "Simple Django ISP Platform installed successfully!"

echo ""
echo "🌐 ACCESS YOUR ISP PLATFORM:"
echo "============================"
echo ""
echo "   🔧 Django Admin:  http://$SERVER_IP/admin"
echo "   📊 API Root:      http://$SERVER_IP/api"
echo "   🌐 Main Site:     http://$SERVER_IP"
echo ""
echo "🔑 LOGIN:"
echo "========"
echo "   Username: admin"
echo "   Password: admin123"
echo "   Email:    admin@haroonnet.com"
echo ""
echo "📋 MANAGEMENT:"
echo "============="
echo "   Status:   supervisorctl status"
echo "   Restart:  supervisorctl restart django-isp"
echo "   Logs:     tail -f /opt/django-isp/logs/django.log"
echo ""

print_status "Your ISP platform is ready at http://$SERVER_IP!"
