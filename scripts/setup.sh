#!/bin/bash

# HaroonNet ISP Platform - Setup Script
# This script sets up the complete platform on Ubuntu 22.04

set -e

echo "🚀 Setting up HaroonNet ISP Platform..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root for security reasons."
   exit 1
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
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Install additional tools
echo "🛠️  Installing additional tools..."
sudo apt install -y curl wget git htop tree jq ufw fail2ban

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1812/udp  # RADIUS Auth
sudo ufw allow 1813/udp  # RADIUS Accounting
sudo ufw allow 3799/udp  # CoA/DM
sudo ufw --force enable

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
mkdir -p config/{nginx/conf.d,prometheus,grafana/{provisioning,dashboards},loki,promtail}
mkdir -p database/backups

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
echo "   Grafana:         https://localhost:3002"
echo "   Prometheus:      https://localhost:9090"
echo ""
echo "🔑 Generated Credentials (SAVE THESE!):"
# Generate secure random password if not already set
if [ -z "$ADMIN_PASSWORD" ]; then
    ADMIN_PASSWORD=$(openssl rand -base64 12)
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> .env
fi
echo "   Admin User:      admin@haroonnet.com"
echo "   Password:        $ADMIN_PASSWORD"
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
if ! groups | grep -q docker; then
    echo "⚠️  You need to logout and login again for Docker group membership to take effect."
fi

echo "🎉 Setup completed successfully!"
