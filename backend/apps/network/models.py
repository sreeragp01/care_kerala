from django.db import models
from django.conf import settings
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal
from apps.organizations.models import Organization

class OrganizationType(models.TextChoices):
    HOSPITAL = 'HOSPITAL', 'Multispecialty / General Hospital'
    CLINIC = 'CLINIC', 'Medical Clinic / Polyclinic'
    PALLIATIVE_CARE_CENTER = 'PALLIATIVE_CARE_CENTER', 'Palliative Care Center & Hospice'
    NURSING_HOME = 'NURSING_HOME', 'Nursing Home'
    REHABILITATION_CENTER = 'REHABILITATION_CENTER', 'Rehabilitation Center'
    DIAGNOSTIC_CENTER = 'DIAGNOSTIC_CENTER', 'Diagnostic Center & Imaging Lab'
    PHARMACY = 'PHARMACY', 'Community Pharmacy'
    BLOOD_BANK = 'BLOOD_BANK', 'Blood Bank & Component Center'
    HOME_CARE_PROVIDER = 'HOME_CARE_PROVIDER', 'Home Healthcare Provider'
    OTHER = 'OTHER', 'Other Healthcare Facility'

class OwnershipType(models.TextChoices):
    GOVERNMENT = 'GOVERNMENT', 'Government / Public Sector (DHS / DME)'
    PRIVATE = 'PRIVATE', 'Private Healthcare'
    TRUST = 'TRUST', 'Charitable Trust / Non-Profit'
    MISSION = 'MISSION', 'Mission Hospital'
    COOPERATIVE = 'COOPERATIVE', 'Cooperative Society'
    OTHER = 'OTHER', 'Other Ownership'

class VerificationStatus(models.TextChoices):
    UNVERIFIED = 'UNVERIFIED', 'Unverified'
    PARTIALLY_VERIFIED = 'PARTIALLY_VERIFIED', 'Partially Verified (Pending Docs)'
    VERIFIED = 'VERIFIED', 'CareLink Verified (Badge Active)'
    EXPIRED = 'EXPIRED', 'Verification Expired (Re-verification Required)'

class OrganizationLifecycleStatus(models.TextChoices):
    PROSPECT = 'PROSPECT', 'Prospect Under Discovery'
    INVITED = 'INVITED', 'Invited (Pending Admin Activation)'
    ACTIVATED = 'ACTIVATED', 'Activated (Account Setup Complete)'
    PROFILE_INCOMPLETE = 'PROFILE_INCOMPLETE', 'Profile Setup Incomplete'
    SUBMITTED_FOR_REVIEW = 'SUBMITTED_FOR_REVIEW', 'Submitted for CareLink Review'
    UNDER_REVIEW = 'UNDER_REVIEW', 'Under CareLink Audit Review'
    ACTION_REQUIRED = 'ACTION_REQUIRED', 'Action Required (Changes Requested)'
    APPROVED = 'APPROVED', 'Approved by CareLink'
    PUBLISHED = 'PUBLISHED', 'Published to Public Directory'
    SUSPENDED = 'SUSPENDED', 'Suspended'

class HealthcareProspectStatus(models.TextChoices):
    CONTACT_NOT_STARTED = 'CONTACT_NOT_STARTED', 'Contact Not Started'
    CONTACTED = 'CONTACTED', 'Contacted'
    INTERESTED = 'INTERESTED', 'Interested in CareLink Network'
    INVITED = 'INVITED', 'Invitation Issued'
    ACTIVATED = 'ACTIVATED', 'Admin Activated'
    PROFILE_COMPLETED = 'PROFILE_COMPLETED', 'Profile Completed'
    VERIFIED = 'VERIFIED', 'Verified & Published'
    DECLINED = 'DECLINED', 'Declined'

class InvitationStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Activation'
    ACCEPTED = 'ACCEPTED', 'Accepted & Activated'
    EXPIRED = 'EXPIRED', 'Expired'
    REVOKED = 'REVOKED', 'Revoked'

