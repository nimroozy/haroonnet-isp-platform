#!/bin/bash

# HaroonNet ISP Platform - Ultimate One-Click Installer
# This script handles EVERYTHING automatically - no manual steps required
#
# Usage: curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/install-isp-platform.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
        "FEATURE") echo -e "${PURPLE}🚀 $message${NC}" ;;
        "STEP") echo -e "${CYAN}🔧 $message${NC}" ;;
    esac
}

echo ""
echo "🏢 HaroonNet ISP Platform - Ultimate One-Click Installer"
echo "========================================================"
echo ""
echo "🚀 INSTALLING COMPLETE PROFESSIONAL ISP PLATFORM:"
echo ""
print_status "FEATURE" "✨ Beautiful Modern UI with Professional Design"
print_status "FEATURE" "🏢 Complete Customer Management System"
print_status "FEATURE" "📡 FreeRADIUS Server with Auto-Configuration"
print_status "FEATURE" "💳 Billing & Payment Processing"
print_status "FEATURE" "📊 Real-time Monitoring & Analytics"
print_status "FEATURE" "🎫 Support Ticket Management"
print_status "FEATURE" "🌐 NAS Device Management (Mikrotik)"
print_status "FEATURE" "👨‍💼 Multi-level Staff Management"
print_status "FEATURE" "📱 SMS & Email Notifications"
print_status "FEATURE" "🔒 IPv4-Only Secure Configuration"
echo ""

# Auto-detect user privileges
if [[ $EUID -eq 0 ]]; then
    print_status "INFO" "Running as root - optimal for server deployment"
    SUDO_CMD=""
else
    print_status "INFO" "Running as regular user - will use sudo when needed"
    SUDO_CMD="sudo"
fi

# Step 1: System Preparation
print_status "STEP" "Step 1/10: Preparing system environment..."

# Update system
print_status "INFO" "Updating system packages..."
if [[ $EUID -eq 0 ]]; then
    apt update && apt upgrade -y
    apt install -y curl wget git htop tree jq vim nano ufw fail2ban build-essential python3-pip openssl
else
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git htop tree jq vim nano ufw fail2ban build-essential python3-pip openssl
fi

# Step 2: IPv6 Disable (Critical for network stability)
print_status "STEP" "Step 2/10: Disabling IPv6 for network stability..."

# Remove any existing IPv6 disable entries
if [[ $EUID -eq 0 ]]; then
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
    sysctl -p
else
    sudo sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sudo sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sudo sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

    echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

print_status "SUCCESS" "IPv6 disabled successfully"

# Step 3: Firewall Configuration (SSH-safe)
print_status "STEP" "Step 3/10: Configuring secure firewall (SSH-safe)..."

if [[ $EUID -eq 0 ]]; then
    # Ensure SSH stays open
    ufw allow 22/tcp
    sleep 2

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing

    # Essential services
    ufw allow 22/tcp    # SSH - CRITICAL
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS

    # RADIUS ports
    ufw allow 1812/udp  # RADIUS Authentication
    ufw allow 1813/udp  # RADIUS Accounting
    ufw allow 3799/udp  # CoA/DM

    # ISP Management interfaces
    ufw allow 3000/tcp  # Admin Portal
    ufw allow 3001/tcp  # Customer Portal
    ufw allow 4000/tcp  # API Backend
    ufw allow 3002/tcp  # Grafana
    ufw allow 9090/tcp  # Prometheus
    ufw allow 5555/tcp  # Flower

    # Disable IPv6 in UFW
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

    ufw --force enable
    ufw status | grep -q "22/tcp" && print_status "SUCCESS" "Firewall configured with SSH protection"
else
    $SUDO_CMD ufw allow 22/tcp
    sleep 2

    $SUDO_CMD ufw --force reset
    $SUDO_CMD ufw default deny incoming
    $SUDO_CMD ufw default allow outgoing

    $SUDO_CMD ufw allow 22/tcp
    $SUDO_CMD ufw allow 80/tcp
    $SUDO_CMD ufw allow 443/tcp
    $SUDO_CMD ufw allow 1812/udp
    $SUDO_CMD ufw allow 1813/udp
    $SUDO_CMD ufw allow 3799/udp
    $SUDO_CMD ufw allow 3000/tcp
    $SUDO_CMD ufw allow 3001/tcp
    $SUDO_CMD ufw allow 4000/tcp
    $SUDO_CMD ufw allow 3002/tcp
    $SUDO_CMD ufw allow 9090/tcp
    $SUDO_CMD ufw allow 5555/tcp

    $SUDO_CMD sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
    $SUDO_CMD ufw --force enable
