#!/bin/bash

# Database setup script for ISP Management System

set -e

echo "=== ISP Management System Database Setup ==="
echo

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL is not installed. Installing..."
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
fi

# Check if Redis is installed
if ! command -v redis-cli &> /dev/null; then
    echo "Redis is not installed. Installing..."
    sudo apt install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
fi

# Database configuration
DB_NAME=${DB_NAME:-isp_management}
DB_USER=${DB_USER:-isp_user}
DB_PASSWORD=${DB_PASSWORD:-isp_password}

echo "Creating PostgreSQL database and user..."

# Create database and user
sudo -u postgres psql << EOF
-- Create user if not exists
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user
      WHERE usename = '$DB_USER') THEN
      CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
   END IF;
END
\$do\$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

echo "Database setup completed!"
echo
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASSWORD"
echo
echo "Please update your .env file with these credentials."