class MembershipRole(models.TextChoices):
    ORGANIZATION_OWNER = 'ORGANIZATION_OWNER', 'Hospital / Organization Owner'
    ORGANIZATION_ADMIN = 'ORGANIZATION_ADMIN', 'Hospital Organization Administrator'
    DEPARTMENT_MODERATOR = 'DEPARTMENT_MODERATOR', 'Departmental Content Moderator'
    DOCTOR = 'DOCTOR', 'Doctor / Specialist Consultant'
    NURSE = 'NURSE', 'Clinical / Palliative Nurse'
    RECEPTION = 'RECEPTION', 'Reception & Desk Staff'
    PHARMACIST = 'PHARMACIST', 'Pharmacist'
    STAFF = 'STAFF', 'Healthcare Staff'
    LIMITED_STAFF = 'LIMITED_STAFF', 'Limited Staff Member'

class MembershipStatus(models.TextChoices):
    INVITED = 'INVITED', 'Invited (Pending Acceptance)'
    PENDING_APPROVAL = 'PENDING_APPROVAL', 'Pending Hospital Admin Approval'
    ACTIVE = 'ACTIVE', 'Active Member'
    REJECTED = 'REJECTED', 'Membership Rejected'
    SUSPENDED = 'SUSPENDED', 'Membership Suspended'
    REVOKED = 'REVOKED', 'Membership Access Revoked'

