from django.test import TestCase
from rest_framework.test import APIClient
from datetime import date, timedelta
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.blood_donors.models import BloodDonor, BloodRequest, BloodRequestStatus

class BloodDonorsWorkflowTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="KZD-101")
        self.user = User.objects.create_user(username="nurse_anitha", password="pass1234", role=UserRole.NURSE, organization=self.org)

        self.donor = BloodDonor.objects.create(
            organization=self.org,
            name="Arjun Das",
            blood_group="O+",
            district="Kozhikode",
            locality="Chevayur",
            phone="9745111223",
            last_donation_date=date.today() - timedelta(days=100),
            total_donations=5
        )

        self.request_obj = BloodRequest.objects.create(
            organization=self.org,
            patient_name="Karthyayani Amma",
            blood_group="O+",
            hospital_name="Calicut Medical College",
            district="Kozhikode",
            units_needed=2,
            urgency="Emergency",
            status=BloodRequestStatus.CREATED
        )

    def test_donor_eligibility(self):
        """Donor who donated > 90 days ago is eligible."""
        self.assertTrue(self.donor.is_eligible)

    def test_emergency_blood_request_notification(self):
        """Notifying matching donors counts eligible donors in same district."""
        self.client.force_authenticate(user=self.user)

        response = self.client.post(f'/api/blood-donors/requests/{self.request_obj.id}/notify_matching_donors/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['notified_count'], 1)
