from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.finance.models import Donation, DonationStatus

class FinanceWorkflowTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="KZD-101")
        self.staff = User.objects.create_user(username="accountant_ram", password="pass1234", role=UserRole.ACCOUNTANT, organization=self.org)

    def test_create_donation_record(self):
        """Creating donation records receipt number and completed status."""
        self.client.force_authenticate(user=self.staff)

        response = self.client.post('/api/finance/', {
            'donor_name': 'Malabar Palliative Supporters',
            'amount': '25000.00',
            'category': 'General Palliative Fund',
            'payment_mode': 'UPI',
            'receipt_number': 'REC-2026-9901',
            'status': DonationStatus.COMPLETED
        })
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Donation.objects.count(), 1)
        donation = Donation.objects.first()
        self.assertEqual(donation.amount, 25000.00)
