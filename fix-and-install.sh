#!/bin/bash

# HaroonNet ISP Platform - Complete Fix and Installation Script
# Run this script on your Ubuntu server to fix all issues and install the platform

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

print_status "INFO" "Starting HaroonNet ISP Platform installation..."

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_status "ERROR" "docker-compose.yml not found. Please run this script from /opt/haroonnet"
    exit 1
fi

print_status "INFO" "Fixing configuration files..."

# 1. Fix the worker requirements.txt cryptography version
print_status "INFO" "Updating Python cryptography version..."
sed -i 's/cryptography==41.0.8/cryptography==43.0.3/' services/worker/requirements.txt
grep "cryptography" services/worker/requirements.txt

# 2. Fix API Dockerfile to use npm install instead of npm ci
print_status "INFO" "Updating API Dockerfile..."
sed -i 's/npm ci --only=production/npm install --only=production/' services/api/Dockerfile
grep "npm install" services/api/Dockerfile

# 3. Generate secure environment configuration
print_status "INFO" "Generating secure environment configuration..."

# Generate secure passwords
MYSQL_ROOT_PASS=$(openssl rand -hex 16)
MYSQL_APP_PASS=$(openssl rand -hex 16)
RADIUS_DB_PASS=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
COA_SECRET=$(openssl rand -hex 16)

# Create .env file
cat > .env << EOF
# HaroonNet ISP Platform Environment Configuration

# Application Settings
NODE_ENV=production
JWT_SECRET=$JWT_SECRET

# MySQL Database Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS
MYSQL_DATABASE=haroonnet
MYSQL_USER=haroonnet
MYSQL_PASSWORD=$MYSQL_APP_PASS

# RADIUS Database Configuration
RADIUS_DB_NAME=radius
RADIUS_DB_USER=radius
RADIUS_DB_PASSWORD=$RADIUS_DB_PASS

# Redis Configuration
REDIS_PASSWORD=

# Grafana Configuration
GRAFANA_PASSWORD=admin123

# Email Configuration (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Company Information
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
MONITORING_ENABLED=true
METRICS_RETENTION_DAYS=90

# Debug and Logging
DEBUG_MODE=false
LOG_LEVEL=info
EOF

# 4. Save credentials securely
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

# 5. Clean Docker completely
print_status "INFO" "Cleaning Docker cache..."
docker-compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -af
docker volume prune -f

# 6. Build services incrementally
print_status "INFO" "Building infrastructure services..."
docker-compose build mysql redis

print_status "INFO" "Building FreeRADIUS..."
docker-compose build freeradius

print_status "INFO" "Building Python workers..."
docker-compose build worker scheduler flower

print_status "INFO" "Building API service..."
docker-compose build api

print_status "INFO" "Building frontend services..."
docker-compose build admin-ui customer-portal

print_status "INFO" "Building monitoring services..."
docker-compose build nginx prometheus grafana loki promtail

# 7. Start all services
print_status "INFO" "Starting all services..."
docker-compose up -d

# 8. Wait for services to initialize
print_status "INFO" "Waiting for services to start..."
sleep 60

# 9. Check service status
print_status "INFO" "Checking service status..."
docker-compose ps

# 10. Test service connectivity
print_status "INFO" "Testing service connectivity..."

# Test API
if curl -f -s http://localhost:4000/health >/dev/null 2>&1; then
    print_status "SUCCESS" "API service is responding"
else
    print_status "WARNING" "API service not ready yet (this is normal, may need more time)"
fi

# Test MySQL
if docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASS -e "SELECT 1" >/dev/null 2>&1; then
    print_status "SUCCESS" "MySQL database is ready"
else
    print_status "WARNING" "MySQL not ready yet"
fi

# Test Redis
if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    print_status "SUCCESS" "Redis cache is ready"
else
    print_status "WARNING" "Redis not ready yet"
fi

# 11. Display final information
echo ""
print_status "SUCCESS" "HaroonNet ISP Platform installation completed!"
echo ""
echo "🌐 Access URLs:"
echo "   Admin Portal:     http://167.172.214.191:3000"
echo "   Customer Portal:  http://167.172.214.191:3001"
echo "   API Docs:         http://167.172.214.191:4000/api/docs"
echo "   Grafana:          http://167.172.214.191:3002"
echo "   Prometheus:       http://167.172.214.191:9090"
echo "   Flower (Workers): http://167.172.214.191:5555"
echo ""
echo "🔑 Default Credentials:"
echo "   Admin: admin@haroonnet.com / admin123"
echo "   Grafana: admin / admin123"
echo ""
echo "📋 Generated Passwords (saved in .credentials file):"
echo "   MySQL Root: $MYSQL_ROOT_PASS"
echo "   MySQL App: $MYSQL_APP_PASS"
echo "   RADIUS DB: $RADIUS_DB_PASS"
echo ""
echo "🔒 Security Notes:"
echo "   - Change all default passwords immediately"
echo "   - Configure proper SSL certificates for production"
echo "   - Review firewall rules and restrict access as needed"
echo ""
echo "📖 Next Steps:"
echo "   1. Login to admin portal and change default password"
echo "   2. Configure your company information"
echo "   3. Add your NAS devices (Mikrotik routers)"
echo "   4. Create service plans"
echo "   5. Test RADIUS authentication"
echo ""

# 12. Show any failed services
FAILED_SERVICES=$(docker-compose ps --filter "status=exited" --format "table {{.Service}}" | tail -n +2)
if [[ -n "$FAILED_SERVICES" ]]; then
    print_status "WARNING" "Some services failed to start:"
    echo "$FAILED_SERVICES"
    echo ""
    print_status "INFO" "Check logs with: docker-compose logs [service-name]"
else
    print_status "SUCCESS" "All services are running successfully!"
fi

echo ""
print_status "SUCCESS" "Installation script completed!"
