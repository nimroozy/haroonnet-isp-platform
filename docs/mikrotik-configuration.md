# Mikrotik Configuration Guide for HaroonNet ISP Platform

This guide explains how to configure Mikrotik RouterOS to work with the HaroonNet ISP Platform's RADIUS server.

## Prerequisites

- Mikrotik RouterOS 6.40+ (RouterOS 7.x recommended)
- Administrative access to the router
- Network connectivity between Mikrotik and RADIUS server
- HaroonNet ISP Platform running and accessible

## Basic RADIUS Configuration

### 1. Add RADIUS Server

```bash
# Add RADIUS server for authentication and accounting
/radius add \
    service=ppp \
    address=192.168.1.100 \
    secret=haroonnet-secret-2024 \
    authentication-port=1812 \
    accounting-port=1813 \
    timeout=3s \
    src-address=192.168.1.1 \
    realm=""

# Verify RADIUS server was added
/radius print
```

### 2. Configure AAA (Authentication, Authorization, Accounting)

```bash
# Enable RADIUS for PPP authentication
/ppp aaa set \
    use-radius=yes \
    interim-update=00:05:00 \
    accounting=yes

# Verify AAA settings
/ppp aaa print
```

## PPPoE Server Configuration

### 1. Create PPPoE Server Profile

```bash
# Create PPPoE profile with RADIUS
/ppp profile add \
    name=pppoe-radius \
    use-mpls=default \
    use-compression=default \
    use-encryption=default \
    only-one=yes \
    change-tcp-mss=yes \
    use-upnp=default \
    address-list="" \
    use-radius=yes

# Verify profile
/ppp profile print where name=pppoe-radius
```

### 2. Set Up PPPoE Server

```bash
# Create PPPoE server interface
/interface pppoe-server server add \
    service-name=HaroonNet \
    interface=ether2 \
    default-profile=pppoe-radius \
    one-session-per-host=yes \
    max-mtu=1480 \
    max-mru=1480 \
    keepalive-timeout=60

# Verify PPPoE server
/interface pppoe-server server print
```

### 3. Configure IP Pool (Optional - if not using RADIUS pools)

```bash
# Create IP pool for PPPoE clients
/ip pool add \
    name=pppoe-pool \
    ranges=10.10.0.2-10.10.255.254

# Assign pool to profile (if not using RADIUS Framed-Pool)
/ppp profile set pppoe-radius local-address=10.10.0.1 remote-address=pppoe-pool
```

## Hotspot Configuration

### 1. Set Up Hotspot with RADIUS

```bash
# Create hotspot profile
/ip hotspot profile add \
    name=radius-hotspot \
    hotspot-address=192.168.100.1 \
    dns-name=hotspot.haroonnet.com \
    html-directory=hotspot \
    http-proxy=0.0.0.0:0 \
    smtp-server=0.0.0.0:25 \
    login-by=cookie,http-chap \
    split-user-domain=no \
    use-radius=yes

# Create hotspot server
/ip hotspot add \
    name=hotspot1 \
    interface=ether3 \
    address-pool=hotspot-pool \
    profile=radius-hotspot \
    idle-timeout=00:05:00 \
    keepalive-timeout=00:02:00 \
    addresses-per-mac=2

# Create IP pool for hotspot
/ip pool add \
    name=hotspot-pool \
    ranges=192.168.100.10-192.168.100.200
```

### 2. Configure Hotspot RADIUS

```bash
# Add RADIUS server for hotspot
/radius add \
    service=hotspot \
    address=192.168.1.100 \
    secret=haroonnet-secret-2024 \
    authentication-port=1812 \
    accounting-port=1813 \
    timeout=3s

# Enable RADIUS for hotspot
/ip hotspot profile set radius-hotspot use-radius=yes
```

## DHCP with RADIUS (Option 82)

### 1. Configure DHCP Server

```bash
# Create DHCP pool
/ip pool add \
    name=dhcp-pool \
    ranges=192.168.200.10-192.168.200.200

# Create DHCP server
/ip dhcp-server add \
    name=dhcp1 \
    interface=ether4 \
    lease-time=1d \
    address-pool=dhcp-pool \
    use-radius=yes

# Configure DHCP network
/ip dhcp-server network add \
    address=192.168.200.0/24 \
    gateway=192.168.200.1 \
    dns-server=8.8.8.8,8.8.4.4

# Add RADIUS for DHCP
/radius add \
    service=dhcp \
    address=192.168.1.100 \
    secret=haroonnet-secret-2024 \
    authentication-port=1812 \
    accounting-port=1813
```

## CoA (Change of Authorization) Configuration

### 1. Enable CoA Support

```bash
# Enable incoming RADIUS requests (for CoA/Disconnect)
/radius incoming set \
    accept=yes \
    port=3799

# Add RADIUS client (the platform server)
/radius incoming add \
    address=192.168.1.100 \
    secret=haroonnet-coa-secret-2024 \
    accept=yes
```

