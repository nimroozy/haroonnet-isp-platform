#!/bin/bash

# Complete ISP Management Platform + FreeRADIUS Integration
# This installs everything: Django ISP GUI + Working RADIUS Server

set -e

echo "🏢 Complete ISP Platform + RADIUS Integration"
echo "============================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_feature() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

print_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
print_feature "INSTALLING COMPLETE PROFESSIONAL ISP PLATFORM:"
print_feature "✅ Django ISP Management with Professional UI"
print_feature "✅ FreeRADIUS Server with Database Integration"
print_feature "✅ Customer Authentication System"
print_feature "✅ NAS Device Management (Mikrotik Ready)"
print_feature "✅ Service Plan Rate Limiting"
print_feature "✅ Real-time Session Tracking"
print_feature "✅ Billing and Invoice Management"
print_feature "✅ Support Ticket System"
echo ""

# Step 1: Install Complete ISP Platform
print_step "Step 1/3: Installing Django ISP Management Platform..."
curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/cursor/develop-isp-management-gui-with-radius-integration-8670/create-complete-isp.sh | bash

# Wait for Django to be ready
sleep 10

# Step 2: Install FreeRADIUS Integration
print_step "Step 2/3: Installing FreeRADIUS Integration..."

# Install FreeRADIUS and MySQL
apt install -y freeradius freeradius-utils freeradius-mysql python3-mysqldb mysql-server mysql-client

# Start MySQL
systemctl start mysql
systemctl enable mysql

# Create RADIUS database
RADIUS_DB_PASSWORD=$(openssl rand -base64 16)

mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS radius;
CREATE USER IF NOT EXISTS 'radius'@'localhost' IDENTIFIED BY '$RADIUS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON radius.* TO 'radius'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import RADIUS schema
mysql -u radius -p$RADIUS_DB_PASSWORD radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

# Configure FreeRADIUS SQL module
cat > /etc/freeradius/3.0/mods-available/sql << EOF
sql {
    driver = "rlm_sql_mysql"
    dialect = "mysql"
    
    server = "localhost"
    port = 3306
    login = "radius"
    password = "$RADIUS_DB_PASSWORD"
    radius_db = "radius"
    
    acct_table1 = "radacct"
    acct_table2 = "radacct"
    postauth_table = "radpostauth"
    authcheck_table = "radcheck"
    groupcheck_table = "radgroupcheck"
    authreply_table = "radreply"
    groupreply_table = "radgroupreply"
    usergroup_table = "radusergroup"
    
    deletestalesessions = yes
    read_clients = yes
    client_table = "nas"
    
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
}
EOF

# Enable SQL module
ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# Configure RADIUS sites
sed -i 's/#.*sql/\tsql/' /etc/freeradius/3.0/sites-available/default
sed -i 's/#.*sql/\tsql/' /etc/freeradius/3.0/sites-available/inner-tunnel

# Configure NAS clients
cat > /etc/freeradius/3.0/clients.conf << EOF
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    require_message_authenticator = no
    nas_type = other
}

client mikrotik-routers {
    ipaddr = 0.0.0.0/0
    secret = haroonnet-radius-secret
    shortname = mikrotik-nas
    nas_type = mikrotik
    require_message_authenticator = no
}
EOF

# Create service plans in RADIUS
mysql -u radius -p$RADIUS_DB_PASSWORD radius << EOF
-- Service Plan Rate Limits
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES 
('basic', 'Mikrotik-Rate-Limit', ':=', '10M/5M'),
('premium', 'Mikrotik-Rate-Limit', ':=', '50M/25M'),
('unlimited', 'Mikrotik-Rate-Limit', ':=', '100M/50M'),
('business', 'Mikrotik-Rate-Limit', ':=', '100M/50M');

-- NAS Devices
INSERT INTO nas (nasname, shortname, type, secret, description) VALUES 
('192.168.1.1', 'main-router', 'mikrotik', 'haroonnet-radius-secret', 'Main Office Router'),
('192.168.1.10', 'tower1', 'mikrotik', 'haroonnet-radius-secret', 'Tower 1 Router'),
('192.168.1.11', 'tower2', 'mikrotik', 'haroonnet-radius-secret', 'Tower 2 Router');
EOF

# Start FreeRADIUS
systemctl enable freeradius
systemctl restart freeradius

# Step 3: Create Integration Tools
print_step "Step 3/3: Creating ISP-RADIUS Integration Tools..."

# Create customer sync script
cat > /opt/add-radius-customer.sh << 'EOF'
#!/bin/bash

# Add Customer to RADIUS
# Usage: ./add-radius-customer.sh username password plan

