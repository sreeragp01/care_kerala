from django.db import models

class OrganizationStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Application'
    UNDER_REVIEW = 'UNDER_REVIEW', 'Under Document Review'
    ACTION_REQUIRED = 'ACTION_REQUIRED', 'Action Required'
    ACTIVE = 'ACTIVE', 'Active'
    REJECTED = 'REJECTED', 'Application Rejected'
    SUSPENDED = 'SUSPENDED', 'Suspended'

class Organization(models.Model):
    """Core Multi-tenant Organization entity (Palliative Units, Hospitals, Trusts, Clinics)"""
    name = models.CharField(max_length=255)
    district = models.CharField(max_length=100)
    registration_number = models.CharField(max_length=100, unique=True)
    phone = models.CharField(max_length=20)
    status = models.CharField(
        max_length=30,
        choices=OrganizationStatus.choices,
        default=OrganizationStatus.ACTIVE
    )
    
    # Financial Escrow & Donation Gateways
    upi_id = models.CharField(max_length=100, blank=True, default='')
    bank_account_name = models.CharField(max_length=200, blank=True, default='')
    bank_account_number = models.CharField(max_length=50, blank=True, default='')
    ifsc_code = models.CharField(max_length=20, blank=True, default='')
    bank_name = models.CharField(max_length=100, blank=True, default='')
    qr_code_image_url = models.CharField(max_length=500, blank=True, default='')
    razorpay_account_id = models.CharField(max_length=100, blank=True, default='')
    
    active_patients_count = models.IntegerField(default=0)
    total_visits_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.district})"
