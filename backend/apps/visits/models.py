from django.db import models
from django.conf import settings
from django.utils import timezone
from apps.organizations.models import Organization
from apps.patients.models import Patient, CareTeam, VitalsReading

class VisitStatus(models.TextChoices):
    REQUESTED = 'REQUESTED', 'Requested by Patient / Family'
    ACCEPTED = 'ACCEPTED', 'Accepted by Hospital / Center'
    REJECTED = 'REJECTED', 'Rejected'
    TEAM_ASSIGNED = 'TEAM_ASSIGNED', 'Care Team Assigned'
    SCHEDULED = 'SCHEDULED', 'Scheduled'
    TEAM_DISPATCHED = 'TEAM_DISPATCHED', 'Team Dispatched / In Transit'
    ARRIVED = 'ARRIVED', 'Arrived at Patient Home'
    IN_PROGRESS = 'IN_PROGRESS', 'Visit In Progress'
    COMPLETED = 'COMPLETED', 'Completed'
    CANCELLED = 'CANCELLED', 'Cancelled'
    RESCHEDULED = 'RESCHEDULED', 'Rescheduled'
    # Legacy aliases
    ASSIGNED = 'Assigned', 'Assigned'
    DOCTOR_REVIEW = 'Doctor Review', 'Doctor Review'
    CLOSED = 'Closed', 'Closed'

class VisitType(models.TextChoices):
    ROUTINE_PALLIATIVE = 'ROUTINE_PALLIATIVE', 'Routine Palliative Follow-up'
    EMERGENCY_FOLLOWUP = 'EMERGENCY_FOLLOWUP', 'Emergency Acute Follow-up'
    CATHETER_CARE = 'CATHETER_CARE', 'Catheter / Stoma Care'
    WOUND_DRESSING = 'WOUND_DRESSING', 'Wound / Bedsore Dressing'
    PAIN_MANAGEMENT = 'PAIN_MANAGEMENT', 'Severe Pain Assessment & Analgesic Review'
    PHYSIOTHERAPY = 'PHYSIOTHERAPY', 'Physiotherapy & Mobility Session'
    COUNSELING = 'COUNSELING', 'Psychological & Bereavement Counseling'
    EQUIPMENT_DELIVERY = 'EQUIPMENT_DELIVERY', 'Equipment Delivery & Setup'

class VisitUrgency(models.TextChoices):
    ROUTINE = 'ROUTINE', 'Routine'
    PRIORITY = 'PRIORITY', 'Priority (Palliative Tier B)'
    URGENT = 'URGENT', 'Urgent / Same-Day'
    CRITICAL = 'CRITICAL', 'Critical Emergency'


class HomeVisitRequest(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='home_visit_requests')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='visit_requests')
    requested_by_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='home_visit_requests')
    requester_name = models.CharField(max_length=150)
    requester_phone = models.CharField(max_length=20)
    requester_relationship = models.CharField(max_length=100, default='Self / Family Member')
    visit_type = models.CharField(max_length=50, choices=VisitType.choices, default=VisitType.ROUTINE_PALLIATIVE)
    urgency = models.CharField(max_length=30, choices=VisitUrgency.choices, default=VisitUrgency.ROUTINE)
    preferred_date = models.DateField()
    preferred_time_slot = models.CharField(max_length=50, default='10:00 AM - 12:00 PM')
    reason_and_symptoms = models.TextField()
    location_address = models.TextField()
    status = models.CharField(max_length=30, default='PENDING') # PENDING, ACCEPTED, REJECTED, CONVERTED_TO_VISIT
    rejection_reason = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Request for {self.patient.name} on {self.preferred_date} ({self.status})"


