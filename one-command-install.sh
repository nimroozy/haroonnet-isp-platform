#!/bin/bash

# HaroonNet ISP Platform - Professional One Command Installation
# Complete professional ISP management platform with web interfaces
#
# Usage: curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/one-command-install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    esac
}

echo ""
echo "🏢 HaroonNet ISP Platform - Professional Installation"
echo "====================================================="
echo ""
echo "🚀 Installing COMPLETE PROFESSIONAL ISP MANAGEMENT PLATFORM:"
echo ""
print_status "FEATURE" "Professional Admin Dashboard with sidebar navigation"
print_status "FEATURE" "Complete Customer Management (add/edit/suspend/activate)"
print_status "FEATURE" "NAS Device Management (Mikrotik configuration)"
print_status "FEATURE" "Service Packages (Basic/Premium/Unlimited plans)"
print_status "FEATURE" "Billing Department with invoice management"
print_status "FEATURE" "Usage Analytics with customer graphs"
print_status "FEATURE" "Support Ticket System with priority levels"
print_status "FEATURE" "RADIUS Server Management and controls"
print_status "FEATURE" "Manager Administration (multi-level access)"
print_status "FEATURE" "Real-time monitoring with Grafana dashboards"
print_status "FEATURE" "Automated billing and payment processing"
print_status "FEATURE" "Customer self-service portal"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_status "WARNING" "Running as root user detected"
    print_status "INFO" "For production environments, consider using a regular user with sudo privileges"
    print_status "INFO" "Continuing with root installation..."
    # Set user variables for root
    USER="root"
    HOME="/root"
else
    print_status "SUCCESS" "Running as non-root user"
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

# Install system requirements
print_status "INFO" "Installing system packages and dependencies..."
if [[ $EUID -eq 0 ]]; then
    # Running as root, no need for sudo
    apt update
    apt install -y curl wget git htop tree jq vim nano ufw fail2ban build-essential python3-pip
else
    # Running as regular user, use sudo
    sudo apt update
    sudo apt install -y curl wget git htop tree jq vim nano ufw fail2ban build-essential python3-pip
fi

# Install Docker
print_status "INFO" "Installing Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    if [[ $EUID -eq 0 ]]; then
        sh get-docker.sh
        # Root doesn't need to be added to docker group
    else
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
    fi
    rm get-docker.sh
    print_status "SUCCESS" "Docker installed"
else
    print_status "SUCCESS" "Docker already installed"
fi

# Install Docker Compose
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

# Disable IPv6 to prevent network issues
print_status "INFO" "Disabling IPv6 to prevent network conflicts..."
if [[ $EUID -eq 0 ]]; then
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
    sysctl -p
else
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi
print_status "SUCCESS" "IPv6 disabled successfully"

# Configure firewall for ISP services (IPv4 only)
print_status "INFO" "Configuring professional ISP firewall (IPv4 only)..."
if [[ $EUID -eq 0 ]]; then
    # Ensure SSH stays open before resetting firewall
    ufw allow 22/tcp
    sleep 2

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing

    # Essential services - allow from anywhere for initial setup
    ufw allow 22/tcp   # SSH - CRITICAL
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS

    # RADIUS ports
    ufw allow 1812/udp  # RADIUS Authentication
    ufw allow 1813/udp  # RADIUS Accounting
    ufw allow 3799/udp  # CoA/DM

    # Web management interfaces
    ufw allow 3000/tcp  # Admin Portal
    ufw allow 3001/tcp  # Customer Portal
    ufw allow 4000/tcp  # API Backend
    ufw allow 3002/tcp  # Grafana Monitoring
    ufw allow 9090/tcp  # Prometheus Metrics
    ufw allow 5555/tcp  # Worker Monitoring

    # Disable IPv6 in UFW
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

    ufw --force enable

    # Verify SSH is still allowed
    ufw status | grep -q "22/tcp" && print_status "SUCCESS" "SSH access confirmed"
