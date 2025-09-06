# HaroonNet ISP Platform - Fresh Ubuntu 22.04 Installation

This guide provides complete step-by-step instructions for installing the HaroonNet ISP Platform on a fresh Ubuntu 22.04 LTS server.

## 🖥️ **System Requirements**

### Minimum Requirements
- **OS**: Ubuntu 22.04 LTS Server
- **CPU**: 4 cores (8+ recommended)
- **RAM**: 16GB (32GB recommended for production)
- **Storage**: 200GB SSD (500GB+ for production)
- **Network**: Static IP address, internet connectivity

### Recommended Hardware
- **CPU**: Intel Xeon or AMD EPYC 8+ cores
- **RAM**: 32GB DDR4
- **Storage**: 1TB NVMe SSD with RAID 1
- **Network**: Dual 1Gbps NICs with bonding

## 🚀 **Step-by-Step Installation**

### Step 1: Initial System Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git htop tree jq vim nano ufw fail2ban \
    software-properties-common apt-transport-https ca-certificates \
    gnupg lsb-release build-essential

# Set timezone (adjust as needed)
sudo timedatectl set-timezone Asia/Kabul

# Configure hostname
sudo hostnamectl set-hostname haroonnet-server

# Reboot to apply updates
sudo reboot
```

### Step 2: Install and Configure FreeRADIUS

```bash
# Install FreeRADIUS and MySQL module
sudo apt install -y freeradius freeradius-mysql freeradius-utils

# Stop FreeRADIUS service (we'll configure it later)
sudo systemctl stop freeradius
sudo systemctl disable freeradius

# Backup original configuration
sudo cp -r /etc/freeradius/3.0 /etc/freeradius/3.0.backup

# Set proper permissions
sudo chown -R freerad:freerad /etc/freeradius/3.0
sudo chmod -R 640 /etc/freeradius/3.0
sudo chmod 750 /etc/freeradius/3.0
```

### Step 3: Install Docker and Docker Compose

```bash
# Remove old Docker versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose (standalone)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
sudo docker run hello-world
```

### Step 4: Configure Firewall

```bash
# Reset firewall to default
sudo ufw --force reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (adjust port if changed)
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow RADIUS ports
sudo ufw allow 1812/udp comment 'RADIUS Authentication'
sudo ufw allow 1813/udp comment 'RADIUS Accounting'
sudo ufw allow 3799/udp comment 'RADIUS CoA/DM'

# Allow management ports (restrict these in production)
sudo ufw allow 3000/tcp comment 'Admin Portal'
sudo ufw allow 3001/tcp comment 'Customer Portal'
sudo ufw allow 4000/tcp comment 'API Server'
sudo ufw allow 3002/tcp comment 'Grafana'
sudo ufw allow 9090/tcp comment 'Prometheus'
sudo ufw allow 5555/tcp comment 'Flower'

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status verbose
```

### Step 5: Download and Setup HaroonNet Platform

```bash
# Create application directory
sudo mkdir -p /opt/haroonnet
sudo chown $USER:$USER /opt/haroonnet
cd /opt/haroonnet

# Clone the platform (replace with actual repository URL)
git clone https://github.com/your-repo/haroonnet-isp-platform.git .

# Or if you have the files locally, copy them:
# cp -r /path/to/haroonnet-isp-platform/* .

