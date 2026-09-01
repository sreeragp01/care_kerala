import datetime
import logging
from typing import Dict, List, Any, Optional
from django.utils import timezone
from .models import (
    Doctor,
    Organization,
    DoctorAffiliation,
    DoctorSchedule,
    DoctorAvailability,
    DoctorAvailabilityStatus,
    ScheduleException,
    AppointmentRequest,
    AppointmentStatus,
    QueueToken,
    TokenStatus,
)
from .events import EventDispatcher, DomainEvent, DomainEventType

logger = logging.getLogger(__name__)


class SmartDoctorSlotEngine:
    """Intelligent Dynamic Slot Generator based on Doctor recurring schedule, max tokens,

    real-time leave/holiday overrides, schedule exceptions, and existing bookings.
    """

    DEFAULT_SLOT_MINUTES = 20

    @classmethod
    def calculate_slots(
        cls, doctor_id: int, organization_id: int, target_date: datetime.date
    ) -> Dict[str, Any]:
        doctor = Doctor.objects.select_related('primary_specialty').filter(id=doctor_id).first()
        if not doctor:
            return {'error': 'Doctor not found.', 'available': False, 'slots': []}

        org = Organization.objects.filter(id=organization_id).first()
        if not org:
            return {'error': 'Organization not found.', 'available': False, 'slots': []}

        # 1. Check Date Specific Doctor Availability Override
        availability = DoctorAvailability.objects.filter(
            doctor_id=doctor_id,
            organization_id=organization_id,
            date=target_date
        ).first()

        is_doctor_available = True
        availability_status = DoctorAvailabilityStatus.AVAILABLE
        availability_reason = ''

        if availability and availability.status != DoctorAvailabilityStatus.AVAILABLE:
            is_doctor_available = False
            availability_status = availability.status
            availability_reason = availability.reason or availability.get_status_display()

        # 2. Check Doctor Affiliation and Schedule Exception
        affiliation = DoctorAffiliation.objects.filter(
            doctor_id=doctor_id,
            organization_id=organization_id
        ).first()

        substitute_doctor_info = None
        is_schedule_exception_cancelled = False

        if affiliation:
            exception = ScheduleException.objects.filter(
                affiliation=affiliation,
                exception_date=target_date
            ).select_related('substitute_doctor', 'substitute_doctor__primary_specialty').first()

            if exception:
                if exception.is_cancelled:
                    is_schedule_exception_cancelled = True
                    availability_reason = exception.reason or 'OPD Session Cancelled by Administration'
                if exception.substitute_doctor:
                    sub = exception.substitute_doctor
                    substitute_doctor_info = {
                        'id': sub.id,
                        'name': f"Dr. {sub.name}",
                        'specialty': sub.primary_specialty.name if sub.primary_specialty else 'General Medicine',
                        'qualification': sub.qualification
                    }

        # 3. Match Day of Week Schedule
        day_name = target_date.strftime('%A')
        schedules = DoctorSchedule.objects.filter(
            affiliation__doctor_id=doctor_id,
            affiliation__organization_id=organization_id,
            day_of_week__iexact=day_name,
            status='ACTIVE'
        )

        if not schedules.exists() and affiliation:
            schedules = DoctorSchedule.objects.filter(
                affiliation=affiliation,
                day_of_week__iexact=day_name,
                status='ACTIVE'
            )

        if not schedules.exists():
            return {
                'doctor_id': doctor.id,
                'doctor_name': f"Dr. {doctor.name}",
                'organization_id': org.id,
                'organization_name': org.name,
                'date': str(target_date),
                'day_of_week': day_name,
                'is_working_day': False,
                'is_available': False,
                'availability_status': 'NOT_SCHEDULED',
                'availability_reason': f"Dr. {doctor.name} does not hold standard OPD on {day_name}s.",
                'substitute_doctor': substitute_doctor_info,
                'total_slots': 0,
                'available_slots_count': 0,
                'max_tokens': 0,
                'booked_tokens_count': 0,
                'slots': []
            }

        schedule = schedules.first()
        max_daily_tokens = schedule.max_tokens or 30

        # 4. If Doctor is On Leave, Holiday, or Cancelled
        if not is_doctor_available or is_schedule_exception_cancelled:
            return {
                'doctor_id': doctor.id,
                'doctor_name': f"Dr. {doctor.name}",
                'organization_id': org.id,
                'organization_name': org.name,
                'date': str(target_date),
                'day_of_week': day_name,
                'is_working_day': True,
                'is_available': False,
                'availability_status': availability_status,
                'availability_reason': availability_reason or 'Doctor Unavailable / On Leave',
                'substitute_doctor': substitute_doctor_info,
                'total_slots': 0,
                'available_slots_count': 0,
                'max_tokens': max_daily_tokens,
                'booked_tokens_count': 0,
                'slots': []
            }

        # 5. Generate Discrete Time Slots from Start/End Time
        slots = cls._generate_slots(schedule, target_date)
        if not slots:
            slots = cls._generate_fallback_slots(schedule)

        # 6. Fetch Existing Active Appointments for this date & doctor
        active_appts = AppointmentRequest.objects.filter(
            doctor_id=doctor_id,
            organization_id=organization_id,
            preferred_date=target_date
        ).exclude(
            status__in=[AppointmentStatus.CANCELLED, AppointmentStatus.REJECTED]
        )

        total_booked_count = active_appts.count()
        slot_booking_counts = {}
        for appt in active_appts:
            key = appt.preferred_time_slot.strip()
            slot_booking_counts[key] = slot_booking_counts.get(key, 0) + 1

        capacity_per_slot = max(1, max_daily_tokens // max(1, len(slots)))

        # 7. Evaluate each slot against capacities and existing bookings
        enhanced_slots = []
        available_slots_count = 0

        for s in slots:
            slot_label = s['label']
            booked = slot_booking_counts.get(slot_label, 0)
            # Fuzzy match slot label if exact string mismatch
            if booked == 0:
                for k, count in slot_booking_counts.items():
                    if s['start_time'] in k or s['end_time'] in k:
                        booked += count

            is_slot_full = booked >= capacity_per_slot or total_booked_count >= max_daily_tokens
            is_avail = not is_slot_full

            if is_avail:
                available_slots_count += 1

            status_text = 'Available'
            if booked > 0 and not is_slot_full:
                status_text = f"{capacity_per_slot - booked} slots left"
            elif is_slot_full:
                status_text = 'Fully Booked'

            enhanced_slots.append({
                'slot_id': f"{schedule.id}_{s['start_time'].replace(' ', '_').replace(':', '')}",
                'start_time': s['start_time'],
                'end_time': s['end_time'],
                'slot_label': slot_label,
                'room_number': schedule.location_room or 'OPD Room 101',
                'consultation_type': schedule.consultation_type or 'General OPD',
                'capacity': capacity_per_slot,
                'booked_count': booked,
                'is_available': is_avail,
                'status_text': status_text,
            })

        return {
            'doctor_id': doctor.id,
            'doctor_name': f"Dr. {doctor.name}",
            'specialty': doctor.primary_specialty.name if doctor.primary_specialty else 'General OPD',
            'organization_id': org.id,
            'organization_name': org.name,
            'date': str(target_date),
            'day_of_week': day_name,
            'is_working_day': True,
            'is_available': available_slots_count > 0,
            'availability_status': 'AVAILABLE',
            'availability_reason': 'Doctor on Duty & Accepting Appointments',
            'substitute_doctor': substitute_doctor_info,
            'room_number': schedule.location_room or 'OPD Room 101',
            'consultation_type': schedule.consultation_type or 'General OPD',
            'total_slots': len(enhanced_slots),
            'available_slots_count': available_slots_count,
            'max_tokens': max_daily_tokens,
            'booked_tokens_count': total_booked_count,
            'slots': enhanced_slots
        }

    @classmethod
    def _generate_slots(cls, schedule: DoctorSchedule, target_date: datetime.date) -> List[Dict[str, str]]:
        """Parses schedule start/end time and generates 20-minute interval slots."""
        try:
            start_t = cls._parse_time(schedule.start_time)
            end_t = cls._parse_time(schedule.end_time)

            if not start_t or not end_t or end_t <= start_t:
                return []

            dt_current = datetime.datetime.combine(target_date, start_t)
            dt_end = datetime.datetime.combine(target_date, end_t)

            slots = []
            while dt_current + datetime.timedelta(minutes=cls.DEFAULT_SLOT_MINUTES) <= dt_end:
                next_dt = dt_current + datetime.timedelta(minutes=cls.DEFAULT_SLOT_MINUTES)
                start_str = dt_current.strftime('%I:%M %p')
                end_str = next_dt.strftime('%I:%M %p')
                slots.append({
                    'start_time': start_str,
                    'end_time': end_str,
                    'label': f"{start_str} - {end_str}"
                })
                dt_current = next_dt
            return slots
        except Exception as e:
            logger.debug(f"Slot parse error for schedule #{schedule.id}: {e}")
            return []

    @classmethod
    def _generate_fallback_slots(cls, schedule: DoctorSchedule) -> List[Dict[str, str]]:
        """Fallback when exact time arithmetic fails."""
        st = schedule.start_time or '09:00 AM'
        et = schedule.end_time or '01:00 PM'
        return [
            {'start_time': '09:00 AM', 'end_time': '09:30 AM', 'label': 'Morning (09:00 AM - 09:30 AM)'},
            {'start_time': '09:30 AM', 'end_time': '10:00 AM', 'label': 'Morning (09:30 AM - 10:00 AM)'},
            {'start_time': '10:00 AM', 'end_time': '10:30 AM', 'label': 'Morning (10:00 AM - 10:30 AM)'},
            {'start_time': '10:30 AM', 'end_time': '11:00 AM', 'label': 'Morning (10:30 AM - 11:00 AM)'},
            {'start_time': '11:00 AM', 'end_time': '11:30 AM', 'label': 'Morning (11:00 AM - 11:30 AM)'},
            {'start_time': '11:30 AM', 'end_time': '12:00 PM', 'label': 'Morning (11:30 AM - 12:00 PM)'},
            {'start_time': '12:00 PM', 'end_time': '12:30 PM', 'label': 'Afternoon (12:00 PM - 12:30 PM)'},
            {'start_time': '12:30 PM', 'end_time': '01:00 PM', 'label': 'Afternoon (12:30 PM - 01:00 PM)'},
        ]

    @classmethod
    def _parse_time(cls, time_str: Any) -> Optional[datetime.time]:
        if isinstance(time_str, datetime.time):
            return time_str
        if not time_str:
            return None
        time_str = str(time_str).strip()
        for fmt in ('%I:%M %p', '%H:%M:%S', '%H:%M', '%I:%M%p'):
            try:
                return datetime.datetime.strptime(time_str, fmt).time()
            except ValueError:
                continue
        return None


class DoctorLeaveImpactEngine:
    """Identifies appointments impacted by doctor unavailability / schedule exceptions

    and coordinates automated flagging, notifications, and bulk resolution.
    """

    @classmethod
    def flag_affected_appointments(
        cls, doctor_id: int, organization_id: int, exception_date: datetime.date, reason: str = '', user=None
    ) -> List[AppointmentRequest]:
        affected = AppointmentRequest.objects.filter(
            doctor_id=doctor_id,
            organization_id=organization_id,
            preferred_date=exception_date,
            status__in=[
                AppointmentStatus.REQUESTED,
                AppointmentStatus.PENDING_HOSPITAL,
                AppointmentStatus.ACCEPTED,
                AppointmentStatus.CONFIRMED,
            ]
        )

        updated = []
        for appt in affected:
            appt.is_doctor_unavailable_flagged = True
            appt.hospital_notes = f"{appt.hospital_notes}\n[DOCTOR ON LEAVE]: {reason}".strip()
            appt.save(update_fields=['is_doctor_unavailable_flagged', 'hospital_notes', 'updated_at'])
            updated.append(appt)

            # Dispatch individual appointment impacted event
            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.DOCTOR_UNAVAILABLE,
                organization_id=organization_id,
                entity_type='AppointmentRequest',
                entity_id=appt.id,
                actor_id=user.id if user and hasattr(user, 'id') else None,
                actor_username=user.username if user and hasattr(user, 'username') else 'system',
                title='Doctor Unavailable - Appointment Flagged',
                message=f"Dr. {appt.doctor.name} is on leave on {exception_date}. Reschedule or substitute doctor recommended.",
                payload={'doctor_id': doctor_id, 'date': str(exception_date), 'reason': reason}
            ))

        return updated

    @classmethod
    def resolve_impact(
        cls,
        organization_id: int,
        appointment_ids: List[int],
        action: str,
        substitute_doctor_id: Optional[int] = None,
        new_date: Optional[datetime.date] = None,
        notes: str = '',
        user=None
    ) -> Dict[str, Any]:
        """Resolves flagged affected appointments via substitute reassignment, auto-reschedule, or cancellation."""
        appts = AppointmentRequest.objects.filter(
            organization_id=organization_id,
            id__in=appointment_ids
        ).select_related('doctor', 'organization')

        count_resolved = 0
        action = action.upper()

        for appt in appts:
            if action == 'REASSIGN_SUBSTITUTE' and substitute_doctor_id:
                sub_doc = Doctor.objects.filter(id=substitute_doctor_id).first()
                if sub_doc:
                    appt.substitute_doctor = sub_doc
                    appt.is_doctor_unavailable_flagged = False
                    appt.hospital_notes = f"{appt.hospital_notes}\n[SUBSTITUTE ASSIGNED]: Consultation re-assigned to Dr. {sub_doc.name}. {notes}".strip()
                    appt.save(update_fields=['substitute_doctor', 'is_doctor_unavailable_flagged', 'hospital_notes', 'updated_at'])
                    count_resolved += 1

                    EventDispatcher.dispatch(DomainEvent(
                        event_type=DomainEventType.DOCTOR_RESCHEDULE_RESOLVED,
                        organization_id=organization_id,
                        entity_type='AppointmentRequest',
                        entity_id=appt.id,
                        actor_id=user.id if user and hasattr(user, 'id') else None,
                        actor_username=user.username if user and hasattr(user, 'username') else 'desk_admin',
                        title='Substitute Doctor Assigned',
                        message=f"Your appointment on {appt.preferred_date} will be conducted by Dr. {sub_doc.name}.",
                        payload={'substitute_doctor_id': sub_doc.id, 'substitute_doctor_name': sub_doc.name}
                    ))

            elif action == 'RESCHEDULE' and new_date:
                old_date = appt.preferred_date
                appt.rescheduled_from_date = old_date
                appt.rescheduled_from_slot = appt.preferred_time_slot
                appt.preferred_date = new_date
                appt.is_doctor_unavailable_flagged = False
                appt.status = AppointmentStatus.RESCHEDULED
                appt.reschedule_reason = notes or 'Rescheduled due to doctor leave/unavailability'
                appt.save(update_fields=[
                    'preferred_date', 'rescheduled_from_date', 'rescheduled_from_slot',
                    'is_doctor_unavailable_flagged', 'status', 'reschedule_reason', 'updated_at'
                ])
                count_resolved += 1

                EventDispatcher.dispatch(DomainEvent(
                    event_type=DomainEventType.APPOINTMENT_RESCHEDULED,
                    organization_id=organization_id,
                    entity_type='AppointmentRequest',
                    entity_id=appt.id,
                    actor_id=user.id if user and hasattr(user, 'id') else None,
                    actor_username=user.username if user and hasattr(user, 'username') else 'desk_admin',
                    title='Appointment Rescheduled',
                    message=f"Appointment shifted from {old_date} to {new_date} due to doctor leave.",
                    payload={'old_date': str(old_date), 'new_date': str(new_date), 'reason': notes}
                ))

            elif action == 'CANCEL':
                appt.status = AppointmentStatus.CANCELLED
                appt.cancellation_reason = notes or 'Cancelled due to doctor unavailability'
                appt.is_doctor_unavailable_flagged = False
                appt.save(update_fields=['status', 'cancellation_reason', 'is_doctor_unavailable_flagged', 'updated_at'])
                count_resolved += 1

                EventDispatcher.dispatch(DomainEvent(
                    event_type=DomainEventType.APPOINTMENT_CANCELLED,
                    organization_id=organization_id,
                    entity_type='AppointmentRequest',
                    entity_id=appt.id,
                    actor_id=user.id if user and hasattr(user, 'id') else None,
                    actor_username=user.username if user and hasattr(user, 'username') else 'desk_admin',
                    title='Appointment Cancelled',
                    message=f"Appointment on {appt.preferred_date} cancelled: {appt.cancellation_reason}",
                    payload={'cancellation_reason': appt.cancellation_reason}
                ))

        return {
            'success': True,
            'action': action,
            'resolved_count': count_resolved,
            'message': f"Successfully resolved {count_resolved} appointments via {action}."
        }
