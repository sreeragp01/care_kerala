from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient, CarePlan, VitalsReading, PatientLifecycleStatus

class ClinicalWorkflowTestCase(TestCase):
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
            lifecycle_status=PatientLifecycleStatus.REGISTRATION,
            diagnosis="Osteoarthritis & Pain Management"
        )

    def test_patient_lifecycle_transitions(self):
        """Test transitioning patient through clinical lifecycle stages."""
        self.client.force_authenticate(user=self.nurse)
        
        # Transition to Active Care
        response = self.client.patch(f'/api/patients/{self.patient.id}/', {'lifecycle_status': PatientLifecycleStatus.ACTIVE_CARE})
        self.assertEqual(response.status_code, 200)
        self.patient.refresh_from_db()
        self.assertEqual(self.patient.lifecycle_status, PatientLifecycleStatus.ACTIVE_CARE)

    def test_care_plan_creation(self):
        """Test attaching a structured care plan to a patient."""
        care_plan = CarePlan.objects.create(
            patient=self.patient,
            primary_nurse_name="Nurse Anitha",
            assigned_doctor_name="Dr. Suresh Kumar",
            care_goals="Pain reduction to <= 3/10, bi-weekly dressing",
            review_frequency_days=14
        )
        self.assertEqual(self.patient.care_plan, care_plan)
        self.assertEqual(self.patient.care_plan.primary_nurse_name, "Nurse Anitha")

    def test_immutable_vitals_history(self):
        """Test recording vitals creates an immutable historical log."""
        self.client.force_authenticate(user=self.nurse)

        # Record 1st vitals
        v1 = VitalsReading.objects.create(patient=self.patient, bp="130/80", pulse=76, spo2=97, temperature=98.4, pain_scale=4, recorded_by="Nurse Anitha")
        # Record 2nd vitals
        v2 = VitalsReading.objects.create(patient=self.patient, bp="125/82", pulse=72, spo2=98, temperature=98.6, pain_scale=2, recorded_by="Nurse Anitha")

        self.assertEqual(self.patient.vitals_history.count(), 2)
        vitals_list = list(self.patient.vitals_history.all())
        self.assertEqual(vitals_list[0].bp, "130/80")
        self.assertEqual(vitals_list[1].bp, "125/82")

    def test_vitals_out_of_bounds_validation(self):
        """Out-of-bounds vitals payload (e.g. SpO2 = 250) returns HTTP 400 Bad Request."""
        self.client.force_authenticate(user=self.nurse)

        response = self.client.post(f'/api/patients/{self.patient.id}/add_vitals/', {
            'bp': '130/80',
            'pulse': 76,
            'spo2': 250, # Invalid SpO2 (> 100)
            'pain_scale': 4
        })
        self.assertEqual(response.status_code, 400)

