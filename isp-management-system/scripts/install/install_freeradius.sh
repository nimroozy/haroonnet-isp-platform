#!/bin/bash

# FreeRADIUS installation and configuration script for Ubuntu 22.04

set -e

echo "=== FreeRADIUS Installation for ISP Management System ==="
echo

# Update package list
sudo apt update

# Install FreeRADIUS and dependencies
echo "Installing FreeRADIUS and related packages..."
sudo apt install -y freeradius freeradius-mysql freeradius-utils

# Install MySQL client if not present
if ! command -v mysql &> /dev/null; then
    sudo apt install -y mysql-client
fi

# Stop FreeRADIUS service during configuration
sudo systemctl stop freeradius

# Backup original configuration
echo "Backing up original FreeRADIUS configuration..."
sudo cp -r /etc/freeradius/3.0 /etc/freeradius/3.0.backup.$(date +%Y%m%d_%H%M%S)

# Create RADIUS database schema
echo "Creating RADIUS database schema..."

DB_NAME=${RADIUS_DB_NAME:-radius}
DB_USER=${RADIUS_DB_USER:-radius}
DB_PASSWORD=${RADIUS_DB_PASSWORD:-radius_password}

# Create the database SQL script
cat > /tmp/radius_schema.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS radius;
USE radius;

-- Table structure for table 'radacct'
CREATE TABLE IF NOT EXISTS radacct (
  radacctid bigint(21) NOT NULL auto_increment,
  acctsessionid varchar(64) NOT NULL default '',
  acctuniqueid varchar(32) NOT NULL default '',
  username varchar(64) NOT NULL default '',
  groupname varchar(64) NOT NULL default '',
  realm varchar(64) default '',
  nasipaddress varchar(15) NOT NULL default '',
  nasportid varchar(32) default NULL,
  nasporttype varchar(32) default NULL,
  acctstarttime datetime NULL default NULL,
  acctupdatetime datetime NULL default NULL,
  acctstoptime datetime NULL default NULL,
  acctinterval int(12) default NULL,
  acctsessiontime int(12) unsigned default NULL,
  acctauthentic varchar(32) default NULL,
  connectinfo_start varchar(50) default NULL,
  connectinfo_stop varchar(50) default NULL,
  acctinputoctets bigint(20) default NULL,
  acctoutputoctets bigint(20) default NULL,
  calledstationid varchar(50) NOT NULL default '',
  callingstationid varchar(50) NOT NULL default '',
  acctterminatecause varchar(32) NOT NULL default '',
  servicetype varchar(32) default NULL,
  framedprotocol varchar(32) default NULL,
  framedipaddress varchar(15) NOT NULL default '',
  PRIMARY KEY (radacctid),
  UNIQUE KEY acctuniqueid (acctuniqueid),
  KEY username (username),
  KEY framedipaddress (framedipaddress),
  KEY acctsessionid (acctsessionid),
  KEY acctsessiontime (acctsessiontime),
  KEY acctstarttime (acctstarttime),
  KEY acctinterval (acctinterval),
  KEY acctstoptime (acctstoptime),
  KEY nasipaddress (nasipaddress)
) ENGINE=InnoDB;

-- Table structure for table 'radcheck'
CREATE TABLE IF NOT EXISTS radcheck (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

-- Table structure for table 'radgroupcheck'
CREATE TABLE IF NOT EXISTS radgroupcheck (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253)  NOT NULL default '',
  PRIMARY KEY  (id),
  KEY groupname (groupname(32))
);

-- Table structure for table 'radgroupreply'
CREATE TABLE IF NOT EXISTS radgroupreply (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253)  NOT NULL default '',
  PRIMARY KEY  (id),
  KEY groupname (groupname(32))
);

