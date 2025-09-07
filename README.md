# 🌐 HaroonNet ISP Platform

A complete ISP management platform with web-based administration, customer portal, RADIUS authentication, billing, and monitoring.

## ✨ Features

- 🔧 **Web-based Admin Portal** - Complete ISP management interface
- 👥 **Customer Portal** - Self-service portal for customers
- 📡 **FreeRADIUS Server** - Authentication for Mikrotik and other NAS devices
- 💰 **Billing System** - Automated invoicing and payment processing
- 📊 **Monitoring** - Grafana dashboards and Prometheus metrics
- 🔄 **Background Tasks** - Celery workers for automated operations
- 🔒 **Security** - JWT authentication, SSL, firewall configuration
- 📱 **Mobile Responsive** - Works on all devices

## 🚀 One-Command Installation

Install the complete platform on Ubuntu 22.04 LTS:

```bash
curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/one-command-install.sh | bash
```

## 📋 Manual Installation

If you prefer manual installation:

```bash
# 1. Clone the repository
git clone https://github.com/nimroozy/haroonnet-isp-platform.git
cd haroonnet-isp-platform

# 2. Run the installation script
chmod +x fix-and-install.sh
./fix-and-install.sh
```

## 🌐 Access URLs

After installation, access your platform:

- **Admin Portal**: `http://YOUR_SERVER_IP:3000`
- **Customer Portal**: `http://YOUR_SERVER_IP:3001`
- **API Documentation**: `http://YOUR_SERVER_IP:4000/health`
- **Grafana Monitoring**: `http://YOUR_SERVER_IP:3002`
- **Prometheus Metrics**: `http://YOUR_SERVER_IP:9090`
- **Worker Dashboard**: `http://YOUR_SERVER_IP:5555`

## 🔑 Default Credentials

- **Admin Portal**: `admin@haroonnet.com` / `admin123`
- **Grafana**: `admin` / `admin123`

⚠️ **Change all default passwords after first login!**

## 📡 RADIUS Configuration

Configure your Mikrotik routers to use:
- **Authentication**: `YOUR_SERVER_IP:1812`
- **Accounting**: `YOUR_SERVER_IP:1813`
- **CoA/DM**: `YOUR_SERVER_IP:3799`
- **Shared Secret**: `testing123` (change in production)

## 🔧 Management Commands

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs [service-name]

# Restart services
docker-compose restart

# Stop platform
docker-compose down

# Update platform
git pull origin main
docker-compose build
docker-compose up -d
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Admin Portal  │    │ Customer Portal │    │   Monitoring    │
│     :3000       │    │     :3001       │    │   Grafana :3002 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Server    │
                    │     :4000       │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   FreeRADIUS    │    │     MySQL       │    │     Redis       │
│   :1812/1813    │    │     :3306       │    │     :6379       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Celery Workers  │
                    │ (Background)    │
                    └─────────────────┘
```

## 📊 Services

| Service | Port | Description |
|---------|------|-------------|
| Admin UI | 3000 | Web-based admin interface |
| Customer Portal | 3001 | Customer self-service portal |
| API | 4000 | RESTful API backend |
| Grafana | 3002 | Monitoring dashboards |
| Prometheus | 9090 | Metrics collection |
| Flower | 5555 | Worker task monitoring |
| MySQL | 3306 | Primary database |
| Redis | 6379 | Cache and sessions |
| FreeRADIUS | 1812/1813 | Authentication server |

## 🛡️ Security Features

- 🔒 **Firewall Configuration** - UFW with minimal required ports
- 🔐 **SSL Certificates** - Self-signed (replace with Let's Encrypt)
- 🛡️ **JWT Authentication** - Secure API access
- 👤 **User Roles** - Admin, operator, customer access levels
- 🚫 **Rate Limiting** - API throttling protection
- 📝 **Audit Logs** - All actions logged for compliance

## 🔧 Customization

Edit these files to customize your platform:
- `config/` - Service configurations
- `services/admin-ui/` - Admin interface customization
- `services/customer-portal/` - Customer portal customization
- `services/api/` - Backend API logic
- `.env` - Environment variables

## 📖 Documentation

- [Fresh Ubuntu Installation](docs/fresh-ubuntu-installation.md)
- [Mikrotik Configuration](docs/mikrotik-configuration.md)
- [Installation Guide](docs/installation.md)

## 🆘 Support

- Create an issue in this repository
- Check the logs: `docker-compose logs [service]`
- Run diagnostics: `./scripts/run_tests.sh`

## 📄 License

This project is licensed under the MIT License.

---

**Built with ❤️ for ISP operators worldwide**