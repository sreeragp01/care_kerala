import datetime
from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.organizations.models import Organization
from apps.network.models import (
    Specialty,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
    DoctorAvailability,
    DoctorAvailabilityStatus,
    ScheduleException,
    AppointmentRequest,
    AppointmentStatus,
    AppointmentStatusHistory,
    DomainEventLog,
    QueueSession,
    QueueToken,
    TokenStatus,
)
from apps.network.events import EventDispatcher, DomainEvent, DomainEventType
from apps.network.slot_engine import SmartDoctorSlotEngine, DoctorLeaveImpactEngine

User = get_user_model()


class AppointmentCoordinationAndSlotsTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Organization
        self.org = Organization.objects.create(
            name="Calicut Medical Center & Palliative Institute",
            district="Kozhikode",
            registration_number="REG-CALICUT-100",
            phone="+91 495 272 1000"
        )

        # Create Specialties
        self.spec_cardio = Specialty.objects.create(name="Cardiology", category="Clinical Specialty")
        self.spec_pall = Specialty.objects.create(name="Palliative Medicine", category="Clinical Specialty")

        # Create Doctors
        self.doc_anil = Doctor.objects.create(
            name="Anil Kumar",
            qualification="MD, DM (Cardiology)",
            primary_specialty=self.spec_cardio,
            experience_years=16,
            registration_number="TCMC-19820"
        )
        self.doc_priya = Doctor.objects.create(
            name="Priya Varma",
            qualification="MD, DM (Oncology)",
            primary_specialty=self.spec_pall,
            experience_years=14,
            registration_number="TCMC-31045"
        )

        # Affiliations
        self.affil_anil = DoctorAffiliation.objects.create(
            doctor=self.doc_anil,
            organization=self.org,
            consultation_fee=500.00
        )
        self.affil_priya = DoctorAffiliation.objects.create(
            doctor=self.doc_priya,
            organization=self.org,
            consultation_fee=400.00
        )

        # Schedules: Dr. Anil on Mondays 09:00 AM - 01:00 PM (max 30 tokens)
        self.sched_anil_mon = DoctorSchedule.objects.create(
            affiliation=self.affil_anil,
            day_of_week="MONDAY",
            start_time="09:00 AM",
            end_time="01:00 PM",
            consultation_type="General Cardiology OPD",
            location_room="OPD Room 102",
            max_tokens=30,
            status="ACTIVE"
        )

        # Users
        self.admin_user = User.objects.create_user(
            username="hospital_admin",
            password="AdminPassword123!",
            email="admin@calicutmed.org",
            role="hospitalAdmin",
            organization=self.org
        )
        self.patient_user = User.objects.create_user(
            username="patient_karthyayani",
            password="PatientPassword123!",
            email="karthyayani@patient.org",
            role="patient"
        )

    def test_smart_slot_calculation_working_day(self):
        """Test slot calculation on a working Monday for Dr. Anil"""
        # Find next Monday date
        today = timezone.now().date()
        days_ahead = (0 - today.weekday()) % 7
        if days_ahead == 0:
            days_ahead = 7
        next_monday = today + datetime.timedelta(days=days_ahead)

        slots_data = SmartDoctorSlotEngine.calculate_slots(
            doctor_id=self.doc_anil.id,
            organization_id=self.org.id,
            target_date=next_monday
        )

        self.assertTrue(slots_data['is_working_day'])
        self.assertTrue(slots_data['is_available'])
        self.assertEqual(slots_data['availability_status'], 'AVAILABLE')
        self.assertGreater(slots_data['total_slots'], 0)
        self.assertGreater(slots_data['available_slots_count'], 0)
        self.assertEqual(slots_data['max_tokens'], 30)

        first_slot = slots_data['slots'][0]
        self.assertIn('start_time', first_slot)
        self.assertIn('end_time', first_slot)
        self.assertIn('slot_label', first_slot)
        self.assertTrue(first_slot['is_available'])

    def test_smart_slot_calculation_non_working_day(self):
        """Test slot calculation on Sunday (non-working day) returns not scheduled"""
        today = timezone.now().date()
        days_ahead = (6 - today.weekday()) % 7
        if days_ahead == 0:
            days_ahead = 7
        next_sunday = today + datetime.timedelta(days=days_ahead)

        slots_data = SmartDoctorSlotEngine.calculate_slots(
            doctor_id=self.doc_anil.id,
            organization_id=self.org.id,
            target_date=next_sunday
        )

        self.assertFalse(slots_data['is_working_day'])
        self.assertFalse(slots_data['is_available'])
        self.assertEqual(slots_data['availability_status'], 'NOT_SCHEDULED')
        self.assertEqual(len(slots_data['slots']), 0)

    def test_smart_slot_doctor_on_leave_override(self):
        """Test slot calculation reflects DoctorAvailability ON_LEAVE override"""
        today = timezone.now().date()
        days_ahead = (0 - today.weekday()) % 7
        if days_ahead == 0:
            days_ahead = 7
        target_date = today + datetime.timedelta(days=days_ahead)

        DoctorAvailability.objects.create(
            doctor=self.doc_anil,
            organization=self.org,
            date=target_date,
            status=DoctorAvailabilityStatus.ON_LEAVE,
            reason="Attending National Cardiology Conference in Kochi"
        )

        slots_data = SmartDoctorSlotEngine.calculate_slots(
            doctor_id=self.doc_anil.id,
            organization_id=self.org.id,
            target_date=target_date
        )

        self.assertFalse(slots_data['is_available'])
        self.assertEqual(slots_data['availability_status'], DoctorAvailabilityStatus.ON_LEAVE)
        self.assertIn("National Cardiology Conference", slots_data['availability_reason'])

    def test_doctor_available_slots_endpoint(self):
        """Test GET /api/network/doctors/<id>/available-slots/ API view"""
        today = timezone.now().date()
        days_ahead = (0 - today.weekday()) % 7
        if days_ahead == 0:
            days_ahead = 7
        next_monday = today + datetime.timedelta(days=days_ahead)

        response = self.client.get(
            f"/api/network/doctors/{self.doc_anil.id}/available-slots/?date={next_monday}&organization_id={self.org.id}"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['doctor_id'], self.doc_anil.id)
        self.assertTrue(response.data['is_working_day'])
        self.assertIn('slots', response.data)

    def test_appointment_lifecycle_and_event_dispatch(self):
        """Test complete appointment lifecycle from request to completion with domain event dispatching"""
        target_date = timezone.now().date() + datetime.timedelta(days=2)

        # 1. Patient requests appointment
        appt_payload = {
            'organization': self.org.id,
            'doctor': self.doc_anil.id,
            'patient_name': 'Karthyayani Amma',
            'patient_phone': '+91 98470 12345',
            'patient_age': 74,
            'patient_gender': 'Female',
            'district': 'Kozhikode',
            'preferred_date': str(target_date),
            'preferred_time_slot': '09:00 AM - 09:20 AM',
            'consultation_mode': 'IN_PERSON',
            'chief_complaint': 'Chest tightness and shortness of breath upon exertion'
        }

        resp = self.client.post('/api/network/appointments/request/', appt_payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        appt_id = resp.data['appointment_id']

        # Verify Event Log
        event = DomainEventLog.objects.filter(entity_type='AppointmentRequest', entity_id=appt_id, event_type=DomainEventType.APPOINTMENT_REQUESTED).first()
        self.assertIsNotNone(event)

        # 2. Hospital Desk accepts appointment
        self.client.force_authenticate(user=self.admin_user)
        action_resp = self.client.post(
            f"/api/network/appointments/{appt_id}/action/accept/",
            {'notes': 'Accepted by Reception Desk for OPD Room 102'},
            format='json'
        )
        self.assertEqual(action_resp.status_code, status.HTTP_200_OK)

        appt = AppointmentRequest.objects.get(id=appt_id)
        self.assertEqual(appt.status, AppointmentStatus.ACCEPTED)

        # 3. Patient reschedules appointment
        new_date = target_date + datetime.timedelta(days=7)
        resched_resp = self.client.post(
            f"/api/network/appointments/{appt_id}/reschedule/",
            {
                'new_date': str(new_date),
                'new_time_slot': '10:00 AM - 10:20 AM',
                'reason': 'Family member transportation arranged for next week'
            },
            format='json'
        )
        self.assertEqual(resched_resp.status_code, status.HTTP_200_OK)
        appt.refresh_from_db()
        self.assertEqual(appt.status, AppointmentStatus.RESCHEDULED)
        self.assertEqual(str(appt.preferred_date), str(new_date))
        self.assertEqual(str(appt.rescheduled_from_date), str(target_date))

        # 4. Patient checks history timeline
        hist_resp = self.client.get(f"/api/network/appointments/{appt_id}/history/")
        self.assertEqual(hist_resp.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(hist_resp.data['status_history']), 2)

    def test_appointment_cancellation(self):
        """Test appointment cancellation endpoint and status history"""
        appt = AppointmentRequest.objects.create(
            organization=self.org,
            doctor=self.doc_anil,
            patient_name="Ramesh Babu",
            patient_phone="+91 98470 55443",
            preferred_date=timezone.now().date() + datetime.timedelta(days=1),
            preferred_time_slot="10:00 AM - 10:20 AM",
            status=AppointmentStatus.ACCEPTED
        )

        resp = self.client.post(
            f"/api/network/appointments/{appt.id}/cancel/",
            {'reason': 'Patient admitted to local clinic'},
            format='json'
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        appt.refresh_from_db()
        self.assertEqual(appt.status, AppointmentStatus.CANCELLED)
        self.assertEqual(appt.cancellation_reason, 'Patient admitted to local clinic')

        # Check status history
        hist = AppointmentStatusHistory.objects.filter(appointment=appt, to_status=AppointmentStatus.CANCELLED).first()
        self.assertIsNotNone(hist)

    def test_patient_appointments_list_filtering(self):
        """Test PatientAppointmentsListView for tabbed retrieval"""
        today = timezone.now().date()
        phone = "+91 98470 99999"

        # Today's appt
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Sita Devi", patient_phone=phone,
            preferred_date=today, status=AppointmentStatus.CONFIRMED
        )
        # Upcoming appt
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Sita Devi", patient_phone=phone,
            preferred_date=today + datetime.timedelta(days=5), status=AppointmentStatus.ACCEPTED
        )
        # Cancelled appt
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Sita Devi", patient_phone=phone,
            preferred_date=today - datetime.timedelta(days=2), status=AppointmentStatus.CANCELLED
        )

        # Test filter today
        resp_today = self.client.get(f"/api/network/appointments/patient/?phone={phone}&status_filter=today")
        self.assertEqual(resp_today.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_today.data['count'], 1)

        # Test filter upcoming
        resp_up = self.client.get(f"/api/network/appointments/patient/?phone={phone}&status_filter=upcoming")
        self.assertEqual(resp_up.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_up.data['count'], 1)

        # Test filter cancelled
        resp_canc = self.client.get(f"/api/network/appointments/patient/?phone={phone}&status_filter=cancelled")
        self.assertEqual(resp_canc.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_canc.data['count'], 1)

    def test_hospital_appointment_desk_metrics_and_list(self):
        """Test HospitalAppointmentDeskView metrics calculation and multi-status list"""
        today = timezone.now().date()
        self.client.force_authenticate(user=self.admin_user)

        # Create various appointment statuses for today
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Patient 1", patient_phone="+919876500001",
            preferred_date=today, status=AppointmentStatus.REQUESTED
        )
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Patient 2", patient_phone="+919876500002",
            preferred_date=today, status=AppointmentStatus.CONFIRMED
        )
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Patient 3", patient_phone="+919876500003",
            preferred_date=today, status=AppointmentStatus.CHECKED_IN
        )
        AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Patient 4", patient_phone="+919876500004",
            preferred_date=today, status=AppointmentStatus.COMPLETED
        )

        resp = self.client.get(f"/api/network/appointments/desk/?organization_id={self.org.id}&date={today}")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        metrics = resp.data['metrics']
        self.assertEqual(metrics['pending_requests_count'], 1)
        self.assertEqual(metrics['confirmed_count'], 1)
        self.assertEqual(metrics['checked_in_count'], 1)
        self.assertEqual(metrics['completed_count'], 1)
        self.assertEqual(metrics['total_appointments_count'], 4)
        self.assertEqual(len(resp.data['appointments']), 4)

    def test_doctor_leave_impact_flagging_and_bulk_resolution(self):
        """Test automatic flagging when doctor marks leave and subsequent bulk resolution"""
        self.client.force_authenticate(user=self.admin_user)
        target_date = timezone.now().date() + datetime.timedelta(days=4)

        # Create 2 appointments for Dr. Anil on target_date
        appt1 = AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Gopalan Nair", patient_phone="+919847011111",
            preferred_date=target_date, status=AppointmentStatus.CONFIRMED
        )
        appt2 = AppointmentRequest.objects.create(
            organization=self.org, doctor=self.doc_anil,
            patient_name="Kavitha K.", patient_phone="+919847022222",
            preferred_date=target_date, status=AppointmentStatus.ACCEPTED
        )

        # Doctor marks leave via DoctorAvailabilityView
        leave_resp = self.client.post('/api/network/doctors/availability/', {
            'doctor_id': self.doc_anil.id,
            'organization_id': self.org.id,
            'date': str(target_date),
            'status': 'ON_LEAVE',
            'reason': 'Emergency Surgery duty in Kozhikode Medical College'
        }, format='json')
        self.assertEqual(leave_resp.status_code, status.HTTP_201_CREATED)

        # Verify appointments are automatically flagged
        appt1.refresh_from_db()
        appt2.refresh_from_db()
        self.assertTrue(appt1.is_doctor_unavailable_flagged)
        self.assertTrue(appt2.is_doctor_unavailable_flagged)
        self.assertIn("Emergency Surgery duty", appt1.hospital_notes)

        # Resolve via Reassign Substitute Doctor (Dr. Priya)
        resolve_resp = self.client.post('/api/network/opd/exceptions/resolve-impact/', {
            'organization_id': self.org.id,
            'appointment_ids': [appt1.id, appt2.id],
            'action': 'REASSIGN_SUBSTITUTE',
            'substitute_doctor_id': self.doc_priya.id,
            'notes': 'Consultation covered by Senior Specialist Dr. Priya Varma'
        }, format='json')
        self.assertEqual(resolve_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resolve_resp.data['resolved_count'], 2)

        appt1.refresh_from_db()
        appt2.refresh_from_db()
        self.assertFalse(appt1.is_doctor_unavailable_flagged)
        self.assertEqual(appt1.substitute_doctor_id, self.doc_priya.id)
        self.assertEqual(appt2.substitute_doctor_id, self.doc_priya.id)
