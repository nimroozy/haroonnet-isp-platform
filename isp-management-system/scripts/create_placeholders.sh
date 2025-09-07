#!/bin/bash

# Create placeholder React components

create_component() {
    local path=$1
    local name=$2
    
    cat > "$path" << EOF
import React from 'react';
import { Typography, Box } from '@mui/material';

function $name() {
  return (
    <Box>
      <Typography variant="h4">$name</Typography>
      <Typography variant="body1" sx={{ mt: 2 }}>
        $name page - Coming soon
      </Typography>
    </Box>
  );
}

export default $name;
EOF
}

# Customer pages
create_component "/workspace/isp-management-system/frontend/src/pages/Customers/CustomerDetail.js" "CustomerDetail"
create_component "/workspace/isp-management-system/frontend/src/pages/Customers/AddCustomer.js" "AddCustomer"

# Billing pages
create_component "/workspace/isp-management-system/frontend/src/pages/Billing/Invoices.js" "Invoices"
create_component "/workspace/isp-management-system/frontend/src/pages/Billing/Payments.js" "Payments"
create_component "/workspace/isp-management-system/frontend/src/pages/Billing/ServicePlans.js" "ServicePlans"
create_component "/workspace/isp-management-system/frontend/src/pages/Billing/Subscriptions.js" "Subscriptions"

# Ticket pages
create_component "/workspace/isp-management-system/frontend/src/pages/Tickets/Tickets.js" "Tickets"
create_component "/workspace/isp-management-system/frontend/src/pages/Tickets/TicketDetail.js" "TicketDetail"
create_component "/workspace/isp-management-system/frontend/src/pages/Tickets/CreateTicket.js" "CreateTicket"

# Sales pages
create_component "/workspace/isp-management-system/frontend/src/pages/Sales/Leads.js" "Leads"
create_component "/workspace/isp-management-system/frontend/src/pages/Sales/Quotes.js" "Quotes"
create_component "/workspace/isp-management-system/frontend/src/pages/Sales/SalesTargets.js" "SalesTargets"

# NOC pages
create_component "/workspace/isp-management-system/frontend/src/pages/NOC/NetworkDevices.js" "NetworkDevices"
create_component "/workspace/isp-management-system/frontend/src/pages/NOC/NetworkMap.js" "NetworkMap"
create_component "/workspace/isp-management-system/frontend/src/pages/NOC/Alerts.js" "Alerts"
create_component "/workspace/isp-management-system/frontend/src/pages/NOC/Monitoring.js" "Monitoring"

# RADIUS pages
create_component "/workspace/isp-management-system/frontend/src/pages/RADIUS/OnlineUsers.js" "OnlineUsers"
create_component "/workspace/isp-management-system/frontend/src/pages/RADIUS/RadiusLogs.js" "RadiusLogs"
create_component "/workspace/isp-management-system/frontend/src/pages/RADIUS/NASDevices.js" "NASDevices"

# Settings pages
create_component "/workspace/isp-management-system/frontend/src/pages/Settings/Settings.js" "Settings"
create_component "/workspace/isp-management-system/frontend/src/pages/Settings/UserManagement.js" "UserManagement"
create_component "/workspace/isp-management-system/frontend/src/pages/Settings/SystemConfig.js" "SystemConfig"

echo "All placeholder components created successfully!"