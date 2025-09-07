# HaroonNet ISP Platform Dashboards

This directory contains Grafana dashboard JSON files that will be automatically provisioned when Grafana starts.

## Dashboard Categories

### System Monitoring
- Infrastructure health
- Resource utilization
- Performance metrics

### ISP Operations
- Customer statistics
- Service performance
- Revenue tracking
- Network monitoring

### RADIUS Authentication
- Authentication success/failure rates
- Active sessions
- Bandwidth usage

### Application Metrics
- API response times
- Error rates
- Database performance
- Queue processing

## Adding New Dashboards

1. Create or import dashboards in Grafana UI
2. Export dashboard JSON
3. Save JSON file in this directory
4. Grafana will automatically reload the dashboard

## Dashboard File Naming Convention

Use descriptive names with prefixes:
- `system-` for system monitoring dashboards
- `isp-` for ISP operations dashboards
- `radius-` for RADIUS monitoring dashboards
- `app-` for application monitoring dashboards

Example: `isp-customer-overview.json`