class Specialty(models.Model):
    """Centralized medical specialty taxonomy across Kerala"""
    name = models.CharField(max_length=120, unique=True)
    category = models.CharField(max_length=100, default='Clinical Specialty')
    icon_name = models.CharField(max_length=80, default='medical_services')
    description = models.TextField(blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Specialties'
        ordering = ['name']

    def __str__(self):
        return self.name

class Department(models.Model):
    """Department within a hospital or clinic"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='departments')
    name = models.CharField(max_length=150)
    head_of_department = models.CharField(max_length=150, blank=True, default='')
    phone_extension = models.CharField(max_length=50, blank=True, default='')
    floor_location = models.CharField(max_length=100, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('organization', 'name')
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.organization.name})"

class HealthcareService(models.Model):
    """Standardized catalog of medical services"""
    name = models.CharField(max_length=120, unique=True)
    category = models.CharField(max_length=80, default='Clinical Service')
    icon_name = models.CharField(max_length=80, default='local_hospital')
    description = models.TextField(blank=True, default='')
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name

class Facility(models.Model):
    """Amenities and infrastructure offerings"""
    name = models.CharField(max_length=120, unique=True)
    icon_name = models.CharField(max_length=80, default='check_circle')
    description = models.TextField(blank=True, default='')
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = 'Facilities'

    def __str__(self):
        return self.name

class HealthcareProfile(models.Model):
    """Healthcare-specific public profile attached to an Organization"""
    organization = models.OneToOneField(Organization, on_delete=models.CASCADE, related_name='healthcare_profile')
    organization_type = models.CharField(
        max_length=50,
        choices=OrganizationType.choices,
        default=OrganizationType.HOSPITAL
    )
    ownership_type = models.CharField(
        max_length=50,
        choices=OwnershipType.choices,
        default=OwnershipType.PRIVATE
    )
    verification_status = models.CharField(
        max_length=40,
        choices=VerificationStatus.choices,
        default=VerificationStatus.VERIFIED
    )
    
    # Location & Contact
    address = models.TextField(blank=True, default='')
    district = models.CharField(max_length=100, default='Kozhikode')
    pincode = models.CharField(max_length=10, blank=True, default='673001')
    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        default=11.2588,
        validators=[MinValueValidator(Decimal('-90.0')), MaxValueValidator(Decimal('90.0'))]
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        default=75.7804,
        validators=[MinValueValidator(Decimal('-180.0')), MaxValueValidator(Decimal('180.0'))]
    )
    phone = models.CharField(max_length=20, blank=True, default='')
    email = models.EmailField(blank=True, default='')
    website = models.URLField(blank=True, default='')
    
    # Emergency & Infrastructure
    is_24x7_emergency = models.BooleanField(default=False)
    emergency_phone = models.CharField(max_length=20, blank=True, default='')
    trauma_care_available = models.BooleanField(default=False)
    ambulance_available = models.BooleanField(default=False)
    total_beds = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    icu_beds = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    
    # Branding & Description
    description = models.TextField(blank=True, default='')
    logo_url = models.CharField(max_length=500, blank=True, default='')
    cover_image_url = models.CharField(max_length=500, blank=True, default='')
    established_year = models.IntegerField(default=2010)
    
    # Freshness & Quality Tracking
    profile_completeness_score = models.IntegerField(default=85)
    last_verified_at = models.DateTimeField(default=timezone.now)
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='verified_healthcare_profiles'
    )
    
    # Lifecycle & Publication State
    lifecycle_status = models.CharField(
        max_length=40,
        choices=OrganizationLifecycleStatus.choices,
        default=OrganizationLifecycleStatus.INVITED
    )
    profile_completeness_percentage = models.IntegerField(default=0)
    is_published = models.BooleanField(default=False)
    review_notes = models.TextField(blank=True, default='')
    submitted_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    # Catalogs
    specialties = models.ManyToManyField(Specialty, blank=True, related_name='profiles')
    services = models.ManyToManyField(HealthcareService, blank=True, related_name='profiles')
    facilities = models.ManyToManyField(Facility, blank=True, related_name='profiles')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def is_carelink_verified(self):
        return self.verification_status == VerificationStatus.VERIFIED

    @property
    def data_freshness_tier(self):
        """Calculates 4-tier freshness based on last_verified_at"""
        if not self.last_verified_at or self.verification_status != VerificationStatus.VERIFIED:
            return 'UNVERIFIED'
        delta = (timezone.now() - self.last_verified_at).days
        if delta <= 30:
            return 'CURRENT' # 🟢 Current (0-30 days)
        elif delta <= 90:
            return 'REVIEW_RECOMMENDED' # 🟡 Review recommended (31-90 days)
        else:
            return 'VERIFICATION_REQUIRED' # 🟠 Verification required (90+ days)

    class Meta:
        ordering = ['-profile_completeness_score', 'id']

    def __str__(self):
        return f"{self.organization.name} Profile ({self.get_organization_type_display()} • {self.district})"

class HealthcareProspect(models.Model):
    """CareLink internal pipeline tracker for discovering & contacting prospective hospitals"""
    name = models.CharField(max_length=255)
    district = models.CharField(max_length=100)
    organization_type = models.CharField(max_length=50, choices=OrganizationType.choices, default=OrganizationType.HOSPITAL)
    ownership_type = models.CharField(max_length=50, choices=OwnershipType.choices, default=OwnershipType.PRIVATE)
    contact_person = models.CharField(max_length=150)
    contact_designation = models.CharField(max_length=150, default='Medical Director / Superintendent')
    contact_phone = models.CharField(max_length=20)
    contact_email = models.EmailField()
    status = models.CharField(max_length=40, choices=HealthcareProspectStatus.choices, default=HealthcareProspectStatus.CONTACT_NOT_STARTED)
    internal_notes = models.TextField(blank=True, default='')
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='created_prospects')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.district}) [{self.get_status_display()}]"

class OrganizationInvitation(models.Model):
    """Secure, single-use token invitation issued by CareLink to an initial Organization Admin"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='invitations')
    prospect = models.ForeignKey(HealthcareProspect, on_delete=models.SET_NULL, null=True, blank=True, related_name='invitations')
    recipient_name = models.CharField(max_length=150)
    recipient_email = models.EmailField()
    recipient_phone = models.CharField(max_length=20)
    recipient_designation = models.CharField(max_length=150, default='Authorized Hospital Administrator')
    token = models.CharField(max_length=128, unique=True, db_index=True)
    status = models.CharField(max_length=20, choices=InvitationStatus.choices, default=InvitationStatus.PENDING)
    invited_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='issued_org_invitations')
    expires_at = models.DateTimeField()
    accepted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Invite for {self.recipient_name} ({self.organization.name}) [{self.status}]"

