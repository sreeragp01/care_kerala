from django.db import models
from django.utils import timezone
from django.conf import settings
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

class CareTeamRole(models.TextChoices):
    DOCTOR = 'DOCTOR', 'Consulting Doctor'
    NURSE = 'NURSE', 'Palliative / Community Nurse'
    COMMUNITY_WORKER = 'COMMUNITY_WORKER', 'Community Healthcare Worker'
    PHYSIOTHERAPIST = 'PHYSIOTHERAPIST', 'Physiotherapist'
    COUNSELOR = 'COUNSELOR', 'Psychological Counselor'
    VOLUNTEER = 'VOLUNTEER', 'Volunteer'

class CaregiverPermission(models.TextChoices):
    VIEW_BASIC_INFO = 'VIEW_BASIC_INFO', 'View Basic Info'
    VIEW_APPOINTMENTS = 'VIEW_APPOINTMENTS', 'View Appointments'
    VIEW_VISITS = 'VIEW_VISITS', 'View Home Visits'
    VIEW_VITALS = 'VIEW_VITALS', 'View Vitals Summary'
    VIEW_CARE_PLAN = 'VIEW_CARE_PLAN', 'View Care Plan Overview'
    RECEIVE_ALERTS = 'RECEIVE_ALERTS', 'Receive Care Alerts'

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


class CareTeam(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='care_teams')
    name = models.CharField(max_length=200)
    lead_doctor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='led_care_teams')
    primary_nurse = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='primary_care_teams')
    area_coverage = models.CharField(max_length=255, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.organization.name})"


class CareTeamMember(models.Model):
    care_team = models.ForeignKey(CareTeam, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name='care_team_memberships')
    member_name = models.CharField(max_length=150)
    role = models.CharField(max_length=40, choices=CareTeamRole.choices, default=CareTeamRole.NURSE)
    phone = models.CharField(max_length=20, blank=True, default='')
    is_primary = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('care_team', 'user')

    def __str__(self):
        return f"{self.member_name} ({self.role}) in {self.care_team.name}"


class PatientCareGoal(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='care_goals')
    category = models.CharField(max_length=100, default='Pain Management') # Pain Management, Wound Dressing, Mobility, Nutrition, Emotional Support
    description = models.TextField()
    target_date = models.DateField(null=True, blank=True)
    is_achieved = models.BooleanField(default=False)
    achieved_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Goal for {self.patient.name}: {self.category} ({'Done' if self.is_achieved else 'Pending'})"


class CarePlan(models.Model):
    patient = models.OneToOneField(Patient, on_delete=models.CASCADE, related_name='care_plan')
    care_team = models.ForeignKey(CareTeam, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_care_plans')
    primary_nurse_name = models.CharField(max_length=100)
    assigned_doctor_name = models.CharField(max_length=100)
    care_goals = models.TextField(default='Pain management, wound dressing, and routine vitals monitoring.')
    
    # Enhanced Phase 2.7 Fields
    pain_assessment_protocol = models.TextField(blank=True, default='WHO 3-step analgesic ladder, monitor every visit.')
    mobility_status = models.CharField(max_length=100, default='Bedridden (Category A)')
    dietary_instructions = models.TextField(blank=True, default='')
    psychological_support_notes = models.TextField(blank=True, default='')
    visit_frequency = models.CharField(max_length=50, default='Weekly') # Daily, Twice Weekly, Weekly, Bi-weekly, Monthly
    emergency_escalation_notes = models.TextField(blank=True, default='')
    dnr_or_advanced_directives = models.TextField(blank=True, default='')
    
    review_frequency_days = models.IntegerField(default=14)
    last_reviewed_date = models.DateField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Care Plan for {self.patient.name}"


class CaregiverAccess(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='caregiver_grants')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='caregiver_grants')
    caregiver_name = models.CharField(max_length=150)
    caregiver_phone = models.CharField(max_length=20)
    relationship = models.CharField(max_length=100, default='Family Member')
    permissions = models.JSONField(default=list) # ['VIEW_BASIC_INFO', 'VIEW_VISITS', 'VIEW_VITALS', 'RECEIVE_ALERTS']
    is_active = models.BooleanField(default=True)
    granted_by = models.CharField(max_length=150, default='Hospital Desk')
    granted_at = models.DateTimeField(auto_now_add=True)

    def has_permission(self, perm: str) -> bool:
        if not self.is_active:
            return False
        return perm in (self.permissions or [])

    def __str__(self):
        return f"Caregiver {self.caregiver_name} -> {self.patient.name} ({len(self.permissions)} perms)"


class MedicationPlan(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='medication_plans')
    medicine_name = models.CharField(max_length=200)
    dosage = models.CharField(max_length=100) # e.g. 500mg, 1 tablet, 10ml
    route = models.CharField(max_length=50, default='Oral') # Oral, Subcutaneous, Topical, Intravenous, Inhalation
    frequency = models.CharField(max_length=100, default='Twice Daily (Morning, Night)')
    time_slots = models.JSONField(default=list) # ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT']
    prescribed_by_doctor = models.CharField(max_length=150)
    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(null=True, blank=True)
    instructions = models.TextField(blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.medicine_name} {self.dosage} for {self.patient.name}"


class MedicationAdministration(models.Model):
    class Status(models.TextChoices):
        TAKEN = 'TAKEN', 'Taken'
        SKIPPED = 'SKIPPED', 'Skipped'
        MISSED = 'MISSED', 'Missed'
        REFUSED = 'REFUSED', 'Refused'

    medication_plan = models.ForeignKey(MedicationPlan, on_delete=models.CASCADE, related_name='administrations')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='medication_logs')
    scheduled_date = models.DateField()
    time_slot = models.CharField(max_length=30, default='MORNING') # MORNING, AFTERNOON, EVENING, NIGHT
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.TAKEN)
    recorded_by_caregiver = models.BooleanField(default=False)
    verified_by_nurse = models.BooleanField(default=False)
    verified_nurse_name = models.CharField(max_length=150, blank=True, default='')
    administered_at = models.DateTimeField(default=timezone.now)
    notes = models.TextField(blank=True, default='')

    def __str__(self):
        return f"{self.medication_plan.medicine_name} ({self.status}) for {self.patient.name} on {self.scheduled_date}"


class VitalsReading(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='vitals_history')
    bp = models.CharField(max_length=20)
    pulse = models.IntegerField()
    spo2 = models.IntegerField()
    temperature = models.DecimalField(max_digits=4, decimal_places=1, default=98.6)
    pain_scale = models.IntegerField(default=0) # 0-10
    respiratory_rate = models.IntegerField(default=16)
    blood_sugar = models.IntegerField(null=True, blank=True) # mg/dL
    recorded_by = models.CharField(max_length=100)
    recorded_date = models.DateField(auto_now_add=True)
    recorded_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"Vitals for {self.patient.name} at {self.recorded_at.strftime('%Y-%m-%d %H:%M')}: BP {self.bp}, SpO2 {self.spo2}%"


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
    action = models.CharField(max_length=50)  # e.g., VIEW, CREATE, UPDATE, DELETE, ADD_VITALS, GRANT_CAREGIVER
    ip_address = models.CharField(max_length=50, blank=True, default='')
    details = models.TextField(blank=True, default='')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"[{self.timestamp.strftime('%Y-%m-%d %H:%M')}] {self.user_username} - {self.action} on {self.patient}"
