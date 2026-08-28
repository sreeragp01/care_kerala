import logging
from django.utils import timezone
from .models import ClinicalAlert, AlertType, AlertSeverity, AlertStatus, UserDevice, NotificationPreference
from apps.authentication.models import User

logger = logging.getLogger(__name__)

class ClinicalRulesEngine:
    @staticmethod
    def evaluate_vitals(vitals_reading):
        """Evaluates vital reading thresholds and generates deterministic ClinicalAlert records."""
        patient = vitals_reading.patient
        org = patient.organization
        alerts_created = []

        # 1. SpO2 threshold check
        if vitals_reading.spo2 and vitals_reading.spo2 < 92:
            alert = ClinicalAlert.objects.create(
                organization=org,
                patient=patient,
                alert_type=AlertType.VITAL_ABNORMAL,
                severity=AlertSeverity.CRITICAL,
                title=f"CRITICAL: Low Oxygen Saturation for {patient.name}",
                message=f"Patient SpO2 dropped to {vitals_reading.spo2}%. Immediate clinical assessment required.",
                metadata={'bp': vitals_reading.bp, 'spo2': vitals_reading.spo2, 'pulse': vitals_reading.pulse}
            )
            alerts_created.append(alert)
            NotificationService.dispatch_alert(alert)

        # 2. Pain Scale threshold check
        if vitals_reading.pain_scale and vitals_reading.pain_scale >= 8:
            alert = ClinicalAlert.objects.create(
                organization=org,
                patient=patient,
                alert_type=AlertType.VITAL_ABNORMAL,
                severity=AlertSeverity.HIGH,
                title=f"HIGH: Severe Pain Reported for {patient.name}",
                message=f"Patient reported pain scale level {vitals_reading.pain_scale}/10. Palliative pain management review requested.",
                metadata={'pain_scale': vitals_reading.pain_scale}
            )
            alerts_created.append(alert)
            NotificationService.dispatch_alert(alert)

        return alerts_created

    @staticmethod
    def evaluate_inventory(medicine_item):
        """Evaluates medicine reorder levels and generates stock alert."""
        if medicine_item.stock_quantity <= medicine_item.reorder_level:
            org = medicine_item.organization
            alert = ClinicalAlert.objects.create(
                organization=org,
                alert_type=AlertType.STOCK_LOW,
                severity=AlertSeverity.MEDIUM,
                title=f"STOCK WARNING: Low Stock for {medicine_item.name}",
                message=f"Current stock is {medicine_item.stock_quantity} {medicine_item.unit} (Reorder level: {medicine_item.reorder_level}).",
                metadata={'medicine_id': medicine_item.id, 'stock_quantity': medicine_item.stock_quantity}
            )
            NotificationService.dispatch_alert(alert)
            return alert
        return None

    @staticmethod
    def evaluate_blood_request(blood_request):
        """Evaluates emergency blood request and generates notification."""
        if blood_request.urgency == 'Emergency':
            org = blood_request.organization
            alert = ClinicalAlert.objects.create(
                organization=org,
                alert_type=AlertType.BLOOD_EMERGENCY,
                severity=AlertSeverity.HIGH,
                title=f"EMERGENCY: Blood Request {blood_request.blood_group} Needed",
                message=f"{blood_request.units_needed} units of {blood_request.blood_group} needed urgently at {blood_request.hospital_name}.",
                metadata={'blood_request_id': blood_request.id, 'group': blood_request.blood_group}
            )
            NotificationService.dispatch_alert(alert)
            return alert
        return None

class NotificationService:
    @staticmethod
    def dispatch_alert(alert):
        """Dispatches alert notifications to staff with matching notification preferences."""
        org = alert.organization
        staff_users = User.objects.filter(organization=org)

        for staff in staff_users:
            pref, _ = NotificationPreference.objects.get_or_create(user=staff)

            # Preference filtering
            if alert.alert_type == AlertType.VITAL_ABNORMAL and not pref.high_risk_alerts:
                continue
            if alert.alert_type in [AlertType.STOCK_LOW, AlertType.STOCK_EXPIRING] and not pref.inventory_alerts:
                continue
            if alert.alert_type == AlertType.BLOOD_EMERGENCY and not pref.blood_request_alerts:
                continue

            privacy_safe_title = "Clinical Alert Requires Review" if alert.severity in [AlertSeverity.CRITICAL, AlertSeverity.HIGH] else "CareLink Notice"
            devices = UserDevice.objects.filter(user=staff, is_active=True)
            for dev in devices:
                logger.info(f"Simulated FCM Push [Device: {dev.device_id}] for User ID {staff.id}: {privacy_safe_title}")

