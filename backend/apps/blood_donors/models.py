from django.db import models
from django.utils import timezone
from apps.organizations.models import Organization

class BloodDonor(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='blood_donors')
    name = models.CharField(max_length=200)
    blood_group = models.CharField(max_length=10)
    district = models.CharField(max_length=100)
    locality = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    last_donation_date = models.DateField()
    total_donations = models.IntegerField(default=1)
    is_available = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_eligible(self):
        if not self.is_available:
            return False
        days_passed = (timezone.now().date() - self.last_donation_date).days
        return days_passed >= 90

    @property
    def days_remaining(self):
        days_passed = (timezone.now().date() - self.last_donation_date).days
        if days_passed >= 90:
            return 0
        return 90 - days_passed

    def __str__(self):
        return f"{self.name} ({self.blood_group}) - {self.district}"

class BloodRequestStatus(models.TextChoices):
    CREATED = 'Created', 'Created'
    MATCHING = 'Matching', 'Matching'
    DONORS_NOTIFIED = 'Donors Notified', 'Donors Notified'
    DONOR_RESPONDED = 'Donor Responded', 'Donor Responded'
    FULFILLED = 'Fulfilled', 'Fulfilled'
    CLOSED = 'Closed', 'Closed'

class BloodRequest(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='blood_requests')
    patient_name = models.CharField(max_length=200)
    blood_group = models.CharField(max_length=10)
    hospital_name = models.CharField(max_length=255)
    district = models.CharField(max_length=100)
    units_needed = models.IntegerField(default=1)
    urgency = models.CharField(max_length=50, default='Emergency')
    requested_date = models.DateField(auto_now_add=True)
    status = models.CharField(max_length=50, choices=BloodRequestStatus.choices, default=BloodRequestStatus.CREATED)
    responding_donor = models.ForeignKey(BloodDonor, on_delete=models.SET_NULL, null=True, blank=True, related_name='responded_requests')
    fulfilled_date = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"Emergency {self.blood_group} Request for {self.patient_name} at {self.hospital_name} ({self.status})"

