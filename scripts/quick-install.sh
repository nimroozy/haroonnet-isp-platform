#!/bin/bash

# HaroonNet ISP Platform - Quick Installation Script for Ubuntu 22.04
# This script automates the complete installation process

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

# Function to check if running on Ubuntu 22.04
check_ubuntu_version() {
    if ! grep -q "22.04" /etc/os-release; then
        print_status "ERROR" "This script requires Ubuntu 22.04 LTS"
        exit 1
    fi
    print_status "SUCCESS" "Ubuntu 22.04 LTS detected"
}

# Function to check if running as non-root user
check_user() {
    if [[ $EUID -eq 0 ]]; then
        print_status "ERROR" "This script should not be run as root for security reasons"
        print_status "INFO" "Please run as a regular user with sudo privileges"
        exit 1
    fi
    print_status "SUCCESS" "Running as non-root user"
}

# Function to install system packages
install_system_packages() {
    print_status "INFO" "Installing system packages..."

    sudo apt update
    sudo apt upgrade -y

    sudo apt install -y \
        curl wget git htop tree jq vim nano ufw fail2ban \
        software-properties-common apt-transport-https ca-certificates \
        gnupg lsb-release build-essential python3-pip \
        freeradius freeradius-mysql freeradius-utils

    print_status "SUCCESS" "System packages installed"
}

# Function to install Docker
install_docker() {
    print_status "INFO" "Installing Docker..."

    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Install Docker Compose standalone
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Add user to docker group
    sudo usermod -aG docker $USER

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    print_status "SUCCESS" "Docker installed successfully"
}

# Function to configure firewall
configure_firewall() {
    print_status "INFO" "Configuring firewall..."

    # Reset and configure UFW
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Essential services
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp

    # RADIUS ports
    sudo ufw allow 1812/udp
    sudo ufw allow 1813/udp
    sudo ufw allow 3799/udp

    # Management ports (restrict these in production)
    sudo ufw allow 3000/tcp
    sudo ufw allow 3001/tcp
    sudo ufw allow 4000/tcp
    sudo ufw allow 3002/tcp
    sudo ufw allow 9090/tcp
    sudo ufw allow 5555/tcp

    # Enable firewall
    sudo ufw --force enable

    print_status "SUCCESS" "Firewall configured"
}

# Function to optimize system
optimize_system() {
    print_status "INFO" "Optimizing system performance..."

    # Set timezone
    sudo timedatectl set-timezone Asia/Kabul

    # Increase system limits
    sudo tee -a /etc/security/limits.conf << EOF
# HaroonNet ISP Platform limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

    # Configure sysctl
    sudo tee -a /etc/sysctl.conf << EOF
# HaroonNet network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
EOF

    sudo sysctl -p

    print_status "SUCCESS" "System optimized"
}

