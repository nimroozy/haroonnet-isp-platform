from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, UserProfile, Permission, Role, UserRole


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'email', 'phone', 'user_type')}),
        (_('Address'), {'fields': ('address', 'city', 'state', 'country', 'postal_code')}),
        (_('Customer info'), {'fields': ('customer_id', 'account_status')}),
        (_('Permissions'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'is_verified', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {'fields': ('last_login', 'date_joined', 'created_at', 'updated_at')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2', 'user_type'),
        }),
    )
    list_display = ('email', 'username', 'first_name', 'last_name', 'user_type', 'account_status', 'is_staff')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'user_type', 'account_status')
    search_fields = ('username', 'first_name', 'last_name', 'email', 'customer_id')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'last_login_ip')


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'company_name', 'email_notifications', 'sms_notifications')
    search_fields = ('user__email', 'company_name', 'tax_id')
    list_filter = ('email_notifications', 'sms_notifications')


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'module')
    list_filter = ('module',)
    search_fields = ('name', 'code', 'description')
    ordering = ('module', 'name')


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ('name', 'is_system', 'permission_count')
    list_filter = ('is_system',)
    search_fields = ('name', 'description')
    filter_horizontal = ('permissions',)
    
    def permission_count(self, obj):
        return obj.permissions.count()
    permission_count.short_description = 'Permissions'


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    list_display = ('user', 'role', 'assigned_at', 'assigned_by')
    list_filter = ('role', 'assigned_at')
    search_fields = ('user__email', 'role__name')
    raw_id_fields = ('user', 'assigned_by')