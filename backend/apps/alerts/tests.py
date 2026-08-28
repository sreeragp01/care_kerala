from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient
from apps.alerts.models import ClinicalAlert, AlertSeverity, AlertStatus, AlertType, UserDevice

class ClinicalAlertsEngineTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org_a = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="KZD-101")
        self.org_b = Organization.objects.create(name="Thrissur Care", district="Thrissur", registration_number="TSR-202")

        self.nurse_a = User.objects.create_user(username="nurse_anitha", password="pass1234", role=UserRole.NURSE, organization=self.org_a)
        self.doctor_a = User.objects.create_user(username="dr_suresh", password="pass1234", role=UserRole.DOCTOR, organization=self.org_a)
        self.nurse_b = User.objects.create_user(username="nurse_biju", password="pass1234", role=UserRole.NURSE, organization=self.org_b)

        self.patient_a = Patient.objects.create(
            organization=self.org_a,
            patient_id_code="PAT-501",
            name="Karthyayani Amma",
            age=74,
            gender="Female",
            district="Kozhikode"
        )

    def test_vitals_critical_rule_trigger(self):
        """Recording SpO2 < 92% automatically triggers a CRITICAL ClinicalAlert."""
        self.client.force_authenticate(user=self.nurse_a)

        res = self.client.post(f'/api/patients/{self.patient_a.id}/add_vitals/', {
            'bp': '130/90',
            'pulse': 88,
            'spo2': 88, # Trigger threshold
            'temperature': 98.6,
            'pain_scale': 4
        })
        self.assertEqual(res.status_code, 201)

        self.assertEqual(ClinicalAlert.objects.count(), 1)
        alert = ClinicalAlert.objects.first()
        self.assertEqual(alert.severity, AlertSeverity.CRITICAL)
        self.assertEqual(alert.alert_type, AlertType.VITAL_ABNORMAL)
        self.assertEqual(alert.status, AlertStatus.OPEN)

    def test_alert_acknowledgment_lifecycle(self):
        """Doctor acknowledges open alert, recording timestamp and identity."""
        alert = ClinicalAlert.objects.create(
            organization=self.org_a,
            patient=self.patient_a,
            severity=AlertSeverity.HIGH,
            title="HIGH: Severe Pain Reported",
            message="Pain scale 9/10"
        )

        self.client.force_authenticate(user=self.doctor_a)
        res = self.client.post(f'/api/alerts/{alert.id}/acknowledge/')
        self.assertEqual(res.status_code, 200)

        alert.refresh_from_db()
        self.assertEqual(alert.status, AlertStatus.ACKNOWLEDGED)
        self.assertEqual(alert.acknowledged_by, "dr_suresh")
        self.assertIsNotNone(alert.acknowledged_at)

    def test_multi_tenant_alert_isolation(self):
        """Staff in Organization B cannot view ClinicalAlerts belonging to Organization A."""
        alert = ClinicalAlert.objects.create(
            organization=self.org_a,
            patient=self.patient_a,
            severity=AlertSeverity.CRITICAL,
            title="CRITICAL: Low Oxygen",
            message="SpO2 85%"
        )

        self.client.force_authenticate(user=self.nurse_b)
        res = self.client.get('/api/alerts/')
        self.assertEqual(res.status_code, 200)
        results = res.data.get('results', res.data)
        self.assertEqual(len(results), 0)


    def test_user_device_fcm_registration(self):
        """User registers FCM token for device notifications."""
        self.client.force_authenticate(user=self.nurse_a)
        res = self.client.post('/api/alerts/devices/register/', {
            'device_id': 'phone-android-xyz-101',
            'fcm_token': 'fcm_token_sample_1234567890',
            'platform': 'flutter_android'
        })
        self.assertEqual(res.status_code, 201)
        self.assertEqual(UserDevice.objects.count(), 1)
        device = UserDevice.objects.first()
        self.assertEqual(device.device_id, 'phone-android-xyz-101')
