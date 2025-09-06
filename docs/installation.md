# HaroonNet ISP Platform - Installation Guide

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 22.04 LTS (recommended)
- **CPU**: 4 cores
- **RAM**: 8GB
- **Storage**: 100GB SSD
- **Network**: 1Gbps connection

### Recommended Requirements (Production)
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 8+ cores
- **RAM**: 32GB
- **Storage**: 500GB NVMe SSD
- **Network**: 10Gbps connection
- **Backup**: Separate storage for backups

## Quick Installation

### 1. System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y git curl wget
```

### 2. Download Platform

```bash
# Clone the repository
git clone <repository-url>
cd haroonnet-isp-platform

# Make setup script executable
chmod +x scripts/setup.sh
```

### 3. Configure Environment

```bash
# Copy environment template
cp env.example .env

# Edit configuration (important!)
nano .env
```

**Important Environment Variables:**
```bash
# Database
MYSQL_ROOT_PASSWORD=your-secure-password
MYSQL_PASSWORD=your-app-password
RADIUS_DB_PASSWORD=your-radius-password

# Security
JWT_SECRET=your-jwt-secret-key

# Company Information
COMPANY_NAME=Your ISP Name
COMPANY_EMAIL=admin@yourisp.com
COMPANY_PHONE=+1-234-567-8900

# Notification Settings
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### 4. Run Installation

```bash
# Run the automated setup script
./scripts/setup.sh
```

The script will:
- Install Docker and Docker Compose
- Configure firewall rules
- Generate SSL certificates
- Build and start all services
- Set up databases
- Create default admin user

### 5. Verify Installation

After installation, verify services are running:

```bash
# Check service status
docker-compose ps

# Check logs if needed
docker-compose logs -f
```

## Manual Installation

If you prefer manual installation or need to customize the process:

### 1. Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login to apply group changes
```

### 2. Configure Firewall

```bash
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
```

### 3. Build Services

```bash
# Build all services
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

### 4. Initialize Database

```bash
# Wait for MySQL to be ready
sleep 30

# The database will be automatically initialized with the SQL files
# in database/mysql/ directory
```

## Post-Installation Configuration

### 1. Access the Platform

- **Admin Portal**: https://localhost:3000
- **Customer Portal**: https://localhost:3001
- **API Documentation**: https://localhost:4000/api/docs
- **Grafana Monitoring**: https://localhost:3002

### 2. Default Credentials

- **Admin User**: admin@haroonnet.com
- **Password**: admin123
- **Grafana**: admin / admin123

### 3. Initial Setup Steps

1. **Change Default Passwords**
   - Login to admin portal
   - Go to Settings → Users
   - Change admin password

2. **Configure Company Settings**
   - Go to Settings → Company
   - Update company information
   - Set timezone and currency

3. **Add NAS Devices**
   - Go to Network → NAS Devices
   - Add your Mikrotik routers
   - Configure shared secrets

4. **Create Service Plans**
   - Go to Services → Plans
   - Create your internet packages
   - Set pricing and speed limits

5. **Configure Notifications**
   - Go to Settings → Notifications
   - Configure SMTP for emails
   - Set up SMS provider

## Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Rebuild if needed
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### Database Connection Issues
```bash
# Check MySQL logs
docker-compose logs mysql

# Verify database credentials in .env file
# Restart MySQL service
docker-compose restart mysql
```

#### RADIUS Authentication Fails
```bash
# Check FreeRADIUS logs
docker-compose logs freeradius

# Test RADIUS locally
docker-compose exec freeradius radtest test test123 localhost 1812 testing123

# Check NAS client configuration
# Verify shared secrets match
```

#### Memory Issues
```bash
# Check memory usage
docker stats

# Increase swap if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Performance Optimization

#### For High Load (10k+ users)

1. **Database Optimization**
   ```bash
   # Edit MySQL configuration
   nano config/mysql/my.cnf

   # Increase buffer pool size
   innodb_buffer_pool_size = 20G  # 70% of available RAM
   ```

2. **Redis Configuration**
   ```bash
   # Edit Redis configuration
   nano config/redis/redis.conf

   # Increase memory limit
   maxmemory 4gb
   ```

3. **Scale Services**
   ```bash
   # Scale API servers
   docker-compose up -d --scale api=3

   # Use load balancer
   # Configure NGINX upstream
   ```

### Monitoring and Maintenance

#### Daily Checks
- Monitor service status: `docker-compose ps`
- Check disk usage: `df -h`
- Review error logs: `docker-compose logs --tail=100`

#### Weekly Tasks
- Review Grafana dashboards
- Check backup integrity
- Update system packages
- Review security logs

#### Monthly Tasks
- Update platform (if new version available)
- Review and rotate logs
- Performance optimization review
- Security audit

## Backup and Recovery

### Automated Backups
The platform includes automated backup scripts:

```bash
# Manual backup
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup-2024-01-01.tar.gz
```

### Manual Database Backup
```bash
# Backup MySQL databases
docker-compose exec mysql mysqldump -u root -p haroonnet > backup-app.sql
docker-compose exec mysql mysqldump -u root -p radius > backup-radius.sql
```

## Security Hardening

### 1. SSL Certificates
Replace self-signed certificates with proper SSL certificates:

```bash
# Using Let's Encrypt
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com

# Copy certificates
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/
```

### 2. Network Security
- Use VPN for admin access
- Restrict database access to application servers only
- Enable fail2ban for additional protection
- Regular security updates

### 3. Application Security
- Change all default passwords
- Enable two-factor authentication
- Regular security audits
- Monitor access logs

## Support

For support and questions:
- Check the documentation in `docs/` directory
- Review troubleshooting section above
- Create an issue in the repository
- Contact: support@haroonnet.com