# Make scripts executable
chmod +x scripts/*.sh

# Create required directories
mkdir -p {logs,backups,uploads,ssl}
mkdir -p config/{nginx/conf.d,prometheus,grafana/{provisioning,dashboards},loki,promtail}
```

### Step 6: Configure Environment

```bash
# Copy environment template
cp env.example .env

# Generate strong passwords and secrets
MYSQL_ROOT_PASS=$(openssl rand -base64 32)
MYSQL_APP_PASS=$(openssl rand -base64 32)
RADIUS_DB_PASS=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
COA_SECRET=$(openssl rand -base64 32)

# Edit environment file
nano .env
```

**Update the following critical values in `.env`:**

```bash
# Database passwords (use the generated ones above)
MYSQL_ROOT_PASSWORD=your-generated-root-password
MYSQL_PASSWORD=your-generated-app-password
RADIUS_DB_PASSWORD=your-generated-radius-password

# Security
JWT_SECRET=your-generated-jwt-secret
COA_SECRET=your-generated-coa-secret

# Company information
COMPANY_NAME=Your ISP Name
COMPANY_EMAIL=admin@yourisp.com
COMPANY_PHONE=+93-XXX-XXX-XXXX

# Email configuration (configure for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# SMS configuration (optional)
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_FROM_NUMBER=+1234567890
```

### Step 7: Generate SSL Certificates

```bash
# Generate self-signed certificates for development
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/selfsigned.key \
    -out ssl/selfsigned.crt \
    -subj "/C=AF/ST=Kabul/L=Kabul/O=YourISP/OU=IT/CN=yourdomain.com"

# Set proper permissions
chmod 600 ssl/selfsigned.key
chmod 644 ssl/selfsigned.crt

# For production, get real SSL certificates:
# sudo apt install certbot
# sudo certbot certonly --standalone -d yourdomain.com
# cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/
# cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/selfsigned.key
```

### Step 8: Configure System Limits

```bash
# Increase system limits for high performance
sudo tee -a /etc/security/limits.conf << EOF
# HaroonNet ISP Platform limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
root soft nofile 65536
root hard nofile 65536
EOF

# Update systemd limits
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/limits.conf << EOF
[Manager]
DefaultLimitNOFILE=65536
DefaultLimitNPROC=32768
EOF

# Configure sysctl for network performance
sudo tee -a /etc/sysctl.conf << EOF
# HaroonNet ISP Platform network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
EOF

# Apply sysctl settings
sudo sysctl -p
```

### Step 9: Build and Start the Platform

```bash
# Log out and log back in to apply docker group membership
exit
# SSH back in

# Navigate to platform directory
cd /opt/haroonnet

# Build all services
docker-compose build --no-cache

# Start the platform
docker-compose up -d

# Check service status
docker-compose ps

# View logs to ensure everything is starting correctly
docker-compose logs -f --tail=50
```

### Step 10: Initialize Database and Verify Installation

```bash
# Wait for services to be fully ready (2-3 minutes)
sleep 180

# Check if all services are running
docker-compose ps

# Verify database initialization
docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"

# Test RADIUS authentication
docker-compose exec freeradius radtest admin@haroonnet.com admin123 localhost 1812 testing123

# Check API health
curl http://localhost:4000/health

# Check admin portal
curl http://localhost:3000

# Run comprehensive tests
./scripts/run_tests.sh
```

## 🔧 **Post-Installation Configuration**

### 1. Access the Platform

- **Admin Portal**: https://your-server-ip:3000
- **Customer Portal**: https://your-server-ip:3001
- **API Documentation**: https://your-server-ip:4000/api/docs
- **Grafana Monitoring**: https://your-server-ip:3002
- **Worker Monitoring**: https://your-server-ip:5555

### 2. Default Login Credentials

- **Admin User**: `admin@haroonnet.com`
- **Password**: `admin123`
- **Grafana**: `admin` / `admin123`

**⚠️ IMPORTANT: Change these passwords immediately after first login!**

### 3. Initial Configuration Steps

1. **Login to Admin Portal**
   ```bash
   # Access: https://your-server-ip:3000
   # Login with: admin@haroonnet.com / admin123
   ```

2. **Change Default Passwords**
   - Go to Settings → Users
   - Change admin password
   - Update Grafana admin password

3. **Configure Company Settings**
   - Go to Settings → Company
   - Update company information
   - Set timezone and currency
   - Configure contact details

4. **Add Your NAS Devices**
   - Go to Network → NAS Devices
   - Add your Mikrotik routers
   - Configure IP addresses and shared secrets
   - Test connectivity

5. **Create Service Plans**
   - Go to Services → Plans
   - Create internet packages (speeds, quotas, pricing)
   - Configure Mikrotik rate limits
   - Set billing cycles

6. **Configure Notifications**
   - Go to Settings → Notifications
   - Configure SMTP settings for emails
   - Set up SMS provider (Twilio)
   - Test notification delivery

## 🔍 **Verification and Testing**

### 1. System Health Check

```bash
# Check all services are running
docker-compose ps

# Check system resources
htop

# Check disk space
df -h

# Check network connectivity
ss -tuln | grep -E ':(1812|1813|3799|3000|4000)'
```

### 2. RADIUS Testing

```bash
# Test RADIUS authentication (from server)
docker-compose exec freeradius radtest test@haroonnet.com test123 localhost 1812 testing123

# Test from external client (replace IP)
radtest test@haroonnet.com test123 YOUR_SERVER_IP 1812 testing123

# Check RADIUS logs
docker-compose logs freeradius

# Monitor active sessions
docker-compose exec mysql mysql -u radius -p${RADIUS_DB_PASSWORD} radius -e "SELECT username, nasipaddress, acctstarttime FROM radacct WHERE acctstoptime IS NULL;"
```

### 3. API Testing

```bash
# Test API health
curl -k https://YOUR_SERVER_IP:4000/health

# Test authentication endpoint
curl -k -X POST https://YOUR_SERVER_IP:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@haroonnet.com","password":"admin123"}'

# Access API documentation
curl -k https://YOUR_SERVER_IP:4000/api/docs
```

### 4. Database Verification

```bash
# Check application database
docker-compose exec mysql mysql -u haroonnet -p${MYSQL_PASSWORD} haroonnet -e "SELECT COUNT(*) as users FROM users; SELECT COUNT(*) as customers FROM customers; SELECT COUNT(*) as plans FROM service_plans;"

# Check RADIUS database
docker-compose exec mysql mysql -u radius -p${RADIUS_DB_PASSWORD} radius -e "SELECT COUNT(*) as users FROM radcheck; SELECT COUNT(*) as groups FROM radgroupreply; SELECT COUNT(*) as nas_devices FROM nas;"
```

### 5. Worker Testing

```bash
# Check worker status
docker-compose exec worker celery -A app.celery inspect active

# Check scheduled tasks
docker-compose exec scheduler celery -A app.celery inspect scheduled

# Monitor worker activity
docker-compose logs -f worker

# Access Flower monitoring
curl -k https://YOUR_SERVER_IP:5555
```

## 🛡️ **Security Hardening**

### 1. System Security

```bash
# Configure fail2ban for additional security
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit fail2ban configuration
sudo nano /etc/fail2ban/jail.local

# Add custom rules for RADIUS
sudo tee /etc/fail2ban/filter.d/freeradius.conf << EOF
[Definition]
failregex = ^.*Login incorrect.*<HOST>.*$
            ^.*Invalid user.*from <HOST>.*$
ignoreregex =
EOF

sudo tee /etc/fail2ban/jail.d/freeradius.conf << EOF
[freeradius]
enabled = true
port = 1812,1813
protocol = udp
filter = freeradius
logpath = /var/log/freeradius/radius.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

# Restart fail2ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

### 2. Docker Security

```bash
# Create Docker daemon configuration for security
sudo tee /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

# Restart Docker
sudo systemctl restart docker
```

### 3. Network Security

```bash
# Configure advanced firewall rules
# Allow only specific IP ranges for admin access (adjust as needed)
sudo ufw allow from 192.168.1.0/24 to any port 3000 comment 'Admin Portal - Local Network'
sudo ufw allow from 192.168.1.0/24 to any port 3002 comment 'Grafana - Local Network'

# Restrict RADIUS access to your network equipment only
sudo ufw allow from 192.168.1.0/24 to any port 1812 comment 'RADIUS Auth - Network Equipment'
sudo ufw allow from 192.168.1.0/24 to any port 1813 comment 'RADIUS Accounting - Network Equipment'
sudo ufw allow from 192.168.1.0/24 to any port 3799 comment 'RADIUS CoA - Network Equipment'

# Block common attack ports
sudo ufw deny 23/tcp comment 'Block Telnet'
sudo ufw deny 135/tcp comment 'Block RPC'
sudo ufw deny 445/tcp comment 'Block SMB'

# Enable logging
sudo ufw logging on

# Reload firewall
sudo ufw reload
```

## 🔧 **Mikrotik Router Configuration**

### 1. Basic RADIUS Setup on Mikrotik

```bash
# Connect to your Mikrotik router via SSH or Winbox
# Replace YOUR_SERVER_IP with your Ubuntu server IP

# Add RADIUS server
/radius add service=ppp address=YOUR_SERVER_IP secret=haroonnet-secret-2024 authentication-port=1812 accounting-port=1813 timeout=3s

# Enable RADIUS for PPP
/ppp aaa set use-radius=yes interim-update=00:05:00 accounting=yes

# Create PPPoE profile
/ppp profile add name=haroonnet-pppoe use-radius=yes only-one=yes change-tcp-mss=yes

# Set up PPPoE server
/interface pppoe-server server add service-name=HaroonNet interface=ether2 default-profile=haroonnet-pppoe

# Enable CoA
/radius incoming set accept=yes port=3799
/radius incoming add address=YOUR_SERVER_IP secret=haroonnet-coa-secret-2024

# Verify configuration
/radius print
/ppp aaa print
```

### 2. Update Platform with Mikrotik Details

```bash
# Update NAS devices in the platform
# Login to admin portal: https://YOUR_SERVER_IP:3000
# Go to Network → NAS Devices
# Add your Mikrotik router:
# - Name: Mikrotik Main Router
# - IP Address: YOUR_MIKROTIK_IP
# - Type: mikrotik
# - Shared Secret: haroonnet-secret-2024
# - CoA Port: 3799
# - CoA Secret: haroonnet-coa-secret-2024
```

## 📊 **Monitoring Setup**

### 1. Access Monitoring Dashboards

```bash
# Grafana (system monitoring)
# URL: https://YOUR_SERVER_IP:3002
# Login: admin / admin123

# Prometheus (metrics)
# URL: https://YOUR_SERVER_IP:9090

# Flower (worker monitoring)
# URL: https://YOUR_SERVER_IP:5555
```

### 2. Configure Alerting

```bash
# Edit Prometheus alerts (already configured)
nano config/prometheus/alert_rules.yml

# Configure email notifications for alerts
# Update Grafana notification channels in the web interface
```

## 🧪 **Testing the Installation**

### 1. Run Comprehensive Tests

```bash
# Run all tests
./scripts/run_tests.sh

# Run specific test categories
./scripts/run_tests.sh unit
./scripts/run_tests.sh integration
./scripts/run_tests.sh e2e
./scripts/run_tests.sh load
```

### 2. Test RADIUS Authentication

```bash
# Create a test user in the admin portal or via API
curl -k -X POST https://YOUR_SERVER_IP:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@haroonnet.com","password":"admin123"}'

# Test RADIUS authentication
docker-compose exec freeradius radtest testuser@haroonnet.com testpass localhost 1812 testing123
```

### 3. Test Complete User Workflow

1. **Create Customer** (Admin Portal)
2. **Create Subscription** with service plan
3. **Test RADIUS Authentication** from Mikrotik
4. **Generate Invoice** (manual or wait for automated)
5. **Process Payment**
6. **Monitor Usage** in real-time
7. **Test CoA** (bandwidth change)

## 🔄 **Ongoing Maintenance**

### 1. Daily Tasks

```bash
# Check system status
docker-compose ps
./scripts/run_tests.sh integration

# Check logs for errors
docker-compose logs --tail=100 | grep -i error

# Monitor disk space
df -h
```

### 2. Weekly Tasks

```bash
# Review monitoring dashboards
# Check backup integrity
# Update system packages (schedule maintenance window)
sudo apt update && sudo apt upgrade -y

# Review security logs
sudo tail -100 /var/log/auth.log
sudo ufw status verbose
```

### 3. Monthly Tasks

```bash
# Platform updates (when available)
git pull origin main
docker-compose build --no-cache
docker-compose up -d

# Database optimization
docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "OPTIMIZE TABLE haroonnet.customers, haroonnet.subscriptions, haroonnet.invoices;"

# Security audit
sudo lynis audit system
```

## 🆘 **Troubleshooting**

### Common Issues and Solutions

#### Services Won't Start
```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Check memory usage
free -h

# Restart services
docker-compose restart
```

#### Database Connection Issues
```bash
# Check MySQL logs
docker-compose logs mysql

# Test database connectivity
docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW PROCESSLIST;"

# Reset database passwords if needed
docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "ALTER USER 'haroonnet'@'%' IDENTIFIED BY 'new-password';"
```

#### RADIUS Authentication Failures
```bash
# Check FreeRADIUS logs
docker-compose logs freeradius

# Test configuration
docker-compose exec freeradius freeradius -CX

# Check database users
docker-compose exec mysql mysql -u radius -p${RADIUS_DB_PASSWORD} radius -e "SELECT * FROM radcheck LIMIT 5;"

# Verify NAS clients
docker-compose exec mysql mysql -u radius -p${RADIUS_DB_PASSWORD} radius -e "SELECT * FROM nas;"
```

#### Performance Issues
```bash
# Check resource usage
docker stats

# Monitor database performance
docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW PROCESSLIST; SHOW ENGINE INNODB STATUS\G"

# Check Redis performance
docker-compose exec redis redis-cli info stats

# Run performance tests
./scripts/run_tests.sh load
```

## 📞 **Production Deployment Checklist**

Before going live with real customers:

- [ ] **Security**: Change all default passwords
- [ ] **SSL**: Install proper SSL certificates
- [ ] **Backup**: Configure automated off-site backups
- [ ] **Monitoring**: Set up alerting to your email/SMS
- [ ] **Testing**: Run full load tests with expected user count
- [ ] **Documentation**: Train your staff on the admin interface
- [ ] **Support**: Set up customer support procedures
- [ ] **Network**: Configure your Mikrotik routers properly
- [ ] **Billing**: Test complete billing cycle end-to-end
- [ ] **Legal**: Ensure compliance with local regulations

## 🎯 **Success Criteria**

Your installation is successful when:

- ✅ All Docker services show "Up" status
- ✅ Admin portal accessible and login works
- ✅ RADIUS authentication succeeds
- ✅ Database contains default data
- ✅ Monitoring dashboards show green metrics
- ✅ Worker tasks are running (check Flower)
- ✅ Test user can authenticate via Mikrotik
- ✅ Comprehensive test suite passes

## 📧 **Support**

If you encounter issues:

1. **Check the logs**: `docker-compose logs service-name`
2. **Run diagnostics**: `./scripts/run_tests.sh`
3. **Review documentation**: Check `docs/` directory
4. **Community support**: Create GitHub issue with logs
5. **Commercial support**: Contact support@haroonnet.com

---

**Congratulations!** 🎉 You now have a fully functional, production-ready ISP billing and RADIUS platform running on Ubuntu 22.04 with comprehensive automation, monitoring, and testing capabilities.
