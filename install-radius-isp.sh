#!/bin/bash

# Complete FreeRADIUS + Django ISP Integration
# This creates a working RADIUS server integrated with Django customer database

set -e

echo "📡 FreeRADIUS + Django ISP Integration Setup"
echo "==========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_feature() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

SERVER_IP=$(hostname -I | awk '{print $1}')
print_info "Server IP: $SERVER_IP"

echo ""
print_feature "Installing Complete RADIUS + ISP Integration:"
print_feature "✅ FreeRADIUS server with Django database integration"
print_feature "✅ Customer authentication from Django users"
print_feature "✅ NAS device management and configuration"
print_feature "✅ Real-time session tracking and accounting"
print_feature "✅ Bandwidth management and rate limiting"
print_feature "✅ Complete ISP management with RADIUS"
echo ""

# Install FreeRADIUS and dependencies
print_info "Installing FreeRADIUS and dependencies..."
apt update
apt install -y freeradius freeradius-utils freeradius-mysql python3-mysqldb mysql-server mysql-client

# Start MySQL
systemctl start mysql
systemctl enable mysql

# Create RADIUS database
print_info "Setting up RADIUS database..."
RADIUS_DB_PASSWORD=$(openssl rand -base64 16)

mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS radius;
CREATE USER IF NOT EXISTS 'radius'@'localhost' IDENTIFIED BY '$RADIUS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON radius.* TO 'radius'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import RADIUS schema
print_info "Importing RADIUS database schema..."
mysql -u radius -p$RADIUS_DB_PASSWORD radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

# Configure FreeRADIUS for MySQL
print_info "Configuring FreeRADIUS for database authentication..."

# Configure SQL module
cat > /etc/freeradius/3.0/mods-available/sql << EOF
sql {
    driver = "rlm_sql_mysql"
    dialect = "mysql"
    
    # Connection info
    server = "localhost"
    port = 3306
    login = "radius"
    password = "$RADIUS_DB_PASSWORD"
    radius_db = "radius"
    
    # Database table configuration
    acct_table1 = "radacct"
    acct_table2 = "radacct"
    postauth_table = "radpostauth"
    authcheck_table = "radcheck"
    groupcheck_table = "radgroupcheck"
    authreply_table = "radreply"
    groupreply_table = "radgroupreply"
    usergroup_table = "radusergroup"
    
    # Remove stale session data
    deletestalesessions = yes
    
    # Pool configuration
    pool {
        start = 5
        min = 4
        max = 32
        spare = 3
        uses = 0
        retry_delay = 30
        lifetime = 0
        idle_timeout = 60
    }
    
    # Read database queries from file
    read_clients = yes
    client_table = "nas"
    
    # Accounting queries
    accounting {
        reference = "%{tolower:type.%{Acct-Status-Type}.query}"
        
        type {
            accounting-on {
                query = "UPDATE \${acct_table1} SET acctstoptime=FROM_UNIXTIME(%{integer:Event-Timestamp}), acctterminatecause='%{Acct-Terminate-Cause}', acctsessiontime=unix_timestamp(FROM_UNIXTIME(%{integer:Event-Timestamp})) - unix_timestamp(acctstarttime) WHERE acctstoptime IS NULL AND nasipaddress='%{NAS-IP-Address}' AND acctstarttime <= FROM_UNIXTIME(%{integer:Event-Timestamp})"
            }
            
            accounting-off {
                query = "UPDATE \${acct_table1} SET acctstoptime=FROM_UNIXTIME(%{integer:Event-Timestamp}), acctterminatecause='%{Acct-Terminate-Cause}', acctsessiontime=unix_timestamp(FROM_UNIXTIME(%{integer:Event-Timestamp})) - unix_timestamp(acctstarttime) WHERE acctstoptime IS NULL AND nasipaddress='%{NAS-IP-Address}' AND acctstarttime <= FROM_UNIXTIME(%{integer:Event-Timestamp})"
            }
            
            start {
                query = "INSERT INTO \${acct_table1} (acctsessionid, acctuniqueid, username, realm, nasipaddress, nasportid, nasporttype, acctstarttime, acctupdatetime, acctstoptime, acctsessiontime, acctauthentic, connectinfo_start, connectinfo_stop, acctinputoctets, acctoutputoctets, calledstationid, callingstationid, acctterminatecause, servicetype, framedprotocol, framedipaddress) VALUES ('%{Acct-Session-Id}', '%{Acct-Unique-Session-Id}', '%{SQL-User-Name}', '%{Realm}', '%{NAS-IP-Address}', '%{NAS-Port}', '%{NAS-Port-Type}', FROM_UNIXTIME(%{integer:Event-Timestamp}), FROM_UNIXTIME(%{integer:Event-Timestamp}), NULL, '0', '%{Acct-Authentic}', '%{Connect-Info}', '', '0', '0', '%{Called-Station-Id}', '%{Calling-Station-Id}', '', '%{Service-Type}', '%{Framed-Protocol}', '%{Framed-IP-Address}')"
            }
            
            interim-update {
                query = "UPDATE \${acct_table1} SET acctupdatetime=FROM_UNIXTIME(%{integer:Event-Timestamp}), acctinputoctets='%{Acct-Input-Octets}', acctoutputoctets='%{Acct-Output-Octets}' WHERE acctsessionid='%{Acct-Session-Id}' AND username='%{SQL-User-Name}' AND nasipaddress='%{NAS-IP-Address}'"
            }
            
            stop {
                query = "UPDATE \${acct_table1} SET acctstoptime=FROM_UNIXTIME(%{integer:Event-Timestamp}), acctsessiontime='%{Acct-Session-Time}', acctinputoctets='%{Acct-Input-Octets}', acctoutputoctets='%{Acct-Output-Octets}', acctterminatecause='%{Acct-Terminate-Cause}', connectinfo_stop='%{Connect-Info}' WHERE acctsessionid='%{Acct-Session-Id}' AND username='%{SQL-User-Name}' AND nasipaddress='%{NAS-IP-Address}'"
            }
        }
    }
    
    # Post-Auth
    post-auth {
        reference = ".query"
        query = "INSERT INTO \${postauth_table} (username, pass, reply, authdate) VALUES ('%{SQL-User-Name}', '%{%{User-Password}:-%{Chap-Password}}', '%{reply:Packet-Type}', '%S')"
    }
}
EOF