# Function to setup platform
setup_platform() {
    print_status "INFO" "Setting up HaroonNet ISP Platform..."

    # Create application directory
    sudo mkdir -p /opt/haroonnet
    sudo chown $USER:$USER /opt/haroonnet
    cd /opt/haroonnet

    # If running from within the platform directory, copy files
    if [[ -f "../docker-compose.yml" ]]; then
        cp -r ../* .
    else
        print_status "ERROR" "Platform files not found. Please ensure you're running this script from the platform directory or have the files available."
        exit 1
    fi

    # Make scripts executable
    chmod +x scripts/*.sh

    # Create required directories
    mkdir -p {logs,backups,uploads,ssl}
    mkdir -p config/{nginx/conf.d,prometheus,grafana/{provisioning,dashboards},loki,promtail}

    print_status "SUCCESS" "Platform files setup complete"
}

# Function to configure environment
configure_environment() {
    print_status "INFO" "Configuring environment..."

    # Generate secure passwords
    MYSQL_ROOT_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    MYSQL_APP_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    RADIUS_DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
    COA_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    # Create environment file
    cat > .env << EOF
# HaroonNet ISP Platform - Auto-generated Configuration
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

# Company Information (PLEASE UPDATE THESE)
COMPANY_NAME=HaroonNet ISP
COMPANY_EMAIL=admin@haroonnet.com
COMPANY_PHONE=+93-123-456-789
COMPANY_ADDRESS=Kabul, Afghanistan
COMPANY_TIMEZONE=Asia/Kabul
DEFAULT_CURRENCY=AFN

# CoA Configuration
COA_SECRET=$COA_SECRET
COA_PORT=3799

# Monitoring
GRAFANA_PASSWORD=admin123
MONITORING_ENABLED=true

# Email Configuration (UPDATE THESE FOR NOTIFICATIONS)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# SMS Configuration (OPTIONAL)
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_FROM_NUMBER=+1234567890
EOF

    # Save credentials for user reference
    cat > .credentials << EOF
# HaroonNet ISP Platform - Generated Credentials
# KEEP THIS FILE SECURE AND BACKUP SAFELY!

MySQL Root Password: $MYSQL_ROOT_PASS
MySQL App Password: $MYSQL_APP_PASS
RADIUS Database Password: $RADIUS_DB_PASS
JWT Secret: $JWT_SECRET
CoA Secret: $COA_SECRET

# Default Login Credentials
Admin Email: admin@haroonnet.com
Admin Password: admin123

# Grafana
Username: admin
Password: admin123

# IMPORTANT: Change the admin password after first login!
EOF

    chmod 600 .credentials

    print_status "SUCCESS" "Environment configured with secure passwords"
    print_status "WARNING" "Credentials saved in .credentials file - keep it secure!"
}

# Function to generate SSL certificates
generate_ssl_certificates() {
    print_status "INFO" "Generating SSL certificates..."

    # Get server IP for certificate
    SERVER_IP=$(hostname -I | awk '{print $1}')

    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/selfsigned.key \
        -out ssl/selfsigned.crt \
        -subj "/C=AF/ST=Kabul/L=Kabul/O=HaroonNet/OU=IT/CN=$SERVER_IP"

    chmod 600 ssl/selfsigned.key
    chmod 644 ssl/selfsigned.crt

    print_status "SUCCESS" "SSL certificates generated"
}

# Function to start platform
start_platform() {
    print_status "INFO" "Building and starting HaroonNet ISP Platform..."

    # Build services
    docker-compose build --parallel

    # Start services
    docker-compose up -d

    print_status "INFO" "Waiting for services to start..."
    sleep 60

    # Check service status
    if docker-compose ps | grep -q "Exit\|unhealthy"; then
        print_status "ERROR" "Some services failed to start"
        docker-compose ps
        docker-compose logs --tail=20
        exit 1
    fi

    print_status "SUCCESS" "All services started successfully"
}

# Function to run initial tests
run_initial_tests() {
    print_status "INFO" "Running initial system tests..."

    # Wait a bit more for services to be fully ready
    sleep 30

    # Test API health
    if curl -f -s http://localhost:4000/health | grep -q "ok"; then
        print_status "SUCCESS" "API health check passed"
    else
        print_status "ERROR" "API health check failed"
        return 1
    fi

    # Test database connectivity
    if docker-compose exec -T mysql mysql -u haroonnet -p$MYSQL_APP_PASS haroonnet -e "SELECT 1" > /dev/null 2>&1; then
        print_status "SUCCESS" "Database connectivity test passed"
    else
        print_status "ERROR" "Database connectivity test failed"
        return 1
    fi

    # Test RADIUS
    if docker-compose exec -T freeradius radtest admin@haroonnet.com admin123 localhost 1812 testing123 | grep -q "Access-Accept"; then
        print_status "SUCCESS" "RADIUS authentication test passed"
    else
        print_status "WARNING" "RADIUS test failed (expected for fresh install)"
    fi

    # Run comprehensive tests
    if ./scripts/run_tests.sh > /dev/null 2>&1; then
        print_status "SUCCESS" "Comprehensive test suite passed"
    else
        print_status "WARNING" "Some tests failed (check ./scripts/run_tests.sh for details)"
    fi

    return 0
}

# Function to display final information
display_final_info() {
    local SERVER_IP=$(hostname -I | awk '{print $1}')

    echo ""
    echo "🎉 HaroonNet ISP Platform Installation Completed Successfully!"
    echo "=============================================================="
    echo ""
    echo "🌐 Access URLs:"
    echo "   Admin Portal:     https://$SERVER_IP:3000"
    echo "   Customer Portal:  https://$SERVER_IP:3001"
    echo "   API Documentation: https://$SERVER_IP:4000/api/docs"
    echo "   Grafana Monitoring: https://$SERVER_IP:3002"
    echo "   Worker Monitoring:  https://$SERVER_IP:5555"
    echo ""
    echo "🔑 Default Credentials:"
    echo "   Admin: admin@haroonnet.com / admin123"
    echo "   Grafana: admin / admin123"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Login to admin portal and change default password"
    echo "   2. Configure your company information"
    echo "   3. Add your NAS devices (Mikrotik routers)"
    echo "   4. Create service plans"
    echo "   5. Configure notification settings"
    echo "   6. Test RADIUS authentication with your equipment"
    echo ""
    echo "🔒 Security Notes:"
    echo "   - Generated credentials are saved in .credentials file"
    echo "   - Change all default passwords immediately"
    echo "   - Configure proper SSL certificates for production"
    echo "   - Review firewall rules and restrict access as needed"
    echo ""
    echo "📖 Documentation:"
    echo "   - Installation guide: docs/fresh-ubuntu-installation.md"
    echo "   - Mikrotik setup: docs/mikrotik-configuration.md"
    echo "   - API documentation: https://$SERVER_IP:4000/api/docs"
    echo ""
    echo "🆘 Support:"
    echo "   - Run diagnostics: ./scripts/run_tests.sh"
    echo "   - Check logs: docker-compose logs [service-name]"
    echo "   - Documentation: docs/ directory"
    echo ""
    echo "✨ Your HaroonNet ISP Platform is ready to serve customers!"
}

# Main installation function
main() {
    echo "🚀 HaroonNet ISP Platform - Quick Installation"
    echo "============================================="
    echo ""
    echo "This script will install the complete HaroonNet ISP Platform"
    echo "on Ubuntu 22.04 with FreeRADIUS, MySQL, and all components."
    echo ""

    # Confirmation
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi

    # Pre-flight checks
    print_status "INFO" "Running pre-flight checks..."
    check_ubuntu_version
    check_user

    # Installation steps
    install_system_packages
    install_docker
    configure_firewall
    optimize_system
    setup_platform
    configure_environment
    generate_ssl_certificates

    # Start platform
    start_platform

    # Run tests
    if run_initial_tests; then
        print_status "SUCCESS" "Installation validation passed"
    else
        print_status "WARNING" "Installation completed but some tests failed"
    fi

    # Display final information
    display_final_info

    # Final note about docker group
    if ! groups | grep -q docker; then
        echo ""
        print_status "WARNING" "You need to logout and login again for Docker group membership to take effect"
        echo "After logging back in, you can manage the platform with:"
        echo "  docker-compose ps    # Check service status"
        echo "  docker-compose logs  # View logs"
        echo "  ./scripts/run_tests.sh  # Run diagnostics"
    fi
}

# Handle script interruption
trap 'echo ""; print_status "ERROR" "Installation interrupted"; exit 1' INT TERM

# Run main installation
main "$@"
