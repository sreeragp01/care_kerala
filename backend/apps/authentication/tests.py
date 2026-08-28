from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient

class MultiTenantSecurityTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create two separate organizations
        self.org1 = Organization.objects.create(
            name="Kozhikode Care",
            district="Kozhikode",
            registration_number="REG-001"
        )
        self.org2 = Organization.objects.create(
            name="Ernakulam Care",
            district="Ernakulam",
            registration_number="REG-002"
        )

        # Create nurse users for each organization
        self.nurse_org1 = User.objects.create_user(
            username="nurse_kozhikode",
            password="password123",
            role=UserRole.NURSE,
            organization=self.org1
        )
        self.nurse_org2 = User.objects.create_user(
            username="nurse_ernakulam",
            password="password123",
            role=UserRole.NURSE,
            organization=self.org2
        )

        # Create patient records under org1 and org2
        self.patient_org1 = Patient.objects.create(
            organization=self.org1,
            patient_id_code="PAT-001",
            name="Patient Kozhikode",
            age=65,
            gender="Male",
            blood_group="O+",
            district="Kozhikode",
            ward="Ward 1",
            address="Kozhikode",
            phone="9998887771",
            diagnosis="Diagnosis 1"
        )
        self.patient_org2 = Patient.objects.create(
            organization=self.org2,
            patient_id_code="PAT-002",
            name="Patient Ernakulam",
            age=70,
            gender="Female",
            blood_group="A+",
            district="Ernakulam",
            ward="Ward 2",
            address="Ernakulam",
            phone="9998887772",
            diagnosis="Diagnosis 2"
        )

    def test_tenant_isolation_prevents_cross_org_access(self):
        """Nurse from Org 1 must NOT be able to view Patient from Org 2."""
        self.client.force_authenticate(user=self.nurse_org1)

        # Nurse 1 fetches patient list
        response = self.client.get('/api/patients/')
        self.assertEqual(response.status_statusCode if hasattr(response, 'status_statusCode') else response.status_code, 200)

        # Verify Nurse 1 only receives Patient from Org 1
        results = response.data.get('results', response.data)
        patient_names = [p['name'] for p in results]
        self.assertIn("Patient Kozhikode", patient_names)
        self.assertNotIn("Patient Ernakulam", patient_names)


    def test_unauthenticated_request_is_rejected(self):
        """Unauthenticated requests must return 401 Unauthorized."""
        response = self.client.get('/api/patients/')
        self.assertEqual(response.status_code, 401)


class ObservabilityTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="REG-001")
        self.user = User.objects.create_user(username="nurse_anitha", password="password123", role=UserRole.NURSE, organization=self.org)

    def test_liveness_health_probe(self):
        """GET /health/live/ returns 200 OK and status alive."""
        response = self.client.get('/health/live/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], 'alive')

    def test_readiness_health_probe(self):
        """GET /health/ready/ returns 200 OK and database connected status."""
        response = self.client.get('/health/ready/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], 'healthy')
        self.assertEqual(response.data['database'], 'connected')

    def test_request_correlation_id_header(self):
        """Every response must return an X-Request-ID correlation header."""
        response = self.client.get('/health/live/')
        self.assertIn('X-Request-ID', response.headers)
        self.assertTrue(response.headers['X-Request-ID'].startswith('REQ-'))

    def test_system_metrics_endpoint(self):
        """Authenticated admin request to /api/health/metrics/ returns metrics dictionary."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/health/metrics/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('metrics', response.data)
        self.assertIn('total_patients', response.data['metrics'])

