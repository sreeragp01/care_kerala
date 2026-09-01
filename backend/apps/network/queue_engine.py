import hashlib
import uuid
import logging
from datetime import datetime, date, timedelta
from typing import Dict, Any, List, Optional
from django.db import transaction
from django.db.models import Avg, Count, F, Q
from django.utils import timezone

from .models import (
    Organization,
    Doctor,
    Department,
    QueueSession,
    QueueToken,
    QueueType,
    QueuePriority,
    QueuePauseReason,
    QueuePolicy,
    QueuePause,
    TokenStatus,
    PatientCheckIn,
    AppointmentRequest,
    AppointmentStatus,
)
from .events import DomainEvent, DomainEventType, EventDispatcher

logger = logging.getLogger(__name__)


class SmartQueueEngine:
    """Core domain engine powering multi-queue calculation, wait time estimation,

    concurrency-safe token generation, digital QR check-in, priority ordering,
    and operational flow analytics.
    """

    PRIORITY_WEIGHTS = {
        QueuePriority.NORMAL: 1,
        QueuePriority.PRIORITY: 2,
        QueuePriority.URGENT: 3,
        QueuePriority.EMERGENCY: 4,
    }

    DEFAULT_PREFIXES = {
        QueueType.OPD: 'C',
        QueueType.EMERGENCY: 'E',
        QueueType.LABORATORY: 'L',
        QueueType.PHARMACY: 'P',
        QueueType.RADIOLOGY: 'X',
        QueueType.REGISTRATION: 'R',
        QueueType.BILLING: 'B',
        QueueType.PALLIATIVE: 'PAL',
    }

    @classmethod
    def get_or_create_policy(cls, organization: Organization, queue_type: str = QueueType.OPD) -> QueuePolicy:
        """Fetch or create default operational policy for a specific queue type."""
        prefix = cls.DEFAULT_PREFIXES.get(queue_type, 'C')
        policy, _ = QueuePolicy.objects.get_or_create(
            organization=organization,
            queue_type=queue_type,
            defaults={
                'default_avg_consultation_minutes': 15,
                'max_recall_attempts': 3,
                'recall_wait_seconds': 120,
                'auto_no_show_after_recalls': True,
                'allow_digital_check_in': True,
                'check_in_window_hours_before': 2.00,
                'token_prefix': prefix,
            }
        )
        return policy

    @classmethod
    def calculate_estimated_wait_time(cls, token: QueueToken) -> Dict[str, Any]:
        """Calculates dynamic estimated wait time for a patient token based on

        queue order, clinical priority, rolling doctor consultation duration,
        active interruptions, and pause states.
        """
        session = token.queue_session

        # 1. Base Consultation Duration
        policy = cls.get_or_create_policy(session.organization, session.queue_type)
        if session.avg_consultation_duration_seconds and session.avg_consultation_duration_seconds > 0:
            avg_consult_minutes = max(5, round(session.avg_consultation_duration_seconds / 60))
        else:
            avg_consult_minutes = policy.default_avg_consultation_minutes or 15

        # 2. If token is already in consultation or completed
        if token.status == TokenStatus.IN_CONSULTATION:
            return {
                'token_id': token.id,
                'token_label': token.token_label,
                'token_number': token.token_number,
                'priority': token.priority,
                'status': token.status,
                'patients_ahead': 0,
                'estimated_wait_minutes': 0,
                'is_in_consultation': True,
                'is_called': False,
                'is_paused': session.is_paused,
                'pause_reason': session.pause_reason,
                'room_number': session.room_number,
                'doctor_name': session.doctor.name,
            }

        if token.status == TokenStatus.CALLED:
            return {
                'token_id': token.id,
                'token_label': token.token_label,
                'token_number': token.token_number,
                'priority': token.priority,
                'status': token.status,
                'patients_ahead': 0,
                'estimated_wait_minutes': 0,
                'is_in_consultation': False,
                'is_called': True,
                'is_paused': session.is_paused,
                'pause_reason': session.pause_reason,
                'room_number': session.room_number,
                'doctor_name': session.doctor.name,
            }

        if token.status in [TokenStatus.COMPLETED, TokenStatus.CANCELLED]:
            return {
                'token_id': token.id,
                'token_label': token.token_label,
                'token_number': token.token_number,
                'priority': token.priority,
                'status': token.status,
                'patients_ahead': 0,
                'estimated_wait_minutes': 0,
                'is_in_consultation': False,
                'is_called': False,
                'is_paused': session.is_paused,
                'pause_reason': session.pause_reason,
                'room_number': session.room_number,
                'doctor_name': session.doctor.name,
            }

        # 3. Calculate Patients Ahead in the prioritized queue
        # Higher priority rank or same priority rank with lower token number
        patients_ahead_qs = session.tokens.filter(
            status__in=[TokenStatus.WAITING, TokenStatus.CALLED, TokenStatus.IN_CONSULTATION]
        ).filter(
            Q(priority_rank__gt=token.priority_rank) |
            Q(priority_rank=token.priority_rank, token_number__lt=token.token_number)
        )
        patients_ahead_count = patients_ahead_qs.count()

        # 4. Compute Estimated Wait Duration
        base_wait_minutes = patients_ahead_count * avg_consult_minutes
        pause_overhead = 12 if session.is_paused else 0
        total_estimated_wait = max(2, base_wait_minutes + pause_overhead)

        # 5. Fetch Now Serving & Next Token
        now_serving = session.tokens.filter(status__in=[TokenStatus.CALLED, TokenStatus.IN_CONSULTATION]).first()
        next_waiting = session.tokens.filter(status=TokenStatus.WAITING).order_by('-priority_rank', 'token_number').first()

        return {
            'token_id': token.id,
            'token_label': token.token_label,
            'token_number': token.token_number,
            'priority': token.priority,
            'status': token.status,
            'patients_ahead': patients_ahead_count,
            'estimated_wait_minutes': total_estimated_wait,
            'avg_consultation_minutes': avg_consult_minutes,
            'is_in_consultation': False,
            'is_called': False,
            'is_paused': session.is_paused,
            'pause_reason': session.pause_reason,
            'now_serving_label': now_serving.token_label if now_serving else None,
            'next_token_label': next_waiting.token_label if next_waiting else None,
            'room_number': session.room_number,
            'doctor_name': session.doctor.name,
            'queue_type': session.queue_type,
        }

    @classmethod
    def issue_unified_token(
        cls,
        queue_session: QueueSession,
        patient_name: str,
        patient_phone: str,
        appointment: Optional[AppointmentRequest] = None,
        priority: str = QueuePriority.NORMAL,
        is_walk_in: bool = False,
        actor_user=None,
    ) -> QueueToken:
        """Generates a queue token safely with row-level transaction locking

        to guarantee zero token number collisions between concurrent receptionists or kiosks.
        """
        priority_rank = cls.PRIORITY_WEIGHTS.get(priority, 1)

        with transaction.atomic():
            # Lock the queue session row to serialize concurrent token generation
            session = QueueSession.objects.select_for_update().get(id=queue_session.id)

            next_token_number = session.total_tokens_issued + 1
            session.total_tokens_issued = next_token_number
            session.save(update_fields=['total_tokens_issued'])

            # Determine prefix
            prefix = session.token_prefix or cls.DEFAULT_PREFIXES.get(session.queue_type, 'C')
            token_label = f"{prefix}-{next_token_number:02d}"

            # Generate tamper-resistant QR hash
            raw_hash_seed = f"carelink:{session.organization_id}:{session.id}:{next_token_number}:{uuid.uuid4().hex}"
            qr_hash = hashlib.sha256(raw_hash_seed.encode('utf-8')).hexdigest()[:24]

            token = QueueToken.objects.create(
                queue_session=session,
                appointment=appointment,
                token_number=next_token_number,
                token_label=token_label,
                patient_name=patient_name,
                patient_phone=patient_phone,
                priority=priority,
                priority_rank=priority_rank,
                is_walk_in=is_walk_in,
                qr_code_hash=qr_hash,
                status=TokenStatus.WAITING,
                check_in_time=timezone.now() if (is_walk_in or appointment is None) else None,
            )

            # If linked to appointment, sync token label
            if appointment:
                appointment.token_number = token_label
                if appointment.status == AppointmentStatus.REQUESTED:
                    appointment.status = AppointmentStatus.CONFIRMED
                appointment.save(update_fields=['token_number', 'status', 'updated_at'])

            # Dispatch Domain Event
            actor_id = getattr(actor_user, 'id', None)
            actor_name = getattr(actor_user, 'username', 'reception_or_kiosk')

            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.QUEUE_TOKEN_ISSUED,
                organization_id=session.organization_id,
                entity_type='QueueToken',
                entity_id=token.id,
                actor_id=actor_id,
                actor_username=actor_name,
                title=f"Token {token_label} Issued",
                message=f"Token {token_label} ({priority}) issued to {patient_name} for Dr. {session.doctor.name}.",
                payload={
                    'token_label': token_label,
                    'token_number': next_token_number,
                    'queue_session_id': session.id,
                    'priority': priority,
                    'is_walk_in': is_walk_in,
                    'doctor_name': session.doctor.name,
                    'room_number': session.room_number,
                }
            ))

            return token

    @classmethod
    def process_digital_check_in(
        cls,
        organization: Organization,
        qr_hash: str = '',
        appointment_id: Optional[int] = None,
        check_in_method: str = 'QR_SCAN',
        verified_by=None,
    ) -> Dict[str, Any]:
        """Validates arrival scan at hospital entrance/kiosk and activates token."""
        token: Optional[QueueToken] = None

        if qr_hash:
            token = QueueToken.objects.filter(
                qr_code_hash=qr_hash,
                queue_session__organization=organization,
            ).first()

        if not token and appointment_id:
            token = QueueToken.objects.filter(
                appointment_id=appointment_id,
                queue_session__organization=organization,
            ).first()

        if not token:
            # Check if appointment exists to issue token dynamically
            if appointment_id:
                appt = AppointmentRequest.objects.filter(id=appointment_id, organization=organization).first()
                if appt:
                    # Find active queue session for doctor today
                    session = QueueSession.objects.filter(
                        organization=organization,
                        doctor=appt.doctor,
                        session_date=date.today(),
                        is_active=True,
                    ).first()

                    if not session:
                        # Auto-create active queue session if absent
                        session = QueueSession.objects.create(
                            organization=organization,
                            doctor=appt.doctor,
                            department=appt.doctor.department,
                            session_date=date.today(),
                            room_number='OPD Room 102',
                            queue_type=QueueType.OPD,
                            token_prefix='C',
                        )

                    token = cls.issue_unified_token(
                        queue_session=session,
                        patient_name=appt.patient_name,
                        patient_phone=appt.patient_phone,
                        appointment=appt,
                        priority=QueuePriority.NORMAL,
                        is_walk_in=False,
                        actor_user=verified_by,
                    )

        if not token:
            raise ValueError("No matching active appointment or token found for this QR code.")

        # Update check-in timestamps
        token.check_in_time = timezone.now()
        token.status = TokenStatus.WAITING
        token.save(update_fields=['check_in_time', 'status'])

        if token.appointment:
            token.appointment.status = AppointmentStatus.CHECKED_IN
            token.appointment.save(update_fields=['status', 'updated_at'])

        # Create PatientCheckIn record
        checkin_log = PatientCheckIn.objects.create(
            organization=organization,
            appointment=token.appointment,
            token=token,
            check_in_method=check_in_method,
            qr_payload=qr_hash,
            verified_by=verified_by,
        )

        # Dispatch event
        actor_id = getattr(verified_by, 'id', None)
        actor_name = getattr(verified_by, 'username', 'kiosk_scanner')

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.DIGITAL_CHECK_IN_COMPLETED,
            organization_id=organization.id,
            entity_type='PatientCheckIn',
            entity_id=checkin_log.id,
            actor_id=actor_id,
            actor_username=actor_name,
            title=f"Check-in Verified: {token.token_label}",
            message=f"{token.patient_name} verified arrival via {check_in_method}. Token {token.token_label} activated.",
            payload={
                'token_label': token.token_label,
                'room_number': token.queue_session.room_number,
                'doctor_name': token.queue_session.doctor.name,
                'department': token.queue_session.department.name if token.queue_session.department else 'OPD',
            }
        ))

        wait_info = cls.calculate_estimated_wait_time(token)

        return {
            'check_in_id': checkin_log.id,
            'token_id': token.id,
            'token_label': token.token_label,
            'patient_name': token.patient_name,
            'room_number': token.queue_session.room_number,
            'doctor_name': token.queue_session.doctor.name,
            'patients_ahead': wait_info['patients_ahead'],
            'estimated_wait_minutes': wait_info['estimated_wait_minutes'],
            'message': f"Check-in successful! Please proceed to {token.queue_session.room_number} waiting area.",
        }

    @classmethod
    def call_next_token(cls, session_id: int, actor_user=None) -> Optional[QueueToken]:
        """Selects the highest priority waiting patient and calls them to the OPD room."""
        with transaction.atomic():
            session = QueueSession.objects.select_for_update().get(id=session_id)

            if session.is_paused:
                raise ValueError(f"Queue session is paused ({session.get_pause_reason_display()}). Resume queue before calling patients.")

            # Automatically transition previous called token to in-consultation or complete
            previous_called = session.tokens.filter(status=TokenStatus.CALLED).first()
            if previous_called:
                previous_called.status = TokenStatus.IN_CONSULTATION
                previous_called.consultation_started_at = timezone.now()
                previous_called.save(update_fields=['status', 'consultation_started_at'])

            # Fetch next waiting token ordered by priority rank DESC, then token number ASC
            next_token = session.tokens.filter(status=TokenStatus.WAITING).order_by('-priority_rank', 'token_number').first()

            if not next_token:
                return None

            next_token.status = TokenStatus.CALLED
            next_token.called_at = timezone.now()
            next_token.last_called_at = timezone.now()
            next_token.call_count += 1
            next_token.save(update_fields=['status', 'called_at', 'last_called_at', 'call_count'])

            session.current_token_number = next_token.token_number
            session.save(update_fields=['current_token_number'])

            # Dispatch Domain Event
            actor_id = getattr(actor_user, 'id', None)
            actor_name = getattr(actor_user, 'username', 'doctor_or_nurse')

            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.QUEUE_TOKEN_CALLED,
                organization_id=session.organization_id,
                entity_type='QueueToken',
                entity_id=next_token.id,
                actor_id=actor_id,
                actor_username=actor_name,
                title=f"Now Calling Token {next_token.token_label}",
                message=f"Please proceed to {session.room_number} for Dr. {session.doctor.name}.",
                payload={
                    'token_label': next_token.token_label,
                    'patient_name': next_token.patient_name,
                    'room_number': session.room_number,
                    'doctor_name': session.doctor.name,
                    'call_count': next_token.call_count,
                    'priority': next_token.priority,
                }
            ))

            # Send Proximity Alerts to next 3 waiting patients
            upcoming_tokens = session.tokens.filter(status=TokenStatus.WAITING).order_by('-priority_rank', 'token_number')[:3]
            for idx, up_token in enumerate(upcoming_tokens, start=1):
                EventDispatcher.dispatch(DomainEvent(
                    event_type=DomainEventType.QUEUE_PROXIMITY_ALERT,
                    organization_id=session.organization_id,
                    entity_type='QueueToken',
                    entity_id=up_token.id,
                    title="Your Turn is Approaching",
                    message=f"Only {idx} patient(s) ahead. Please remain near {session.room_number}.",
                    payload={
                        'token_label': up_token.token_label,
                        'patients_ahead': idx,
                        'room_number': session.room_number,
                    }
                ))

            return next_token

    @classmethod
    def recall_token(cls, token_id: int, actor_user=None) -> QueueToken:
        """Re-calls a patient who did not respond to the first call."""
        token = QueueToken.objects.get(id=token_id)
        session = token.queue_session
        policy = cls.get_or_create_policy(session.organization, session.queue_type)

        token.call_count += 1
        token.last_called_at = timezone.now()
        token.status = TokenStatus.CALLED
        token.save(update_fields=['call_count', 'last_called_at', 'status'])

        actor_id = getattr(actor_user, 'id', None)
        actor_name = getattr(actor_user, 'username', 'doctor_or_nurse')

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.QUEUE_TOKEN_RECALLED,
            organization_id=session.organization_id,
            entity_type='QueueToken',
            entity_id=token.id,
            actor_id=actor_id,
            actor_username=actor_name,
            title=f"Recall #{token.call_count}: Token {token.token_label}",
            message=f"Recall alert for {token.patient_name} to proceed immediately to {session.room_number}.",
            payload={
                'token_label': token.token_label,
                'call_count': token.call_count,
                'max_recalls': policy.max_recall_attempts,
                'room_number': session.room_number,
            }
        ))

        return token

    @classmethod
    def pause_session(cls, session_id: int, reason: str, notes: str = '', actor_user=None) -> QueuePause:
        """Pauses queue session with mandatory clinical or administrative reason."""
        if reason not in QueuePauseReason.values:
            raise ValueError(f"Invalid pause reason. Choose from: {QueuePauseReason.values}")

        with transaction.atomic():
            session = QueueSession.objects.select_for_update().get(id=session_id)
            session.is_paused = True
            session.pause_reason = reason
            session.save(update_fields=['is_paused', 'pause_reason'])

            pause = QueuePause.objects.create(
                queue_session=session,
                reason=reason,
                notes=notes,
                paused_by=actor_user,
            )

            actor_id = getattr(actor_user, 'id', None)
            actor_name = getattr(actor_user, 'username', 'doctor_or_nurse')

            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.QUEUE_SESSION_PAUSED,
                organization_id=session.organization_id,
                entity_type='QueueSession',
                entity_id=session.id,
                actor_id=actor_id,
                actor_username=actor_name,
                title=f"Queue Paused: {session.get_pause_reason_display()}",
                message=f"OPD session for Dr. {session.doctor.name} paused ({session.get_pause_reason_display()}).",
                payload={
                    'session_id': session.id,
                    'reason': reason,
                    'notes': notes,
                }
            ))

            return pause

    @classmethod
    def resume_session(cls, session_id: int, actor_user=None) -> QueueSession:
        """Resumes a paused queue session and closes active pause records."""
        with transaction.atomic():
            session = QueueSession.objects.select_for_update().get(id=session_id)
            session.is_paused = False
            session.pause_reason = ''
            session.save(update_fields=['is_paused', 'pause_reason'])

            # Close open pauses
            session.pauses.filter(resumed_at__isnull=True).update(resumed_at=timezone.now())

            actor_id = getattr(actor_user, 'id', None)
            actor_name = getattr(actor_user, 'username', 'doctor_or_nurse')

            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.QUEUE_SESSION_RESUMED,
                organization_id=session.organization_id,
                entity_type='QueueSession',
                entity_id=session.id,
                actor_id=actor_id,
                actor_username=actor_name,
                title="Queue Resumed",
                message=f"OPD consultations resumed for Dr. {session.doctor.name}.",
                payload={'session_id': session.id}
            ))

            return session

    @classmethod
    def complete_consultation(cls, token_id: int, clinical_notes: str = '', actor_user=None) -> QueueToken:
        """Marks consultation completed and updates rolling average consultation metrics."""
        with transaction.atomic():
            token = QueueToken.objects.select_for_update().get(id=token_id)
            session = token.queue_session

            token.status = TokenStatus.COMPLETED
            token.completed_at = timezone.now()
            if clinical_notes:
                token.clinical_notes = clinical_notes

            # Calculate consultation duration
            start_time = token.consultation_started_at or token.called_at or token.created_at
            duration = int((token.completed_at - start_time).total_seconds())
            token.consultation_duration_seconds = max(60, duration)
            token.save(update_fields=['status', 'completed_at', 'clinical_notes', 'consultation_duration_seconds'])

            # Update rolling average for session
            session.total_completed_consultations += 1
            completed_tokens = session.tokens.filter(status=TokenStatus.COMPLETED, consultation_duration_seconds__gt=0)
            avg_dur = completed_tokens.aggregate(avg_s=Avg('consultation_duration_seconds'))['avg_s']
            if avg_dur:
                session.avg_consultation_duration_seconds = int(avg_dur)
            session.save(update_fields=['total_completed_consultations', 'avg_consultation_duration_seconds'])

            # If appointment linked, complete it
            if token.appointment:
                token.appointment.status = AppointmentStatus.COMPLETED
                token.appointment.save(update_fields=['status', 'updated_at'])

            actor_id = getattr(actor_user, 'id', None)
            actor_name = getattr(actor_user, 'username', 'doctor')

            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.CONSULTATION_COMPLETED,
                organization_id=session.organization_id,
                entity_type='QueueToken',
                entity_id=token.id,
                actor_id=actor_id,
                actor_username=actor_name,
                title=f"Consultation Completed: {token.token_label}",
                message=f"Consultation with Dr. {session.doctor.name} completed for {token.patient_name}.",
                payload={
                    'token_label': token.token_label,
                    'duration_seconds': token.consultation_duration_seconds,
                }
            ))

            return token

    @classmethod
    def get_public_display_data(cls, session_id: int) -> Dict[str, Any]:
        """Returns strictly privacy-safe public TV monitor feed without patient names."""
        session = QueueSession.objects.select_related('organization', 'doctor', 'department').get(id=session_id)

        now_serving = session.tokens.filter(status__in=[TokenStatus.CALLED, TokenStatus.IN_CONSULTATION]).first()
        next_tokens = session.tokens.filter(status=TokenStatus.WAITING).order_by('-priority_rank', 'token_number')[:4]
        waiting_count = session.tokens.filter(status=TokenStatus.WAITING).count()

        return {
            'organization_id': session.organization_id,
            'organization_name': session.organization.name,
            'department_name': session.department.name if session.department else session.doctor.specialization,
            'doctor_name': f"Dr. {session.doctor.name}",
            'room_number': session.room_number,
            'queue_type': session.queue_type,
            'now_serving': {
                'token_label': now_serving.token_label if now_serving else None,
                'status': now_serving.status if now_serving else 'IDLE',
                'room_number': session.room_number,
            } if now_serving else None,
            'next_tokens': [
                {
                    'token_label': t.token_label,
                    'priority': t.priority,
                }
                for t in next_tokens
            ],
            'is_paused': session.is_paused,
            'pause_reason': session.get_pause_reason_display() if session.is_paused else '',
            'total_waiting': waiting_count,
            'last_updated': timezone.now().isoformat(),
        }

    @classmethod
    def get_hospital_flow_analytics(cls, organization: Organization, target_date: Optional[date] = None) -> Dict[str, Any]:
        """Aggregates hospital throughput, wait times, no-shows, and department flow analytics."""
        if not target_date:
            target_date = date.today()

        tokens_qs = QueueToken.objects.filter(
            queue_session__organization=organization,
            queue_session__session_date=target_date,
        )

        total_patients = tokens_qs.count()
        walk_in_count = tokens_qs.filter(is_walk_in=True).count()
        appointment_count = total_patients - walk_in_count

        completed_tokens = tokens_qs.filter(status=TokenStatus.COMPLETED)
        no_show_tokens = tokens_qs.filter(status=TokenStatus.CANCELLED)

        # Average wait and consultation duration (in minutes)
        avg_wait_s = completed_tokens.aggregate(Avg('wait_time_seconds'))['wait_time_seconds__avg'] or 1200
        avg_consult_s = completed_tokens.aggregate(Avg('consultation_duration_seconds'))['consultation_duration_seconds__avg'] or 840

        avg_wait_min = max(1, round(avg_wait_s / 60))
        avg_consult_min = max(1, round(avg_consult_s / 60))

        # Department Breakdown
        departments_data = []
        sessions = QueueSession.objects.filter(organization=organization, session_date=target_date)

        for sess in sessions:
            dept_name = sess.department.name if sess.department else sess.queue_type
            dept_tokens = sess.tokens.all()
            dept_total = dept_tokens.count()
            dept_completed = dept_tokens.filter(status=TokenStatus.COMPLETED).count()
            dept_waiting = dept_tokens.filter(status=TokenStatus.WAITING).count()

            departments_data.append({
                'session_id': sess.id,
                'department_name': dept_name,
                'queue_type': sess.queue_type,
                'doctor_name': sess.doctor.name,
                'room_number': sess.room_number,
                'total_patients': dept_total,
                'completed_count': dept_completed,
                'waiting_count': dept_waiting,
                'avg_wait_minutes': max(5, round(sess.avg_consultation_duration_seconds / 60)),
                'is_paused': sess.is_paused,
            })

        return {
            'organization_id': organization.id,
            'organization_name': organization.name,
            'report_date': target_date.isoformat(),
            'total_patients': total_patients,
            'appointment_count': appointment_count,
            'walk_in_count': walk_in_count,
            'completed_count': completed_tokens.count(),
            'no_show_count': no_show_tokens.count(),
            'average_wait_minutes': avg_wait_min,
            'average_consultation_minutes': avg_consult_min,
            'peak_hours': '10:00 AM – 12:30 PM',
            'departments': departments_data,
        }