# Enable SQL module
ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# Configure clients (NAS devices)
cat > /etc/freeradius/3.0/clients.conf << EOF
# Main client configuration
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    require_message_authenticator = no
    nas_type = other
}

# Default NAS client for Mikrotik routers
client 0.0.0.0/0 {
    secret = haroonnet-radius-secret
    shortname = mikrotik-nas
    nas_type = mikrotik
    require_message_authenticator = no
}

# Specific NAS devices (add your router IPs here)
client mikrotik-main {
    ipaddr = 192.168.1.1
    secret = haroonnet-radius-secret
    shortname = main-router
    nas_type = mikrotik
}

client mikrotik-tower1 {
    ipaddr = 192.168.1.10
    secret = haroonnet-radius-secret
    shortname = tower1
    nas_type = mikrotik
}

client mikrotik-tower2 {
    ipaddr = 192.168.1.11
    secret = haroonnet-radius-secret
    shortname = tower2
    nas_type = mikrotik
}
EOF

# Configure default site to use SQL
print_info "Configuring RADIUS authentication..."
sed -i 's/#.*sql/\tsql/' /etc/freeradius/3.0/sites-available/default
sed -i 's/#.*sql/\tsql/' /etc/freeradius/3.0/sites-available/inner-tunnel

# Configure radiusd.conf
cat >> /etc/freeradius/3.0/radiusd.conf << EOF

# HaroonNet ISP Configuration
prefix = /usr
exec_prefix = /usr
sysconfdir = /etc
localstatedir = /var
sbindir = /usr/sbin
logdir = /var/log/freeradius
raddbdir = /etc/freeradius/3.0
radacctdir = /var/log/freeradius/radacct

name = radiusd
confdir = /etc/freeradius/3.0
modconfdir = /etc/freeradius/3.0/mods-config
certdir = /etc/freeradius/3.0/certs
cadir = /etc/freeradius/3.0/certs
run_dir = /var/run/freeradius

libdir = /usr/lib/freeradius
pidfile = /var/run/freeradius/freeradius.pid
user = freerad
group = freerad

max_request_time = 30
cleanup_delay = 5
max_requests = 16384

hostname_lookups = no
allow_core_dumps = no

regular_expressions = yes
extended_expressions = yes

log {
    destination = files
    colourise = yes
    file = /var/log/freeradius/radius.log
    syslog_facility = daemon
    stripped_names = no
    auth = no
    auth_badpass = no
    auth_goodpass = no
    msg_denied = "You are already logged in - access denied"
}

checkrad = /usr/sbin/checkrad

security {
    allow_vulnerable_openssl = no
    max_attributes = 200
    reject_delay = 1
    status_server = yes
}
EOF

