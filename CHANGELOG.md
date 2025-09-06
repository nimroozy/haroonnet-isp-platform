# Changelog

All notable changes to the HaroonNet ISP Platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-06

### Changed

#### API Service
- Updated NestJS framework from 10.3.x to 10.4.20
- Updated TypeORM from 0.3.17 to 0.3.26
- Updated MySQL2 driver from 3.6.5 to 3.14.4
- Updated Redis client from 4.6.11 to 4.7.1
- Updated Bull queue from 4.12.0 to 4.16.5
- Updated security packages (helmet 7.1.0 → 7.2.0, express-rate-limit 7.1.5 → 7.5.1)
- Updated notification services (nodemailer 6.9.7 → 6.10.1, twilio 4.19.0 → 4.23.0)
- Updated payment processing (stripe 14.9.0 → 14.25.0)
- Updated validation (joi 17.11.0 → 17.13.3)
- Updated TypeScript from 5.2.2 to 5.7.3
- Updated ESLint and related packages to latest versions
- Updated all @types packages to latest compatible versions

#### Admin UI Service
- Updated Next.js from 14.0.4 to 14.2.28
- Updated React Query from 5.8.4 to 5.70.3
- Updated React Table from 8.10.7 to 8.20.7
- Updated Axios from 1.6.2 to 1.7.9
- Updated TailwindCSS from 3.3.6 to 3.4.17
- Updated form handling (react-hook-form 7.48.2 → 7.54.2)
- Updated validation (zod 3.22.4 → 3.25.76)
- Updated UI components to latest versions
- Updated TypeScript from 5.2.2 to 5.7.3

#### Worker Service (Python)
- Updated Celery from 5.3.4 to 5.4.0
- Updated Redis client from 5.0.1 to 5.2.1
- Updated SQLAlchemy from 2.0.23 to 2.0.36
- Updated Pydantic from 2.5.0 to 2.10.4
- Updated Twilio SDK from 8.10.3 to 9.5.2
- Updated Stripe SDK from 7.8.0 to 11.5.0
- Updated testing and development tools to latest versions
- Updated timezone data (pytz 2023.3 → 2024.2)

#### Docker Images
- Updated Node.js base image from 20-alpine to 22-alpine
- Updated Python base image from 3.12-slim to 3.13-slim
- Updated Ubuntu base image from 22.04 to 24.04

### Security
- Updated cryptography package from 41.0.8 to 44.0.0 addressing security vulnerabilities
- All security-related packages updated to latest stable versions

### Performance
- Improved build times with updated Node.js 22
- Better memory management with updated Python 3.13
- Optimized dependencies for smaller container sizes

### Developer Experience
- Updated all development tools to latest versions
- Improved TypeScript support with version 5.7.3
- Better linting and formatting with updated ESLint and Prettier

## [1.0.0] - 2024-12-XX (Initial Release)

### Added
- Complete ISP management platform with multi-service architecture
- FreeRADIUS integration for customer authentication
- Billing and subscription management
- Customer portal and admin interface
- Real-time monitoring with Prometheus and Grafana
- Automated notification system
- Payment processing with Stripe integration
- Support ticket system
- Comprehensive API with NestJS
- Modern UI with Next.js and TailwindCSS