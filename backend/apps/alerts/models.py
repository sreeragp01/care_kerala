from django.db import models
from django.conf import settings
from apps.organizations.models import Organization
from apps.patients.models import Patient
from apps.visits.models import HomeVisit

class AlertSeverity(models.TextChoices):
    INFO = 'INFO', 'Informational'
    LOW = 'LOW', 'Low Severity'
    MEDIUM = 'MEDIUM', 'Medium Severity'
    HIGH = 'HIGH', 'High Severity'
    CRITICAL = 'CRITICAL', 'Critical Emergency'

class AlertStatus(models.TextChoices):
    OPEN = 'OPEN', 'Open Alert'
    ACKNOWLEDGED = 'ACKNOWLEDGED', 'Acknowledged by Staff'
    RESOLVED = 'RESOLVED', 'Resolved'
    DISMISSED = 'DISMISSED', 'Dismissed'

class AlertType(models.TextChoices):
    VITAL_ABNORMAL = 'VITAL_ABNORMAL', 'Abnormal Vital Reading'
    VISIT_OVERDUE = 'VISIT_OVERDUE', 'Overdue Home Visit'
    STOCK_LOW = 'STOCK_LOW', 'Low Medicine Stock'
    STOCK_EXPIRING = 'STOCK_EXPIRING', 'Medicine Expiring Soon'
    BLOOD_EMERGENCY = 'BLOOD_EMERGENCY', 'Emergency Blood Request'

class ClinicalAlert(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='clinical_alerts')
    patient = models.ForeignKey(Patient, on_delete=models.SET_NULL, null=True, blank=True, related_name='clinical_alerts')
    visit = models.ForeignKey(HomeVisit, on_delete=models.SET_NULL, null=True, blank=True, related_name='clinical_alerts')
    alert_type = models.CharField(max_length=40, choices=AlertType.choices, default=AlertType.VITAL_ABNORMAL)
    severity = models.CharField(max_length=20, choices=AlertSeverity.choices, default=AlertSeverity.MEDIUM)
    title = models.CharField(max_length=255)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=AlertStatus.choices, default=AlertStatus.OPEN)
    created_at = models.DateTimeField(auto_now_add=True)
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    acknowledged_by = models.CharField(max_length=150, blank=True, default='')
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.severity}] {self.title} ({self.status})"

class UserDevice(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='devices')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='devices')
    device_id = models.CharField(max_length=255)
    fcm_token = models.TextField()
    platform = models.CharField(max_length=20, default='flutter_android')
    is_active = models.BooleanField(default=True)
    last_seen_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'device_id')

    def __str__(self):
        return f"{self.user.username} - {self.device_id} ({self.platform})"

class NotificationPreference(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notification_preference')
    high_risk_alerts = models.BooleanField(default=True)
    visit_alerts = models.BooleanField(default=True)
    inventory_alerts = models.BooleanField(default=True)
    blood_request_alerts = models.BooleanField(default=True)

    def __str__(self):
        return f"Notification Preferences for {self.user.username}"
