# HaroonNet ISP Platform - Installation Summary

## 🎯 **Quick Start for Fresh Ubuntu 22.04**

### **Option 1: Automated Installation (Recommended)**

```bash
# 1. Download the platform
git clone <repository-url>
cd haroonnet-isp-platform

# 2. Run the automated installer
./scripts/quick-install.sh

# 3. Access the platform
# Admin Portal: https://your-server-ip:3000
# Login: admin@haroonnet.com / admin123
```

### **Option 2: Manual Installation**

Follow the detailed guide in `docs/fresh-ubuntu-installation.md`

## 📋 **What Gets Installed**

### **System Components**
- ✅ **FreeRADIUS 3.2.x** with MySQL integration
- ✅ **Docker & Docker Compose** for containerization
- ✅ **MySQL 8.x** with optimized configuration
- ✅ **Redis** for caching and queues
- ✅ **Nginx** reverse proxy with SSL termination

### **Application Services**
- ✅ **NestJS API Server** (Node.js 20)
- ✅ **Admin Portal** (Next.js with Tailwind CSS)
- ✅ **Customer Portal** (Next.js)
- ✅ **Python Workers** (Celery with Redis broker)
- ✅ **Task Scheduler** (Celery Beat)

### **Monitoring Stack**
- ✅ **Prometheus** for metrics collection
- ✅ **Grafana** for dashboards and visualization
- ✅ **Loki** for log aggregation
- ✅ **Promtail** for log shipping
- ✅ **Flower** for worker monitoring

### **Security & Operations**
- ✅ **UFW Firewall** with RADIUS port configuration
- ✅ **Fail2ban** for intrusion prevention
- ✅ **SSL/TLS** certificates (self-signed by default)
- ✅ **Rate limiting** and DDoS protection
- ✅ **Automated backups** and maintenance

## 🔧 **Post-Installation Steps**

### **1. Immediate Actions (First 30 minutes)**

```bash
# Access admin portal
https://your-server-ip:3000

# Login with default credentials
Email: admin@haroonnet.com
Password: admin123

# IMMEDIATELY change the admin password
# Go to Settings → Users → Edit Admin User
```

### **2. Basic Configuration (First Hour)**

1. **Company Settings**
   - Go to Settings → Company
   - Update company name, address, contact details
   - Set timezone and default currency

2. **Add Your First NAS Device**
   - Go to Network → NAS Devices → Add New
   - Enter your Mikrotik router IP address
   - Set shared secret: `haroonnet-secret-2024`
   - Enable CoA with secret: `haroonnet-coa-secret-2024`

3. **Create Service Plans**
   - Go to Services → Plans → Add New
   - Example: "Basic 50Mbps" - 50M/50M speed, $50/month
   - Set Mikrotik rate limit: `50M/50M 100M/100M 50M/50M 8/8`

### **3. Mikrotik Router Configuration**

```bash
# SSH to your Mikrotik router and run:

# Add RADIUS server (replace YOUR_SERVER_IP)
/radius add service=ppp address=YOUR_SERVER_IP secret=haroonnet-secret-2024 authentication-port=1812 accounting-port=1813

# Enable RADIUS for PPP
/ppp aaa set use-radius=yes interim-update=00:05:00 accounting=yes

# Create PPPoE profile
/ppp profile add name=haroonnet-pppoe use-radius=yes only-one=yes

# Enable CoA
/radius incoming set accept=yes port=3799
/radius incoming add address=YOUR_SERVER_IP secret=haroonnet-coa-secret-2024

# Test configuration
/radius print
```

### **4. Create Your First Customer**

1. **Add Customer**
   - Go to Customers → Add New
   - Fill in customer details
   - Set status to "Active"

2. **Create Subscription**
   - Go to Subscriptions → Add New
   - Select customer and service plan
   - Set username (e.g., customer@haroonnet.com)
   - Set password
   - Activate subscription