class OrganizationMembership(models.Model):
    """Core relation connecting a User to an Organization with sovereign hospital admin approval"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='organization_memberships')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='memberships')
    role = models.CharField(max_length=40, choices=MembershipRole.choices, default=MembershipRole.STAFF)
    status = models.CharField(max_length=30, choices=MembershipStatus.choices, default=MembershipStatus.PENDING_APPROVAL)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True, related_name='memberships')
    designation = models.CharField(max_length=150, blank=True, default='')
    medical_registration_number = models.CharField(max_length=100, blank=True, default='')
    permissions = models.JSONField(default=dict, blank=True)
    invited_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='sent_team_invitations')
    approved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_memberships')
    approved_at = models.DateTimeField(null=True, blank=True)
    joined_at = models.DateTimeField(null=True, blank=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'organization')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} at {self.organization.name} ({self.get_role_display()} - {self.get_status_display()})"

class HospitalTeamInvitation(models.Model):
    """Invitation issued by a Hospital Admin to add doctors, moderators, or staff to their hospital"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='team_invitations')
    recipient_name = models.CharField(max_length=150)
    recipient_email = models.EmailField()
    recipient_phone = models.CharField(max_length=20, blank=True, default='')
    role = models.CharField(max_length=40, choices=MembershipRole.choices, default=MembershipRole.STAFF)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True)
    designation = models.CharField(max_length=150, blank=True, default='')
    token = models.CharField(max_length=128, unique=True, db_index=True)
    status = models.CharField(max_length=20, choices=InvitationStatus.choices, default=InvitationStatus.PENDING)
    invited_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='issued_team_invitations')
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Team Invite: {self.recipient_name} -> {self.organization.name} ({self.get_role_display()})"

class Doctor(models.Model):
    """Doctor / Specialist entity (Independent practitioner profile)"""
    name = models.CharField(max_length=150)
    profile_photo_url = models.CharField(max_length=500, blank=True, default='')
    qualification = models.CharField(max_length=200, help_text='e.g., MBBS, MD, DM (Cardiology), DNB')
    primary_specialty = models.ForeignKey(Specialty, on_delete=models.PROTECT, related_name='doctors')
    sub_specialties = models.CharField(max_length=200, blank=True, default='')
    experience_years = models.IntegerField(default=5)
    languages = models.CharField(max_length=200, default='Malayalam, English')
    
    # Medical Council Registration
    registration_authority = models.CharField(max_length=150, default='Travancore-Cochin Medical Council (TCMC)')
    registration_number = models.CharField(max_length=100)
    is_reg_verified = models.BooleanField(default=True)
    
    biography = models.TextField(blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Dr. {self.name} ({self.primary_specialty.name})"

class ConsultationMode(models.TextChoices):
    IN_PERSON = 'IN_PERSON', 'In-Person Hospital OPD'
    VIDEO = 'VIDEO', 'Telemedicine Video Consultation'
    HOME_VISIT = 'HOME_VISIT', 'Palliative / Home Care Visit'
    ALL = 'ALL', 'In-Person, Video & Home Visit'

class DoctorAffiliation(models.Model):
    """Multi-tenancy link connecting a Doctor to a specific Hospital/Clinic"""
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='affiliations')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='doctor_affiliations')
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True, related_name='doctor_affiliations')
    designation = models.CharField(max_length=150, default='Senior Consultant')
    consultation_mode = models.CharField(max_length=30, choices=ConsultationMode.choices, default=ConsultationMode.IN_PERSON)
    consultation_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text='0 for Free / Trust Clinics')
    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    verification_status = models.CharField(
        max_length=30,
        choices=VerificationStatus.choices,
        default=VerificationStatus.VERIFIED
    )
    verified_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('doctor', 'organization')

    def __str__(self):
        return f"Dr. {self.doctor.name} at {self.organization.name} ({self.designation})"

class DayOfWeek(models.TextChoices):
    MONDAY = 'MONDAY', 'Monday'
    TUESDAY = 'TUESDAY', 'Tuesday'
    WEDNESDAY = 'WEDNESDAY', 'Wednesday'
    THURSDAY = 'THURSDAY', 'Thursday'
    FRIDAY = 'FRIDAY', 'Friday'
    SATURDAY = 'SATURDAY', 'Saturday'
    SUNDAY = 'SUNDAY', 'Sunday'

class ScheduleStatus(models.TextChoices):
    ACTIVE = 'ACTIVE', 'Active & On Duty'
    CANCELLED = 'CANCELLED', 'Cancelled for this date'
    ON_LEAVE = 'ON_LEAVE', 'Doctor on Leave'

