# 🏢 HaroonNet ISP Platform - Professional Edition

A **complete professional ISP management platform** with comprehensive web-based administration, customer management, RADIUS authentication, billing, monitoring, and support systems.

## ⚡ **ULTIMATE ONE-CLICK INSTALLATION**

### 🎯 **Perfect Installation (Handles Everything Automatically)**
```bash
# Ultimate installer - zero manual steps required
curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/install-isp-platform.sh | bash
```

**✅ This installer automatically handles:**
- ✨ **Beautiful Modern UI** - Professional design with gradients
- 🔒 **IPv6 Disable** - Prevents network conflicts
- 🛡️ **SSH-Safe Firewall** - No disconnection during install
- 🐳 **Docker IPv4 Config** - Optimal container networking
- 📁 **Directory Creation** - All permissions handled
- 🔧 **Volume Mount Fixes** - No more Docker errors
- 🔄 **Intelligent Retries** - Auto-restarts failed services
- ✅ **Health Checks** - Verifies all services work
- 📋 **Complete Setup** - Ready to use immediately

### 🔄 **Alternative Installation (Original)**
```bash
curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/one-command-install.sh | bash
```

**🎉 That's it!** Your complete professional ISP management system will be ready in 10-15 minutes with **ZERO manual intervention**.

---

## 🏢 **PROFESSIONAL FEATURES**

### 🔧 **Professional Admin Dashboard**
- **📊 Executive Dashboard** - Complete ISP KPIs, revenue, customer metrics
- **👥 Customer Management** - Add, edit, suspend, activate customers with full profiles
- **🌐 NAS Device Management** - Add, configure, restart Mikrotik routers remotely
- **📦 Service Package Management** - Create Basic/Premium/Unlimited plans with custom pricing
- **💰 Billing Department** - Professional invoice generation, payment tracking, overdue management
- **📈 Usage Analytics** - Real-time customer usage graphs, network performance analytics
- **🎫 Support Ticket System** - Full ticket management with priority levels and SLA tracking
- **📡 RADIUS Server Management** - Restart, configure, monitor authentication server
- **👨‍💼 Manager Administration** - Multi-level user access, staff management, role-based permissions

### 👥 **Customer Self-Service Portal**
- **📱 Account Dashboard** - Usage tracking, billing history, account status
- **💳 Online Payment System** - Secure bill payment, payment history
- **📊 Usage Monitoring** - Real-time data consumption tracking with graphs
- **🎫 Support System** - Submit tickets, track status, live chat
- **📋 Service Management** - Upgrade/downgrade plans, service history

### 📡 **Network Management**
- **🌐 Multi-NAS Support** - Manage multiple Mikrotik routers from single interface
- **📊 Real-time Monitoring** - Live network performance, bandwidth utilization
- **🔧 Remote Configuration** - Configure RADIUS settings, restart devices remotely
- **📈 Analytics** - Network usage patterns, peak hours, capacity planning
- **🚨 Alerting** - Automated alerts for network issues, high usage, device failures

### 💰 **Professional Billing System**
- **📄 Automated Invoicing** - Generate invoices automatically based on service plans
- **💳 Payment Processing** - Multiple payment methods, online payment gateway integration
- **📊 Revenue Analytics** - Monthly revenue reports, growth tracking, profit analysis
- **⏰ Overdue Management** - Automated reminders, service suspension for non-payment
- **📈 Business Intelligence** - Customer lifetime value, churn analysis, revenue forecasting

---

## 🌐 **ACCESS URLS**

After installation, access your professional platform:

| Service | URL | Credentials |
|---------|-----|-------------|
| **🔧 Admin Portal** | `http://YOUR_SERVER_IP:3000` | `admin@haroonnet.com` / `admin123` |
| **👥 Customer Portal** | `http://YOUR_SERVER_IP:3001` | Customer credentials |
| **📊 Grafana Monitoring** | `http://YOUR_SERVER_IP:3002` | `admin` / (generated password) |
| **📈 Prometheus Metrics** | `http://YOUR_SERVER_IP:9090` | No authentication |
| **🌸 Worker Dashboard** | `http://YOUR_SERVER_IP:5555` | No authentication |
| **🔍 API Health** | `http://YOUR_SERVER_IP:4000/health` | API endpoints |

---

## 📡 **RADIUS SERVER CONFIGURATION**

Your RADIUS server will be ready for Mikrotik configuration:

### **RADIUS Settings:**
- **Server IP**: `YOUR_SERVER_IP`
- **Authentication Port**: `1812`
- **Accounting Port**: `1813`
- **CoA Port**: `3799`
- **Shared Secret**: `haroonnet-coa-secret`

### **Mikrotik Configuration:**
```mikrotik
/radius add service=login address=YOUR_SERVER_IP secret=haroonnet-coa-secret
/radius add service=accounting address=YOUR_SERVER_IP secret=haroonnet-coa-secret
/ip hotspot profile set default use-radius=yes
```

