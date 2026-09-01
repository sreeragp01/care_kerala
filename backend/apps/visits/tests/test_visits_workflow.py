from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient
from apps.visits.models import HomeVisit, VisitStatus

class HomeVisitWorkflowTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="KZD-101")
        self.nurse = User.objects.create_user(username="nurse_anitha", password="pass1234", role=UserRole.NURSE, organization=self.org)
        self.doctor = User.objects.create_user(username="dr_suresh", password="pass1234", role=UserRole.DOCTOR, organization=self.org)

        self.patient = Patient.objects.create(
            organization=self.org,
            patient_id_code="PAT-501",
            name="Karthyayani Amma",
            age=74,
            gender="Female",
            blood_group="O+",
            district="Kozhikode",
            ward="Ward 14",
            address="Chevayur",
            phone="9847012345",
            diagnosis="Osteoarthritis"
        )

        self.visit = HomeVisit.objects.create(
            organization=self.org,
            patient=self.patient,
            assigned_nurse_name="Nurse Anitha",
            scheduled_date="2026-08-10",
            scheduled_time="10:00 AM",
            status=VisitStatus.SCHEDULED
        )

    def test_complete_visit_workflow_with_structured_notes(self):
        """Nurse completes visit with structured clinical notes."""
        self.client.force_authenticate(user=self.nurse)

        response = self.client.post(f'/api/visits/{self.visit.id}/complete_visit/', {
            'clinical_notes': 'Patient comfortable',
            'symptoms_observed': 'Mild knee swelling',
            'care_provided': 'Wound dressing & pain relief',
            'medication_administered': 'Paracetamol 500mg',
            'equipment_used': 'Air Mattress checked'
        })
        self.assertEqual(response.status_code, 200)
        self.visit.refresh_from_db()
        self.assertEqual(self.visit.status, VisitStatus.COMPLETED)
        self.assertEqual(self.visit.symptoms_observed, 'Mild knee swelling')

    def test_sync_push_and_pull_batch_operations(self):
        """Batch sync push operation processes local offline visits and vitals."""
        self.client.force_authenticate(user=self.nurse)

        payload = {
            'device_id': 'dev-nurse-phone-101',
            'operations': [
                {
                    'operation': 'CREATE_VISIT',
                    'local_id': 'local-v-101',
                    'data': {
                        'patient_id': self.patient.id,
                        'scheduled_date': '2026-08-12',
                        'scheduled_time': '02:00 PM'
                    }
                },
                {
                    'operation': 'ADD_VITALS',
                    'local_id': 'local-vit-101',
                    'data': {
                        'patient_id': self.patient.id,
                        'bp': '128/84',
                        'pulse': 74,
                        'spo2': 98,
                        'temperature': 98.4,
                        'pain_scale': 3
                    }
                }
            ]
        }

        response = self.client.post('/api/sync/push/', payload, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], 'success')
        self.assertEqual(len(response.data['accepted']), 2)

        # Pull updated records
        pull_res = self.client.get('/api/sync/pull/')
        self.assertEqual(pull_res.status_code, 200)
        self.assertIn('patients', pull_res.data)
        self.assertIn('visits', pull_res.data)

    def test_nurse_attempting_doctor_signoff_forbidden(self):
        """Nurse role attempting doctor review sign-off returns HTTP 403 Forbidden."""
        self.client.force_authenticate(user=self.nurse)

        response = self.client.post(f'/api/visits/{self.visit.id}/doctor_review/', {
            'doctor_review_notes': 'Nurse signoff attempt'
        })
        self.assertEqual(response.status_code, 403)

    def test_sync_push_idempotency(self):
        """Duplicate sync operations return existing server ID without creating duplicate visits."""
        self.client.force_authenticate(user=self.nurse)

        payload = {
            'device_id': 'dev-nurse-phone-101',
            'operations': [
                {
                    'operation': 'CREATE_VISIT',
                    'local_id': 'local-v-999',
                    'data': {
                        'patient_id': self.patient.id,
                        'scheduled_date': '2026-08-15',
                        'scheduled_time': '11:00 AM'
                    }
                }
            ]
        }

        res1 = self.client.post('/api/sync/push/', payload, format='json')
        self.assertEqual(res1.status_code, 200)

        res2 = self.client.post('/api/sync/push/', payload, format='json')
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res1.data['accepted'][0]['server_id'], res2.data['accepted'][0]['server_id'])
        self.assertEqual(HomeVisit.objects.filter(patient=self.patient, scheduled_date='2026-08-15').count(), 1)