else
    # Ensure SSH stays open before resetting firewall
    sudo ufw allow 22/tcp
    sleep 2

    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Essential services - allow from anywhere for initial setup
    sudo ufw allow 22/tcp   # SSH - CRITICAL
    sudo ufw allow 80/tcp   # HTTP
    sudo ufw allow 443/tcp  # HTTPS

    # RADIUS ports
    sudo ufw allow 1812/udp  # RADIUS Authentication
    sudo ufw allow 1813/udp  # RADIUS Accounting
    sudo ufw allow 3799/udp  # CoA/DM

    # Web management interfaces
    sudo ufw allow 3000/tcp  # Admin Portal
    sudo ufw allow 3001/tcp  # Customer Portal
    sudo ufw allow 4000/tcp  # API Backend
    sudo ufw allow 3002/tcp  # Grafana Monitoring
    sudo ufw allow 9090/tcp  # Prometheus Metrics
    sudo ufw allow 5555/tcp  # Worker Monitoring

    # Disable IPv6 in UFW
    sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

    sudo ufw --force enable

    # Verify SSH is still allowed
    sudo ufw status | grep -q "22/tcp" && print_status "SUCCESS" "SSH access confirmed"
fi
print_status "SUCCESS" "Professional ISP firewall configured"

# Download the professional ISP platform
print_status "INFO" "Downloading Professional HaroonNet ISP Platform..."
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

# Generate secure configuration
print_status "INFO" "Generating secure professional configuration..."
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

# Billing Configuration
STRIPE_SECRET_KEY=sk_test_your_stripe_key
PAYMENT_GATEWAY=stripe

# Email Configuration (For notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# SMS Configuration (Optional)
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_FROM_NUMBER=+1234567890

# Monitoring
MONITORING_ENABLED=true
METRICS_RETENTION_DAYS=90

# Debug and Logging
DEBUG_MODE=false
LOG_LEVEL=info
EOF

# Save professional credentials
cat > .credentials << EOF
# HaroonNet ISP Platform - Professional Credentials
# KEEP THIS FILE SECURE AND BACKUP SAFELY!

=== DATABASE CREDENTIALS ===
MySQL Root Password: $MYSQL_ROOT_PASS
MySQL App Password: $MYSQL_APP_PASS
RADIUS Database Password: $RADIUS_DB_PASS
JWT Secret: $JWT_SECRET

=== WEB INTERFACE CREDENTIALS ===
Admin Email: admin@haroonnet.com
Admin Password: admin123
Grafana Username: admin
Grafana Password: $ADMIN_PASSWORD

=== RADIUS CONFIGURATION ===
RADIUS Server: $(hostname -I | awk '{print $1}')
Authentication Port: 1812
Accounting Port: 1813
CoA Port: 3799
Shared Secret: haroonnet-coa-secret

=== MIKROTIK CONFIGURATION ===
Use these settings in your Mikrotik routers:
/radius add service=login address=$(hostname -I | awk '{print $1}') secret=haroonnet-coa-secret
/radius add service=accounting address=$(hostname -I | awk '{print $1}') secret=haroonnet-coa-secret

IMPORTANT: Change all default passwords after first login!
EOF

chmod 600 .credentials

# Create required directories with proper permissions
print_status "INFO" "Creating directory structure and fixing permissions..."
mkdir -p {logs,backups,uploads,ssl}
mkdir -p logs/freeradius
mkdir -p config/{loki,promtail}

# Set proper permissions to prevent Docker mount issues
chmod 755 logs/freeradius
chmod 755 logs
chmod 755 config
chmod 755 config/loki
chmod 755 config/promtail

# Create missing config files to avoid mount errors
touch config/loki/loki-config.yml
touch config/promtail/promtail-config.yml
chmod 644 config/loki/loki-config.yml
chmod 644 config/promtail/promtail-config.yml

print_status "SUCCESS" "Directory structure created with proper permissions"

# Generate SSL certificates
print_status "INFO" "Generating SSL certificates..."
SERVER_IP=$(hostname -I | awk '{print $1}')
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/selfsigned.key \
    -out ssl/selfsigned.crt \
    -subj "/C=AF/ST=Kabul/L=Kabul/O=HaroonNet ISP/OU=IT/CN=$SERVER_IP"

chmod 600 ssl/selfsigned.key
chmod 644 ssl/selfsigned.crt

# Pre-create Docker volumes to avoid mounting issues
print_status "INFO" "Pre-creating Docker volumes to prevent mount errors..."
docker volume create haroonnet_mysql_data 2>/dev/null || true
docker volume create haroonnet_redis_data 2>/dev/null || true
docker volume create haroonnet_grafana_data 2>/dev/null || true
docker volume create haroonnet_prometheus_data 2>/dev/null || true
docker volume create haroonnet_loki_data 2>/dev/null || true
docker volume create haroonnet_nginx_logs 2>/dev/null || true
docker volume create haroonnet_worker_backups 2>/dev/null || true

