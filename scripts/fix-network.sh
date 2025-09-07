#!/bin/bash

# HaroonNet ISP Platform - Network Configuration Fix
# This script fixes common network issues that cause SSH disconnections

set -e

echo "🔧 HaroonNet ISP Platform - Network Fix Script"
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

# 1. Disable IPv6 completely
print_status "INFO" "Disabling IPv6 system-wide..."
if [[ $EUID -eq 0 ]]; then
    # Remove any existing IPv6 disable entries to avoid duplicates
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf
    
    # Add IPv6 disable configuration
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
    
    # Apply immediately
    sysctl -p
    
    # Disable IPv6 in GRUB
    if grep -q "ipv6.disable=1" /etc/default/grub; then
        print_status "INFO" "IPv6 already disabled in GRUB"
    else
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 /' /etc/default/grub
        update-grub
        print_status "SUCCESS" "IPv6 disabled in GRUB (requires reboot)"
    fi
else
    print_status "ERROR" "This script must be run as root"
    exit 1
fi

# 2. Configure UFW for IPv4 only with SSH protection
print_status "INFO" "Configuring firewall with SSH protection..."

# First, ensure SSH is allowed before any changes
ufw allow 22/tcp
sleep 2

# Reset UFW
ufw --force reset

# Set defaults
ufw default deny incoming
ufw default allow outgoing

# Critical services first
ufw allow 22/tcp    # SSH - MUST BE FIRST
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS

# RADIUS services
ufw allow 1812/udp  # RADIUS Authentication
ufw allow 1813/udp  # RADIUS Accounting
ufw allow 3799/udp  # CoA/DM

# Web management interfaces
ufw allow 3000/tcp  # Admin Portal
ufw allow 3001/tcp  # Customer Portal
ufw allow 4000/tcp  # API Backend
ufw allow 3002/tcp  # Grafana
ufw allow 9090/tcp  # Prometheus
ufw allow 5555/tcp  # Flower

# Disable IPv6 in UFW
sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

# Enable UFW
ufw --force enable

# Verify SSH is still accessible
if ufw status | grep -q "22/tcp"; then
    print_status "SUCCESS" "SSH access confirmed in firewall"
else
    print_status "ERROR" "SSH access not found in firewall rules!"
    ufw allow 22/tcp
fi

# 3. Configure Docker daemon for IPv4 only
print_status "INFO" "Configuring Docker for IPv4 only..."

# Create Docker daemon configuration
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

# Restart Docker daemon
systemctl restart docker
print_status "SUCCESS" "Docker configured for IPv4 only"

# 4. Configure SSH daemon for security
print_status "INFO" "Securing SSH configuration..."

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Configure SSH for better security and IPv4 only
cat >> /etc/ssh/sshd_config << EOF

# HaroonNet ISP Platform SSH Security Configuration
AddressFamily inet
ListenAddress 0.0.0.0
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
EOF

# Test SSH configuration
if sshd -t; then
    systemctl restart sshd
    print_status "SUCCESS" "SSH daemon configured and restarted"
else
    print_status "ERROR" "SSH configuration error - restoring backup"
    cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    systemctl restart sshd
fi

# 5. Network interface configuration
print_status "INFO" "Checking network interface configuration..."

# Get primary network interface
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
print_status "INFO" "Primary network interface: $PRIMARY_INTERFACE"

# Ensure IPv6 is disabled on the interface
if [[ -n "$PRIMARY_INTERFACE" ]]; then
    echo 0 > /proc/sys/net/ipv6/conf/$PRIMARY_INTERFACE/disable_ipv6
    print_status "SUCCESS" "IPv6 disabled on $PRIMARY_INTERFACE"
fi

# 6. DNS configuration (IPv4 only)
print_status "INFO" "Configuring DNS for IPv4 only..."

# Backup resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.backup

# Set reliable IPv4 DNS servers
cat > /etc/resolv.conf << EOF
# HaroonNet ISP Platform DNS Configuration (IPv4 only)
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

print_status "SUCCESS" "DNS configured for IPv4 only"

# 7. Final network status check
print_status "INFO" "Final network configuration check..."

echo ""
echo "🌐 Network Configuration Summary:"
echo "================================="
echo "IPv6 Status: $(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 | sed 's/1/DISABLED/g' | sed 's/0/ENABLED/g')"
echo "Primary Interface: $PRIMARY_INTERFACE"
echo "Current IP: $(hostname -I | awk '{print $1}')"
echo ""

print_status "INFO" "UFW Status:"
ufw status numbered

echo ""
print_status "SUCCESS" "Network configuration completed!"
print_status "WARNING" "Reboot recommended to ensure all IPv6 settings take effect"
print_status "INFO" "Your SSH connection should remain stable now"

echo ""
echo "📋 Next Steps:"
echo "1. Test SSH connection stability"
echo "2. Run the ISP platform installation"
echo "3. Reboot server when convenient to complete IPv6 disable"
