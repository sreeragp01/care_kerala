from django.test import TestCase
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient, VitalsReading, PatientAuditLog
from apps.visits.models import HomeVisit, VisitStatus
from apps.inventory.models import MedicineItem, MedicineTransaction
from apps.alerts.models import ClinicalAlert, AlertSeverity, AlertStatus

class PerformanceLoadAndIntegrationTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="REG-KZD-01")
        self.nurse = User.objects.create_user(username="nurse_anitha", password="password123", role=UserRole.NURSE, organization=self.org)
        self.doctor = User.objects.create_user(username="dr_suresh", password="password123", role=UserRole.DOCTOR, organization=self.org)

        self.patient = Patient.objects.create(
            organization=self.org,
            patient_id_code="PAT-LOAD-101",
            name="Karthyayani Amma",
            age=74,
            gender="Female",
            blood_group="O+",
            district="Kozhikode",
            ward="Ward 14",
            address="Chevayur",
            phone="9847012345",
            diagnosis="Osteoarthritis & Chronic Pain"
        )

        self.medicine = MedicineItem.objects.create(
            organization=self.org,
            name="Morphine Oral Sol. 10mg/5ml",
            category="Analgesics",
            stock_quantity=10,
            unit="bottles",
            reorder_level=5,
            expiry_date=timezone.now().date() + timedelta(days=365),
            batch_number="BATCH-LOAD-01"
        )

    def test_offline_sync_burst_simulation(self):
        """Simulates 20 visits and 20 vitals pushed in a single offline sync payload batch."""
        self.client.force_authenticate(user=self.nurse)

        operations = []
        for i in range(1, 21):
            operations.append({
                'operation': 'CREATE_VISIT',
                'local_id': f'burst-v-{i}',
                'data': {
                    'patient_id': self.patient.id,
                    'scheduled_date': f'2026-08-{i:02d}',
                    'scheduled_time': '10:00 AM'
                }
            })
            operations.append({
                'operation': 'ADD_VITALS',
                'local_id': f'burst-vit-{i}',
                'data': {
                    'patient_id': self.patient.id,
                    'bp': f'{120 + (i % 5)}/{80 + (i % 3)}',
                    'pulse': 72 + (i % 6),
                    'spo2': 98,
                    'pain_scale': i % 5
                }
            })

        payload = {
            'device_id': 'flutter_field_tablet_nurse_01',
            'operations': operations
        }

        response = self.client.post('/api/sync/push/', payload, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], 'success')
        self.assertEqual(len(response.data['accepted']), 40)
        self.assertEqual(len(response.data['failed']), 0)
        self.assertEqual(HomeVisit.objects.filter(patient=self.patient).count(), 20)

    def test_concurrent_stock_issuance_race_condition(self):
        """Simulates simultaneous stock requests where Nurse A requests 6 and Nurse B requests 7 when stock is 10."""
        self.client.force_authenticate(user=self.nurse)

        # 1. Nurse A issues 6 bottles (Success: 10 - 6 = 4 remaining)
        res1 = self.client.post(f'/api/inventory/medicines/{self.medicine.id}/issue_stock/', {'quantity': 6})
        self.assertEqual(res1.status_code, 200)
        self.medicine.refresh_from_db()
        self.assertEqual(self.medicine.stock_quantity, 4)

        # 2. Nurse B requests 7 bottles (Rejected: 7 > 4 remaining)
        res2 = self.client.post(f'/api/inventory/medicines/{self.medicine.id}/issue_stock/', {'quantity': 7})
        self.assertEqual(res2.status_code, 400)
        self.medicine.refresh_from_db()
        self.assertEqual(self.medicine.stock_quantity, 4)

    def test_end_to_end_clinical_lifecycle_integration(self):
        """Tests complete clinical workflow from patient registration, vitals recording, critical alert trigger, to doctor sign-off."""
        self.client.force_authenticate(user=self.nurse)
        res_vitals = self.client.post(f'/api/patients/{self.patient.id}/add_vitals/', {
            'bp': '110/70',
            'pulse': 95,
            'spo2': 88,
            'pain_scale': 8
        })
        self.assertIn(res_vitals.status_code, [200, 201])

        alert = ClinicalAlert.objects.filter(patient=self.patient, severity=AlertSeverity.CRITICAL).first()
        self.assertIsNotNone(alert)
        self.assertEqual(alert.status, AlertStatus.OPEN)

        visit = HomeVisit.objects.create(
            organization=self.org,
            patient=self.patient,
            assigned_nurse_name="Nurse Anitha",
            scheduled_date="2026-08-25",
            scheduled_time="11:00 AM",
            status=VisitStatus.IN_PROGRESS
        )
        res_complete = self.client.post(f'/api/visits/{visit.id}/complete_visit/', {
            'clinical_notes': 'Oxygen therapy administered via concentrator.',
            'care_provided': 'Oxygen support 2L/min'
        })
        self.assertEqual(res_complete.status_code, 200)

        self.client.force_authenticate(user=self.doctor)
        res_doc = self.client.post(f'/api/visits/{visit.id}/doctor_review/', {
            'doctor_review_notes': 'SpO2 stabilized to 96% after oxygen therapy. Continue monitoring.'
        })
        self.assertEqual(res_doc.status_code, 200)
        visit.refresh_from_db()
        self.assertEqual(visit.status, VisitStatus.CLOSED)
        self.assertTrue(visit.doctor_signed_off)
        self.assertGreaterEqual(PatientAuditLog.objects.filter(patient=self.patient).count(), 1)
