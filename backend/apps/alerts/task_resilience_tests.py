from django.test import TestCase
from unittest.mock import patch
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient
from apps.alerts.models import ClinicalAlert, AlertSeverity, AlertStatus

class NotificationOutageResilienceTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Resilience Test Care", district="Kozhikode", registration_number="REG-RES-01")
        self.nurse = User.objects.create_user(username="nurse_resilient", password="password123", role=UserRole.NURSE, organization=self.org)
        self.patient = Patient.objects.create(
            organization=self.org,
            patient_id_code="PAT-RES-01",
            name="Radhakrishnan Nair",
            age=68,
            gender="Male",
            blood_group="B+",
            district="Kozhikode",
            address="Chevayur",
            phone="9847098765",
            diagnosis="Cardiomyopathy"
        )

    @patch('apps.alerts.services.NotificationService.send_fcm_notification')
    def test_clinical_vitals_recording_succeeds_during_fcm_outage(self, mock_fcm):
        """Simulates FCM / Push Notification service failure and verifies clinical vitals recording HTTP API request still succeeds with 201 Created."""
        mock_fcm.side_effect = Exception("Simulated FCM Network Connection Timeout!")

        self.client.force_authenticate(user=self.nurse)
        res = self.client.post(f'/api/patients/{self.patient.id}/add_vitals/', {
            'bp': '100/60',
            'pulse': 105,
            'spo2': 88, # Critical SpO2 < 92%
            'pain_scale': 9
        })

        # 1. Clinical HTTP API request MUST succeed despite notification outage
        self.assertEqual(res.status_code, 201)

        # 2. Critical ClinicalAlert MUST be recorded in database
        alert = ClinicalAlert.objects.filter(patient=self.patient, severity=AlertSeverity.CRITICAL).first()
        self.assertIsNotNone(alert)
        self.assertEqual(alert.status, AlertStatus.OPEN)
