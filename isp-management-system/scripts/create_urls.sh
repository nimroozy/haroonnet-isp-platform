#!/bin/bash

# Create URL files for Django apps

create_urls() {
    local app=$1
    
    cat > "/workspace/isp-management-system/backend/$app/urls.py" << EOF
from django.urls import path, include
from rest_framework.routers import DefaultRouter

router = DefaultRouter()

app_name = '$app'

urlpatterns = [
    path('', include(router.urls)),
]
EOF
}

# Create URL files for all apps
create_urls "billing"
create_urls "tickets"
create_urls "sales"
create_urls "noc"
create_urls "radius_integration"

echo "All URL files created successfully!"