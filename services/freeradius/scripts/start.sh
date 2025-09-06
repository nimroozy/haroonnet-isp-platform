#!/bin/bash

# HaroonNet ISP Platform - FreeRADIUS Startup Script

set -e

echo "Starting FreeRADIUS for HaroonNet ISP Platform..."

# Wait for MySQL to be ready
echo "Waiting for MySQL database..."
until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    echo "MySQL is unavailable - sleeping"
    sleep 5
done

echo "MySQL is ready - continuing..."

# Test database connection
echo "Testing RADIUS database connection..."
mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;" > /dev/null

# Update SQL module configuration with environment variables
sed -i "s/server = .*/server = \"$DB_HOST\"/" /etc/freeradius/3.0/mods-available/sql
sed -i "s/login = .*/login = \"$DB_USER\"/" /etc/freeradius/3.0/mods-available/sql
sed -i "s/password = .*/password = \"$DB_PASSWORD\"/" /etc/freeradius/3.0/mods-available/sql
sed -i "s/radius_db = .*/radius_db = \"$DB_NAME\"/" /etc/freeradius/3.0/mods-available/sql

# Enable SQL module
ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# Enable CoA site
ln -sf /etc/freeradius/3.0/sites-available/coa /etc/freeradius/3.0/sites-enabled/coa

# Test configuration
echo "Testing FreeRADIUS configuration..."
freeradius -CX

# Start FreeRADIUS in foreground
echo "Starting FreeRADIUS server..."
exec freeradius -f -X
