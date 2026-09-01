import logging
from typing import Dict, Any, Optional, List
from django.utils import timezone
from django.db import transaction
from apps.authentication.models import User, UserRole
from apps.patients.models import (
    Patient, CarePlan, CareTeam, CareTeamMember, VitalsReading,
    PatientCareGoal, CaregiverAccess, MedicationPlan, MedicationAdministration,
    PatientAuditLog
)
from apps.visits.models import (
    HomeVisitRequest, HomeVisit, VisitStatus, VisitType, VisitUrgency,
    HomeVisitStatusHistory, CareTeamRoute, RouteStop
)
from apps.alerts.models import ClinicalAlert, AlertType, AlertSeverity, AlertStatus
from apps.alerts.services import ClinicalRulesEngine
from apps.network.events import DomainEventType, DomainEvent, EventDispatcher

logger = logging.getLogger(__name__)


class PalliativeCareEngine:
    """Core domain engine managing Palliative Care, Multi-Disciplinary Care Teams,
    Home Visit Lifecycles, Medication Adherence, and Caregiver Access Control."""

    @classmethod
    @transaction.atomic
    def request_home_visit(
        cls,
        patient_id: int,
        preferred_date,
        reason_and_symptoms: str,
        requester_name: str,
        requester_phone: str,
        requester_relationship: str = 'Family Member',
        visit_type: str = VisitType.ROUTINE_PALLIATIVE,
        urgency: str = VisitUrgency.ROUTINE,
        preferred_time_slot: str = '10:00 AM - 12:00 PM',
        location_address: str = '',
        requested_by_user: Optional[User] = None
    ) -> HomeVisitRequest:
        """Processes and logs a new home palliative visit request from patient or caregiver."""
        patient = Patient.objects.select_for_update().get(id=patient_id)
        org = patient.organization
        address = location_address or patient.address

        req = HomeVisitRequest.objects.create(
            organization=org,
            patient=patient,
            requested_by_user=requested_by_user,
            requester_name=requester_name,
            requester_phone=requester_phone,
            requester_relationship=requester_relationship,
            visit_type=visit_type,
            urgency=urgency,
            preferred_date=preferred_date,
            preferred_time_slot=preferred_time_slot,
            reason_and_symptoms=reason_and_symptoms,
            location_address=address,
            status='PENDING',
        )

        # Audit Log
        PatientAuditLog.objects.create(
            patient=patient,
            user_username=requested_by_user.username if requested_by_user else requester_name,
            user_role=getattr(requested_by_user, 'role', 'CAREGIVER'),
            organization_name=org.name,
            action='REQUEST_HOME_VISIT',
            details=f"Requested {visit_type} for {preferred_date} ({urgency}): {reason_and_symptoms[:60]}",
        )

        # Dispatch Domain Event
        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_REQUESTED,
            organization_id=org.id,
            entity_type='HomeVisitRequest',
            entity_id=req.id,
            actor_id=requested_by_user.id if requested_by_user else None,
            actor_username=requested_by_user.username if requested_by_user else requester_name,
            title=f"Home Visit Requested: {patient.name}",
            message=f"{requester_name} requested {visit_type} for {preferred_date} ({urgency}).",
            payload={
                'request_id': req.id,
                'patient_id': patient.id,
                'preferred_date': str(preferred_date),
                'urgency': urgency,
                'visit_type': visit_type,
            }
        ))

        return req

    @classmethod
    @transaction.atomic
    def accept_home_visit_request(
        cls,
        request_id: int,
        actor_user: User,
        scheduled_date=None,
        scheduled_time: str = '10:00 AM',
        assigned_nurse_name: str = '',
        care_team_id: Optional[int] = None
    ) -> HomeVisit:
        """Accepts a home visit request and generates a scheduled HomeVisit."""
        req = HomeVisitRequest.objects.select_for_update().get(id=request_id)
        patient = req.patient
        org = req.organization

        care_team = None
        if care_team_id:
            care_team = CareTeam.objects.get(id=care_team_id, organization=org)
        elif hasattr(patient, 'care_plan') and patient.care_plan.care_team:
            care_team = patient.care_plan.care_team

        nurse_name = assigned_nurse_name or (care_team.primary_nurse.username if care_team and care_team.primary_nurse else 'Assigned Nurse')
        doctor_name = care_team.lead_doctor.username if care_team and care_team.lead_doctor else (
            patient.care_plan.assigned_doctor_name if hasattr(patient, 'care_plan') else ''
        )

        date_to_schedule = scheduled_date or req.preferred_date

        visit = HomeVisit.objects.create(
            organization=org,
            patient=patient,
            visit_request=req,
            care_team=care_team,
            assigned_nurse_name=nurse_name,
            assigned_doctor_name=doctor_name,
            visit_type=req.visit_type,
            urgency=req.urgency,
            scheduled_date=date_to_schedule,
            scheduled_time=scheduled_time,
            status=VisitStatus.SCHEDULED,
        )

        req.status = 'ACCEPTED'
        req.save()

        # Status history
        HomeVisitStatusHistory.objects.create(
            visit=visit,
            from_status=VisitStatus.REQUESTED,
            to_status=VisitStatus.SCHEDULED,
            changed_by_username=actor_user.username,
            notes=f"Request #{req.id} accepted and scheduled for {date_to_schedule} at {scheduled_time}.",
        )

        # Dispatch Domain Event
        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_ACCEPTED,
            organization_id=org.id,
            entity_type='HomeVisit',
            entity_id=visit.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Home Visit Accepted for {patient.name}",
            message=f"Visit scheduled for {date_to_schedule} at {scheduled_time}. Assigned nurse: {nurse_name}.",
            payload={'visit_id': visit.id, 'patient_id': patient.id, 'date': str(date_to_schedule)}
        ))

        return visit

    @classmethod
    @transaction.atomic
    def assign_care_team(
        cls,
        visit_id: int,
        care_team_id: int,
        actor_user: User,
        assigned_nurse_name: str = '',
        assigned_doctor_name: str = ''
    ) -> HomeVisit:
        """Assigns or updates care team on a HomeVisit."""
        visit = HomeVisit.objects.select_for_update().get(id=visit_id)
        care_team = CareTeam.objects.get(id=care_team_id, organization=visit.organization)

        old_status = visit.status
        visit.care_team = care_team
        if assigned_nurse_name:
            visit.assigned_nurse_name = assigned_nurse_name
        elif care_team.primary_nurse:
            visit.assigned_nurse_name = care_team.primary_nurse.get_full_name() or care_team.primary_nurse.username

        if assigned_doctor_name:
            visit.assigned_doctor_name = assigned_doctor_name
        elif care_team.lead_doctor:
            visit.assigned_doctor_name = care_team.lead_doctor.get_full_name() or care_team.lead_doctor.username

        visit.status = VisitStatus.TEAM_ASSIGNED
        visit.save()

        HomeVisitStatusHistory.objects.create(
            visit=visit,
            from_status=old_status,
            to_status=VisitStatus.TEAM_ASSIGNED,
            changed_by_username=actor_user.username,
            notes=f"Assigned to {care_team.name} (Nurse: {visit.assigned_nurse_name}).",
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_TEAM_ASSIGNED,
            organization_id=visit.organization_id,
            entity_type='HomeVisit',
            entity_id=visit.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Care Team Assigned: {care_team.name}",
            message=f"{care_team.name} assigned to visit #{visit.id} for {visit.patient.name}.",
            payload={'visit_id': visit.id, 'care_team_id': care_team.id}
        ))

        return visit

    @classmethod
    @transaction.atomic
    def dispatch_care_team(cls, visit_id: int, actor_user: User) -> HomeVisit:
        """Dispatches care team into transit towards patient home."""
        visit = HomeVisit.objects.select_for_update().get(id=visit_id)
        old_status = visit.status
        visit.status = VisitStatus.TEAM_DISPATCHED
        visit.dispatch_timestamp = timezone.now()
        visit.save()

        HomeVisitStatusHistory.objects.create(
            visit=visit,
            from_status=old_status,
            to_status=VisitStatus.TEAM_DISPATCHED,
            changed_by_username=actor_user.username,
            notes="Care team dispatched and in transit to patient location.",
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_DISPATCHED,
            organization_id=visit.organization_id,
            entity_type='HomeVisit',
            entity_id=visit.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Care Team In Transit for {visit.patient.name}",
            message=f"Team dispatched for visit #{visit.id}.",
            payload={'visit_id': visit.id, 'dispatched_at': str(visit.dispatch_timestamp)}
        ))

        return visit

    @classmethod
    @transaction.atomic
    def record_visit_arrival(
        cls,
        visit_id: int,
        actor_user: User,
        gps_location_name: str = 'Patient Residence Coordinates',
        gps_check_in_time: str = 'GPS Verified'
    ) -> HomeVisit:
        """Records arrival of nurse/team at patient residence."""
        visit = HomeVisit.objects.select_for_update().get(id=visit_id)
        old_status = visit.status
        visit.status = VisitStatus.IN_PROGRESS
        visit.arrival_timestamp = timezone.now()
        visit.gps_location_name = gps_location_name
        visit.gps_check_in_time = gps_check_in_time
        visit.save()

        HomeVisitStatusHistory.objects.create(
            visit=visit,
            from_status=old_status,
            to_status=VisitStatus.IN_PROGRESS,
            changed_by_username=actor_user.username,
            notes=f"Arrived at location ({gps_location_name}). Clinical session in progress.",
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_ARRIVED,
            organization_id=visit.organization_id,
            entity_type='HomeVisit',
            entity_id=visit.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Care Team Arrived at {visit.patient.name}'s Residence",
            message=f"Visit in progress at {gps_location_name}.",
            payload={'visit_id': visit.id, 'arrival_time': str(visit.arrival_timestamp)}
        ))

        return visit

    @classmethod
    @transaction.atomic
    def complete_home_visit(
        cls,
        visit_id: int,
        actor_user: User,
        symptoms_observed: str = '',
        assessment_notes: str = '',
        care_provided: str = '',
        medication_administered: str = '',
        equipment_used: str = '',
        follow_up_instructions: str = '',
        clinical_notes: str = '',
        vitals_data: Optional[Dict[str, Any]] = None,
        next_visit_date=None
    ) -> HomeVisit:
        """Completes home visit clinical documentation, records vitals, and evaluates safety alerts."""
        visit = HomeVisit.objects.select_for_update().get(id=visit_id)
        patient = visit.patient
        old_status = visit.status

        # 1. Process Vitals if provided
        vitals_obj = None
        if vitals_data:
            bp = vitals_data.get('bp', '120/80')
            pulse = int(vitals_data.get('pulse', 72))
            spo2 = int(vitals_data.get('spo2', 98))
            temperature = float(vitals_data.get('temperature', 98.6))
            pain_scale = int(vitals_data.get('pain_scale', 0))
            respiratory_rate = int(vitals_data.get('respiratory_rate', 16))
            blood_sugar = vitals_data.get('blood_sugar')

            vitals_obj = VitalsReading.objects.create(
                patient=patient,
                bp=bp,
                pulse=pulse,
                spo2=spo2,
                temperature=temperature,
                pain_scale=pain_scale,
                respiratory_rate=respiratory_rate,
                blood_sugar=int(blood_sugar) if blood_sugar is not None else None,
                recorded_by=actor_user.username,
            )
            visit.vitals_reading = vitals_obj

            # Evaluate clinical safety rules
            try:
                ClinicalRulesEngine.evaluate_vitals(vitals_obj)
            except Exception as e:
                logger.error(f"Error evaluating clinical rules on visit vitals: {e}")

        # 2. Update Visit fields
        visit.status = VisitStatus.COMPLETED
        visit.completion_timestamp = timezone.now()
        visit.symptoms_observed = symptoms_observed or visit.symptoms_observed
        visit.assessment_notes = assessment_notes or visit.assessment_notes
        visit.care_provided = care_provided or visit.care_provided
        visit.medication_administered = medication_administered or visit.medication_administered
        visit.equipment_used = equipment_used or visit.equipment_used
        visit.follow_up_instructions = follow_up_instructions or visit.follow_up_instructions
        visit.clinical_notes = clinical_notes or visit.clinical_notes
        if next_visit_date:
            visit.next_visit_date = next_visit_date
        visit.save()

        # 3. Status History
        HomeVisitStatusHistory.objects.create(
            visit=visit,
            from_status=old_status,
            to_status=VisitStatus.COMPLETED,
            changed_by_username=actor_user.username,
            notes="Clinical visit completed and documented.",
        )

        # 4. Audit Log
        PatientAuditLog.objects.create(
            patient=patient,
            user_username=actor_user.username,
            user_role=getattr(actor_user, 'role', ''),
            organization_name=visit.organization.name,
            action='COMPLETE_HOME_VISIT',
            details=f"Completed visit #{visit.id}: {care_provided[:80]}",
        )

        # 5. Dispatch Event
        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_COMPLETED,
            organization_id=visit.organization_id,
            entity_type='HomeVisit',
            entity_id=visit.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Home Visit Completed: {patient.name}",
            message=f"Visit #{visit.id} successfully completed by {actor_user.username}.",
            payload={'visit_id': visit.id, 'patient_id': patient.id, 'has_vitals': vitals_obj is not None}
        ))

        return visit

    @classmethod
    @transaction.atomic
    def cancel_home_visit(cls, visit_id: int, actor_user: User, reason: str = 'Patient Unavailable') -> HomeVisit:
        """Cancels a scheduled or requested home visit."""
        visit = HomeVisit.objects.select_for_update().get(id=visit_id)
        old_status = visit.status
        visit.status = VisitStatus.CANCELLED
        visit.clinical_notes = f"[CANCELLED]: {reason}\n{visit.clinical_notes or ''}"
        visit.save()

        HomeVisitStatusHistory.objects.create(
            visit=visit,
            from_status=old_status,
            to_status=VisitStatus.CANCELLED,
            changed_by_username=actor_user.username,
            notes=f"Visit cancelled: {reason}",
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.HOME_VISIT_CANCELLED,
            organization_id=visit.organization_id,
            entity_type='HomeVisit',
            entity_id=visit.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Home Visit Cancelled: {visit.patient.name}",
            message=f"Visit #{visit.id} was cancelled. Reason: {reason}.",
            payload={'visit_id': visit.id, 'reason': reason}
        ))

        return visit

    @classmethod
    @transaction.atomic
    def record_medication_intake(
        cls,
        medication_plan_id: int,
        time_slot: str,
        status: str = 'TAKEN',
        actor_user: Optional[User] = None,
        is_nurse_verified: bool = False,
        notes: str = ''
    ) -> MedicationAdministration:
        """Records a medication administration dose (patient-reported or nurse-verified)."""
        plan = MedicationPlan.objects.get(id=medication_plan_id)
        patient = plan.patient

        log = MedicationAdministration.objects.create(
            medication_plan=plan,
            patient=patient,
            scheduled_date=timezone.now().date(),
            time_slot=time_slot,
            status=status,
            recorded_by_caregiver=not is_nurse_verified,
            verified_by_nurse=is_nurse_verified,
            verified_nurse_name=actor_user.username if (is_nurse_verified and actor_user) else '',
            notes=notes,
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.MEDICATION_LOGGED,
            organization_id=patient.organization_id,
            entity_type='MedicationAdministration',
            entity_id=log.id,
            actor_id=actor_user.id if actor_user else None,
            actor_username=actor_user.username if actor_user else 'Caregiver',
            title=f"Medication Logged: {plan.medicine_name}",
            message=f"Status: {status} ({time_slot}) for {patient.name}.",
            payload={'medication': plan.medicine_name, 'status': status, 'slot': time_slot}
        ))

        return log

    @classmethod
    @transaction.atomic
    def grant_caregiver_access(
        cls,
        patient_id: int,
        caregiver_name: str,
        caregiver_phone: str,
        permissions: List[str],
        actor_user: User,
        relationship: str = 'Family Member',
        caregiver_user: Optional[User] = None
    ) -> CaregiverAccess:
        """Grants explicit, granular permission consent to a family caregiver."""
        patient = Patient.objects.get(id=patient_id)
        grant, created = CaregiverAccess.objects.update_or_create(
            patient=patient,
            caregiver_phone=caregiver_phone,
            defaults={
                'user': caregiver_user,
                'caregiver_name': caregiver_name,
                'relationship': relationship,
                'permissions': permissions,
                'is_active': True,
                'granted_by': actor_user.username,
            }
        )

        PatientAuditLog.objects.create(
            patient=patient,
            user_username=actor_user.username,
            user_role=getattr(actor_user, 'role', ''),
            organization_name=patient.organization.name,
            action='GRANT_CAREGIVER_ACCESS',
            details=f"Granted permissions {permissions} to {caregiver_name} ({caregiver_phone})",
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.CAREGIVER_ACCESS_GRANTED,
            organization_id=patient.organization_id,
            entity_type='CaregiverAccess',
            entity_id=grant.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"Caregiver Access Granted: {caregiver_name}",
            message=f"Permissions: {', '.join(permissions)} on {patient.name}.",
            payload={'grant_id': grant.id, 'permissions': permissions}
        ))

        return grant

    @classmethod
    def evaluate_palliative_emergency_escalation(
        cls,
        patient_id: int,
        alert_reason: str,
        actor_user: User,
        vital_reading: Optional[VitalsReading] = None
    ) -> ClinicalAlert:
        """Surfaces a high-urgency clinical warning and alerts the care team without automated medical diagnosis."""
        patient = Patient.objects.get(id=patient_id)
        org = patient.organization

        alert = ClinicalAlert.objects.create(
            organization=org,
            patient=patient,
            alert_type=AlertType.VITAL_ABNORMAL,
            severity=AlertSeverity.CRITICAL,
            title=f"PALLIATIVE EMERGENCY: Urgent Review Needed for {patient.name}",
            message=f"Escalated by {actor_user.username}: {alert_reason}",
            metadata={
                'bp': vital_reading.bp if vital_reading else 'N/A',
                'spo2': vital_reading.spo2 if vital_reading else 'N/A',
                'escalated_by': actor_user.username,
            }
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.PALLIATIVE_EMERGENCY_ESCALATED,
            organization_id=org.id,
            entity_type='ClinicalAlert',
            entity_id=alert.id,
            actor_id=actor_user.id,
            actor_username=actor_user.username,
            title=f"CRITICAL ESCALATION: {patient.name}",
            message=alert_reason,
            payload={'alert_id': alert.id, 'patient_id': patient.id}
        ))

        return alert