if [ $# -ne 3 ]; then
    echo "Usage: $0 username password service_plan"
    echo "Service plans: basic, premium, unlimited, business"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
PLAN=$3

echo "👥 Adding customer to RADIUS: $USERNAME"

mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius << EOF
-- Add user authentication
INSERT INTO radcheck (username, attribute, op, value) VALUES 
('$USERNAME', 'Cleartext-Password', ':=', '$PASSWORD');

-- Assign service plan
INSERT INTO radusergroup (username, groupname, priority) VALUES 
('$USERNAME', '$PLAN', 1);
EOF

echo "✅ Customer $USERNAME added with $PLAN plan"
echo "🔧 Test with: radtest $USERNAME $PASSWORD $SERVER_IP 1812 haroonnet-radius-secret"
EOF

sed -i "s/RADIUS_PASSWORD_PLACEHOLDER/$RADIUS_DB_PASSWORD/g" /opt/add-radius-customer.sh
chmod +x /opt/add-radius-customer.sh

# Create RADIUS status dashboard
cat > /opt/radius-dashboard.sh << 'EOF'
#!/bin/bash

echo "📡 HAROONNET ISP RADIUS DASHBOARD"
echo "================================"
echo ""

# Server status
echo "🖥️  RADIUS Server Status:"
if systemctl is-active --quiet freeradius; then
    echo "   ✅ FreeRADIUS: Running"
else
    echo "   ❌ FreeRADIUS: Stopped"
fi

# User count
USER_COUNT=$(mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius -se "SELECT COUNT(*) FROM radcheck WHERE attribute='Cleartext-Password';")
echo "   👥 Total Users: $USER_COUNT"

# Active sessions
ACTIVE_SESSIONS=$(mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius -se "SELECT COUNT(*) FROM radacct WHERE acctstoptime IS NULL;")
echo "   📊 Active Sessions: $ACTIVE_SESSIONS"

# NAS devices
NAS_COUNT=$(mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius -se "SELECT COUNT(*) FROM nas;")
echo "   🌐 NAS Devices: $NAS_COUNT"

echo ""
echo "📊 RECENT AUTHENTICATIONS:"
echo "========================="
mysql -u radius -pRADIUS_PASSWORD_PLACEHOLDER radius -e "SELECT username, reply, authdate FROM radpostauth ORDER BY authdate DESC LIMIT 5;"

echo ""
echo "🔧 QUICK COMMANDS:"
echo "=================="
echo "   Add Customer:    /opt/add-radius-customer.sh username password plan"
echo "   Test Auth:       radtest username password $SERVER_IP 1812 haroonnet-radius-secret"
echo "   View Sessions:   /opt/radius-tools.sh sessions"
echo "   Restart RADIUS:  /opt/radius-tools.sh restart"
echo ""
EOF

sed -i "s/RADIUS_PASSWORD_PLACEHOLDER/$RADIUS_DB_PASSWORD/g" /opt/radius-dashboard.sh
chmod +x /opt/radius-dashboard.sh

# Configure firewall
ufw allow 1812/udp
ufw allow 1813/udp  
ufw allow 3799/udp
ufw reload

print_status "Complete ISP + RADIUS integration finished!"

echo ""
echo "🎉 HAROONNET ISP PLATFORM WITH RADIUS READY!"
echo "============================================"
echo ""
print_feature "Professional ISP Management: http://$SERVER_IP/admin"
print_feature "RADIUS Authentication Server: $SERVER_IP:1812"
print_feature "Complete Customer Management System"
print_feature "Mikrotik Router Integration Ready"
print_feature "Service Plan Rate Limiting Active"
print_feature "Real-time Session Monitoring"
echo ""
echo "🔑 ACCESS & CREDENTIALS:"
echo "======================="
echo "   🏢 Django Admin: http://$SERVER_IP/admin (admin/admin123)"
echo "   📡 RADIUS Server: $SERVER_IP:1812 (haroonnet-radius-secret)"
echo "   🗄️  Database: radius/$RADIUS_DB_PASSWORD"
echo ""
echo "🛠️  MANAGEMENT TOOLS:"
echo "===================="
echo "   📊 RADIUS Dashboard: /opt/radius-dashboard.sh"
echo "   👥 Add Customer:     /opt/add-radius-customer.sh username password plan"
echo "   🔧 RADIUS Tools:     /opt/radius-tools.sh [command]"
echo ""
echo "🌐 MIKROTIK CONFIGURATION:"
echo "========================="
echo "   /radius add service=login address=$SERVER_IP secret=haroonnet-radius-secret"
echo "   /radius add service=accounting address=$SERVER_IP secret=haroonnet-radius-secret"
echo "   /ip hotspot profile set default use-radius=yes"
echo ""

print_status "Your complete ISP platform with working RADIUS is ready for business!"
print_info "Run '/opt/radius-dashboard.sh' to see RADIUS status anytime"
