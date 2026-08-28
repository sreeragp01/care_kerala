from django.db import models
from apps.organizations.models import Organization

class MedicineItem(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='medicines')
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=100)
    stock_quantity = models.IntegerField()
    unit = models.CharField(max_length=50) # tablets, bottles, ampoules
    reorder_level = models.IntegerField()
    expiry_date = models.DateField()
    batch_number = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_low_stock(self):
        return self.stock_quantity <= self.reorder_level

    def __str__(self):
        return f"{self.name} - {self.stock_quantity} {self.unit}"

class EquipmentStatus(models.TextChoices):
    AVAILABLE = 'Available', 'Available'
    RESERVED = 'Reserved', 'Reserved'
    ISSUED = 'Issued', 'Issued'
    UNDER_MAINTENANCE = 'Under Maintenance', 'Under Maintenance'
    RETURNED = 'Returned', 'Returned'

class MedicineTransaction(models.Model):
    class TransactionType(models.TextChoices):
        RECEIVED = 'RECEIVED', 'Stock Received'
        ISSUED = 'ISSUED_TO_PATIENT', 'Issued to Patient'
        RETURNED = 'RETURNED', 'Stock Returned'
        EXPIRED = 'EXPIRED_DISCARD', 'Expired & Discarded'

    medicine = models.ForeignKey(MedicineItem, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=50, choices=TransactionType.choices)
    quantity = models.IntegerField()
    recorded_by = models.CharField(max_length=100)
    notes = models.TextField(blank=True, default='')
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.transaction_type}: {self.quantity} of {self.medicine.name}"

class EquipmentItem(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='equipment')
    name = models.CharField(max_length=200)
    total_count = models.IntegerField()
    available_count = models.IntegerField()
    loaned_count = models.IntegerField()
    maintenance_status = models.CharField(max_length=50, choices=EquipmentStatus.choices, default=EquipmentStatus.AVAILABLE)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.available_count}/{self.total_count} Available)"