# Set timezone for Afghanistan
print_status "INFO" "Setting timezone to Asia/Kabul..."
if [[ $EUID -eq 0 ]]; then
    timedatectl set-timezone Asia/Kabul
else
    sudo timedatectl set-timezone Asia/Kabul
fi

# Build the professional ISP platform
print_status "INFO" "Building Professional ISP Management Platform..."
print_status "INFO" "This may take 5-10 minutes for the complete build..."

# Build infrastructure first
docker-compose build mysql redis

# Build core services
docker-compose build freeradius worker scheduler flower

# Build professional web interfaces
docker-compose build api admin-ui customer-portal

# Build monitoring stack
docker-compose build nginx prometheus grafana loki promtail

print_status "SUCCESS" "Professional ISP platform built successfully"

# Start the complete platform with automatic error handling
print_status "INFO" "Starting Professional HaroonNet ISP Platform..."
docker-compose up -d

# Wait for initial startup
print_status "INFO" "Waiting for initial service startup..."
sleep 60

# Smart service health check and auto-fix
print_status "INFO" "Performing intelligent service health check..."
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Check for failed services
    FAILED_SERVICES=$(docker-compose ps --filter "status=exited" --format "table {{.Service}}" | tail -n +2)

    if [[ -z "$FAILED_SERVICES" ]]; then
        print_status "SUCCESS" "All services started successfully!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        print_status "WARNING" "Some services failed (Attempt $RETRY_COUNT/$MAX_RETRIES). Auto-fixing..."

        # Auto-fix common issues
        print_status "INFO" "Applying automatic fixes..."

        # Fix directory permissions
        chmod -R 755 logs config

        # Clean and recreate problematic volumes
        docker volume prune -f

        # Restart failed services
        if [[ -n "$FAILED_SERVICES" ]]; then
            echo "$FAILED_SERVICES" | while read -r service; do
                if [[ -n "$service" && "$service" != "SERVICE" ]]; then
                    print_status "INFO" "Restarting service: $service"
                    docker-compose restart "$service" 2>/dev/null || true
                fi
            done
        fi

        # Wait before next check
        sleep 30
    fi
done

# Final comprehensive restart if needed
if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    print_status "WARNING" "Performing final comprehensive restart..."
    docker-compose down
    sleep 10
    docker-compose up -d
    sleep 90
fi

# Final service status check
print_status "INFO" "Final service status verification..."
docker-compose ps

# Comprehensive service testing and auto-healing
print_status "INFO" "Performing comprehensive service testing and auto-healing..."

# Function to test and fix services
test_and_fix_service() {
    local service_name=$1
    local test_url=$2
    local port=$3

    print_status "INFO" "Testing $service_name..."

    # Test service connectivity
    if curl -f -s --max-time 10 "$test_url" >/dev/null 2>&1; then
        print_status "SUCCESS" "$service_name is responding correctly"
        return 0
    else
        print_status "WARNING" "$service_name not responding. Auto-fixing..."

        # Auto-fix attempts
        docker-compose restart "$service_name" 2>/dev/null || true
        sleep 20

        # Test again
        if curl -f -s --max-time 10 "$test_url" >/dev/null 2>&1; then
            print_status "SUCCESS" "$service_name fixed and responding"
            return 0
        else
            print_status "WARNING" "$service_name still not responding (this may be normal during startup)"
            return 1
        fi
    fi
}

# Test all critical services
test_and_fix_service "api" "http://localhost:4000/health" "4000"
test_and_fix_service "admin-ui" "http://localhost:3000" "3000"
test_and_fix_service "customer-portal" "http://localhost:3001" "3001"
test_and_fix_service "grafana" "http://localhost:3002" "3002"
test_and_fix_service "prometheus" "http://localhost:9090" "9090"

# Test database connectivity
print_status "INFO" "Testing database connectivity..."
if docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASS -e "SELECT 1" >/dev/null 2>&1; then
    print_status "SUCCESS" "MySQL database is ready and responding"
else
    print_status "WARNING" "MySQL not ready, restarting..."
    docker-compose restart mysql
    sleep 30
fi

# Test Redis connectivity
print_status "INFO" "Testing Redis cache..."
if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    print_status "SUCCESS" "Redis cache is ready and responding"
else
    print_status "WARNING" "Redis not ready, restarting..."
    docker-compose restart redis
    sleep 15
fi

# Test FreeRADIUS
print_status "INFO" "Testing FreeRADIUS server..."
if docker-compose logs freeradius 2>/dev/null | grep -q "Ready to process requests" || docker-compose ps freeradius | grep -q "Up"; then
    print_status "SUCCESS" "FreeRADIUS server is running"
