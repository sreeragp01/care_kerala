from datetime import date, timedelta
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from apps.organizations.models import Organization
from apps.network.models import (
    HealthcareProfile,
    Specialty,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
    DoctorAvailability,
    DoctorAvailabilityStatus,
    AppointmentRequest,
    AppointmentStatus,
    AppointmentStatusHistory,
    QueueSession,
    QueueToken,
    TokenStatus,
    OrganizationMembership,
)

User = get_user_model()

class HospitalOperationsAndQueueTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.today = timezone.now().date()

        # 1. Platform Super Admin
        self.super_admin = User.objects.create_superuser(
            username='platform_super',
            email='super@carelink.in',
            password='AdminPassword123#'
        )

        # 2. Hospital A: Calicut Medical Center
        self.org_a = Organization.objects.create(
            name='Calicut Medical Center',
            registration_number='REG-CMC-001',
            district='Kozhikode',
            status='ACTIVE'
        )
        self.profile_a = HealthcareProfile.objects.create(
            organization=self.org_a,
            organization_type='HOSPITAL',
            verification_status='VERIFIED',
            lifecycle_status='PUBLISHED',
            is_published=True,
            total_beds=250
        )
        self.admin_a = User.objects.create_user(
            username='admin_cmc',
            email='admin@cmc.org',
            password='Password123#',
            role='orgAdmin',
            organization=self.org_a
        )
        OrganizationMembership.objects.create(
            user=self.admin_a,
            organization=self.org_a,
            role='ORGANIZATION_ADMIN',
            status='ACTIVE'
        )

        # 3. Hospital B: Aster MIMS
        self.org_b = Organization.objects.create(
            name='Aster MIMS Kozhikode',
            registration_number='REG-MIMS-002',
            district='Kozhikode',
            status='ACTIVE'
        )
        self.profile_b = HealthcareProfile.objects.create(
            organization=self.org_b,
            organization_type='HOSPITAL',
            verification_status='VERIFIED',
            lifecycle_status='PUBLISHED',
            is_published=True,
            total_beds=400
        )
        self.admin_b = User.objects.create_user(
            username='admin_mims',
            email='admin@mims.org',
            password='Password123#',
            role='orgAdmin',
            organization=self.org_b
        )
        OrganizationMembership.objects.create(
            user=self.admin_b,
            organization=self.org_b,
            role='ORGANIZATION_ADMIN',
            status='ACTIVE'
        )

        # 4. Doctors & Specialties
        self.specialty_cardio = Specialty.objects.create(name='Cardiology', category='Clinical')
        
        self.user_doctor_a = User.objects.create_user(
            username='dr_priya',
            email='priya@cmc.org',
            password='Password123#',
            role='doctor',
            organization=self.org_a
        )
        self.doctor_a = Doctor.objects.create(
            name='Dr. Priya Varma',
            primary_specialty=self.specialty_cardio,
            qualification='MBBS, MD (Cardiology)',
            registration_number='TCMC/64291/K'
        )
        self.aff_a = DoctorAffiliation.objects.create(
            doctor=self.doctor_a,
            organization=self.org_a,
            designation='Lead Cardiologist',
            is_active=True
        )

        self.user_doctor_b = User.objects.create_user(
            username='dr_suresh',
            email='suresh@mims.org',
            password='Password123#',
            role='doctor',
            organization=self.org_b
        )
        self.doctor_b = Doctor.objects.create(
            name='Dr. Suresh Menon',
            primary_specialty=self.specialty_cardio,
            qualification='MBBS, MS',
            registration_number='TCMC/88123/K'
        )
        self.aff_b = DoctorAffiliation.objects.create(
            doctor=self.doctor_b,
            organization=self.org_b,
            designation='Consultant',
            is_active=True
        )

    def test_doctor_availability_and_leave_override(self):
        """Test real-time doctor availability and date-specific leave management"""
        self.client.force_authenticate(user=self.admin_a)

        # 1. Hospital Admin sets Dr. Priya to AVAILABLE today
        res = self.client.post('/api/network/doctors/availability/', {
            'doctor_id': self.doctor_a.id,
            'organization_id': self.org_a.id,
            'date': str(self.today),
            'status': 'AVAILABLE',
            'reason': 'On Duty General OPD'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['status'], 'AVAILABLE')

        # 2. Query availability
        res_get = self.client.get(f'/api/network/doctors/availability/?doctor_id={self.doctor_a.id}&organization_id={self.org_a.id}&date={self.today}')
        self.assertEqual(res_get.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res_get.data), 1)
        self.assertEqual(res_get.data[0]['status'], 'AVAILABLE')

        # 3. Doctor marks leave for tomorrow
        tomorrow = self.today + timedelta(days=1)
        res_leave = self.client.post('/api/network/doctors/availability/', {
            'doctor_id': self.doctor_a.id,
            'organization_id': self.org_a.id,
            'date': str(tomorrow),
            'status': 'ON_LEAVE',
            'reason': 'Attending Cardiology Summit'
        })
        self.assertEqual(res_leave.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res_leave.data['status'], 'ON_LEAVE')

        # 4. Cross-tenant defense: Hospital B cannot set Hospital A's doctor availability
        self.client.force_authenticate(user=self.admin_b)
        res_cross = self.client.post('/api/network/doctors/availability/', {
            'doctor_id': self.doctor_a.id,
            'organization_id': self.org_a.id,
            'date': str(self.today),
            'status': 'ON_LEAVE'
        })
        self.assertEqual(res_cross.status_code, status.HTTP_403_FORBIDDEN)

    def test_appointment_7_stage_lifecycle_and_audit(self):
        """Test complete appointment lifecycle from patient request to doctor completion with status history"""
        # 1. Patient requests appointment
        appt = AppointmentRequest.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            affiliation=self.aff_a,
            patient_name='Rahul Narayanan',
            patient_phone='+919876543210',
            preferred_date=self.today,
            status=AppointmentStatus.REQUESTED
        )
        self.assertEqual(appt.status, AppointmentStatus.REQUESTED)

        # 2. Hospital Admin accepts appointment
        self.client.force_authenticate(user=self.admin_a)
        res_accept = self.client.post(f'/api/network/appointments/{appt.id}/action/accept/', {'notes': 'Slot verified'})
        self.assertEqual(res_accept.status_code, status.HTTP_200_OK)
        appt.refresh_from_db()
        self.assertEqual(appt.status, AppointmentStatus.ACCEPTED)

        # 3. Hospital Admin confirms appointment
        res_confirm = self.client.post(f'/api/network/appointments/{appt.id}/action/confirm/', {'notes': 'Patient confirmed by phone'})
        self.assertEqual(res_confirm.status_code, status.HTTP_200_OK)
        appt.refresh_from_db()
        self.assertEqual(appt.status, AppointmentStatus.CONFIRMED)

        # 4. Patient arrives at hospital -> Reception Check-in (automatically links QueueSession and QueueToken)
        res_checkin = self.client.post(f'/api/network/appointments/{appt.id}/action/check-in/', {'notes': 'Patient at reception desk'})
        self.assertEqual(res_checkin.status_code, status.HTTP_200_OK)
        appt.refresh_from_db()
        self.assertEqual(appt.status, AppointmentStatus.CHECKED_IN)
        self.assertTrue(appt.token_number.startswith('A-'))
        self.assertTrue(QueueToken.objects.filter(appointment=appt).exists())

        # 5. Doctor starts consultation
        token = QueueToken.objects.get(appointment=appt)
        res_start = self.client.post(f'/api/network/queue/tokens/{token.id}/consultation/start/')
        self.assertEqual(res_start.status_code, status.HTTP_200_OK)
        token.refresh_from_db()
        appt.refresh_from_db()
        self.assertEqual(token.status, TokenStatus.IN_CONSULTATION)
        self.assertEqual(appt.status, AppointmentStatus.IN_CONSULTATION)

        # 6. Doctor completes consultation with clinical notes
        res_complete = self.client.post(f'/api/network/queue/tokens/{token.id}/consultation/complete/', {
            'clinical_notes': 'ECG Normal. Prescribed medication for 1 month.'
        })
        self.assertEqual(res_complete.status_code, status.HTTP_200_OK)
        token.refresh_from_db()
        appt.refresh_from_db()
        self.assertEqual(token.status, TokenStatus.COMPLETED)
        self.assertEqual(appt.status, AppointmentStatus.COMPLETED)
        self.assertIn('ECG Normal', token.clinical_notes)

        # 7. Verify status audit history records
        history = AppointmentStatusHistory.objects.filter(appointment=appt)
        self.assertEqual(history.count(), 3)  # ACCEPTED, CONFIRMED, CHECKED_IN logged via action endpoint
        self.assertEqual(history.first().to_status, AppointmentStatus.ACCEPTED)

    def test_live_queue_and_token_caller(self):
        """Test queue session start, token issuance, token calling, and patient live queue estimation"""
        self.client.force_authenticate(user=self.admin_a)

        # 1. Start live queue session
        res_session = self.client.post('/api/network/queue/sessions/start/', {
            'doctor_id': self.doctor_a.id,
            'organization_id': self.org_a.id,
            'room_number': 'Room 102 - Cardiology OPD'
        })
        self.assertEqual(res_session.status_code, status.HTTP_201_CREATED)
        session_id = res_session.data['id']

        # 2. Issue 3 Tokens
        t1 = self.client.post('/api/network/queue/tokens/issue/', {
            'queue_session_id': session_id,
            'patient_name': 'Patient One',
            'patient_phone': '+919800000001'
        })
        t2 = self.client.post('/api/network/queue/tokens/issue/', {
            'queue_session_id': session_id,
            'patient_name': 'Patient Two',
            'patient_phone': '+919800000002'
        })
        t3 = self.client.post('/api/network/queue/tokens/issue/', {
            'queue_session_id': session_id,
            'patient_name': 'Patient Three',
            'patient_phone': '+919800000003'
        })
        self.assertEqual(t1.data['token_label'], 'A-01')
        self.assertEqual(t2.data['token_label'], 'A-02')
        self.assertEqual(t3.data['token_label'], 'A-03')

        # 3. Doctor calls Token A-01
        res_call = self.client.post(f'/api/network/queue/tokens/{t1.data["id"]}/call-next/')
        self.assertEqual(res_call.status_code, status.HTTP_200_OK)
        self.assertEqual(res_call.data['current_token_number'], 1)

        # 4. Patient Three checks live queue tracker (Token A-03)
        res_tracker = self.client.get(f'/api/network/queue/live/{t3.data["id"]}/')
        self.assertEqual(res_tracker.status_code, status.HTTP_200_OK)
        self.assertEqual(res_tracker.data['token_label'], 'A-03')
        self.assertEqual(res_tracker.data['current_token_label'], 'A-01')
        self.assertEqual(res_tracker.data['patients_ahead'], 2)
        self.assertEqual(res_tracker.data['estimated_wait_minutes'], 20)  # 2 ahead * 10 mins

    def test_cross_tenant_queue_isolation(self):
        """Verify Hospital B cannot call or manipulate Hospital A's queue tokens"""
        session = QueueSession.objects.create(
            doctor=self.doctor_a,
            organization=self.org_a,
            session_date=self.today
        )
        token = QueueToken.objects.create(
            queue_session=session,
            token_number=1,
            token_label='A-01',
            patient_name='Hospital A Patient',
            patient_phone='+919000000000'
        )

        # Hospital B attempts to call Hospital A token -> 403 Forbidden
        self.client.force_authenticate(user=self.admin_b)
        res = self.client.post(f'/api/network/queue/tokens/{token.id}/call-next/')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_hospital_operations_summary_aggregation(self):
        """Test aggregation calculations for today's OPD operations dashboard"""
        AppointmentRequest.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            patient_name='P1',
            patient_phone='+919000000001',
            preferred_date=self.today,
            status=AppointmentStatus.ACCEPTED
        )
        AppointmentRequest.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            patient_name='P2',
            patient_phone='+919000000002',
            preferred_date=self.today,
            status=AppointmentStatus.COMPLETED
        )
        AppointmentRequest.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            patient_name='P3',
            patient_phone='+919000000003',
            preferred_date=self.today,
            status=AppointmentStatus.CANCELLED
        )

        self.client.force_authenticate(user=self.admin_a)
        res = self.client.get(f'/api/network/operations/summary/?organization_id={self.org_a.id}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['total_appointments_today'], 3)
        self.assertEqual(res.data['waiting_patients'], 1)
        self.assertEqual(res.data['completed_consultations'], 1)
        self.assertEqual(res.data['cancelled_or_noshow'], 1)