class DoctorSchedule(models.Model):
    """Weekly consultation hours and OPD timetable linked to a specific doctor affiliation"""
    affiliation = models.ForeignKey(DoctorAffiliation, on_delete=models.CASCADE, related_name='schedules')
    day_of_week = models.CharField(max_length=20, choices=DayOfWeek.choices)
    start_time = models.CharField(max_length=20, help_text='e.g., 09:00 AM or 16:00')
    end_time = models.CharField(max_length=20, help_text='e.g., 01:00 PM or 19:00')
    consultation_type = models.CharField(max_length=50, default='General OPD')
    location_room = models.CharField(max_length=100, blank=True, default='OPD Room 102')
    max_tokens = models.IntegerField(default=30)
    appointment_required = models.BooleanField(default=True)
    status = models.CharField(max_length=20, choices=ScheduleStatus.choices, default=ScheduleStatus.ACTIVE)
    last_verified_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['day_of_week', 'start_time']

    def clean(self):
        from django.core.exceptions import ValidationError
        super().clean()
        if self.start_time and self.end_time:
            if self.start_time.strip() == self.end_time.strip():
                raise ValidationError({'end_time': 'End time cannot be identical to start time.'})

    def __str__(self):
        return f"{self.affiliation.doctor.name} @ {self.affiliation.organization.name} | {self.get_day_of_week_display()} ({self.start_time} - {self.end_time})"

class ChangeRequestEntityType(models.TextChoices):
    DOCTOR_PROFILE = 'DOCTOR_PROFILE', 'Doctor Profile'
    DOCTOR_SCHEDULE = 'DOCTOR_SCHEDULE', 'Doctor Consultation Schedule'
    SERVICES_FACILITIES = 'SERVICES_FACILITIES', 'Services & Facilities'
    HOSPITAL_PROFILE = 'HOSPITAL_PROFILE', 'Hospital General Profile'

class ChangeRequestStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Admin Review'
    APPROVED = 'APPROVED', 'Approved & Published'
    REJECTED = 'REJECTED', 'Rejected'
    EXPIRED = 'EXPIRED', 'Expired'

class ChangeRequest(models.Model):
    """Moderator change proposal workflow with JSON diff and expiration"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='change_requests')
    requested_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='submitted_change_requests')
    reviewed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_change_requests')
    entity_type = models.CharField(max_length=40, choices=ChangeRequestEntityType.choices)
    entity_id = models.CharField(max_length=100, blank=True, default='')
    change_summary = models.CharField(max_length=255)
    old_data = models.JSONField(default=dict, blank=True)
    new_data = models.JSONField(default=dict, blank=True)
    reason = models.TextField(blank=True, default='')
    priority = models.CharField(max_length=20, default='NORMAL')
    status = models.CharField(max_length=20, choices=ChangeRequestStatus.choices, default=ChangeRequestStatus.PENDING)
    reviewer_notes = models.TextField(blank=True, default='')
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"CR #{self.id} [{self.get_status_display()}] - {self.change_summary}"

class OrganizationDocumentType(models.TextChoices):
    HOSPITAL_LICENSE = 'HOSPITAL_LICENSE', 'Kerala Clinical Establishment License'
    REGISTRATION_CERTIFICATE = 'REGISTRATION_CERTIFICATE', 'Society / Trust / Company Registration'
    NABH_ACCREDITATION = 'NABH_ACCREDITATION', 'NABH / NABL Accreditation'
    OWNERSHIP_PROOF = 'OWNERSHIP_PROOF', 'Ownership / Authorized Signatory Proof'
    OTHER = 'OTHER', 'Other Supporting Document'

class OrganizationDocument(models.Model):
    """Verification documents uploaded by healthcare institutions"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=40, choices=OrganizationDocumentType.choices)
    title = models.CharField(max_length=200)
    document_file_url = models.CharField(max_length=500)
    document_number = models.CharField(max_length=100, blank=True, default='')
    expiry_date = models.DateField(null=True, blank=True)
    verification_status = models.CharField(max_length=20, choices=VerificationStatus.choices, default=VerificationStatus.UNVERIFIED)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='verified_documents')
    verified_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.get_document_type_display()} - {self.organization.name}"

class ClaimStatus(models.TextChoices):
    PENDING = 'PENDING', 'Claim Pending Review'
    APPROVED = 'APPROVED', 'Claim Approved'
    REJECTED = 'REJECTED', 'Claim Rejected'

