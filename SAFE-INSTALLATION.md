# 🔒 HaroonNet ISP Platform - Safe Installation Guide

This guide ensures you won't lose SSH access during installation and provides IPv4-only configuration.

## ⚠️ IMPORTANT: Preventing SSH Disconnection

### Before Installation - Secure Your Access

1. **Test SSH Connection Stability**
   ```bash
   # Test from your local machine
   ssh -o ServerAliveInterval=60 root@YOUR_SERVER_IP
   ```

2. **Create a Backup SSH Session**
   ```bash
   # Always keep a second SSH session open as backup
   ssh root@YOUR_SERVER_IP
   ```

3. **Run Network Fix First (Recommended)**
   ```bash
   # Download and run the network fix script first
   wget https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/scripts/fix-network.sh
   chmod +x fix-network.sh
   ./fix-network.sh
   ```

## 🚀 Safe Installation Methods

### Method 1: One-Command Installation (Recommended)
```bash
# This version includes IPv6 disable and SSH protection
curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/one-command-install.sh | bash
```

### Method 2: Manual Installation
```bash
# Clone repository
git clone https://github.com/nimroozy/haroonnet-isp-platform.git
cd haroonnet-isp-platform

# Run network fix first
./scripts/fix-network.sh

# Then run setup
./scripts/setup.sh
```

### Method 3: Step-by-Step Safe Installation
```bash
# 1. Prepare system
apt update && apt upgrade -y

# 2. Install essential tools
apt install -y curl wget git htop tree jq vim nano

# 3. Secure SSH before any firewall changes
ufw allow 22/tcp
ufw --force enable

# 4. Disable IPv6
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p

# 5. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# 6. Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 7. Configure Docker for IPv4 only
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "ipv6": false,
  "fixed-cidr": "172.17.0.0/16",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker

# 8. Clone and setup ISP platform
git clone https://github.com/nimroozy/haroonnet-isp-platform.git
cd haroonnet-isp-platform

# 9. Create required directories
mkdir -p logs/freeradius
chmod 755 logs/freeradius

# 10. Configure firewall safely
ufw allow 22/tcp    # SSH - CRITICAL
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
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

# 11. Build and start platform
docker-compose build
docker-compose up -d
```

## 🔧 Troubleshooting SSH Issues

### If SSH Connection is Lost
1. **Use Console Access** (DigitalOcean, AWS, etc.)
2. **Check UFW Status**
   ```bash
   ufw status
   ```
3. **Re-enable SSH**
   ```bash
   ufw allow 22/tcp
   ufw reload
   ```
4. **Restart SSH Service**
   ```bash
   systemctl restart sshd
   ```

### If IPv6 Causes Issues
```bash
# Completely disable IPv6
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p

# Disable in GRUB (permanent)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 /' /etc/default/grub
update-grub
```

## ✅ Verification Steps

### After Installation
1. **Check SSH Access**
   ```bash
   # Should work without issues
   ssh root@YOUR_SERVER_IP
   ```

2. **Verify IPv6 is Disabled**
   ```bash
   cat /proc/sys/net/ipv6/conf/all/disable_ipv6
   # Should return: 1
   ```

3. **Check Firewall Status**
   ```bash
   ufw status
   # Should show SSH (22/tcp) as ALLOW
   ```

4. **Test ISP Platform**
   ```bash
   docker-compose ps
   # All services should be running
   ```

5. **Access Web Interfaces**
   - Admin Portal: `http://YOUR_SERVER_IP:3000`
   - Customer Portal: `http://YOUR_SERVER_IP:3001`
   - Grafana: `http://YOUR_SERVER_IP:3002`

## 🆘 Emergency Recovery

### If Completely Locked Out
1. Use your cloud provider's console access
2. Run the network fix script:
   ```bash
   wget https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/scripts/fix-network.sh
   chmod +x fix-network.sh
   ./fix-network.sh
   ```

### Reset Firewall Completely
```bash
ufw --force reset
ufw allow 22/tcp
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
```

## 📋 What's Fixed in This Version

- ✅ **IPv6 Completely Disabled** - Prevents network conflicts
- ✅ **SSH Protection** - Ensures SSH stays accessible during firewall changes
- ✅ **Docker IPv4 Only** - Configured for IPv4-only networking
- ✅ **UFW IPv6 Disabled** - Firewall configured for IPv4 only
- ✅ **Network Fix Script** - Comprehensive network configuration tool
- ✅ **Safe Installation** - Multiple installation methods with safety checks

## 🌟 Features After Installation

Your ISP platform will include:
- 🏢 **Professional Admin Dashboard**
- 👥 **Customer Management System**
- 📡 **FreeRADIUS Server**
- 💳 **Billing & Payment Processing**
- 📊 **Real-time Monitoring**
- 🎫 **Support Ticket System**
- 📈 **Usage Analytics**
- 🔧 **NAS Device Management**

**Default Login**: admin@haroonnet.com / admin123

Remember to change default passwords after first login!