class HomeVisit(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='visits')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='visits')
    visit_request = models.OneToOneField(HomeVisitRequest, on_delete=models.SET_NULL, null=True, blank=True, related_name='generated_visit')
    care_team = models.ForeignKey(CareTeam, on_delete=models.SET_NULL, null=True, blank=True, related_name='visits')
    assigned_nurse_name = models.CharField(max_length=100)
    assigned_doctor_name = models.CharField(max_length=100, blank=True, default='')
    visit_type = models.CharField(max_length=50, choices=VisitType.choices, default=VisitType.ROUTINE_PALLIATIVE)
    urgency = models.CharField(max_length=30, choices=VisitUrgency.choices, default=VisitUrgency.ROUTINE)
    scheduled_date = models.DateField()
    scheduled_time = models.CharField(max_length=50)
    status = models.CharField(max_length=50, choices=VisitStatus.choices, default=VisitStatus.SCHEDULED)
    
    # Direct Vitals Connection (Phase 2.7)
    vitals_reading = models.OneToOneField(VitalsReading, on_delete=models.SET_NULL, null=True, blank=True, related_name='home_visit')

    # GPS & Transit Tracking
    gps_check_in_time = models.CharField(max_length=100, blank=True, null=True)
    gps_location_name = models.CharField(max_length=255, blank=True, null=True)
    dispatch_timestamp = models.DateTimeField(blank=True, null=True)
    arrival_timestamp = models.DateTimeField(blank=True, null=True)
    completion_timestamp = models.DateTimeField(blank=True, null=True)

    # Structured Clinical Visit Documentation
    symptoms_observed = models.TextField(blank=True, default='')
    assessment_notes = models.TextField(blank=True, default='')
    care_provided = models.TextField(blank=True, default='')
    medication_administered = models.TextField(blank=True, default='')
    equipment_used = models.TextField(blank=True, default='')
    follow_up_instructions = models.TextField(blank=True, default='')
    next_visit_date = models.DateField(blank=True, null=True)
    clinical_notes = models.TextField(blank=True, null=True)
    voice_recording_path = models.CharField(max_length=255, blank=True, null=True)

    # Doctor Review & Sign-Off
    doctor_review_notes = models.TextField(blank=True, default='')
    doctor_signed_off = models.BooleanField(default=False)
    doctor_signoff_timestamp = models.DateTimeField(blank=True, null=True)

    is_synced_offline = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Visit for {self.patient.name} on {self.scheduled_date} ({self.status})"


class HomeVisitStatusHistory(models.Model):
    visit = models.ForeignKey(HomeVisit, on_delete=models.CASCADE, related_name='status_history')
    from_status = models.CharField(max_length=50)
    to_status = models.CharField(max_length=50)
    changed_by_username = models.CharField(max_length=150, default='system')
    notes = models.TextField(blank=True, default='')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"Visit #{self.visit.id}: {self.from_status} -> {self.to_status} by {self.changed_by_username}"


class CareTeamRoute(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='team_routes')
    care_team = models.ForeignKey(CareTeam, on_delete=models.CASCADE, related_name='routes')
    route_date = models.DateField(default=timezone.now)
    primary_nurse_name = models.CharField(max_length=150)
    status = models.CharField(max_length=30, default='PLANNED') # PLANNED, DISPATCHED, COMPLETED
    total_stops = models.IntegerField(default=0)
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Route for {self.care_team.name} on {self.route_date} ({self.status})"


class RouteStop(models.Model):
    route = models.ForeignKey(CareTeamRoute, on_delete=models.CASCADE, related_name='stops')
    visit = models.ForeignKey(HomeVisit, on_delete=models.CASCADE, related_name='route_stop')
    sequence_order = models.IntegerField(default=1)
    location_area = models.CharField(max_length=150) # e.g. Kozhikode North, Feroke, Ramanattukara
    estimated_arrival_time = models.CharField(max_length=50, default='10:00 AM')
    is_completed = models.BooleanField(default=False)

    class Meta:
        ordering = ['sequence_order']

    def __str__(self):
        return f"Stop #{self.sequence_order}: {self.visit.patient.name} ({self.location_area})"