---

## 🏗️ **PROFESSIONAL ARCHITECTURE**

```
                    ┌─────────────────────────────────────┐
                    │     PROFESSIONAL WEB INTERFACES     │
                    └─────────────────────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
┌───────▼───────┐           ┌──────────▼──────────┐           ┌──────▼──────┐
│ Admin Portal  │           │   Customer Portal   │           │  Monitoring │
│   :3000       │           │      :3001          │           │ Grafana     │
│               │           │                     │           │   :3002     │
│ • Customers   │           │ • Account Info      │           │             │
│ • NAS Devices │           │ • Usage Tracking    │           │ • Analytics │
│ • Billing     │           │ • Bill Payment      │           │ • Reports   │
│ • Tickets     │           │ • Support Tickets   │           │ • Alerts    │
│ • Analytics   │           │ • Service History   │           │ • Dashboards│
└───────────────┘           └─────────────────────┘           └─────────────┘
                                       │
                    ┌─────────────────────────────────────┐
                    │         API BACKEND :4000           │
                    │                                     │
                    │ • Customer Management APIs          │
                    │ • NAS Device Control APIs           │
                    │ • Billing & Payment APIs            │
                    │ • Support Ticket APIs               │
                    │ • Usage Analytics APIs              │
                    │ • RADIUS Integration APIs           │
                    └─────────────────────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
┌───────▼───────┐           ┌──────────▼──────────┐           ┌──────▼──────┐
│   FreeRADIUS  │           │       MySQL         │           │    Redis    │
│   :1812/1813  │           │       :3306         │           │    :6379    │
│               │           │                     │           │             │
│ • Auth Server │           │ • Customer Data     │           │ • Sessions  │
│ • Accounting  │           │ • Billing Records   │           │ • Cache     │
│ • CoA/DM      │           │ • Usage Statistics  │           │ • Queue     │
│ • Mikrotik    │           │ • Support Tickets   │           │ • Tasks     │
└───────────────┘           └─────────────────────┘           └─────────────┘
```

---

## 📋 **PROFESSIONAL SERVICE MANAGEMENT**

### **Customer Management:**
- Add customers with complete profiles
- Assign service packages and pricing
- Suspend/activate accounts
- Track usage and billing history
- Manage customer support requests

### **NAS Device Management:**
- Add Mikrotik routers and other NAS devices
- Configure RADIUS settings remotely
- Monitor device status and performance
- Restart devices and update configurations
- View active sessions and connected users

### **Service Package Management:**
- Create custom service packages
- Set speed limits (upload/download)
- Configure data limits (limited/unlimited)
- Set pricing and billing cycles
- Manage package upgrades/downgrades

### **Billing & Payment Management:**
- Automated invoice generation
- Multiple payment method support
- Overdue account management
- Revenue tracking and analytics
- Payment gateway integration

### **Support Ticket System:**
- Customer ticket submission
- Priority level management
- Status tracking and updates
- SLA monitoring and alerts
- Knowledge base integration

---

## 🔧 **MANAGEMENT COMMANDS**

```bash
# Check all services status
docker-compose ps

# View service logs
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]

# Restart RADIUS server
docker-compose restart freeradius

# Update platform
git pull origin main
docker-compose build
docker-compose up -d

# Backup database
docker-compose exec mysql mysqldump -u root -p haroonnet > backup.sql

# Monitor real-time logs
docker-compose logs -f [service-name]
```

---

## 🎯 **GETTING STARTED**

1. **🚀 Install**: Run the one-command installation
2. **🌐 Access**: Open `http://YOUR_SERVER_IP:3000`
3. **🔑 Login**: Use `admin@haroonnet.com` / `admin123`
4. **⚙️ Configure**: Set up your company information
5. **🌐 Add NAS**: Configure your Mikrotik devices
6. **📦 Create Plans**: Set up your service packages
7. **👥 Add Customers**: Start onboarding customers
8. **💰 Start Billing**: Automated invoicing begins

---

## 🛡️ **SECURITY & COMPLIANCE**

- 🔒 **SSL/TLS Encryption** - Secure web interfaces
- 🛡️ **Firewall Configuration** - Minimal attack surface
- 👤 **Role-based Access** - Admin, manager, customer roles
- 📝 **Audit Logging** - Complete activity tracking
- 🔐 **Secure Authentication** - JWT tokens, password hashing
- 🚫 **Rate Limiting** - API protection against abuse

---

## 📞 **SUPPORT**

- **Documentation**: Check the `docs/` directory
- **Issues**: Create GitHub issues for bug reports
- **Diagnostics**: Run `docker-compose logs [service]`
- **Updates**: Regular updates via Git pull

---

## 📄 **LICENSE**

MIT License - Free for commercial use

---

**🌟 Built for Professional ISP Operations Worldwide 🌟**

*Complete ISP management platform with enterprise-grade features for small to medium ISP operators.*