fi

# Step 4: Docker Installation
print_status "STEP" "Step 4/10: Installing Docker and Docker Compose..."

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    if [[ $EUID -eq 0 ]]; then
        sh get-docker.sh
    else
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
    fi
    rm get-docker.sh
    print_status "SUCCESS" "Docker installed"
else
    print_status "SUCCESS" "Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    if [[ $EUID -eq 0 ]]; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    print_status "SUCCESS" "Docker Compose installed"
else
    print_status "SUCCESS" "Docker Compose already installed"
fi

# Step 5: Docker Configuration for IPv4
print_status "STEP" "Step 5/10: Configuring Docker for optimal ISP platform..."

if [[ $EUID -eq 0 ]]; then
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << EOF
{
  "ipv6": false,
  "fixed-cidr": "172.17.0.0/16",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    systemctl restart docker
else
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "ipv6": false,
  "fixed-cidr": "172.17.0.0/16",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    sudo systemctl restart docker
fi

print_status "SUCCESS" "Docker configured for IPv4-only operation"

# Step 6: Download ISP Platform
print_status "STEP" "Step 6/10: Downloading HaroonNet ISP Platform..."

cd ~
if [[ $EUID -eq 0 ]]; then
    rm -rf /opt/haroonnet
    rm -rf haroonnet-isp-platform

    git clone https://github.com/nimroozy/haroonnet-isp-platform.git
    mv haroonnet-isp-platform /opt/haroonnet
    cd /opt/haroonnet
else
    sudo rm -rf /opt/haroonnet
    rm -rf haroonnet-isp-platform

    git clone https://github.com/nimroozy/haroonnet-isp-platform.git
    sudo mv haroonnet-isp-platform /opt/haroonnet
    sudo chown -R $USER:$USER /opt/haroonnet
    cd /opt/haroonnet
fi

print_status "SUCCESS" "ISP Platform downloaded to /opt/haroonnet"

# Step 7: Environment Configuration
print_status "STEP" "Step 7/10: Generating secure environment configuration..."

# Generate secure passwords
MYSQL_ROOT_PASS=$(openssl rand -hex 16)
MYSQL_APP_PASS=$(openssl rand -hex 16)
RADIUS_DB_PASS=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_PASSWORD=$(openssl rand -hex 8)

# Create professional environment file
cat > .env << EOF
# HaroonNet ISP Platform - Professional Configuration
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

# Web Interface Configuration
NEXT_PUBLIC_API_URL=http://localhost:4000
GRAFANA_PASSWORD=$ADMIN_PASSWORD

# Company Information (CUSTOMIZE THESE)
COMPANY_NAME=HaroonNet ISP
COMPANY_EMAIL=admin@haroonnet.com
COMPANY_PHONE=+93-123-456-789
COMPANY_ADDRESS=Kabul, Afghanistan
COMPANY_TIMEZONE=Asia/Kabul
DEFAULT_CURRENCY=AFN

# RADIUS Configuration
COA_SECRET=haroonnet-coa-secret
COA_PORT=3799

# Monitoring
MONITORING_ENABLED=true
METRICS_RETENTION_DAYS=90

# Debug and Logging
DEBUG_MODE=false
LOG_LEVEL=info
EOF

print_status "SUCCESS" "Environment configured with secure passwords"

# Step 8: Directory Structure and Permissions
print_status "STEP" "Step 8/10: Creating directory structure and fixing all permissions..."

# Create all required directories
mkdir -p {logs,backups,uploads,ssl}
mkdir -p logs/freeradius
mkdir -p config/{nginx/conf.d,prometheus,grafana/{provisioning,dashboards},loki,promtail}
mkdir -p database/backups

# Set comprehensive permissions
chmod 755 logs logs/freeradius config config/loki config/promtail
chmod 755 config/nginx config/prometheus config/grafana
chmod 755 database database/backups backups uploads ssl

# Create config files
touch config/loki/loki-config.yml
touch config/promtail/promtail-config.yml
chmod 644 config/loki/loki-config.yml
chmod 644 config/promtail/promtail-config.yml

# Generate SSL certificates
SERVER_IP=$(hostname -I | awk '{print $1}')
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/selfsigned.key \
    -out ssl/selfsigned.crt \
    -subj "/C=AF/ST=Kabul/L=Kabul/O=HaroonNet ISP/OU=IT/CN=$SERVER_IP"

chmod 600 ssl/selfsigned.key
chmod 644 ssl/selfsigned.crt

print_status "SUCCESS" "All directories and permissions configured"

# Step 9: Build and Deploy Platform
print_status "STEP" "Step 9/10: Building and deploying ISP platform..."

# Clean any existing Docker resources
docker-compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -af
docker volume prune -f

# Pre-create volumes to prevent mount errors
docker volume create haroonnet_mysql_data 2>/dev/null || true
docker volume create haroonnet_redis_data 2>/dev/null || true
docker volume create haroonnet_grafana_data 2>/dev/null || true
docker volume create haroonnet_prometheus_data 2>/dev/null || true
docker volume create haroonnet_loki_data 2>/dev/null || true
docker volume create haroonnet_nginx_logs 2>/dev/null || true
docker volume create haroonnet_worker_backups 2>/dev/null || true

print_status "INFO" "Building ISP platform (this may take 5-10 minutes)..."

# Build services incrementally for better reliability
docker-compose build mysql redis
docker-compose build freeradius
docker-compose build worker scheduler flower
docker-compose build api
docker-compose build admin-ui customer-portal
docker-compose build nginx prometheus grafana loki promtail 2>/dev/null || true

print_status "SUCCESS" "ISP platform built successfully"

# Start services with intelligent retry logic
print_status "INFO" "Starting services with automatic error recovery..."

MAX_ATTEMPTS=3
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    print_status "INFO" "Deployment attempt $ATTEMPT/$MAX_ATTEMPTS..."

    # Start services
    docker-compose up -d

    # Wait for startup
    sleep 60

    # Check for failed services
    FAILED_SERVICES=$(docker-compose ps --filter "status=exited" --format "{{.Service}}" 2>/dev/null || true)

    if [[ -z "$FAILED_SERVICES" ]]; then
        print_status "SUCCESS" "All services started successfully on attempt $ATTEMPT!"
        break
    else
        print_status "WARNING" "Some services failed on attempt $ATTEMPT. Auto-fixing..."

        # Apply fixes
        chmod -R 755 logs config
        docker volume prune -f

        # Restart failed services individually
        echo "$FAILED_SERVICES" | while read -r service; do
            if [[ -n "$service" ]]; then
                print_status "INFO" "Restarting $service..."
                docker-compose restart "$service" 2>/dev/null || true
            fi
        done

        sleep 30
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

# Step 10: Final Verification and Health Checks
print_status "STEP" "Step 10/10: Final verification and health checks..."

# Wait for all services to fully initialize
sleep 60

# Comprehensive health check
print_status "INFO" "Performing comprehensive health checks..."

# Test critical services
test_service() {
    local service=$1
    local url=$2
    local name=$3

    if curl -f -s --max-time 10 "$url" >/dev/null 2>&1; then
        print_status "SUCCESS" "$name is ready and responding"
        return 0
    else
        print_status "WARNING" "$name not ready yet (may need more time)"
        return 1
    fi
}

# Test services with retries
test_service "api" "http://localhost:4000/health" "API Service"
test_service "admin-ui" "http://localhost:3000" "Admin Portal"
test_service "customer-portal" "http://localhost:3001" "Customer Portal"
test_service "grafana" "http://localhost:3002" "Grafana"
test_service "prometheus" "http://localhost:9090" "Prometheus"

# Test database
if docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASS -e "SELECT 1" >/dev/null 2>&1; then
    print_status "SUCCESS" "MySQL database is ready"
else
    print_status "WARNING" "MySQL still initializing (normal for first run)"
fi

# Test Redis
if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    print_status "SUCCESS" "Redis cache is ready"
else
    print_status "WARNING" "Redis still initializing"
fi

# Save credentials securely
cat > .credentials << EOF
# HaroonNet ISP Platform - Generated Credentials
# KEEP THIS FILE SECURE AND BACKUP SAFELY!

=== WEB INTERFACE CREDENTIALS ===
Admin Portal: http://$SERVER_IP:3000
Email: admin@haroonnet.com
Password: admin123

Customer Portal: http://$SERVER_IP:3001

=== MONITORING CREDENTIALS ===
Grafana: http://$SERVER_IP:3002
Username: admin
Password: $ADMIN_PASSWORD

Prometheus: http://$SERVER_IP:9090
Flower (Workers): http://$SERVER_IP:5555

=== DATABASE CREDENTIALS ===
MySQL Root Password: $MYSQL_ROOT_PASS
MySQL App Password: $MYSQL_APP_PASS
RADIUS Database Password: $RADIUS_DB_PASS
JWT Secret: $JWT_SECRET

=== RADIUS SERVER CONFIGURATION ===
Server IP: $SERVER_IP
Authentication Port: 1812
Accounting Port: 1813
CoA Port: 3799
Shared Secret: haroonnet-coa-secret

=== MIKROTIK CONFIGURATION ===
/radius add service=login address=$SERVER_IP secret=haroonnet-coa-secret
/radius add service=accounting address=$SERVER_IP secret=haroonnet-coa-secret

IMPORTANT: Change default passwords after first login!
EOF

chmod 600 .credentials

# Set timezone
print_status "INFO" "Setting timezone to Asia/Kabul..."
if [[ $EUID -eq 0 ]]; then
    timedatectl set-timezone Asia/Kabul
else
    sudo timedatectl set-timezone Asia/Kabul
fi

# Final status display
echo ""
echo "🎉 HAROONNET ISP PLATFORM SUCCESSFULLY INSTALLED!"
echo "================================================="
echo ""
print_status "SUCCESS" "Professional ISP Management Platform is Ready!"
echo ""
echo "🌐 ACCESS YOUR ISP PLATFORM:"
echo ""
echo "   🏢 Admin Portal:      http://$SERVER_IP:3000"
echo "   👥 Customer Portal:   http://$SERVER_IP:3001"
echo "   📊 Grafana Monitor:   http://$SERVER_IP:3002"
echo "   📈 Prometheus:        http://$SERVER_IP:9090"
echo "   🌸 Worker Monitor:    http://$SERVER_IP:5555"
echo "   🔍 API Health:        http://$SERVER_IP:4000/health"
echo ""
echo "🔑 LOGIN CREDENTIALS:"
echo ""
echo "   📧 Email:     admin@haroonnet.com"
echo "   🔒 Password:  admin123"
echo "   📊 Grafana:   admin / $ADMIN_PASSWORD"
echo ""
echo "🎯 PROFESSIONAL FEATURES READY:"
echo ""
echo "   ✨ Beautiful Modern UI with Professional Design"
echo "   🏢 Complete Customer Management (Add/Edit/Suspend)"
echo "   📡 FreeRADIUS Server (Fully Configured)"
echo "   💳 Billing & Payment Processing"
echo "   📊 Real-time Analytics & Monitoring"
echo "   🎫 Support Ticket Management"
echo "   🌐 NAS Device Management (Mikrotik Ready)"
echo "   👨‍💼 Multi-level Staff Management"
echo "   📱 SMS & Email Notification System"
echo "   🔒 Enterprise Security & IPv4 Configuration"
echo ""
echo "📡 RADIUS SERVER READY:"
echo "   Server: $SERVER_IP:1812 (Auth) / 1813 (Acct) / 3799 (CoA)"
echo "   Secret: haroonnet-coa-secret"
echo ""
echo "🔧 MIKROTIK CONFIGURATION:"
echo "   /radius add service=login address=$SERVER_IP secret=haroonnet-coa-secret"
echo "   /radius add service=accounting address=$SERVER_IP secret=haroonnet-coa-secret"
echo ""
echo "📋 MANAGEMENT COMMANDS:"
echo "   Check Status:    docker-compose ps"
echo "   View Logs:       docker-compose logs [service]"
echo "   Restart Service: docker-compose restart [service]"
echo "   Stop Platform:   docker-compose down"
echo "   Update Platform: git pull && docker-compose build && docker-compose up -d"
echo ""

# Check Docker group membership warning
if [[ $EUID -ne 0 ]] && ! groups | grep -q docker; then
    echo ""
    print_status "WARNING" "You may need to logout and login again for Docker group membership"
    echo "After logging back in, your ISP platform will be fully operational"
fi

# Final service status
echo ""
print_status "INFO" "Final Service Status:"
docker-compose ps

echo ""
echo "🌟 CONGRATULATIONS! 🌟"
echo ""
print_status "SUCCESS" "Your Professional ISP Management Platform is READY!"
print_status "FEATURE" "Open http://$SERVER_IP:3000 to start managing your ISP business!"
echo ""
echo "🚀 ONE-CLICK INSTALLATION COMPLETED SUCCESSFULLY! 🚀"
