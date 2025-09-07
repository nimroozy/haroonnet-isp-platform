#!/bin/bash

# HaroonNet ISP Platform - Django Version One-Click Installer
# This installs the professional Django + React ISP management system
# Designed for external access and production use

set -e

echo "🏢 HaroonNet ISP Platform - Professional Django Installation"
echo "==========================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    case "$status" in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "FEATURE") echo -e "${PURPLE}🚀 $message${NC}" ;;
    esac
}

echo "🚀 INSTALLING PROFESSIONAL DJANGO-BASED ISP PLATFORM:"
echo ""
print_status "FEATURE" "Django REST Framework backend with PostgreSQL"
print_status "FEATURE" "React frontend with Material-UI professional design"
print_status "FEATURE" "Complete customer management with billing"
print_status "FEATURE" "FreeRADIUS integration for authentication"
print_status "FEATURE" "Support ticket system with SLA tracking"
print_status "FEATURE" "Network operations center (NOC) monitoring"
print_status "FEATURE" "Sales and CRM functionality"
print_status "FEATURE" "Professional Nginx configuration for external access"
echo ""

# Get server IP for configuration
SERVER_IP=$(hostname -I | awk '{print $1}')
print_status "INFO" "Server IP detected: $SERVER_IP"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_status "WARNING" "Running as root - will create regular user for Django"
    # Create isp user for running Django
    if ! id "isp" &>/dev/null; then
        useradd -m -s /bin/bash isp
        usermod -aG sudo isp
        print_status "SUCCESS" "Created user 'isp' for Django application"
    fi
    ISP_USER="isp"
    ISP_HOME="/home/isp"
else
    ISP_USER=$USER
    ISP_HOME=$HOME
    print_status "SUCCESS" "Running as non-root user: $ISP_USER"
fi

# Update system
print_status "INFO" "Updating system packages..."
if [[ $EUID -eq 0 ]]; then
    apt update && apt upgrade -y
    apt install -y build-essential python3-dev python3-pip python3-venv postgresql postgresql-contrib redis-server nginx supervisor git curl wget htop net-tools software-properties-common ufw
else
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y build-essential python3-dev python3-pip python3-venv postgresql postgresql-contrib redis-server nginx supervisor git curl wget htop net-tools software-properties-common ufw
fi

# Install Node.js
print_status "INFO" "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Configure firewall for external access
print_status "INFO" "Configuring firewall for external access..."
if [[ $EUID -eq 0 ]]; then
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 8000/tcp  # Django API
    ufw allow 3000/tcp  # React frontend
    ufw allow 1812/udp  # RADIUS Auth
    ufw allow 1813/udp  # RADIUS Accounting
    ufw --force enable
else
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8000/tcp
    sudo ufw allow 3000/tcp
    sudo ufw allow 1812/udp
    sudo ufw allow 1813/udp
    sudo ufw --force enable
fi

# Configure PostgreSQL
print_status "INFO" "Setting up PostgreSQL database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Generate secure database credentials
DB_NAME="isp_management"
DB_USER="isp_user"
DB_PASSWORD=$(openssl rand -base64 32)

# Create database and user
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

print_status "SUCCESS" "Database configured successfully"

# Configure Redis
print_status "INFO" "Configuring Redis..."
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Download the Django ISP platform
print_status "INFO" "Downloading Django ISP Management System..."
cd $ISP_HOME
rm -rf isp-management-system
git clone -b cursor/develop-isp-management-gui-with-radius-integration-8670 https://github.com/nimroozy/haroonnet-isp-platform.git isp-management-system
cd isp-management-system

# Setup backend
print_status "INFO" "Setting up Django backend..."
cd isp-management-system/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create environment configuration
cat > .env << EOF
# Django settings
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,$SERVER_IP,0.0.0.0

# Database
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432

# RADIUS Server
RADIUS_SERVER=localhost
RADIUS_AUTH_PORT=1812
RADIUS_ACCT_PORT=1813
RADIUS_SECRET=haroonnet-radius-secret

# Redis
REDIS_URL=redis://127.0.0.1:6379/1
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# CORS - Allow external access
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://$SERVER_IP:3000,http://$SERVER_IP:8000,http://$SERVER_IP

