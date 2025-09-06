# HaroonNet ISP Platform - Security Configuration Guide

## Critical Security Configuration Required for Production

This document outlines the security configurations that MUST be implemented before deploying to production.

### 1. Environment Variables

The following environment variables MUST be set with strong, unique values in production:

#### API Service
```bash
# JWT Secret - Must be at least 32 characters
JWT_SECRET=your-super-secure-jwt-secret-at-least-32-chars-long

# Database Credentials - Use strong passwords
DB_USER=secure_db_username
DB_PASSWORD=secure_database_password_at_least_12_chars

# RADIUS Database Credentials
RADIUS_DB_USER=secure_radius_username
RADIUS_DB_PASSWORD=secure_radius_password_at_least_12_chars
```

#### Worker Service
```bash
# Database passwords (must match API service)
DB_PASSWORD=secure_database_password_at_least_12_chars
RADIUS_DB_PASSWORD=secure_radius_password_at_least_12_chars

# CoA Secret - Must be at least 32 characters
COA_SECRET=your-super-secure-coa-secret-at-least-32-chars-long

# SMTP Configuration
SMTP_USER=your-smtp-username
SMTP_PASSWORD=your-smtp-password

# External Service Keys
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
STRIPE_SECRET_KEY=your-stripe-secret-key
```

#### Docker Compose
```bash
# MySQL Root Password
MYSQL_ROOT_PASSWORD=secure_mysql_root_password

# MySQL Application Database
MYSQL_PASSWORD=secure_database_password_at_least_12_chars

# RADIUS Database
RADIUS_DB_PASSWORD=secure_radius_password_at_least_12_chars

# Grafana Admin Password
GRAFANA_PASSWORD=secure_grafana_password
```

### 2. Production Validation

The application includes automatic validation that will prevent startup in production with weak credentials:

- JWT_SECRET must be at least 32 characters
- Database passwords must be at least 12 characters
- CoA secret must be at least 32 characters
- Default usernames like 'haroonnet' are not allowed in production
- SMTP credentials must be configured

### 3. Additional Security Measures

#### Database Security
- Change default database usernames
- Use strong, unique passwords for each database user
- Restrict database access to application containers only
- Enable SSL/TLS for database connections

#### Network Security
- Use proper firewall rules
- Restrict access to admin interfaces
- Enable HTTPS/TLS for all web interfaces
- Use VPN or IP whitelisting for administrative access

#### Application Security
- Regularly update dependencies
- Monitor for security vulnerabilities
- Implement proper logging and monitoring
- Use rate limiting and DDoS protection

### 4. Password Generation Examples

Use these commands to generate secure passwords:

```bash
# Generate JWT Secret (64 characters)
openssl rand -base64 48

# Generate Database Password (16 characters)
openssl rand -base64 12

# Generate CoA Secret (64 characters)
openssl rand -hex 32
```

### 5. Deployment Checklist

Before deploying to production:

- [ ] All environment variables are set with strong values
- [ ] Default passwords have been changed
- [ ] Database access is restricted
- [ ] HTTPS is enabled
- [ ] Firewall rules are configured
- [ ] Monitoring and logging are enabled
- [ ] Backup procedures are in place
- [ ] Security scanning has been performed

## Security Issues Fixed

This security update addresses the following vulnerabilities:

1. **Hardcoded JWT Secret**: Replaced with environment variable validation
2. **Weak Default Database Passwords**: Added production validation and secure defaults
3. **Hardcoded CoA Secret**: Replaced with configurable secret with validation
4. **Missing Production Checks**: Added automatic validation for production deployments

## Contact

For security-related issues, please contact the development team immediately.