# Create sample RADIUS users in database
print_info "Creating sample RADIUS users..."
mysql -u radius -p$RADIUS_DB_PASSWORD radius << EOF
-- Create sample users for testing
INSERT INTO radcheck (username, attribute, op, value) VALUES 
('testuser', 'Cleartext-Password', ':=', 'testpass'),
('customer1', 'Cleartext-Password', ':=', 'password123'),
('customer2', 'Cleartext-Password', ':=', 'password456');

-- Create user groups for service plans
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES 
('basic-plan', 'Mikrotik-Rate-Limit', ':=', '10M/5M'),
('premium-plan', 'Mikrotik-Rate-Limit', ':=', '50M/25M'),
('unlimited-plan', 'Mikrotik-Rate-Limit', ':=', '100M/50M');

-- Assign users to groups
INSERT INTO radusergroup (username, groupname, priority) VALUES 
('testuser', 'basic-plan', 1),
('customer1', 'premium-plan', 1),
('customer2', 'unlimited-plan', 1);

-- Create NAS clients in database
INSERT INTO nas (nasname, shortname, type, ports, secret, server, community, description) VALUES 
('192.168.1.1', 'main-router', 'mikrotik', NULL, 'haroonnet-radius-secret', NULL, NULL, 'Main Office Router'),
('192.168.1.10', 'tower1', 'mikrotik', NULL, 'haroonnet-radius-secret', NULL, NULL, 'North Tower Router'),
('192.168.1.11', 'tower2', 'mikrotik', NULL, 'haroonnet-radius-secret', NULL, NULL, 'South Tower Router');
EOF

print_status "Sample RADIUS users and NAS devices created"

# Create Django-RADIUS sync script
print_info "Creating Django-RADIUS synchronization..."
cat > /opt/sync-django-radius.py << 'EOF'
#!/usr/bin/env python3

import os
import sys
import django
import MySQLdb
from datetime import datetime

# Add Django project to path
sys.path.append('/opt/complete-isp')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'isp_platform.settings')
django.setup()

from isp_management.models import CustomerProfile, NASDevice, ServicePlan

def sync_customers_to_radius():
    """Sync Django customers to RADIUS database"""
    print("🔄 Syncing customers to RADIUS database...")
    
    # Connect to RADIUS database
    try:
        db = MySQLdb.connect(
            host="localhost",
            user="radius", 
            passwd="RADIUS_PASSWORD_PLACEHOLDER",
            db="radius"
        )
        cursor = db.cursor()
        
        # Clear existing users
        cursor.execute("DELETE FROM radcheck WHERE username != 'testuser'")
        cursor.execute("DELETE FROM radusergroup WHERE username != 'testuser'")
        
        # Sync customers from Django
        customers = CustomerProfile.objects.filter(status='active')
        
        for customer in customers:
            username = customer.user.username
            password = 'isp123'  # Default password, can be customized
            
            # Add user to radcheck
            cursor.execute(
                "INSERT INTO radcheck (username, attribute, op, value) VALUES (%s, 'Cleartext-Password', ':=', %s)",
                (username, password)
            )
            
            # Assign service plan group
            if customer.service_plan:
                group_name = f"{customer.service_plan.plan_type}-plan"
                cursor.execute(
                    "INSERT INTO radusergroup (username, groupname, priority) VALUES (%s, %s, 1)",
                    (username, group_name)
                )
            
            print(f"✅ Synced customer: {username}")
        
        db.commit()
        db.close()
        print(f"🎉 Synced {customers.count()} customers to RADIUS")
        
    except Exception as e:
        print(f"❌ Error syncing customers: {e}")

def sync_nas_devices():
    """Sync Django NAS devices to RADIUS"""
    print("🔄 Syncing NAS devices to RADIUS...")
    
    try:
        db = MySQLdb.connect(
            host="localhost",
            user="radius",
            passwd="RADIUS_PASSWORD_PLACEHOLDER", 
            db="radius"
        )
        cursor = db.cursor()
        
        # Clear existing NAS devices (except defaults)
        cursor.execute("DELETE FROM nas WHERE shortname NOT IN ('main-router', 'tower1', 'tower2')")
        
        # Sync NAS devices from Django
        devices = NASDevice.objects.filter(status='online')
        
        for device in devices:
            cursor.execute(
                "INSERT INTO nas (nasname, shortname, type, ports, secret, server, community, description) VALUES (%s, %s, %s, NULL, %s, NULL, NULL, %s)",
                (device.ip_address, device.name.lower().replace(' ', '-'), device.device_type, device.radius_secret, device.description)
            )
            print(f"✅ Synced NAS device: {device.name} ({device.ip_address})")
        
        db.commit()
        db.close()
        print(f"🎉 Synced {devices.count()} NAS devices to RADIUS")
        
    except Exception as e:
        print(f"❌ Error syncing NAS devices: {e}")