# Email (configure later)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=admin@haroonnet.com
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=noreply@haroonnet.com

# Logging
DJANGO_LOG_LEVEL=INFO
EOF

# Create logs directory
mkdir -p logs

# Run migrations
print_status "INFO" "Setting up database schema..."
python manage.py makemigrations
python manage.py migrate

# Create superuser automatically
print_status "INFO" "Creating admin user..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@haroonnet.com', 'admin123') if not User.objects.filter(username='admin').exists() else None" | python manage.py shell

# Collect static files
python manage.py collectstatic --noinput

deactivate

# Setup frontend
print_status "INFO" "Setting up React frontend..."
cd ../frontend

# Create frontend environment
cat > .env << EOF
REACT_APP_API_URL=http://$SERVER_IP:8000/api
REACT_APP_WEBSOCKET_URL=ws://$SERVER_IP:8000/ws
EOF

# Install and build frontend
npm install
npm run build

# Configure Nginx for external access
print_status "INFO" "Configuring Nginx for external access..."
sudo tee /etc/nginx/sites-available/haroonnet-isp > /dev/null << EOF
server {
    listen 80;
    server_name $SERVER_IP localhost;

    # Frontend
    location / {
        root $ISP_HOME/isp-management-system/isp-management-system/frontend/build;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API - External access enabled
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CORS headers for external access
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
    }

    # Django Admin
    location /admin {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Static files
    location /static {
        alias $ISP_HOME/isp-management-system/isp-management-system/backend/staticfiles;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/haroonnet-isp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Configure Supervisor for Django
print_status "INFO" "Configuring Django services..."
sudo tee /etc/supervisor/conf.d/haroonnet-isp.conf > /dev/null << EOF
[program:haroonnet-django]
command=$ISP_HOME/isp-management-system/isp-management-system/backend/venv/bin/gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 4
directory=$ISP_HOME/isp-management-system/isp-management-system/backend
user=$ISP_USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=$ISP_HOME/isp-management-system/isp-management-system/backend/logs/gunicorn.log
environment=PATH="$ISP_HOME/isp-management-system/isp-management-system/backend/venv/bin"

[program:haroonnet-celery]
command=$ISP_HOME/isp-management-system/isp-management-system/backend/venv/bin/celery -A core worker -l info
directory=$ISP_HOME/isp-management-system/isp-management-system/backend
user=$ISP_USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=$ISP_HOME/isp-management-system/isp-management-system/backend/logs/celery.log
EOF

# Set proper permissions
if [[ $EUID -eq 0 ]]; then
    chown -R $ISP_USER:$ISP_USER $ISP_HOME/isp-management-system
fi

# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start all

print_status "SUCCESS" "Django ISP Management System installed successfully!"

echo ""
echo "🌐 ACCESS YOUR PROFESSIONAL ISP PLATFORM:"
echo "=========================================="
echo ""
echo "   🏢 Frontend (React):    http://$SERVER_IP"
echo "   🔧 Django Admin:        http://$SERVER_IP/admin"
echo "   📊 API Docs:            http://$SERVER_IP/api/docs"
echo ""
echo "🔑 LOGIN CREDENTIALS:"
echo "===================="
echo "   📧 Username: admin"
echo "   🔒 Password: admin123"
echo "   📧 Email:    admin@haroonnet.com"
echo ""
echo "🎯 FEATURES AVAILABLE:"
echo "====================="
echo "   ✅ Customer Management"
echo "   ✅ Billing & Invoicing"
echo "   ✅ RADIUS Integration"
echo "   ✅ Support Tickets"
echo "   ✅ Sales & CRM"
echo "   ✅ Network Monitoring"
echo "   ✅ Professional UI"
echo ""
echo "📋 MANAGEMENT COMMANDS:"
echo "======================"
echo "   Start:   sudo supervisorctl start all"
echo "   Stop:    sudo supervisorctl stop all"
echo "   Restart: sudo supervisorctl restart all"
echo "   Status:  sudo supervisorctl status"
echo ""

print_status "SUCCESS" "Professional ISP Management Platform Ready!"
print_status "FEATURE" "Open http://$SERVER_IP to start managing your ISP!"