### 2. Test CoA Functionality

```bash
# Check active PPP sessions
/ppp active print

# Monitor RADIUS messages
/log print where topics~"radius"
```

## Advanced Configuration

### 1. Rate Limiting with Queues

The platform sends `Mikrotik-Rate-Limit` attributes. Ensure queue system is enabled:

```bash
# Check if queues are enabled
/queue simple print

# Enable queue system if not already enabled
# (Usually enabled by default)
```

### 2. Address Lists for User Management

Configure address lists for blocked/allowed users:

```bash
# Create address lists
/ip firewall address-list add \
    list=blocked-users \
    comment="Blocked users from RADIUS"

/ip firewall address-list add \
    list=premium-users \
    comment="Premium users from RADIUS"

# Create firewall rules
/ip firewall filter add \
    chain=forward \
    src-address-list=blocked-users \
    action=drop \
    comment="Block suspended users"
```

### 3. Bandwidth Monitoring

Enable traffic monitoring for accounting:

```bash
# Enable IP accounting
/ip accounting set enabled=yes

# Check accounting data
/ip accounting print
```

## Monitoring and Troubleshooting

### 1. RADIUS Logs

```bash
# Enable RADIUS logging
/system logging add \
    topics=radius \
    action=memory

# View RADIUS logs
/log print where topics~"radius"
```

### 2. PPP Session Monitoring

```bash
# View active PPP sessions
/ppp active print

# View PPP session details
/ppp active print detail where name=username

# Monitor session statistics
/interface monitor-traffic pppoe-out1
```

### 3. Common Issues and Solutions

#### Authentication Failures
```bash
# Check RADIUS server connectivity
/tool netwatch add host=192.168.1.100

# Test RADIUS authentication
/radius monitor 0 user=testuser password=testpass

# Check shared secret
/radius print detail
```

#### Accounting Issues
```bash
# Check if accounting is enabled
/ppp aaa print

# Verify interim updates are being sent
/log print where topics~"radius" and message~"accounting"

# Check accounting packets
/tool sniffer quick port=1813
```

#### CoA Not Working
```bash
# Verify CoA is enabled
/radius incoming print

# Check if CoA packets are received
/log print where topics~"radius" and message~"coa"

# Test with manual disconnect
/ppp active remove [find name=username]
```

## Security Best Practices

### 1. RADIUS Security

```bash
# Use strong shared secrets (minimum 16 characters)
# Change default secrets immediately
# Use different secrets for different services

# Example of secure secret generation
# openssl rand -base64 32
```

### 2. Network Security

```bash
# Restrict RADIUS traffic to specific interfaces
/ip firewall filter add \
    chain=input \
    protocol=udp \
    dst-port=1812,1813,3799 \
    src-address=!192.168.1.100 \
    action=drop \
    comment="Block unauthorized RADIUS access"
```

### 3. Access Control

```bash
# Limit administrative access
/user group set full policy=local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,password,web,sniff,sensitive,api,romon,dude

# Create limited admin user
/user add name=radius-admin group=read password=SecurePassword123
```

## Integration Testing

### 1. Test Authentication

```bash
# From the platform server, test RADIUS auth:
# radtest username password mikrotik-ip 1812 shared-secret

# On Mikrotik, check logs:
/log print where topics~"radius"
```

### 2. Test Accounting

```bash
# Create a test PPPoE session
# Check accounting data in platform
# Verify interim updates are received

# On Mikrotik:
/ppp active print
/radius monitor 0
```

### 3. Test CoA

```bash
# From platform, send CoA request
# Check if rate limit changes on Mikrotik
# Verify disconnect works

# Monitor on Mikrotik:
/log print where topics~"radius" and message~"coa"
```

## Performance Optimization

### 1. High Load Configuration

For high user counts (1000+ concurrent sessions):

```bash
# Increase RADIUS timeout and retries
/radius set 0 timeout=5s tries=3

# Optimize PPP settings
/ppp aaa set interim-update=00:10:00

# Enable connection tracking optimization
/ip firewall connection tracking set enabled=auto
```

### 2. Memory and CPU Optimization

```bash
# Monitor resource usage
/system resource print

# Optimize logging (disable unnecessary logs)
/system logging disable [find where topics~"debug"]

# Use connection tracking helpers only when needed
/ip firewall service-port print
```

## Backup Configuration

```bash
# Export configuration
/export file=mikrotik-radius-config

# Create backup
/system backup save name=radius-backup

# Schedule automatic backups
/system scheduler add \
    name=daily-backup \
    on-event="/system backup save name=(\"backup-\" . [/system clock get date])" \
    start-date=today \
    start-time=02:00:00 \
    interval=1d
```

This configuration will enable your Mikrotik router to work seamlessly with the HaroonNet ISP Platform for comprehensive user management, billing, and network control.
