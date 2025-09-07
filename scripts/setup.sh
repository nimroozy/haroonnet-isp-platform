#!/bin/bash

# HaroonNet ISP Platform - Setup Script
# This script sets up the complete platform on Ubuntu 22.04

set -e

echo "🚀 Setting up HaroonNet ISP Platform..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "⚠️  Running as root user detected"
   echo "ℹ️  For production environments, consider using a regular user with sudo privileges"
   echo "ℹ️  Continuing with root installation..."
   USER="root"
   HOME="/root"
else
   echo "✅ Running as non-root user"
fi

# Check Ubuntu version
if ! grep -q "22.04" /etc/os-release; then
    echo "⚠️  Warning: This script is designed for Ubuntu 22.04 LTS"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system packages
echo "📦 Updating system packages..."
if [[ $EUID -eq 0 ]]; then
    apt update && apt upgrade -y
else
    sudo apt update && sudo apt upgrade -y
fi

# Install Docker and Docker Compose
echo "🐳 Installing Docker..."
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
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    if [[ $EUID -eq 0 ]]; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Install additional tools
echo "🛠️  Installing additional tools..."
if [[ $EUID -eq 0 ]]; then
    apt install -y curl wget git htop tree jq ufw fail2ban
else
    sudo apt install -y curl wget git htop tree jq ufw fail2ban
fi

# Disable IPv6 to prevent network issues
echo "🔒 Disabling IPv6 to prevent network conflicts..."
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
echo "✅ IPv6 disabled successfully"

# Configure firewall (IPv4 only)
echo "🔒 Configuring firewall (IPv4 only)..."
if [[ $EUID -eq 0 ]]; then
    # Ensure SSH stays open before resetting firewall
    ufw allow 22/tcp
    sleep 2

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp   # SSH - CRITICAL
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 1812/udp  # RADIUS Auth
    ufw allow 1813/udp  # RADIUS Accounting
    ufw allow 3799/udp  # CoA/DM
    ufw allow 3000/tcp  # Admin Portal
    ufw allow 3001/tcp  # Customer Portal
    ufw allow 4000/tcp  # API Backend
    ufw allow 3002/tcp  # Grafana
    ufw allow 9090/tcp  # Prometheus
    ufw allow 5555/tcp  # Flower

    # Disable IPv6 in UFW
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

    ufw --force enable

    # Verify SSH is still allowed
    ufw status | grep -q "22/tcp" && echo "✅ SSH access confirmed"
else
    # Ensure SSH stays open before resetting firewall
    sudo ufw allow 22/tcp
    sleep 2

    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp   # SSH - CRITICAL
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 1812/udp  # RADIUS Auth
    sudo ufw allow 1813/udp  # RADIUS Accounting
    sudo ufw allow 3799/udp  # CoA/DM
    sudo ufw allow 3000/tcp  # Admin Portal
    sudo ufw allow 3001/tcp  # Customer Portal
    sudo ufw allow 4000/tcp  # API Backend
    sudo ufw allow 3002/tcp  # Grafana
    sudo ufw allow 9090/tcp  # Prometheus
    sudo ufw allow 5555/tcp  # Flower

    # Disable IPv6 in UFW
    sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

    sudo ufw --force enable

    # Verify SSH is still allowed
    sudo ufw status | grep -q "22/tcp" && echo "✅ SSH access confirmed"
fi

# Create environment file if it doesn't exist
echo "⚙️  Setting up environment configuration..."
if [ ! -f .env ]; then
    cp env.example .env
    echo "Environment file created. Please edit .env with your settings."
fi

# Generate SSL certificates directory
echo "🔐 Creating SSL certificates directory..."
mkdir -p ssl
if [ ! -f ssl/selfsigned.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/selfsigned.key \
        -out ssl/selfsigned.crt \
        -subj "/C=AF/ST=Kabul/L=Kabul/O=HaroonNet/OU=IT/CN=haroonnet.local"
    echo "Self-signed SSL certificates generated"
fi

# Create required directories
echo "📁 Creating required directories..."
mkdir -p {logs,backups,uploads}
mkdir -p logs/freeradius
mkdir -p config/{nginx/conf.d,prometheus,grafana/{provisioning,dashboards},loki,promtail}
mkdir -p database/backups
chmod 755 logs/freeradius

# Set proper permissions
echo "🔑 Setting permissions..."
chmod 755 scripts/*.sh
chmod 600 ssl/selfsigned.key
chmod 644 ssl/selfsigned.crt

# Build and start services
echo "🏗️  Building and starting services..."
docker-compose build

echo "🚀 Starting HaroonNet ISP Platform..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "🔍 Checking service status..."
docker-compose ps

# Run database migrations and seed data
echo "🗄️  Setting up database..."
docker-compose exec api npm run migration:run || true

# Display access information
echo ""
echo "✅ HaroonNet ISP Platform setup completed!"
echo ""
echo "🌐 Access URLs:"
echo "   Admin Portal:    https://localhost:3000"
echo "   Customer Portal: https://localhost:3001"
echo "   API Docs:        https://localhost:4000/api/docs"
echo "   Grafana:         https://localhost:3002 (admin/admin123)"
echo "   Prometheus:      https://localhost:9090"
echo ""
echo "🔑 Default Credentials:"
echo "   Admin User:      admin@haroonnet.com"
echo "   Password:        admin123"
echo ""
echo "📋 Next Steps:"
echo "   1. Change default passwords"
echo "   2. Configure your NAS devices in the admin portal"
echo "   3. Set up your service plans"
echo "   4. Configure notification settings"
echo "   5. Test RADIUS authentication"
echo ""
echo "📖 Documentation: Check the docs/ directory for detailed guides"
echo "🆘 Support: Create an issue in the repository for help"
echo ""

# Check if user needs to logout/login for docker group
if [[ $EUID -ne 0 ]] && ! groups | grep -q docker; then
    echo "⚠️  You need to logout and login again for Docker group membership to take effect."
fi

echo "🎉 Setup completed successfully!"
