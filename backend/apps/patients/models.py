from django.db import models
from django.utils import timezone
from apps.organizations.models import Organization

class PatientLifecycleStatus(models.TextChoices):
    REGISTRATION = 'Registration', 'Registration'
    ASSESSMENT = 'Assessment', 'Assessment'
    CARE_CATEGORY = 'Care Category', 'Care Category'
    CARE_PLAN = 'Care Plan', 'Care Plan'
    ACTIVE_CARE = 'Active Care', 'Active Care'
    FOLLOW_UP = 'Follow-up', 'Follow-up'
    DISCHARGED = 'Discharged', 'Discharged'
    ARCHIVED = 'Archived', 'Archived'

class CategoryTier(models.TextChoices):
    CAT_A = 'Category A (Bedridden)', 'Category A (Bedridden)'
    CAT_B = 'Category B (Semi-mobile)', 'Category B (Semi-mobile)'
    CAT_C = 'Category C (Mobile/Chronic)', 'Category C (Mobile/Chronic)'
    CAT_D = 'Category D (Supportive)', 'Category D (Supportive)'

class RiskLevel(models.TextChoices):
    HIGH = 'High Risk', 'High Risk'
    MODERATE = 'Moderate Risk', 'Moderate Risk'
    LOW = 'Low Risk', 'Low Risk'

class Patient(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='patients')
    patient_id_code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=200)
    age = models.IntegerField()
    gender = models.CharField(max_length=20)
    blood_group = models.CharField(max_length=10)
    district = models.CharField(max_length=100)
    ward = models.CharField(max_length=100)
    address = models.TextField()
    phone = models.CharField(max_length=20)
    lifecycle_status = models.CharField(max_length=50, choices=PatientLifecycleStatus.choices, default=PatientLifecycleStatus.ACTIVE_CARE)
    category_tier = models.CharField(max_length=100, choices=CategoryTier.choices, default=CategoryTier.CAT_A)
    diagnosis = models.TextField()
    risk_level = models.CharField(max_length=50, choices=RiskLevel.choices, default=RiskLevel.MODERATE)
    ai_summary = models.TextField(blank=True, default='')
    emergency_contact_name = models.CharField(max_length=100)
    emergency_contact_phone = models.CharField(max_length=20)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.patient_id_code}) - {self.lifecycle_status}"

class CarePlan(models.Model):
    patient = models.OneToOneField(Patient, on_delete=models.CASCADE, related_name='care_plan')
    primary_nurse_name = models.CharField(max_length=100)
    assigned_doctor_name = models.CharField(max_length=100)
    care_goals = models.TextField(default='Pain management, wound dressing, and routine vitals monitoring.')
    dietary_instructions = models.TextField(blank=True, default='')
    emergency_escalation_notes = models.TextField(blank=True, default='')
    review_frequency_days = models.IntegerField(default=14)
    last_reviewed_date = models.DateField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Care Plan for {self.patient.name}"

class VitalsReading(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='vitals_history')
    bp = models.CharField(max_length=20)
    pulse = models.IntegerField()
    spo2 = models.IntegerField()
    temperature = models.DecimalField(max_digits=4, decimal_places=1, default=98.6)
    pain_scale = models.IntegerField(default=0) # 0-10
    respiratory_rate = models.IntegerField(default=16)
    recorded_by = models.CharField(max_length=100)
    recorded_date = models.DateField(auto_now_add=True)
    recorded_at = models.DateTimeField(default=timezone.now)



class EquipmentIssued(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='equipment_issued')
    equipment_name = models.CharField(max_length=200)
    serial_number = models.CharField(max_length=100)
    issued_date = models.DateField()
    status = models.CharField(max_length=50, default='Active')

class FamilyMemberContact(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='family_members')
    name = models.CharField(max_length=100)
    relation = models.CharField(max_length=50)
    phone = models.CharField(max_length=20)

class PatientAuditLog(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.SET_NULL, null=True, blank=True, related_name='audit_logs')
    user_username = models.CharField(max_length=150)
    user_role = models.CharField(max_length=50, blank=True)
    organization_name = models.CharField(max_length=200, blank=True)
    action = models.CharField(max_length=50)  # e.g., VIEW, CREATE, UPDATE, DELETE, ADD_VITALS
    ip_address = models.CharField(max_length=50, blank=True, default='')
    details = models.TextField(blank=True, default='')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"[{self.timestamp.strftime('%Y-%m-%d %H:%M')}] {self.user_username} - {self.action} on {self.patient}"
