#!/bin/bash

# ISP Management System Installation Script for Ubuntu 22.04
# This script will install and configure the complete ISP Management System

set -e

echo "========================================="
echo "ISP Management System Installation Script"
echo "========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    print_warning "This script is designed for Ubuntu 22.04 LTS"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y \
    build-essential \
    python3-dev \
    python3-pip \
    python3-venv \
    postgresql \
    postgresql-contrib \
    redis-server \
    nginx \
    supervisor \
    git \
    curl \
    wget \
    htop \
    net-tools \
    software-properties-common

# Install Node.js
print_status "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Configure PostgreSQL
print_status "Configuring PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
DB_NAME="isp_management"
DB_USER="isp_user"
DB_PASSWORD=$(openssl rand -base64 32)

sudo -u postgres psql << EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

print_status "Database created successfully"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASSWORD"

# Configure Redis
print_status "Configuring Redis..."
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Setup backend
print_status "Setting up backend..."
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
# Django settings
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,$(hostname -I | cut -d' ' -f1)

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
RADIUS_SECRET=testing123

# Redis
REDIS_URL=redis://127.0.0.1:6379/1
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Email (configure with your SMTP settings)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=noreply@isp-management.com

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Logging
DJANGO_LOG_LEVEL=INFO
EOF

# Create logs directory
mkdir -p logs

# Run migrations
print_status "Running database migrations..."
python manage.py makemigrations
python manage.py migrate

# Create superuser
print_status "Creating superuser..."
echo "Please create a superuser account:"
python manage.py createsuperuser

# Collect static files
print_status "Collecting static files..."
python manage.py collectstatic --noinput

# Deactivate virtual environment
deactivate

# Setup frontend
print_status "Setting up frontend..."
cd ../frontend

# Create .env file
cat > .env << EOF
REACT_APP_API_URL=http://localhost:8000/api
REACT_APP_WEBSOCKET_URL=ws://localhost:8000/ws
EOF

# Install dependencies
npm install

# Build frontend
print_status "Building frontend..."
npm run build

# Configure Nginx
print_status "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/isp-management > /dev/null << EOF
server {
    listen 80;
    server_name localhost;
    
    # Frontend
    location / {
        root /home/$USER/isp-management-system/frontend/build;
        try_files \$uri \$uri/ /index.html;
    }
    
    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Django Admin
    location /admin {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    # Static files
    location /static {
        alias /home/$USER/isp-management-system/backend/staticfiles;
    }
    
    # Media files
    location /media {
        alias /home/$USER/isp-management-system/backend/media;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/isp-management /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Configure Supervisor
print_status "Configuring Supervisor..."
sudo tee /etc/supervisor/conf.d/isp-management.conf > /dev/null << EOF
[program:isp-django]
command=/home/$USER/isp-management-system/backend/venv/bin/gunicorn core.wsgi:application --bind 127.0.0.1:8000 --workers 4
directory=/home/$USER/isp-management-system/backend
user=$USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/$USER/isp-management-system/backend/logs/gunicorn.log
environment=PATH="/home/$USER/isp-management-system/backend/venv/bin"

[program:isp-celery-worker]
command=/home/$USER/isp-management-system/backend/venv/bin/celery -A core worker -l info
directory=/home/$USER/isp-management-system/backend
user=$USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/$USER/isp-management-system/backend/logs/celery-worker.log

[program:isp-celery-beat]
command=/home/$USER/isp-management-system/backend/venv/bin/celery -A core beat -l info
directory=/home/$USER/isp-management-system/backend
user=$USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/$USER/isp-management-system/backend/logs/celery-beat.log
EOF

# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update

# Create systemd service for easier management
sudo tee /etc/systemd/system/isp-management.service > /dev/null << EOF
[Unit]
Description=ISP Management System
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/supervisorctl start isp-django isp-celery-worker isp-celery-beat
ExecStop=/usr/bin/supervisorctl stop isp-django isp-celery-worker isp-celery-beat
ExecReload=/usr/bin/supervisorctl restart isp-django isp-celery-worker isp-celery-beat

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable isp-management

# Optional: Install FreeRADIUS
read -p "Do you want to install FreeRADIUS? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installing FreeRADIUS..."
    cd /home/$USER/isp-management-system
    sudo ./scripts/install/install_freeradius.sh
fi

# Start all services
print_status "Starting all services..."
sudo supervisorctl start all

# Final setup
print_status "Creating data directories..."
cd /home/$USER/isp-management-system/backend
mkdir -p media/avatars media/ticket_attachments

# Set permissions
sudo chown -R $USER:$USER /home/$USER/isp-management-system

# Print summary
echo
echo "========================================="
echo -e "${GREEN}Installation completed successfully!${NC}"
echo "========================================="
echo
echo "Access the application at:"
echo "  - Frontend: http://localhost"
echo "  - API: http://localhost/api"
echo "  - Admin Panel: http://localhost/admin"
echo
echo "Database credentials have been saved to:"
echo "  - /home/$USER/isp-management-system/backend/.env"
echo
echo "Default superuser:"
echo "  - Username: [The one you created]"
echo
echo "To start/stop services:"
echo "  - sudo systemctl start isp-management"
echo "  - sudo systemctl stop isp-management"
echo "  - sudo systemctl restart isp-management"
echo
echo "Logs are available at:"
echo "  - /home/$USER/isp-management-system/backend/logs/"
echo
print_warning "Remember to:"
echo "  1. Configure your email settings in .env"
echo "  2. Set up SSL certificates for production"
echo "  3. Configure firewall rules"
echo "  4. Set up regular backups"
echo
echo "Thank you for installing ISP Management System!"