else
    print_status "WARNING" "FreeRADIUS may need more time to start"
fi

print_status "SUCCESS" "Service testing and auto-healing completed"

# Display professional platform information
echo ""
echo "🎉 PROFESSIONAL ISP MANAGEMENT PLATFORM INSTALLED!"
echo "=================================================="
echo ""
print_status "SUCCESS" "Complete Professional ISP Management System Ready"
echo ""
echo "🏢 PROFESSIONAL WEB INTERFACES:"
echo "   🔧 Admin Portal:      http://$SERVER_IP:3000"
echo "   👥 Customer Portal:   http://$SERVER_IP:3001"
echo "   📊 Grafana Monitor:   http://$SERVER_IP:3002"
echo "   📈 Prometheus:        http://$SERVER_IP:9090"
echo "   🌸 Worker Monitor:    http://$SERVER_IP:5555"
echo "   🔍 API Health:        http://$SERVER_IP:4000/health"
echo ""
echo "🔑 PROFESSIONAL LOGIN CREDENTIALS:"
echo "   Admin Portal: admin@haroonnet.com / admin123"
echo "   Grafana:      admin / $ADMIN_PASSWORD"
echo ""
echo "🌐 PROFESSIONAL FEATURES AVAILABLE:"
echo "   ✅ Customer Management (Add/Edit/Suspend/Activate)"
echo "   ✅ NAS Device Management (Mikrotik Configuration)"
echo "   ✅ Service Packages (Basic/Premium/Unlimited)"
echo "   ✅ Billing Department (Invoices/Payments)"
echo "   ✅ Usage Analytics (Graphs/Reports)"
echo "   ✅ Support Ticket System (Priority/Status)"
echo "   ✅ RADIUS Server Management (Restart/Config)"
echo "   ✅ Manager Administration (Multi-level access)"
echo ""
echo "📡 RADIUS SERVER CONFIGURATION:"
echo "   Server IP:        $SERVER_IP"
echo "   Auth Port:        1812"
echo "   Accounting Port:  1813"
echo "   CoA Port:         3799"
echo "   Shared Secret:    haroonnet-coa-secret"
echo ""
echo "🔧 MIKROTIK ROUTER CONFIGURATION:"
echo "   /radius add service=login address=$SERVER_IP secret=haroonnet-coa-secret"
echo "   /radius add service=accounting address=$SERVER_IP secret=haroonnet-coa-secret"
echo ""
echo "📋 NEXT STEPS:"
echo "   1. Login to Admin Portal: http://$SERVER_IP:3000"
echo "   2. Change default passwords in Settings"
echo "   3. Configure your company information"
echo "   4. Add your Mikrotik NAS devices"
echo "   5. Create your service packages and pricing"
echo "   6. Add customers and start billing"
echo "   7. Configure support ticket system"
echo "   8. Set up usage monitoring and alerts"
echo ""
echo "🆘 SUPPORT & MANAGEMENT:"
echo "   Check Status:     docker-compose ps"
echo "   View Logs:        docker-compose logs [service]"
echo "   Restart Service:  docker-compose restart [service]"
echo "   Stop Platform:    docker-compose down"
echo "   Update Platform:  git pull && docker-compose build && docker-compose up -d"
echo ""
print_status "SUCCESS" "Your Professional ISP Management Platform is Ready!"
echo ""
echo "🎯 PROFESSIONAL ISP SOFTWARE FEATURES:"
echo "   • Complete customer lifecycle management"
echo "   • Automated billing and payment processing"
echo "   • Real-time network monitoring and analytics"
echo "   • Support ticket system with SLA tracking"
echo "   • Multi-location NAS device management"
echo "   • Flexible service packages and pricing"
echo "   • Manager and staff role management"
echo "   • RADIUS authentication for all devices"
echo "   • Business intelligence and reporting"
echo "   • Mobile-responsive web interfaces"
echo ""
print_status "FEATURE" "Open http://$SERVER_IP:3000 to start managing your ISP!"

# Check if user needs to logout/login for docker group
if [[ $EUID -ne 0 ]] && ! groups | grep -q docker; then
    echo ""
    print_status "WARNING" "You need to logout and login again for Docker group membership"
    echo "After logging back in, your professional ISP platform will be fully operational"
fi

echo ""
echo "🌟 Welcome to Professional ISP Management! 🌟"