3. **Test Authentication**
   ```bash
   # Test from server
   docker-compose exec freeradius radtest customer@haroonnet.com password localhost 1812 testing123

   # Should return: Access-Accept
   ```

## 📊 **Monitoring and Management**

### **Access Monitoring Dashboards**

- **Grafana**: https://your-server-ip:3002 (admin/admin123)
- **Prometheus**: https://your-server-ip:9090
- **Worker Monitoring**: https://your-server-ip:5555

### **Check System Health**

```bash
# Service status
docker-compose ps

# System resources
htop

# Run diagnostics
./scripts/run_tests.sh

# View logs
docker-compose logs -f --tail=50
```

### **Daily Operations**

```bash
# Check active RADIUS sessions
docker-compose exec mysql mysql -u radius -pradpass radius -e "SELECT username, nasipaddress, acctstarttime FROM radacct WHERE acctstoptime IS NULL LIMIT 10;"

# View recent invoices
# Access admin portal → Billing → Invoices

# Monitor worker tasks
# Access https://your-server-ip:5555

# Check system alerts
# Access Grafana dashboards
```

## 🛠️ **Common Management Tasks**

### **Add New Customer**
1. Admin Portal → Customers → Add New
2. Fill customer information
3. Create subscription with service plan
4. Customer can now authenticate via RADIUS

### **Change Customer Speed**
1. Admin Portal → Subscriptions → Edit
2. Change service plan OR
3. Use CoA to change speed immediately:
   - Go to Subscriptions → Actions → Change Speed
   - New rate limit applied instantly via CoA

### **Process Payments**
1. Admin Portal → Billing → Payments → Add New
2. Select customer and invoice
3. Enter payment details
4. System automatically updates invoice status

### **Handle Support Tickets**
1. Tickets are created via customer portal or admin portal
2. Admin Portal → Support → Tickets
3. Assign to technician
4. Track resolution time and SLA

### **Generate Reports**
1. Admin Portal → Reports
2. Select report type (revenue, usage, customer growth)
3. Choose date range
4. Export as PDF/Excel

## 🚨 **Troubleshooting**

### **Services Won't Start**
```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Check memory
free -h

# Restart specific service
docker-compose restart mysql
```

### **RADIUS Authentication Fails**
```bash
# Check FreeRADIUS logs
docker-compose logs freeradius

# Test configuration
docker-compose exec freeradius freeradius -CX

# Check user in database
docker-compose exec mysql mysql -u radius -pradpass radius -e "SELECT * FROM radcheck WHERE username='test@haroonnet.com';"
```

### **Database Issues**
```bash
# Check MySQL logs
docker-compose logs mysql

# Access MySQL directly
docker-compose exec mysql mysql -u root -p

# Check database sizes
docker-compose exec mysql mysql -u root -p -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;"
```

### **Performance Issues**
```bash
# Check resource usage
docker stats

# Run performance tests
./scripts/run_tests.sh load

# Check slow queries
docker-compose logs mysql | grep "slow query"

# Optimize database
docker-compose exec mysql mysql -u root -p -e "OPTIMIZE TABLE haroonnet.customers, haroonnet.subscriptions, radius.radacct;"
```

## 🔐 **Security Checklist**

After installation, ensure:

- [ ] **Changed all default passwords**
- [ ] **Configured proper SSL certificates**
- [ ] **Restricted firewall rules to your networks only**
- [ ] **Enabled fail2ban and monitoring**
- [ ] **Set up automated backups**
- [ ] **Configured email notifications for alerts**
- [ ] **Tested backup and restore procedures**
- [ ] **Reviewed audit logs and access controls**

## 📞 **Getting Help**

1. **Check Documentation**: `docs/` directory
2. **Run Diagnostics**: `./scripts/run_tests.sh`
3. **View Logs**: `docker-compose logs [service]`
4. **Community Support**: GitHub Issues
5. **Commercial Support**: support@haroonnet.com

---

**🎉 Congratulations!** Your HaroonNet ISP Platform is now ready to manage customers, process billing, and handle RADIUS authentication for your ISP business!