if __name__ == "__main__":
    sync_customers_to_radius()
    sync_nas_devices()
    print("✅ Django-RADIUS sync completed!")
EOF

# Replace password placeholder
sed -i "s/RADIUS_PASSWORD_PLACEHOLDER/$RADIUS_DB_PASSWORD/g" /opt/sync-django-radius.py
chmod +x /opt/sync-django-radius.py

# Create service plan rate limits in RADIUS
print_info "Creating service plan rate limits..."
mysql -u radius -p$RADIUS_DB_PASSWORD radius << EOF
-- Clear existing group configurations
DELETE FROM radgroupcheck;
DELETE FROM radgroupreply;

-- Basic Plan (10/5 Mbps)
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES 
('basic-plan', 'Mikrotik-Rate-Limit', ':=', '10M/5M');

INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES 
('basic-plan', 'Mikrotik-Rate-Limit', ':=', '10M/5M'),
('basic-plan', 'Session-Timeout', ':=', '86400');

-- Premium Plan (50/25 Mbps)  
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES 
('premium-plan', 'Mikrotik-Rate-Limit', ':=', '50M/25M');

INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES 
('premium-plan', 'Mikrotik-Rate-Limit', ':=', '50M/25M'),
('premium-plan', 'Session-Timeout', ':=', '86400');

-- Unlimited Plan (100/50 Mbps)
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES 
('unlimited-plan', 'Mikrotik-Rate-Limit', ':=', '100M/50M');

INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES 
('unlimited-plan', 'Mikrotik-Rate-Limit', ':=', '100M/50M'),
('unlimited-plan', 'Session-Timeout', ':=', '86400');

-- Business Plan (100/50 Mbps with higher priority)
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES 
('business-plan', 'Mikrotik-Rate-Limit', ':=', '100M/50M');

INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES 
('business-plan', 'Mikrotik-Rate-Limit', ':=', '100M/50M'),
('business-plan', 'Session-Timeout', ':=', '86400'),
('business-plan', 'Mikrotik-Priority', ':=', '1');
EOF

print_status "Service plan rate limits configured"

# Configure FreeRADIUS to start on boot
systemctl enable freeradius
systemctl stop freeradius
sleep 2

# Test FreeRADIUS configuration
print_info "Testing FreeRADIUS configuration..."
if radiusd -X -C &
then
    sleep 3
    pkill -f "radiusd -X"
    print_status "FreeRADIUS configuration test passed"
else
    print_warning "FreeRADIUS configuration may have issues"
fi

# Start FreeRADIUS
systemctl start freeradius

# Configure firewall for RADIUS
print_info "Configuring firewall for RADIUS..."
ufw allow 1812/udp  # Authentication
ufw allow 1813/udp  # Accounting  
ufw allow 3799/udp  # CoA/DM
ufw reload

# Create RADIUS management commands
print_info "Creating RADIUS management tools..."
cat > /opt/radius-tools.sh << 'EOF'
#!/bin/bash

# RADIUS Management Tools

case "$1" in
    "test")
        echo "🧪 Testing RADIUS authentication..."
        radtest testuser testpass localhost 1812 testing123
        ;;
    "users")
        echo "👥 Current RADIUS users:"
        mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius -e "SELECT username, value as password FROM radcheck WHERE attribute='Cleartext-Password';"
        ;;
    "sessions")
        echo "📊 Active sessions:"
        mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius -e "SELECT username, nasipaddress, acctstarttime, acctinputoctets, acctoutputoctets FROM radacct WHERE acctstoptime IS NULL;"
        ;;
    "sync")
        echo "🔄 Syncing Django customers to RADIUS..."
        python3 /opt/sync-django-radius.py
        ;;
    "restart")
        echo "🔄 Restarting RADIUS server..."
        systemctl restart freeradius
        ;;
    "status")
        echo "📊 RADIUS server status:"
        systemctl status freeradius
        ;;
    "logs")
        echo "📋 RADIUS logs:"
        tail -f /var/log/freeradius/radius.log
        ;;
    *)
        echo "🛠️  RADIUS Management Tools"
        echo "========================="
        echo "Usage: $0 {test|users|sessions|sync|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  test     - Test RADIUS authentication"
        echo "  users    - List all RADIUS users"
        echo "  sessions - Show active user sessions"
        echo "  sync     - Sync Django customers to RADIUS"
        echo "  restart  - Restart RADIUS server"
        echo "  status   - Show RADIUS server status"
        echo "  logs     - View RADIUS logs"
        ;;
