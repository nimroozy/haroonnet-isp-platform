# HaroonNet ISP Billing & RADIUS Platform

**Version 1.1.0** - Released January 6, 2025

A comprehensive ISP billing and RADIUS platform built for scale, supporting 10,000+ concurrent subscribers with FreeRADIUS 3.2.x, MySQL, and modern web technologies.

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
- **Deployment**: Docker Compose (v1.0) → Kubernetes (v2.0)

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
- [Configuration Guide](docs/configuration.md)
- [API Documentation](docs/api.md)
- [FreeRADIUS Setup](docs/freeradius.md)
- [Mikrotik Configuration](docs/mikrotik.md)
- [Monitoring Setup](docs/monitoring.md)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

For support and questions, please create an issue in the repository.