-- Table structure for table 'radreply'
CREATE TABLE IF NOT EXISTS radreply (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

-- Table structure for table 'radusergroup'
CREATE TABLE IF NOT EXISTS radusergroup (
  username varchar(64) NOT NULL default '',
  groupname varchar(64) NOT NULL default '',
  priority int(11) NOT NULL default '1',
  KEY username (username(32))
);

-- Table structure for table 'radpostauth'
CREATE TABLE IF NOT EXISTS radpostauth (
  id int(11) NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  pass varchar(64) NOT NULL default '',
  reply varchar(32) NOT NULL default '',
  authdate timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY  (id)
);

-- Table structure for table 'nas'
CREATE TABLE IF NOT EXISTS nas (
  id int(10) NOT NULL auto_increment,
  nasname varchar(128) NOT NULL,
  shortname varchar(32),
  type varchar(30) DEFAULT 'other',
  ports int(5),
  secret varchar(60) DEFAULT 'secret' NOT NULL,
  server varchar(64),
  community varchar(50),
  description varchar(200) DEFAULT 'RADIUS Client',
  PRIMARY KEY (id),
  KEY nasname (nasname)
);
EOF

# Execute the SQL script
echo "Please enter MySQL root password:"
mysql -u root -p < /tmp/radius_schema.sql

# Create database user
mysql -u root -p << EOF
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Configure FreeRADIUS to use MySQL
echo "Configuring FreeRADIUS to use MySQL..."

# Enable SQL module
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/

# Configure SQL module
sudo tee /etc/freeradius/3.0/mods-enabled/sql > /dev/null << EOF
sql {
    driver = "rlm_sql_mysql"
    dialect = "mysql"
    
    server = "localhost"
    port = 3306
    login = "$DB_USER"
    password = "$DB_PASSWORD"
    
    radius_db = "$DB_NAME"
    
    acct_table1 = "radacct"
    acct_table2 = "radacct"
    
    postauth_table = "radpostauth"
    
    authcheck_table = "radcheck"
    groupcheck_table = "radgroupcheck"
    
    authreply_table = "radreply"
    groupreply_table = "radgroupreply"
    
    usergroup_table = "radusergroup"
    
    delete_stale_sessions = yes
    
    pool {
        start = 5
        min = 4
        max = 10
        spare = 3
        uses = 0
        lifetime = 0
        idle_timeout = 60
    }
    
    read_clients = yes
    client_table = "nas"
}
EOF

# Configure sites
sudo tee /etc/freeradius/3.0/sites-enabled/default > /dev/null << 'EOF'
server default {
    listen {
        type = auth
        ipaddr = *
        port = 0
        limit {
            max_connections = 16
            lifetime = 0
            idle_timeout = 30
        }
    }
    
    listen {
        ipaddr = *
        port = 0
        type = acct
        limit {
        }
    }
    
    authorize {
        preprocess
        chap
        mschap
        digest
        suffix
        eap {
            ok = return
        }
        files
        sql
        -ldap
        expiration
        logintime
        pap
    }
    
    authenticate {
        Auth-Type PAP {
            pap
        }
        Auth-Type CHAP {
            chap
        }
        Auth-Type MS-CHAP {
            mschap
        }
        mschap
        digest
        eap
    }
    
    preacct {
        preprocess
        acct_unique
        suffix
        files
    }
    
    accounting {
        detail
        unix
        sql
        exec
        attr_filter.accounting_response
    }
    
    session {
        sql
    }
    
    post-auth {
        update {
            &reply: += &session-state:
        }
        sql
        exec
        remove_reply_message_if_eap
    }
    
    pre-proxy {
    }
    
    post-proxy {
        eap
    }
}
EOF

# Configure inner-tunnel
sudo tee /etc/freeradius/3.0/sites-enabled/inner-tunnel > /dev/null << 'EOF'
server inner-tunnel {
    listen {
        ipaddr = 127.0.0.1
        port = 18120
        type = auth
    }
    
    authorize {
        filter_username
        chap
        mschap
        suffix
        update control {
            &Proxy-To-Realm := LOCAL
        }
        eap {
            ok = return
        }
        files
        sql
        -ldap
        expiration
        logintime
        pap
    }
    
    authenticate {
        Auth-Type PAP {
            pap
        }
        Auth-Type CHAP {
            chap
        }
        Auth-Type MS-CHAP {
            mschap
        }
        mschap
        eap
    }
    
    session {
        sql
    }
    
    post-auth {
        sql
    }
    
    pre-proxy {
    }
    
    post-proxy {
        eap
    }
}
EOF

# Set proper permissions
sudo chown -R freerad:freerad /etc/freeradius/3.0/mods-enabled/sql
sudo chmod 640 /etc/freeradius/3.0/mods-enabled/sql

# Enable and start FreeRADIUS
echo "Starting FreeRADIUS service..."
sudo systemctl enable freeradius
sudo systemctl start freeradius

# Test FreeRADIUS
echo "Testing FreeRADIUS configuration..."
sudo freeradius -X -f > /tmp/freeradius_test.log 2>&1 &
RADIUS_PID=$!
sleep 5
sudo kill $RADIUS_PID 2>/dev/null || true

if grep -q "Ready to process requests" /tmp/freeradius_test.log; then
    echo "✓ FreeRADIUS is configured correctly!"
else
    echo "✗ FreeRADIUS configuration error. Check /tmp/freeradius_test.log for details."
fi

# Create sample NAS entry
echo "Creating sample NAS entry..."
mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME << EOF
INSERT INTO nas (nasname, shortname, type, secret, description) 
VALUES ('127.0.0.1', 'localhost', 'other', 'testing123', 'Local test NAS');
EOF

echo
echo "=== FreeRADIUS Installation Complete ==="
echo
echo "Database: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASSWORD"
echo
echo "Default NAS secret: testing123"
echo
echo "To test RADIUS authentication:"
echo "  radtest testuser testpassword localhost 0 testing123"
echo
echo "FreeRADIUS logs: /var/log/freeradius/radius.log"
echo "Configuration: /etc/freeradius/3.0/"