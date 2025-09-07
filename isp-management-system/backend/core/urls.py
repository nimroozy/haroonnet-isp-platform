"""
URL configuration for ISP Management System.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import routers
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)

# Create a router for API endpoints
router = routers.DefaultRouter()

urlpatterns = [
    # Admin panel
    path('admin/', admin.site.urls),
    
    # API Authentication
    path('api/auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/verify/', TokenVerifyView.as_view(), name='token_verify'),
    
    # API endpoints
    path('api/', include(router.urls)),
    path('api/accounts/', include('accounts.urls')),
    path('api/billing/', include('billing.urls')),
    path('api/tickets/', include('tickets.urls')),
    path('api/sales/', include('sales.urls')),
    path('api/noc/', include('noc.urls')),
    path('api/radius/', include('radius_integration.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Customize admin site
admin.site.site_header = "ISP Management System"
admin.site.site_title = "ISP Admin"
admin.site.index_title = "Welcome to ISP Management System"