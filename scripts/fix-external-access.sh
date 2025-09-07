#!/bin/bash

# HaroonNet ISP Platform - Fix External Access
# This script fixes connection refused issues and enables external access

set -e

echo "🔧 HaroonNet ISP Platform - External Access Fix"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_status "ERROR" "This script must be run as root"
    exit 1
fi

# 1. Check current firewall status
print_status "INFO" "Checking current firewall configuration..."
ufw status numbered

# 2. Ensure all required ports are open for external access
print_status "INFO" "Opening all required ports for external access..."

# Allow from any IP address (0.0.0.0/0)
ufw allow from any to any port 22 proto tcp    # SSH
ufw allow from any to any port 80 proto tcp    # HTTP
ufw allow from any to any port 443 proto tcp   # HTTPS
ufw allow from any to any port 3000 proto tcp  # Admin Portal
ufw allow from any to any port 3001 proto tcp  # Customer Portal
ufw allow from any to any port 4000 proto tcp  # API
ufw allow from any to any port 3002 proto tcp  # Grafana
ufw allow from any to any port 9090 proto tcp  # Prometheus
ufw allow from any to any port 5555 proto tcp  # Flower

# RADIUS ports
ufw allow from any to any port 1812 proto udp  # RADIUS Auth
ufw allow from any to any port 1813 proto udp  # RADIUS Accounting
ufw allow from any to any port 3799 proto udp  # CoA/DM

ufw reload

print_status "SUCCESS" "Firewall configured for external access"

# 3. Check if Docker is binding to all interfaces
print_status "INFO" "Checking Docker daemon configuration..."

# Ensure Docker daemon allows external access
cat > /etc/docker/daemon.json << EOF
{
  "ipv6": false,
  "fixed-cidr": "172.17.0.0/16",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"],
  "insecure-registries": [],
  "registry-mirrors": []
}
EOF

# Restart Docker to apply changes
systemctl restart docker
sleep 10

print_status "SUCCESS" "Docker daemon configured for external access"

# 4. Check and restart services
print_status "INFO" "Restarting services with external access configuration..."

cd /opt/haroonnet

# Stop all services
docker-compose down

# Remove any problematic networks
docker network prune -f

# Start services
docker-compose up -d

# Wait for services to start
sleep 60

print_status "SUCCESS" "Services restarted with external access"

# 5. Verify external access
print_status "INFO" "Verifying external access to services..."

SERVER_IP=$(hostname -I | awk '{print $1}')
print_status "INFO" "Server IP: $SERVER_IP"

# Check if ports are listening
print_status "INFO" "Checking listening ports..."
netstat -tlnp | grep -E ':(3000|3001|4000|3002|9090|5555)' || print_status "WARNING" "Some ports may not be listening yet"

# 6. Test internal connectivity first
print_status "INFO" "Testing internal service connectivity..."

test_internal() {
    local port=$1
    local service=$2

    if nc -z localhost $port 2>/dev/null; then
        print_status "SUCCESS" "$service (port $port) is listening internally"
        return 0
    else
        print_status "WARNING" "$service (port $port) not responding internally"
        return 1
    fi
}

test_internal 3000 "Admin Portal"
test_internal 3001 "Customer Portal"
test_internal 4000 "API Service"
test_internal 3002 "Grafana"
test_internal 9090 "Prometheus"
test_internal 5555 "Flower"

# 7. Check Docker container port bindings
print_status "INFO" "Checking Docker container port bindings..."
docker-compose ps

# 8. Display network diagnostics
print_status "INFO" "Network diagnostic information..."
echo ""
echo "🌐 Network Configuration:"
echo "========================="
echo "Server IP: $SERVER_IP"
echo "Docker Network: $(docker network ls | grep haroonnet | awk '{print $2}')"
echo ""
echo "🔍 Port Status:"
echo "==============="
netstat -tlnp | grep -E ':(22|80|443|3000|3001|4000|3002|9090|5555)' | head -10

echo ""
echo "🐳 Container Status:"
echo "==================="
docker-compose ps --format "table {{.Service}}\t{{.State}}\t{{.Ports}}"

echo ""
print_status "INFO" "External access diagnostic completed"

# 9. Final recommendations
echo ""
echo "🔧 TROUBLESHOOTING RECOMMENDATIONS:"
echo "==================================="
echo ""
echo "1. Test from server console first:"
echo "   curl -I http://localhost:3000"
echo "   curl -I http://localhost:4000/health"
echo ""
echo "2. Check if services are binding correctly:"
echo "   docker-compose logs admin-ui"
echo "   docker-compose logs api"
echo ""
echo "3. Verify firewall allows external access:"
echo "   ufw status numbered"
echo ""
echo "4. Test external access:"
echo "   curl -I http://$SERVER_IP:3000"
echo ""
echo "5. If still not working, try:"
echo "   docker-compose restart admin-ui api"
echo ""

print_status "SUCCESS" "External access fix completed!"
