from django.db import models
from apps.organizations.models import Organization
from apps.patients.models import Patient

class VisitStatus(models.TextChoices):
    SCHEDULED = 'Scheduled', 'Scheduled'
    ASSIGNED = 'Assigned', 'Assigned'
    ACCEPTED = 'Accepted', 'Accepted'
    IN_PROGRESS = 'In Progress', 'In Progress'
    COMPLETED = 'Completed', 'Completed'
    DOCTOR_REVIEW = 'Doctor Review', 'Doctor Review'
    CLOSED = 'Closed', 'Closed'

class HomeVisit(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='visits')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='visits')
    assigned_nurse_name = models.CharField(max_length=100)
    scheduled_date = models.DateField()
    scheduled_time = models.CharField(max_length=50)
    status = models.CharField(max_length=50, choices=VisitStatus.choices, default=VisitStatus.SCHEDULED)
    
    # GPS Tracking
    gps_check_in_time = models.CharField(max_length=100, blank=True, null=True)
    gps_location_name = models.CharField(max_length=255, blank=True, null=True)
    
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

