# ISP Management Admin Interface
# Add this to your Django admin.py to get complete ISP management

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User
from django.utils.html import format_html
from .models import NASDevice, ServicePlan, CustomerProfile, Invoice, SupportTicket, UsageRecord, Payment

# Unregister default User admin and register custom one
admin.site.unregister(User)

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_customer', 'customer_status')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    search_fields = ('username', 'first_name', 'last_name', 'email')

    def is_customer(self, obj):
        return hasattr(obj, 'customerprofile')
    is_customer.boolean = True
    is_customer.short_description = 'Customer'

    def customer_status(self, obj):
        if hasattr(obj, 'customerprofile'):
            status = obj.customerprofile.status
            colors = {
                'active': 'green',
                'suspended': 'orange',
                'terminated': 'red',
                'pending': 'blue'
            }
            return format_html(
                '<span style="color: {};">{}</span>',
                colors.get(status, 'black'),
                status.title()
            )
        return '-'
    customer_status.short_description = 'Status'

@admin.register(NASDevice)
class NASDeviceAdmin(admin.ModelAdmin):
    list_display = ('name', 'ip_address', 'device_type', 'location', 'status', 'created_at')
    list_filter = ('device_type', 'status', 'created_at')
    search_fields = ('name', 'ip_address', 'location')
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('Device Information', {
            'fields': ('name', 'ip_address', 'device_type', 'location', 'status')
        }),
        ('RADIUS Configuration', {
            'fields': ('radius_secret',)
        }),
        ('Additional Info', {
            'fields': ('description', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ServicePlan)
class ServicePlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'plan_type', 'speed_display', 'monthly_price', 'is_active')
    list_filter = ('plan_type', 'is_active')
    search_fields = ('name', 'description')

    def speed_display(self, obj):
        return f"{obj.download_speed}/{obj.upload_speed} Mbps"
    speed_display.short_description = 'Speed (Down/Up)'

@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ('customer_id', 'user_full_name', 'phone', 'service_plan', 'status', 'installation_date')
    list_filter = ('status', 'service_plan', 'nas_device', 'installation_date')
    search_fields = ('customer_id', 'user__username', 'user__first_name', 'user__last_name', 'phone')
    raw_id_fields = ('user', 'service_plan', 'nas_device')

    def user_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username
    user_full_name.short_description = 'Customer Name'

    fieldsets = (
        ('Customer Information', {
            'fields': ('user', 'customer_id', 'phone', 'address', 'status')
        }),
        ('Service Configuration', {
            'fields': ('service_plan', 'nas_device', 'static_ip', 'installation_date')
        }),
        ('Billing Information', {
            'fields': ('last_payment_date', 'notes'),
            'classes': ('collapse',)
        }),
    )

@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'customer_name', 'amount', 'status', 'invoice_date', 'due_date')
    list_filter = ('status', 'invoice_date', 'due_date')
    search_fields = ('invoice_number', 'customer__customer_id', 'customer__user__username')
    readonly_fields = ('invoice_date', 'paid_date')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

    fieldsets = (
        ('Invoice Information', {
            'fields': ('customer', 'invoice_number', 'amount', 'description')
        }),
        ('Dates', {
            'fields': ('invoice_date', 'due_date', 'paid_date')
        }),
        ('Status', {
            'fields': ('status',)
        }),
    )

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_id', 'customer_name', 'title', 'category', 'priority', 'status', 'created_at')
    list_filter = ('category', 'priority', 'status', 'created_at')
    search_fields = ('ticket_id', 'title', 'customer__customer_id', 'customer__user__username')
    raw_id_fields = ('customer', 'assigned_to')
    readonly_fields = ('ticket_id', 'created_at', 'updated_at', 'resolved_at')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

    fieldsets = (
        ('Ticket Information', {
            'fields': ('ticket_id', 'customer', 'title', 'description')
        }),
        ('Classification', {
            'fields': ('category', 'priority', 'status', 'assigned_to')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'resolved_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(UsageRecord)
class UsageRecordAdmin(admin.ModelAdmin):
    list_display = ('customer_name', 'nas_device', 'session_start', 'session_duration_display', 'data_usage_display')
    list_filter = ('nas_device', 'session_start')
    search_fields = ('customer__customer_id', 'customer__user__username')
    readonly_fields = ('session_start', 'session_end', 'session_duration')

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

    def session_duration_display(self, obj):
        if obj.session_duration:
            hours = obj.session_duration // 3600
            minutes = (obj.session_duration % 3600) // 60
            return f"{hours}h {minutes}m"
        return '-'
    session_duration_display.short_description = 'Duration'

    def data_usage_display(self, obj):
        total_mb = (obj.bytes_downloaded + obj.bytes_uploaded) / (1024 * 1024)
        if total_mb > 1024:
            return f"{total_mb/1024:.2f} GB"
        return f"{total_mb:.2f} MB"
    data_usage_display.short_description = 'Data Usage'

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('customer_name', 'amount', 'payment_method', 'payment_date', 'reference_number')
    list_filter = ('payment_method', 'payment_date')
    search_fields = ('customer__customer_id', 'customer__user__username', 'reference_number')
    readonly_fields = ('payment_date',)

    def customer_name(self, obj):
        return obj.customer.user.get_full_name() or obj.customer.user.username
    customer_name.short_description = 'Customer'

# Customize admin site
admin.site.site_header = "HaroonNet ISP Management"
admin.site.site_title = "HaroonNet ISP Admin"
admin.site.index_title = "ISP Management Dashboard"