class ClaimOrganizationRequest(models.Model):
    """Claim existing organization profile on CareLink Network"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='claims')
    claimant = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='organization_claims')
    claimant_designation = models.CharField(max_length=150, help_text='e.g., Medical Director, Administrative Officer')
    official_email = models.EmailField()
    official_phone = models.CharField(max_length=20)
    proof_document_url = models.CharField(max_length=500, blank=True, default='')
    status = models.CharField(max_length=20, choices=ClaimStatus.choices, default=ClaimStatus.PENDING)
    reviewed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_claims')
    review_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Claim for {self.organization.name} by {self.claimant.username}"

class ReportType(models.TextChoices):
    DOCTOR_LEFT = 'DOCTOR_LEFT', 'Doctor no longer practices here'
    INCORRECT_SCHEDULE = 'INCORRECT_SCHEDULE', 'Consultation schedule is incorrect'
    INCORRECT_PHONE = 'INCORRECT_PHONE', 'Phone / Contact number is incorrect'
    HOSPITAL_MOVED = 'HOSPITAL_MOVED', 'Hospital location or address changed'
    SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE', 'Listed service is not available'
    OTHER = 'OTHER', 'Other inaccuracy'

class PatientInformationReport(models.Model):
    """Community & patient feedback reporting incorrect information"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='inaccuracy_reports')
    doctor = models.ForeignKey(Doctor, on_delete=models.SET_NULL, null=True, blank=True, related_name='inaccuracy_reports')
    reported_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    report_type = models.CharField(max_length=40, choices=ReportType.choices)
    description = models.TextField()
    status = models.CharField(max_length=20, default='PENDING')
    admin_response = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Report on {self.organization.name}: {self.get_report_type_display()}"

class AppointmentStatus(models.TextChoices):
    REQUESTED = 'REQUESTED', 'Appointment Requested by Patient'
    PENDING_HOSPITAL = 'PENDING_HOSPITAL', 'Pending Hospital Acceptance'
    ACCEPTED = 'ACCEPTED', 'Accepted by Hospital Desk'
    CONFIRMED = 'CONFIRMED', 'Confirmed & Token Issued'
    CHECKED_IN = 'CHECKED_IN', 'Patient Arrived & Checked In'
    IN_CONSULTATION = 'IN_CONSULTATION', 'In Consultation with Doctor'
    COMPLETED = 'COMPLETED', 'Consultation Completed'
    CANCELLED = 'CANCELLED', 'Cancelled'
    REJECTED = 'REJECTED', 'Rejected by Hospital'
    NO_SHOW = 'NO_SHOW', 'Patient Did Not Arrive'
    RESCHEDULED = 'RESCHEDULED', 'Rescheduled'

