# HaroonNet ISP Billing & RADIUS Platform v1.1.0

A comprehensive ISP billing and RADIUS platform built for scale, supporting 10,000+ concurrent subscribers with FreeRADIUS 3.2.x, MySQL, and modern web technologies.

> **🔒 Security Update v1.1.0**: Critical security vulnerabilities in Next.js have been patched. Upgrade recommended for all installations.

## Features

- **FreeRADIUS 3.2.x Integration**: Full MySQL integration with Mikrotik attributes support
- **Comprehensive Billing**: Pre-paid, post-paid, quotas, FUP, multi-currency support
- **CRM & Customer Management**: Lead tracking, customer profiles, service management
- **NOC Module**: Network monitoring, device management, incident tracking
- **Ticketing System**: Support tickets with SLA management
- **Real-time Analytics**: Usage graphs, billing reports, network statistics
- **Role-based Access Control**: Department-specific dashboards and permissions
- **CoA/DM Support**: Dynamic session management and bandwidth control
- **Multi-site Support**: Branch management and geolocation features

## Architecture

- **Frontend**: Next.js (React) with Tailwind CSS and shadcn/ui
- **API**: Node.js with NestJS framework
- **Workers**: Python with Celery for background tasks
- **Database**: MySQL 8.x with optimized schemas
- **Cache**: Redis for sessions and caching
- **RADIUS**: FreeRADIUS 3.2.x with SQL module
- **Monitoring**: Prometheus + Grafana + Loki
- **Deployment**: Docker Compose (production-ready) with Kubernetes support planned

## Quick Start

### Prerequisites

- Ubuntu 22.04 LTS
- Docker & Docker Compose
- 16GB RAM minimum (32GB recommended for production)
- 4 CPU cores minimum (8+ recommended)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd haroonnet-isp-platform
```

2. Copy environment configuration:
```bash
cp .env.example .env
```

3. Edit the `.env` file with your settings:
```bash
nano .env
```

4. Start all services:
```bash
docker-compose up -d
```

5. Run initial setup:
```bash
./scripts/setup.sh
```

6. Access the platform:
- Admin Portal: https://localhost:3000
- Customer Portal: https://localhost:3001
- API Documentation: https://localhost:4000/api/docs

## Default Credentials

- **Admin User**: admin@haroonnet.com / admin123
- **MySQL Root**: root / haroonnet123
- **RADIUS DB**: radius / radpass

## Documentation

- [Installation Guide](docs/installation.md)
- [Fresh Ubuntu Installation](docs/fresh-ubuntu-installation.md)
- [Mikrotik Configuration](docs/mikrotik-configuration.md)
- [Installation Summary](INSTALLATION-SUMMARY.md)
- [Deployment Status](DEPLOYMENT-STATUS.md)
- [Changelog](CHANGELOG.md)

## What's New in v1.1.0

🔒 **Security Fixes**
- Updated Next.js to 14.2.32 (from 14.0.4) - **Critical security update**
- Fixed multiple vulnerabilities including SSRF, cache poisoning, and authorization bypass
- Updated NestJS CLI and other dependencies

🚀 **Production Ready**
- Complete ISP billing and RADIUS platform (90%+ feature complete)
- Supports 10,000+ concurrent subscribers
- Full automation with Celery workers
- Comprehensive monitoring with Prometheus/Grafana
- Load tested and performance optimized

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

For support and questions, please create an issue in the repository.
