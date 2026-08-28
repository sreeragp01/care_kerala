from django.test import TestCase
from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.inventory.models import MedicineItem, EquipmentItem, MedicineTransaction, EquipmentStatus

class InventoryWorkflowTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Kozhikode Care", district="Kozhikode", registration_number="KZD-101")
        self.staff = User.objects.create_user(username="pharmacist_rahul", password="pass1234", role=UserRole.PHARMACIST, organization=self.org)

        self.medicine = MedicineItem.objects.create(
            organization=self.org,
            name="Morphine Oral Sol. 10mg/5ml",
            category="Analgesics",
            stock_quantity=50,
            unit="bottles",
            reorder_level=20,
            expiry_date="2027-04-30",
            batch_number="BAT-901"
        )

        self.equipment = EquipmentItem.objects.create(
            organization=self.org,
            name="Oxygen Concentrator 5L",
            total_count=10,
            available_count=4,
            loaned_count=6,
            maintenance_status=EquipmentStatus.AVAILABLE
        )

    def test_issue_medicine_creates_transaction_log(self):
        """Issuing medicine stock must update quantity and log a MedicineTransaction."""
        self.client.force_authenticate(user=self.staff)

        response = self.client.post(f'/api/inventory/medicines/{self.medicine.id}/issue_stock/', {'quantity': 5})
        self.assertEqual(response.status_code, 200)

        self.medicine.refresh_from_db()
        self.assertEqual(self.medicine.stock_quantity, 45)
        self.assertEqual(MedicineTransaction.objects.count(), 1)
        tx = MedicineTransaction.objects.first()
        self.assertEqual(tx.quantity, 5)
        self.assertEqual(tx.recorded_by, "pharmacist_rahul")

    def test_loan_equipment_status(self):
        """Loaning equipment decrements available count and increments loaned count."""
        self.client.force_authenticate(user=self.staff)

        response = self.client.post(f'/api/inventory/equipment/{self.equipment.id}/loan_equipment/')
        self.assertEqual(response.status_code, 200)

        self.equipment.refresh_from_db()
        self.assertEqual(self.equipment.available_count, 3)
        self.assertEqual(self.equipment.loaned_count, 7)

    def test_insufficient_stock_rejection(self):
        """Attempting to issue more stock than available returns HTTP 400 Insufficient Stock."""
        self.client.force_authenticate(user=self.staff)

        response = self.client.post(f'/api/inventory/medicines/{self.medicine.id}/issue_stock/', {'quantity': 100})
        self.assertEqual(response.status_code, 400)
        self.medicine.refresh_from_db()
        self.assertEqual(self.medicine.stock_quantity, 50)