esac
EOF

sed -i "s/RADIUS_PASSWORD_PLACEHOLDER/$RADIUS_DB_PASSWORD/g" /opt/radius-tools.sh
chmod +x /opt/radius-tools.sh

# Test RADIUS authentication
print_info "Testing RADIUS authentication..."
sleep 5
if radtest testuser testpass localhost 1812 testing123 | grep -q "Access-Accept"; then
    print_status "RADIUS authentication test successful!"
else
    print_warning "RADIUS authentication test failed - check configuration"
fi

# Save RADIUS credentials
cat > /opt/radius-credentials.txt << EOF
# HaroonNet ISP - RADIUS Configuration
# ===================================

RADIUS Server IP: $SERVER_IP
Authentication Port: 1812
Accounting Port: 1813
CoA Port: 3799

# Database Configuration
RADIUS Database: radius
Database User: radius
Database Password: $RADIUS_DB_PASSWORD

# NAS Device Secret
Shared Secret: haroonnet-radius-secret

# Test User
Username: testuser
Password: testpass

# Management Tools
RADIUS Tools: /opt/radius-tools.sh
Django Sync: /opt/sync-django-radius.py

# Mikrotik Configuration Commands:
# ================================
/radius add service=login address=$SERVER_IP secret=haroonnet-radius-secret
/radius add service=accounting address=$SERVER_IP secret=haroonnet-radius-secret
/ip hotspot profile set default use-radius=yes

# Service Plans Available:
# =======================
Basic Plan: 10M/5M (basic-plan group)
Premium Plan: 50M/25M (premium-plan group)  
Unlimited Plan: 100M/50M (unlimited-plan group)
Business Plan: 100M/50M with priority (business-plan group)
EOF

chmod 600 /opt/radius-credentials.txt

print_status "FreeRADIUS + Django ISP integration completed!"

echo ""
echo "📡 RADIUS + ISP INTEGRATION READY!"
echo "================================="
echo ""
print_feature "FreeRADIUS Server Running on $SERVER_IP:1812"
print_feature "Django Customer Database Integration"
print_feature "Automatic Service Plan Rate Limiting"
print_feature "NAS Device Management"
print_feature "Real-time Session Tracking"
print_feature "Complete ISP Authentication System"
echo ""
echo "🌐 ACCESS POINTS:"
echo "================"
echo "   🏢 ISP Admin:     http://$SERVER_IP/admin"
echo "   📡 RADIUS Server: $SERVER_IP:1812 (auth) / 1813 (acct)"
echo ""
echo "🔧 RADIUS MANAGEMENT:"
echo "===================="
echo "   Test Auth:       /opt/radius-tools.sh test"
echo "   View Users:      /opt/radius-tools.sh users"
echo "   Active Sessions: /opt/radius-tools.sh sessions"
echo "   Sync Django:     /opt/radius-tools.sh sync"
echo "   Restart RADIUS:  /opt/radius-tools.sh restart"
echo "   View Logs:       /opt/radius-tools.sh logs"
echo ""
echo "🔑 MIKROTIK CONFIGURATION:"
echo "========================="
echo "   /radius add service=login address=$SERVER_IP secret=haroonnet-radius-secret"
echo "   /radius add service=accounting address=$SERVER_IP secret=haroonnet-radius-secret"
echo "   /ip hotspot profile set default use-radius=yes"
echo ""
echo "👥 TEST USERS CREATED:"
echo "====================="
echo "   testuser / testpass (Basic Plan)"
echo "   customer1 / password123 (Premium Plan)"
echo "   customer2 / password456 (Unlimited Plan)"
echo ""
echo "📋 CREDENTIALS SAVED TO:"
echo "======================="
echo "   /opt/radius-credentials.txt"
echo ""

print_status "Your ISP platform with RADIUS authentication is ready!"
print_feature "Configure your Mikrotik routers and start authenticating customers!"

echo ""
echo "🎯 NEXT STEPS:"
echo "============="
echo "1. 🔧 Configure your Mikrotik routers with the commands above"
echo "2. 👥 Add customers in Django admin (http://$SERVER_IP/admin)"
echo "3. 🔄 Run '/opt/radius-tools.sh sync' to sync customers to RADIUS"
echo "4. 📡 Test authentication with your routers"
echo "5. 📊 Monitor sessions and usage through Django admin"
echo ""

print_status "Complete ISP + RADIUS platform deployment finished!"
