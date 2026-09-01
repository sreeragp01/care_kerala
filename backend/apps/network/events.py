import logging
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, Optional
from django.utils import timezone
from django.conf import settings

logger = logging.getLogger(__name__)


class DomainEventType:
    # Appointment Lifecycle Events
    APPOINTMENT_REQUESTED = 'APPOINTMENT_REQUESTED'
    APPOINTMENT_ACCEPTED = 'APPOINTMENT_ACCEPTED'
    APPOINTMENT_REJECTED = 'APPOINTMENT_REJECTED'
    APPOINTMENT_CONFIRMED = 'APPOINTMENT_CONFIRMED'
    APPOINTMENT_RESCHEDULED = 'APPOINTMENT_RESCHEDULED'
    APPOINTMENT_CANCELLED = 'APPOINTMENT_CANCELLED'
    APPOINTMENT_CHECKED_IN = 'APPOINTMENT_CHECKED_IN'
    APPOINTMENT_NO_SHOW = 'APPOINTMENT_NO_SHOW'
    APPOINTMENT_COMPLETED = 'APPOINTMENT_COMPLETED'

    # Doctor Schedule & Availability Events
    DOCTOR_LEAVE_MARKED = 'DOCTOR_LEAVE_MARKED'
    DOCTOR_UNAVAILABLE = 'DOCTOR_UNAVAILABLE'
    SCHEDULE_EXCEPTION_CREATED = 'SCHEDULE_EXCEPTION_CREATED'
    DOCTOR_RESCHEDULE_RESOLVED = 'DOCTOR_RESCHEDULE_RESOLVED'

    # OPD & Multi-Queue Events
    QUEUE_SESSION_STARTED = 'QUEUE_SESSION_STARTED'
    QUEUE_SESSION_PAUSED = 'QUEUE_SESSION_PAUSED'
    QUEUE_SESSION_RESUMED = 'QUEUE_SESSION_RESUMED'
    QUEUE_TOKEN_ISSUED = 'QUEUE_TOKEN_ISSUED'
    QUEUE_TOKEN_CALLED = 'QUEUE_TOKEN_CALLED'
    QUEUE_TOKEN_RECALLED = 'QUEUE_TOKEN_RECALLED'
    QUEUE_TOKEN_SKIPPED = 'QUEUE_TOKEN_SKIPPED'
    CONSULTATION_STARTED = 'CONSULTATION_STARTED'
    CONSULTATION_COMPLETED = 'CONSULTATION_COMPLETED'
    DIGITAL_CHECK_IN_COMPLETED = 'DIGITAL_CHECK_IN_COMPLETED'
    QUEUE_PROXIMITY_ALERT = 'QUEUE_PROXIMITY_ALERT'
    PRIORITY_TRIAGE_ASSIGNED = 'PRIORITY_TRIAGE_ASSIGNED'

    # Palliative & Home Healthcare Events (Phase 2.7)
    HOME_VISIT_REQUESTED = 'HOME_VISIT_REQUESTED'
    HOME_VISIT_ACCEPTED = 'HOME_VISIT_ACCEPTED'
    HOME_VISIT_REJECTED = 'HOME_VISIT_REJECTED'
    HOME_VISIT_TEAM_ASSIGNED = 'HOME_VISIT_TEAM_ASSIGNED'
    HOME_VISIT_SCHEDULED = 'HOME_VISIT_SCHEDULED'
    HOME_VISIT_DISPATCHED = 'HOME_VISIT_DISPATCHED'
    HOME_VISIT_ARRIVED = 'HOME_VISIT_ARRIVED'
    HOME_VISIT_IN_PROGRESS = 'HOME_VISIT_IN_PROGRESS'
    HOME_VISIT_COMPLETED = 'HOME_VISIT_COMPLETED'
    HOME_VISIT_CANCELLED = 'HOME_VISIT_CANCELLED'
    CARE_PLAN_UPDATED = 'CARE_PLAN_UPDATED'
    CARE_TEAM_ASSIGNED = 'CARE_TEAM_ASSIGNED'
    CAREGIVER_ACCESS_GRANTED = 'CAREGIVER_ACCESS_GRANTED'
    CAREGIVER_ACCESS_REVOKED = 'CAREGIVER_ACCESS_REVOKED'
    MEDICATION_LOGGED = 'MEDICATION_LOGGED'
    PALLIATIVE_EMERGENCY_ESCALATED = 'PALLIATIVE_EMERGENCY_ESCALATED'


@dataclass
class DomainEvent:
    event_type: str
    organization_id: int
    entity_type: str
    entity_id: int
    actor_id: Optional[int] = None
    actor_username: str = 'system'
    title: str = ''
    message: str = ''
    payload: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=timezone.now)


class EventDispatcher:
    """Centralized domain event bus connecting domain events to audit logs, notifications, and analytics."""

    @classmethod
    def dispatch(cls, event: DomainEvent):
        logger.info(f"[DOMAIN EVENT] {event.event_type} on {event.entity_type} #{event.entity_id} by {event.actor_username}")

        # 1. Persist Event into DomainEventLog for central auditing
        from .models import DomainEventLog
        try:
            DomainEventLog.objects.create(
                event_type=event.event_type,
                organization_id=event.organization_id,
                entity_type=event.entity_type,
                entity_id=event.entity_id,
                actor_id=event.actor_id,
                actor_username=event.actor_username,
                title=event.title or event.event_type.replace('_', ' ').title(),
                message=event.message,
                payload=event.payload,
            )
        except Exception as e:
            logger.error(f"Failed to record DomainEventLog: {e}")

        # 2. Trigger FCM & In-App Notification Pipeline if applicable
        cls._trigger_notifications(event)

        # 3. Trigger Analytics telemetry update
        cls._update_analytics(event)

    @classmethod
    def _trigger_notifications(cls, event: DomainEvent):
        """Simulate FCM push notification dispatch & in-app alerts to patients/staff."""
        try:
            from apps.alerts.models import UserDevice
            # If notification is for staff of the organization
            if event.organization_id:
                devices = UserDevice.objects.filter(organization_id=event.organization_id, is_active=True)
                for dev in devices:
                    logger.info(
                        f"[FCM PUSH] Device {dev.device_id} (User {dev.user_id}): {event.title} - {event.message}"
                    )
        except Exception as e:
            logger.debug(f"Notification dispatch notice: {e}")

    @classmethod
    def _update_analytics(cls, event: DomainEvent):
        """Real-time metrics counter update."""
        logger.debug(f"[ANALYTICS] Updated metrics stream for {event.event_type} (Org: {event.organization_id})")