class AppointmentRequest(models.Model):
    """Patient consultation request and booking record"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='appointments')
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='appointments')
    affiliation = models.ForeignKey(DoctorAffiliation, on_delete=models.CASCADE, null=True, blank=True, related_name='appointments')
    patient_name = models.CharField(max_length=150)
    patient_phone = models.CharField(max_length=20)
    patient_age = models.IntegerField(default=45)
    patient_gender = models.CharField(max_length=20, default='Male')
    district = models.CharField(max_length=100, default='Kozhikode')
    preferred_date = models.DateField()
    preferred_time_slot = models.CharField(max_length=50, default='Morning (09:00 AM - 01:00 PM)')
    consultation_mode = models.CharField(max_length=30, choices=ConsultationMode.choices, default=ConsultationMode.IN_PERSON)
    chief_complaint = models.TextField(blank=True, default='')
    status = models.CharField(max_length=30, choices=AppointmentStatus.choices, default=AppointmentStatus.REQUESTED)
    token_number = models.CharField(max_length=50, blank=True, default='')
    hospital_notes = models.TextField(blank=True, default='')
    idempotency_key = models.CharField(max_length=64, blank=True, null=True, db_index=True)
    responded_at = models.DateTimeField(null=True, blank=True)
    responded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='responded_appointments'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Appt #{self.id}: {self.patient_name} with Dr. {self.doctor.name} ({self.preferred_date})"

class DoctorAvailabilityStatus(models.TextChoices):
    AVAILABLE = 'AVAILABLE', 'Available on Duty'
    ON_LEAVE = 'ON_LEAVE', 'On Leave'
    HOLIDAY = 'HOLIDAY', 'Hospital / Public Holiday'
    EMERGENCY_DUTY = 'EMERGENCY_DUTY', 'Emergency Casualty Duty'
    UNAVAILABLE = 'UNAVAILABLE', 'Unavailable'

class DoctorAvailability(models.Model):
    """Date-specific real-time doctor availability status override"""
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='availabilities')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='doctor_availabilities')
    date = models.DateField()
    status = models.CharField(max_length=30, choices=DoctorAvailabilityStatus.choices, default=DoctorAvailabilityStatus.AVAILABLE)
    reason = models.CharField(max_length=255, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('doctor', 'organization', 'date')
        ordering = ['date']

    def __str__(self):
        return f"{self.doctor.name} @ {self.organization.name} on {self.date}: {self.get_status_display()}"

class ScheduleException(models.Model):
    """Specific date cancellations or substitute assignments for recurring OPD schedules"""
    affiliation = models.ForeignKey(DoctorAffiliation, on_delete=models.CASCADE, related_name='schedule_exceptions')
    exception_date = models.DateField()
    is_cancelled = models.BooleanField(default=True)
    substitute_doctor = models.ForeignKey(Doctor, on_delete=models.SET_NULL, null=True, blank=True, related_name='substitute_duties')
    reason = models.CharField(max_length=255, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('affiliation', 'exception_date')
        ordering = ['exception_date']

    def __str__(self):
        return f"Exception on {self.exception_date} for {self.affiliation}"

class AppointmentStatusHistory(models.Model):
    """Audit log of appointment lifecycle transitions"""
    appointment = models.ForeignKey(AppointmentRequest, on_delete=models.CASCADE, related_name='status_history')
    from_status = models.CharField(max_length=30)
    to_status = models.CharField(max_length=30)
    changed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Appt #{self.appointment_id}: {self.from_status} -> {self.to_status} at {self.created_at}"

class TokenStatus(models.TextChoices):
    WAITING = 'WAITING', 'Waiting in Queue'
    CALLED = 'CALLED', 'Called to OPD Room'
    IN_CONSULTATION = 'IN_CONSULTATION', 'In Consultation with Doctor'
    COMPLETED = 'COMPLETED', 'Consultation Completed'
    SKIPPED = 'SKIPPED', 'Skipped / On Hold'
    CANCELLED = 'CANCELLED', 'Cancelled / No Show'

class QueueSession(models.Model):
    """Live OPD Queue session for a doctor and room on a given day"""
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='queue_sessions')
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='queue_sessions')
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True, related_name='queue_sessions')
    schedule = models.ForeignKey(DoctorSchedule, on_delete=models.SET_NULL, null=True, blank=True)
    session_date = models.DateField(default=timezone.now)
    room_number = models.CharField(max_length=50, default='OPD Room 102')
    current_token_number = models.IntegerField(default=0)
    total_tokens_issued = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-session_date', '-started_at']

    def __str__(self):
        return f"Queue for Dr. {self.doctor.name} on {self.session_date} (Current: {self.current_token_number}/{self.total_tokens_issued})"

class QueueToken(models.Model):
    """Patient queue token record linked to live queue session and appointment"""
    queue_session = models.ForeignKey(QueueSession, on_delete=models.CASCADE, related_name='tokens')
    appointment = models.ForeignKey(AppointmentRequest, on_delete=models.SET_NULL, null=True, blank=True, related_name='queue_tokens')
    token_number = models.IntegerField()
    token_label = models.CharField(max_length=20, default='A-01')
    patient_name = models.CharField(max_length=150)
    patient_phone = models.CharField(max_length=20)
    status = models.CharField(max_length=30, choices=TokenStatus.choices, default=TokenStatus.WAITING)
    called_at = models.DateTimeField(null=True, blank=True)
    consultation_started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    clinical_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['token_number']
        unique_together = ('queue_session', 'token_number')

    def __str__(self):
        return f"Token {self.token_label} (#{self.token_number}) - {self.patient_name} [{self.get_status_display()}]"

