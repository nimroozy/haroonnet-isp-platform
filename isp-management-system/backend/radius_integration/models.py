from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid

User = get_user_model()


class RadiusNAS(models.Model):
    """Network Access Server (NAS) configuration"""
    NAS_TYPE_CHOICES = (
        ('mikrotik', 'MikroTik'),
        ('cisco', 'Cisco'),
        ('ubiquiti', 'Ubiquiti'),
        ('pfsense', 'pfSense'),
        ('other', 'Other'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    nas_identifier = models.CharField(max_length=128, unique=True)
    
    # Network details
    ip_address = models.GenericIPAddressField(unique=True)
    secret = models.CharField(max_length=255)  # Should be encrypted
    
    # NAS Configuration
    nas_type = models.CharField(max_length=20, choices=NAS_TYPE_CHOICES)
    ports = models.IntegerField(default=0, help_text="Number of ports")
    
    # Location
    location = models.CharField(max_length=500, blank=True)
    description = models.TextField(blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'radius_nas'
        verbose_name = 'RADIUS NAS'
        verbose_name_plural = 'RADIUS NAS Devices'
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.ip_address})"


class RadiusGroup(models.Model):
    """RADIUS groups for service plans"""
    name = models.CharField(max_length=64, unique=True)
    description = models.TextField(blank=True)
    
    # Default attributes for the group
    priority = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'radius_groups'
        ordering = ['priority', 'name']
    
    def __str__(self):
        return self.name


class RadiusGroupReply(models.Model):
    """Reply attributes for RADIUS groups"""
    ATTRIBUTE_CHOICES = (
        ('Mikrotik-Rate-Limit', 'Mikrotik-Rate-Limit'),
        ('Framed-Pool', 'Framed-Pool'),
        ('Session-Timeout', 'Session-Timeout'),
        ('Idle-Timeout', 'Idle-Timeout'),
        ('Acct-Interim-Interval', 'Acct-Interim-Interval'),
        ('Mikrotik-Address-List', 'Mikrotik-Address-List'),
        ('Filter-Id', 'Filter-Id'),
        ('Reply-Message', 'Reply-Message'),
    )
    
    OPERATOR_CHOICES = (
        ('=', '='),
        (':=', ':='),
        ('+=', '+='),
        ('==', '=='),
        ('!=', '!='),
        ('>', '>'),
        ('>=', '>='),
        ('<', '<'),
        ('<=', '<='),
    )
    
    group = models.ForeignKey(RadiusGroup, on_delete=models.CASCADE, related_name='reply_attributes')
    attribute = models.CharField(max_length=64, choices=ATTRIBUTE_CHOICES)
    operator = models.CharField(max_length=2, choices=OPERATOR_CHOICES, default=':=')
    value = models.CharField(max_length=253)
    
    class Meta:
        db_table = 'radius_group_reply'
        unique_together = ('group', 'attribute')
    
    def __str__(self):
        return f"{self.group.name} - {self.attribute} {self.operator} {self.value}"


class RadiusGroupCheck(models.Model):
    """Check attributes for RADIUS groups"""
    ATTRIBUTE_CHOICES = (
        ('Auth-Type', 'Auth-Type'),
        ('Simultaneous-Use', 'Simultaneous-Use'),
        ('Pool-Name', 'Pool-Name'),
        ('Huntgroup-Name', 'Huntgroup-Name'),
    )
    
    OPERATOR_CHOICES = (
        ('=', '='),
        (':=', ':='),
        ('==', '=='),
        ('+=', '+='),
        ('!=', '!='),
        ('>', '>'),
        ('>=', '>='),
        ('<', '<'),
        ('<=', '<='),
    )
    
    group = models.ForeignKey(RadiusGroup, on_delete=models.CASCADE, related_name='check_attributes')
    attribute = models.CharField(max_length=64, choices=ATTRIBUTE_CHOICES)
    operator = models.CharField(max_length=2, choices=OPERATOR_CHOICES, default=':=')
    value = models.CharField(max_length=253)
    
    class Meta:
        db_table = 'radius_group_check'
        unique_together = ('group', 'attribute')
    
    def __str__(self):
        return f"{self.group.name} - {self.attribute} {self.operator} {self.value}"


class RadiusUserGroup(models.Model):
    """Assign users to RADIUS groups"""
    username = models.CharField(max_length=64)
    group = models.ForeignKey(RadiusGroup, on_delete=models.CASCADE)
    priority = models.IntegerField(default=0)
    
    class Meta:
        db_table = 'radius_user_group'
        unique_together = ('username', 'group')
        ordering = ['username', 'priority']
    
    def __str__(self):
        return f"{self.username} - {self.group.name}"


class RadiusCheck(models.Model):
    """User check attributes for RADIUS"""
    ATTRIBUTE_CHOICES = (
        ('Cleartext-Password', 'Cleartext-Password'),
        ('User-Password', 'User-Password'),
        ('Crypt-Password', 'Crypt-Password'),
        ('MD5-Password', 'MD5-Password'),
        ('SMD5-Password', 'SMD5-Password'),
        ('SHA-Password', 'SHA-Password'),
        ('SSHA-Password', 'SSHA-Password'),
        ('Auth-Type', 'Auth-Type'),
    )
    
    username = models.CharField(max_length=64)
    attribute = models.CharField(max_length=64, choices=ATTRIBUTE_CHOICES)
    operator = models.CharField(max_length=2, default=':=')
    value = models.CharField(max_length=253)
    
    class Meta:
        db_table = 'radius_check'
        unique_together = ('username', 'attribute')
    
    def __str__(self):
        return f"{self.username} - {self.attribute}"


class RadiusReply(models.Model):
    """User reply attributes for RADIUS"""
    username = models.CharField(max_length=64)
    attribute = models.CharField(max_length=64)
    operator = models.CharField(max_length=2, default=':=')
    value = models.CharField(max_length=253)
    
    class Meta:
        db_table = 'radius_reply'
        unique_together = ('username', 'attribute')
    
    def __str__(self):
        return f"{self.username} - {self.attribute}"


class RadiusAccounting(models.Model):
    """RADIUS accounting records"""
    id = models.BigAutoField(primary_key=True)
    
    # Session info
    acct_session_id = models.CharField(max_length=64, db_index=True)
    acct_unique_id = models.CharField(max_length=32, unique=True)
    username = models.CharField(max_length=64, db_index=True)
    realm = models.CharField(max_length=64, blank=True)
    
    # NAS info
    nas_ip_address = models.GenericIPAddressField(db_index=True)
    nas_port_id = models.CharField(max_length=32, blank=True)
    nas_port_type = models.CharField(max_length=32, blank=True)
    
    # Timing
    acct_start_time = models.DateTimeField(db_index=True)
    acct_update_time = models.DateTimeField(null=True, blank=True)
    acct_stop_time = models.DateTimeField(null=True, blank=True, db_index=True)
    acct_session_time = models.BigIntegerField(default=0)
    
    # Traffic
    acct_input_octets = models.BigIntegerField(default=0)
    acct_output_octets = models.BigIntegerField(default=0)
    acct_input_gigawords = models.BigIntegerField(default=0)
    acct_output_gigawords = models.BigIntegerField(default=0)
    acct_input_packets = models.BigIntegerField(default=0)
    acct_output_packets = models.BigIntegerField(default=0)
    
    # Connection info
    framed_ip_address = models.GenericIPAddressField(null=True, blank=True)
    calling_station_id = models.CharField(max_length=50, blank=True)
    called_station_id = models.CharField(max_length=50, blank=True)
    
    # Termination
    acct_terminate_cause = models.CharField(max_length=32, blank=True)
    
    # Service info
    service_type = models.CharField(max_length=32, blank=True)
    framed_protocol = models.CharField(max_length=32, blank=True)
    
    class Meta:
        db_table = 'radius_accounting'
        ordering = ['-acct_start_time']
        indexes = [
            models.Index(fields=['username', 'acct_start_time']),
            models.Index(fields=['nas_ip_address', 'acct_start_time']),
        ]
    
    def __str__(self):
        return f"{self.username} - {self.acct_session_id}"
    
    @property
    def total_input_bytes(self):
        return self.acct_input_octets + (self.acct_input_gigawords * 4294967296)
    
    @property
    def total_output_bytes(self):
        return self.acct_output_octets + (self.acct_output_gigawords * 4294967296)


class RadiusPostAuth(models.Model):
    """RADIUS post-authentication log"""
    username = models.CharField(max_length=64)
    password = models.CharField(max_length=64, blank=True)
    reply = models.TextField(blank=True)
    auth_date = models.DateTimeField(default=timezone.now)
    
    class Meta:
        db_table = 'radius_post_auth'
        ordering = ['-auth_date']
    
    def __str__(self):
        return f"{self.username} - {self.auth_date}"


class RadiusOnlineUser(models.Model):
    """Currently online RADIUS users"""
    username = models.CharField(max_length=64, unique=True)
    nas_ip_address = models.GenericIPAddressField()
    nas_port_id = models.CharField(max_length=32, blank=True)
    
    acct_session_id = models.CharField(max_length=64)
    framed_ip_address = models.GenericIPAddressField(null=True, blank=True)
    calling_station_id = models.CharField(max_length=50, blank=True)
    
    start_time = models.DateTimeField()
    update_time = models.DateTimeField(auto_now=True)
    
    # Current session stats
    session_time = models.BigIntegerField(default=0)
    input_octets = models.BigIntegerField(default=0)
    output_octets = models.BigIntegerField(default=0)
    
    class Meta:
        db_table = 'radius_online_users'
        ordering = ['-start_time']
    
    def __str__(self):
        return f"{self.username} - Online since {self.start_time}"