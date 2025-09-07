#!/bin/bash

# HaroonNet ISP Platform - One Command Installation
# Complete ISP management platform with web interfaces
#
# Usage: curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/one-command-install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case "$status" in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

echo ""
echo "🚀 HaroonNet ISP Platform - One Command Installation"
echo "====================================================="
echo ""
echo "This will install a complete ISP management platform with:"
echo "  • Web-based admin and customer portals"
echo "  • FreeRADIUS authentication server"
echo "  • MySQL database and Redis cache"
echo "  • Monitoring with Grafana and Prometheus"
echo "  • Background task processing"
echo "  • Complete billing and customer management"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_status "ERROR" "This script should not be run as root for security reasons"
    print_status "INFO" "Please run as a regular user with sudo privileges"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "22.04" /etc/os-release; then
    print_status "WARNING" "This script is designed for Ubuntu 22.04 LTS"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "SUCCESS" "Ubuntu 22.04 LTS detected"
print_status "SUCCESS" "Running as non-root user"

# Install system requirements
print_status "INFO" "Installing system packages..."
sudo apt update
sudo apt install -y curl wget git htop tree jq vim nano ufw fail2ban build-essential

# Install Docker
print_status "INFO" "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "SUCCESS" "Docker installed"
else
    print_status "SUCCESS" "Docker already installed"
fi

# Install Docker Compose
print_status "INFO" "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "SUCCESS" "Docker Compose installed"
else
    print_status "SUCCESS" "Docker Compose already installed"
fi

# Configure firewall
print_status "INFO" "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1812/udp  # RADIUS Auth
sudo ufw allow 1813/udp  # RADIUS Accounting
sudo ufw allow 3799/udp  # CoA/DM
sudo ufw allow 3000/tcp  # Admin UI
sudo ufw allow 3001/tcp  # Customer Portal
sudo ufw allow 4000/tcp  # API
sudo ufw allow 3002/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 5555/tcp  # Flower
sudo ufw --force enable

# Clone the platform
print_status "INFO" "Downloading HaroonNet ISP Platform..."
cd ~
sudo rm -rf /opt/haroonnet
rm -rf haroonnet-isp-platform

git clone https://github.com/nimroozy/haroonnet-isp-platform.git
sudo mv haroonnet-isp-platform /opt/haroonnet
sudo chown -R $USER:$USER /opt/haroonnet
cd /opt/haroonnet

# Generate secure configuration
print_status "INFO" "Generating secure configuration..."
MYSQL_ROOT_PASS=$(openssl rand -hex 16)
MYSQL_APP_PASS=$(openssl rand -hex 16)
RADIUS_DB_PASS=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)

# Create environment file
cat > .env << EOF
NODE_ENV=production
JWT_SECRET=$JWT_SECRET

# Database Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS
MYSQL_DATABASE=haroonnet
MYSQL_USER=haroonnet
MYSQL_PASSWORD=$MYSQL_APP_PASS

# RADIUS Database
RADIUS_DB_NAME=radius
RADIUS_DB_USER=radius
RADIUS_DB_PASSWORD=$RADIUS_DB_PASS

# Redis Configuration
REDIS_PASSWORD=

# Grafana Configuration
GRAFANA_PASSWORD=admin123

# Company Information
COMPANY_NAME=HaroonNet ISP
COMPANY_EMAIL=admin@haroonnet.com
COMPANY_PHONE=+93-123-456-789
COMPANY_ADDRESS=Kabul, Afghanistan
COMPANY_TIMEZONE=Asia/Kabul
DEFAULT_CURRENCY=AFN

# CoA Configuration
COA_SECRET=shared-secret-for-coa
COA_PORT=3799

# Monitoring
MONITORING_ENABLED=true
METRICS_RETENTION_DAYS=90

# Debug and Logging
DEBUG_MODE=false
LOG_LEVEL=info
EOF

# Save credentials
cat > .credentials << EOF
# HaroonNet ISP Platform - Generated Credentials
# KEEP THIS FILE SECURE!

MySQL Root Password: $MYSQL_ROOT_PASS
MySQL App Password: $MYSQL_APP_PASS
RADIUS Database Password: $RADIUS_DB_PASS
JWT Secret: $JWT_SECRET

# Web Interface Credentials
Admin Email: admin@haroonnet.com
Admin Password: admin123
Grafana Username: admin
Grafana Password: admin123

# IMPORTANT: Change passwords after first login!
EOF

chmod 600 .credentials

# Create required directories
mkdir -p {logs,backups,uploads,ssl}

# Generate SSL certificates
print_status "INFO" "Generating SSL certificates..."
SERVER_IP=$(hostname -I | awk '{print $1}')
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/selfsigned.key \
    -out ssl/selfsigned.crt \
    -subj "/C=AF/ST=Kabul/L=Kabul/O=HaroonNet/OU=IT/CN=$SERVER_IP"

chmod 600 ssl/selfsigned.key
chmod 644 ssl/selfsigned.crt

# Build and start platform
print_status "INFO" "Building HaroonNet ISP Platform..."
docker-compose build

print_status "INFO" "Starting all services..."
docker-compose up -d

# Wait for services to start
print_status "INFO" "Waiting for services to initialize..."
sleep 90

# Check service status
print_status "INFO" "Checking service status..."
docker-compose ps

# Test services
print_status "INFO" "Testing service connectivity..."
sleep 30

# Display final information
echo ""
echo "🎉 HaroonNet ISP Platform Installation Complete!"
echo "=================================================="
echo ""
echo "🌐 Web Management Interfaces:"
echo "   Admin Portal:     http://$SERVER_IP:3000"
echo "   Customer Portal:  http://$SERVER_IP:3001"
echo "   API Health:       http://$SERVER_IP:4000/health"
echo "   Grafana Monitor:  http://$SERVER_IP:3002"
echo "   Prometheus:       http://$SERVER_IP:9090"
echo "   Worker Monitor:   http://$SERVER_IP:5555"
echo ""
echo "🔑 Login Credentials:"
echo "   Admin: admin@haroonnet.com / admin123"
echo "   Grafana: admin / admin123"
echo ""
echo "📡 RADIUS Server:"
echo "   Authentication: $SERVER_IP:1812"
echo "   Accounting:     $SERVER_IP:1813"
echo "   CoA/DM:         $SERVER_IP:3799"
echo ""
echo "🔒 Generated Database Passwords:"
echo "   MySQL Root: $MYSQL_ROOT_PASS"
echo "   MySQL App:  $MYSQL_APP_PASS"
echo "   RADIUS DB:  $RADIUS_DB_PASS"
echo ""
echo "📋 Next Steps:"
echo "   1. Login to Admin Portal: http://$SERVER_IP:3000"
echo "   2. Change default passwords"
echo "   3. Configure your company information"
echo "   4. Add your Mikrotik NAS devices"
echo "   5. Create service plans"
echo "   6. Add customers and start billing"
echo ""
echo "🆘 Support Commands:"
echo "   Check status:  docker-compose ps"
echo "   View logs:     docker-compose logs [service]"
echo "   Restart:       docker-compose restart"
echo "   Stop:          docker-compose down"
echo ""
print_status "SUCCESS" "Your ISP platform is ready to serve customers!"

# Check if user needs to logout/login for docker group
if ! groups | grep -q docker; then
    echo ""
    print_status "WARNING" "You need to logout and login again for Docker group membership"
    echo "After logging back in, you can manage the platform with docker-compose commands"
fi
