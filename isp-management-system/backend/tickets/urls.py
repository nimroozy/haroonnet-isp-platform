from django.urls import path, include
from rest_framework.routers import DefaultRouter

router = DefaultRouter()

app_name = 'tickets'

urlpatterns = [
    path('', include(router.urls)),
]
