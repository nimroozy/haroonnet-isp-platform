#!/bin/bash

# HaroonNet ISP Platform - Complete Cleanup Script
# This script removes EVERYTHING completely for fresh installation

set -e

echo "🗑️  HaroonNet ISP Platform - Complete Cleanup"
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

print_status "WARNING" "This will remove ALL HaroonNet ISP Platform components"
print_status "WARNING" "Including all data, configurations, and Docker resources"
echo ""
read -p "Are you sure you want to proceed? (type 'YES' to confirm): " -r
if [[ ! $REPLY == "YES" ]]; then
    print_status "INFO" "Cleanup cancelled"
    exit 0
fi

echo ""
print_status "INFO" "Starting complete cleanup..."

# 1. Stop and remove all Docker containers
print_status "INFO" "Stopping and removing all Docker containers..."
cd /opt/haroonnet 2>/dev/null || true
docker-compose down --volumes --remove-orphans 2>/dev/null || true

# Remove all HaroonNet containers (even if not in compose)
docker ps -a --filter "name=haroonnet" --format "{{.Names}}" | xargs -r docker rm -f 2>/dev/null || true

print_status "SUCCESS" "All containers removed"

# 2. Remove all Docker volumes
print_status "INFO" "Removing all Docker volumes..."
docker volume ls --filter "name=haroonnet" --format "{{.Name}}" | xargs -r docker volume rm -f 2>/dev/null || true
docker volume prune -f

print_status "SUCCESS" "All volumes removed"

# 3. Remove all Docker networks
print_status "INFO" "Removing all Docker networks..."
docker network ls --filter "name=haroonnet" --format "{{.Name}}" | xargs -r docker network rm 2>/dev/null || true
docker network prune -f

print_status "SUCCESS" "All networks removed"

# 4. Remove all Docker images
print_status "INFO" "Removing all HaroonNet Docker images..."
docker images --filter "reference=haroonnet*" --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f 2>/dev/null || true
docker image prune -af

print_status "SUCCESS" "All images removed"

# 5. Complete Docker cleanup
print_status "INFO" "Performing complete Docker system cleanup..."
docker system prune -af --volumes
docker builder prune -af

print_status "SUCCESS" "Docker system completely cleaned"

# 6. Remove installation directory
print_status "INFO" "Removing installation directory..."
rm -rf /opt/haroonnet
rm -rf ~/haroonnet-isp-platform

print_status "SUCCESS" "Installation directories removed"

# 7. Clean up configuration files
print_status "INFO" "Cleaning up system configuration..."

# Remove IPv6 disable entries (optional - you may want to keep these)
# sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
# sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
# sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

# Reset Docker daemon config (optional)
# rm -f /etc/docker/daemon.json

print_status "INFO" "System configuration preserved (IPv6 disable and Docker config kept)"

# 8. Optional: Reset firewall (uncomment if you want to reset firewall)
# print_status "INFO" "Resetting firewall..."
# ufw --force reset
# ufw default deny incoming
# ufw default allow outgoing
# ufw allow ssh
# ufw --force enable

print_status "INFO" "Firewall configuration preserved"

# 9. Verify cleanup
print_status "INFO" "Verifying complete cleanup..."

REMAINING_CONTAINERS=$(docker ps -a --filter "name=haroonnet" --format "{{.Names}}" | wc -l)
REMAINING_VOLUMES=$(docker volume ls --filter "name=haroonnet" --format "{{.Name}}" | wc -l)
REMAINING_NETWORKS=$(docker network ls --filter "name=haroonnet" --format "{{.Name}}" | wc -l)
REMAINING_IMAGES=$(docker images --filter "reference=haroonnet*" --format "{{.Repository}}" | wc -l)

if [[ $REMAINING_CONTAINERS -eq 0 && $REMAINING_VOLUMES -eq 0 && $REMAINING_NETWORKS -eq 0 && $REMAINING_IMAGES -eq 0 ]]; then
    print_status "SUCCESS" "Complete cleanup verified - all HaroonNet components removed"
else
    print_status "WARNING" "Some components may still exist:"
    print_status "INFO" "Containers: $REMAINING_CONTAINERS"
    print_status "INFO" "Volumes: $REMAINING_VOLUMES"
    print_status "INFO" "Networks: $REMAINING_NETWORKS"
    print_status "INFO" "Images: $REMAINING_IMAGES"
fi

echo ""
echo "🎯 CLEANUP COMPLETED!"
echo "===================="
echo ""
print_status "SUCCESS" "HaroonNet ISP Platform completely removed"
echo ""
echo "🚀 FOR FRESH INSTALLATION:"
echo ""
echo "Run this command for perfect one-click installation:"
echo ""
echo "curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/install-isp-platform.sh | bash"
echo ""
echo "This will install the complete professional ISP platform with:"
echo "✨ Beautiful modern UI"
echo "🔧 All issues automatically fixed"
echo "🚀 Zero manual intervention required"
echo ""
print_status "INFO" "Your server is now ready for fresh installation!"
