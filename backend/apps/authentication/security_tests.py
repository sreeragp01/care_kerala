from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient
from apps.visits.models import HomeVisit, VisitStatus
from apps.inventory.models import MedicineItem
from apps.finance.models import Donation, PaymentStatus
from apps.alerts.models import ClinicalAlert, AlertSeverity, AlertStatus

class SecurityPenetrationTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Organizations
        self.org1 = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="REG-KZD-01")
        self.org2 = Organization.objects.create(name="Ernakulam Care", district="Ernakulam", registration_number="REG-EKM-02")

        # Create Users per Role for Org 1
        self.org1_admin = User.objects.create_user(username="admin_org1", password="password123", role=UserRole.ORG_ADMIN, organization=self.org1)
        self.org1_doctor = User.objects.create_user(username="dr_org1", password="password123", role=UserRole.DOCTOR, organization=self.org1)
        self.org1_nurse = User.objects.create_user(username="nurse_org1", password="password123", role=UserRole.NURSE, organization=self.org1)
        self.org1_volunteer = User.objects.create_user(username="volunteer_org1", password="password123", role=UserRole.VOLUNTEER, organization=self.org1)

        # Create User for Org 2
        self.org2_nurse = User.objects.create_user(username="nurse_org2", password="password123", role=UserRole.NURSE, organization=self.org2)

        # Create Records for Org 1
        self.patient_org1 = Patient.objects.create(organization=self.org1, patient_id_code="PAT-01", name="Patient Org1", age=60, gender="Male", blood_group="A+", district="Kozhikode", ward="Ward 1", address="Addr1", phone="9000000001", diagnosis="Diag1")
        self.visit_org1 = HomeVisit.objects.create(organization=self.org1, patient=self.patient_org1, assigned_nurse_name="Nurse Org1", scheduled_date="2026-08-20", scheduled_time="10:00 AM", status=VisitStatus.COMPLETED)
        self.medicine_org1 = MedicineItem.objects.create(organization=self.org1, name="Paracetamol", stock_quantity=100, unit="tablets", reorder_level=20)
        self.donation_org1 = Donation.objects.create(organization=self.org1, donor_name="Donor 1", amount=5000.0, payment_status=PaymentStatus.PAID, transaction_id="TXN-01")
        self.alert_org1 = ClinicalAlert.objects.create(organization=self.org1, patient=self.patient_org1, severity=AlertSeverity.CRITICAL, title="Critical Alert Org 1", message="Test alert message", status=AlertStatus.OPEN)

        # Create Records for Org 2
        self.patient_org2 = Patient.objects.create(organization=self.org2, patient_id_code="PAT-02", name="Patient Org2", age=70, gender="Female", blood_group="B+", district="Ernakulam", ward="Ward 2", address="Addr2", phone="9000000002", diagnosis="Diag2")

    def test_rbac_doctor_review_matrix(self):
        """Doctor role can perform doctor review; Nurse & Volunteer roles are rejected with 403 Forbidden."""
        # 1. Nurse attempt -> Forbidden
        self.client.force_authenticate(user=self.org1_nurse)
        res_nurse = self.client.post(f'/api/visits/{self.visit_org1.id}/doctor_review/', {'doctor_review_notes': 'Nurse signoff'})
        self.assertEqual(res_nurse.status_code, 403)

        # 2. Volunteer attempt -> Forbidden
        self.client.force_authenticate(user=self.org1_volunteer)
        res_vol = self.client.post(f'/api/visits/{self.visit_org1.id}/doctor_review/', {'doctor_review_notes': 'Vol signoff'})
        self.assertEqual(res_vol.status_code, 403)

        # 3. Doctor attempt -> Allowed
        self.client.force_authenticate(user=self.org1_doctor)
        res_doc = self.client.post(f'/api/visits/{self.visit_org1.id}/doctor_review/', {'doctor_review_notes': 'Approved by Doctor'})
        self.assertEqual(res_doc.status_code, 200)

    def test_multi_tenant_idor_isolation_penetration(self):
        """User from Org 2 querying Patient or Visit ID belonging to Org 1 is denied access (404/403)."""
        self.client.force_authenticate(user=self.org2_nurse)

        # IDOR attempt on Patient belonging to Org 1
        res_p = self.client.get(f'/api/patients/{self.patient_org1.id}/')
        self.assertEqual(res_p.status_code, 404)

        # IDOR attempt on Visit belonging to Org 1
        res_v = self.client.get(f'/api/visits/{self.visit_org1.id}/')
        self.assertEqual(res_v.status_code, 404)

        # IDOR attempt on Alert belonging to Org 1
        res_a = self.client.get(f'/api/alerts/{self.alert_org1.id}/')
        self.assertEqual(res_a.status_code, 404)

    def test_tenant_spoofing_prevention(self):
        """Submitting organization_id in request body is ignored; server enforces authenticated user's organization."""
        self.client.force_authenticate(user=self.org1_nurse)

        # Attempt to create patient for Org 2 using Org 1 user credentials
        res = self.client.post('/api/patients/', {
            'patient_id_code': 'PAT-SPOOF-99',
            'name': 'Spoof Patient',
            'age': 55,
            'gender': 'Male',
            'blood_group': 'AB+',
            'district': 'Kozhikode',
            'ward': 'Ward 5',
            'address': 'Kozhikode',
            'phone': '9991112223',
            'diagnosis': 'Spoof Test',
            'organization': self.org2.id # Attempting to force Org 2 ID
        }, format='json')

        self.assertEqual(res.status_code, 215 if hasattr(res, 'status_215') else 201)
        created_patient = Patient.objects.get(patient_id_code='PAT-SPOOF-99')
        # Verify server forced patient's organization to Org 1
        self.assertEqual(created_patient.organization, self.org1)

    def test_security_response_headers_present(self):
        """Verify presence of security hardening headers on all responses."""
        response = self.client.get('/health/live/')
        self.assertEqual(response.headers.get('X-Content-Type-Options'), 'nosniff')
        self.assertEqual(response.headers.get('X-Frame-Options'), 'DENY')
        self.assertEqual(response.headers.get('Referrer-Policy'), 'strict-origin-when-cross-origin')
