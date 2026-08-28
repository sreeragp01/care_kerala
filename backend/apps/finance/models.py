from django.db import models
from apps.organizations.models import Organization

class DonationStatus(models.TextChoices):
    CREATED = 'Created', 'Created'
    PAYMENT_PENDING = 'Payment Pending', 'Payment Pending'
    PAID = 'Paid', 'Paid'
    RECEIPT_GENERATED = 'Receipt Generated', 'Receipt Generated'
    COMPLETED = 'Completed', 'Completed'

class Donation(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='donations')
    donor_name = models.CharField(max_length=200)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.CharField(max_length=100) # General Palliative Fund, Equipment Fund, Medicine Support, Treatment Appeal
    payment_mode = models.CharField(max_length=50) # Razorpay, UPI_QR, Bank Transfer, Cash
    receipt_number = models.CharField(max_length=100, unique=True)
    status = models.CharField(max_length=50, choices=DonationStatus.choices, default=DonationStatus.COMPLETED)
    transaction_id = models.CharField(max_length=100, blank=True, default='')
    razorpay_payment_id = models.CharField(max_length=100, blank=True, default='')
    razorpay_order_id = models.CharField(max_length=100, blank=True, default='')
    razorpay_signature = models.CharField(max_length=200, blank=True, default='')
    is_verified = models.BooleanField(default=True)
    fundraiser_id = models.CharField(max_length=100, blank=True, default='')
    donor_prayer = models.TextField(blank=True, default='')
    is_anonymous = models.BooleanField(default=False)
    date = models.DateField(auto_now_add=True)

    def __str__(self):
        return f"₹{self.amount} from {self.donor_name} (#{self.receipt_number}) - {self.status}"


class MedicalFundraiser(models.Model):
    cooperating_organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='fundraisers')
    patient_name = models.CharField(max_length=200)
    patient_age = models.IntegerField(default=40)
    patient_gender = models.CharField(max_length=20, default='Male')
    blood_group = models.CharField(max_length=10, default='O+')
    district = models.CharField(max_length=100)
    ward = models.CharField(max_length=100)
    hospital_name = models.CharField(max_length=255)
    doctor_name = models.CharField(max_length=200)
    treatment_title = models.CharField(max_length=255)
    category = models.CharField(max_length=100)
    target_amount = models.DecimalField(max_digits=12, decimal_places=2)
    collected_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    donors_count = models.IntegerField(default=0)
    story = models.TextField()
    medical_estimate_summary = models.TextField(blank=True, default='')
    is_doctor_verified = models.BooleanField(default=True)
    days_remaining = models.IntegerField(default=30)
    status = models.CharField(max_length=50, default='Active')
    patient_family_gratitude_message = models.TextField(blank=True, default='')
    
    # QR Routing: use cooperating org's QR or custom campaign QR
    use_org_qr = models.BooleanField(default=True)
    custom_upi_id = models.CharField(max_length=100, blank=True, default='')
    custom_qr_url = models.CharField(max_length=500, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.treatment_title} for {self.patient_name} (Cooperating: {self.cooperating_organization.name})"


