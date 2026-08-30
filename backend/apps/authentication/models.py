from django.contrib.auth.models import AbstractUser
from django.db import models
from apps.organizations.models import Organization

class UserRole(models.TextChoices):
    SUPER_ADMIN = 'SUPER_ADMIN', 'CareLink Super Admin'
    PLATFORM_ADMIN = 'PLATFORM_ADMIN', 'CareLink Platform Admin'
    ORGANIZATION_OWNER = 'ORGANIZATION_OWNER', 'Hospital / Organization Owner'
    ORG_ADMIN = 'ORG_ADMIN', 'Hospital / Organization Admin'
    MODERATOR = 'MODERATOR', 'Healthcare Content Moderator'
    DOCTOR = 'DOCTOR', 'Doctor / Specialist'
    NURSE = 'NURSE', 'Community / Clinical Nurse'
    VOLUNTEER = 'VOLUNTEER', 'Volunteer'
    RECEPTION = 'RECEPTION', 'Reception & Desk Staff'
    PHARMACIST = 'PHARMACIST', 'Pharmacist'
    ACCOUNTANT = 'ACCOUNTANT', 'Accountant'
    AMBULANCE_DRIVER = 'AMBULANCE_DRIVER', 'Ambulance Driver'
    PATIENT = 'PATIENT', 'Patient'
    FAMILY_MEMBER = 'FAMILY_MEMBER', 'Family Member'
    BLOOD_DONOR = 'BLOOD_DONOR', 'Blood Donor'

class User(AbstractUser):
    role = models.CharField(max_length=50, choices=UserRole.choices, default=UserRole.NURSE)
    organization = models.ForeignKey(Organization, on_delete=models.SET_NULL, null=True, blank=True, related_name='users')
    phone = models.CharField(max_length=20, blank=True)
    district = models.CharField(max_length=100, default='Kozhikode')

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
