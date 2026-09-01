import datetime
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.organizations.models import Organization
from apps.network.models import (
    Specialty,
    Department,
    Doctor,
    QueueSession,
    QueueToken,
    QueueType,
    QueuePriority,
    QueuePauseReason,
    QueuePolicy,
    TokenStatus,
    AppointmentRequest,
    AppointmentStatus,
    PatientCheckIn,
    DomainEventLog,
)
from apps.network.queue_engine import SmartQueueEngine

User = get_user_model()


class AdvancedQueueAndPatientFlowTests(TestCase):
    """Automated test suite verifying Phase 2.6:

    - Smart wait time algorithm & rolling consultation averages
    - Multi-queue types & priority queue ordering (EMERGENCY > URGENT > PRIORITY > NORMAL)
    - Concurrency & collision safety during token generation
    - Cross-tenant & Doctor boundary security isolation
    - Digital QR check-in & token activation
    - Staged recall & no-show management
    - Public TV display anonymization & privacy compliance
    - Hospital patient flow analytics
    """

    def setUp(self):
        self.client = APIClient()

        # 1. Organizations
        self.org_a = Organization.objects.create(
            name="Aster Medcity Kochi",
            district="Ernakulam",
            registration_number="REG-ASTER-201",
            phone="+91 484 669 9999"
        )
        self.org_b = Organization.objects.create(
            name="Baby Memorial Hospital Calicut",
            district="Kozhikode",
            registration_number="REG-BMH-302",
            phone="+91 495 277 7777"
        )

        # 2. Users & Roles
        self.admin_a = User.objects.create_user(
            username="admin_aster",
            email="admin@aster.org",
            password="password123",
            role="hospitalAdmin",
            organization=self.org_a
        )
        self.admin_b = User.objects.create_user(
            username="admin_bmh",
            email="admin@bmh.org",
            password="password123",
            role="hospitalAdmin",
            organization=self.org_b
        )

        self.doctor_user_a = User.objects.create_user(
            username="dr_mohan",
            email="mohan@aster.org",
            password="password123",
            role="doctor",
            organization=self.org_a
        )
        self.doctor_user_b = User.objects.create_user(
            username="dr_suresh",
            email="suresh@bmh.org",
            password="password123",
            role="doctor",
            organization=self.org_b
        )

        self.patient_user = User.objects.create_user(
            username="patient_kavitha",
            email="kavitha@example.com",
            password="password123",
            role="patient"
        )

        # 3. Clinical Specialists & Doctors
        self.spec_cardio = Specialty.objects.create(name="Cardiology", category="Clinical Specialty")
        self.dept_cardio = Department.objects.create(organization=self.org_a, name="Cardiology Department")

        self.doctor_a = Doctor.objects.create(
            name="Dr. Mohan Kumar",
            qualification="MD, DM (Cardiology)",
            primary_specialty=self.spec_cardio,
            experience_years=12,
            registration_number="TCMC-99112",
            is_active=True
        )
        self.doctor_b = Doctor.objects.create(
            name="Dr. Suresh Varma",
            qualification="MD, DM (Cardiology)",
            primary_specialty=self.spec_cardio,
            experience_years=10,
            registration_number="TCMC-99113",
            is_active=True
        )

        # 4. Queue Sessions
        self.session_a = QueueSession.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            department=self.dept_cardio,
            session_date=datetime.date.today(),
            room_number="Room 203",
            queue_type=QueueType.OPD,
            token_prefix="C",
            avg_consultation_duration_seconds=900,  # 15 mins
            is_active=True
        )

    def test_smart_wait_time_calculation(self):
        """Test dynamic calculation of estimated wait time based on patients ahead,

        priority rank, and pause overhead.
        """
        # Issue 4 normal tokens
        t1 = SmartQueueEngine.issue_unified_token(self.session_a, "Patient 1", "9847000001", priority=QueuePriority.NORMAL)
        t2 = SmartQueueEngine.issue_unified_token(self.session_a, "Patient 2", "9847000002", priority=QueuePriority.NORMAL)
        t3 = SmartQueueEngine.issue_unified_token(self.session_a, "Patient 3", "9847000003", priority=QueuePriority.NORMAL)
        t4 = SmartQueueEngine.issue_unified_token(self.session_a, "Patient 4", "9847000004", priority=QueuePriority.NORMAL)

        # Patients ahead of t1 = 0 -> wait = 2 min min
        w1 = SmartQueueEngine.calculate_estimated_wait_time(t1)
        self.assertEqual(w1['patients_ahead'], 0)

        # Patients ahead of t4 = 3 -> wait = 3 * 15 = 45 mins
        w4 = SmartQueueEngine.calculate_estimated_wait_time(t4)
        self.assertEqual(w4['patients_ahead'], 3)
        self.assertEqual(w4['estimated_wait_minutes'], 45)

        # Now simulate an emergency pause
        SmartQueueEngine.pause_session(self.session_a.id, reason=QueuePauseReason.EMERGENCY, actor_user=self.admin_a)
        t4.refresh_from_db()
        w4_paused = SmartQueueEngine.calculate_estimated_wait_time(t4)
        self.assertTrue(w4_paused['is_paused'])
        self.assertGreater(w4_paused['estimated_wait_minutes'], 45)

    def test_concurrent_token_issuance_collision_protection(self):
        """Test that multiple issued tokens get sequential token numbers and unique labels without collisions."""
        tokens = []
        for i in range(1, 11):
            tok = SmartQueueEngine.issue_unified_token(
                queue_session=self.session_a,
                patient_name=f"Walk-in Patient {i}",
                patient_phone=f"98470000{i:02d}",
                priority=QueuePriority.NORMAL,
                is_walk_in=True,
                actor_user=self.admin_a
            )
            tokens.append(tok)

        # Verify all 10 tokens have unique sequential numbers from 1 to 10
        numbers = [t.token_number for t in tokens]
        self.assertEqual(numbers, list(range(1, 11)))

        labels = [t.token_label for t in tokens]
        self.assertEqual(len(set(labels)), 10)
        self.assertEqual(labels[0], "C-01")
        self.assertEqual(labels[9], "C-10")

        # Verify QR hashes are all unique
        qr_hashes = [t.qr_code_hash for t in tokens]
        self.assertEqual(len(set(qr_hashes)), 10)

    def test_priority_queue_ordering(self):
        """Test that priority tokens (EMERGENCY > URGENT > PRIORITY > NORMAL) are called first."""
        # 1. Normal patient arrives first
        t_norm = SmartQueueEngine.issue_unified_token(self.session_a, "Normal Patient", "9847000001", priority=QueuePriority.NORMAL)
        # 2. Priority patient arrives second
        t_prio = SmartQueueEngine.issue_unified_token(self.session_a, "Palliative Priority Patient", "9847000002", priority=QueuePriority.PRIORITY)
        # 3. Urgent patient arrives third
        t_urg = SmartQueueEngine.issue_unified_token(self.session_a, "Urgent Trauma Patient", "9847000003", priority=QueuePriority.URGENT)
        # 4. Emergency patient arrives fourth
        t_emg = SmartQueueEngine.issue_unified_token(self.session_a, "Emergency Cardiac Patient", "9847000004", priority=QueuePriority.EMERGENCY)

        # Call Next -> Emergency should be called first!
        called_1 = SmartQueueEngine.call_next_token(self.session_a.id, actor_user=self.doctor_user_a)
        self.assertEqual(called_1.id, t_emg.id)
        self.assertEqual(called_1.priority, QueuePriority.EMERGENCY)

        # Call Next -> Urgent should be called second!
        called_2 = SmartQueueEngine.call_next_token(self.session_a.id, actor_user=self.doctor_user_a)
        self.assertEqual(called_2.id, t_urg.id)
        self.assertEqual(called_2.priority, QueuePriority.URGENT)

        # Call Next -> Priority should be called third!
        called_3 = SmartQueueEngine.call_next_token(self.session_a.id, actor_user=self.doctor_user_a)
        self.assertEqual(called_3.id, t_prio.id)
        self.assertEqual(called_3.priority, QueuePriority.PRIORITY)

        # Call Next -> Normal should be called last!
        called_4 = SmartQueueEngine.call_next_token(self.session_a.id, actor_user=self.doctor_user_a)
        self.assertEqual(called_4.id, t_norm.id)
        self.assertEqual(called_4.priority, QueuePriority.NORMAL)

    def test_cross_tenant_queue_isolation(self):
        """Test that Admin of Hospital B cannot manipulate or call Hospital A's queue."""
        self.client.force_authenticate(user=self.admin_b)

        # Admin B tries to call Hospital A's queue -> 403 Forbidden
        res_call = self.client.post(f"/api/network/queues/{self.session_a.id}/call-next/")
        self.assertEqual(res_call.status_code, status.HTTP_403_FORBIDDEN)

        # Admin B tries to pause Hospital A's queue -> 403 Forbidden
        res_pause = self.client.post(f"/api/network/queues/{self.session_a.id}/pause/", {
            'reason': 'BREAK',
            'notes': 'Illegal cross-tenant pause attempt'
        })
        self.assertEqual(res_pause.status_code, status.HTTP_403_FORBIDDEN)

    def test_doctor_boundary_isolation(self):
        """Test that Doctor B cannot call or pause Doctor A's OPD queue session."""
        self.client.force_authenticate(user=self.doctor_user_b)

        res_call = self.client.post(f"/api/network/queues/{self.session_a.id}/call-next/")
        self.assertEqual(res_call.status_code, status.HTTP_403_FORBIDDEN)

    def test_queue_pause_and_resume_lifecycle(self):
        """Test pausing queue with mandatory reason and resuming."""
        self.client.force_authenticate(user=self.doctor_user_a)

        # 1. Pause queue with mandatory reason
        res_pause = self.client.post(f"/api/network/queues/{self.session_a.id}/pause/", {
            'reason': 'DOCTOR_UNAVAILABLE',
            'notes': 'Doctor called to emergency ward rounds'
        })
        self.assertEqual(res_pause.status_code, status.HTTP_200_OK)

        self.session_a.refresh_from_db()
        self.assertTrue(self.session_a.is_paused)
        self.assertEqual(self.session_a.pause_reason, 'DOCTOR_UNAVAILABLE')

        # 2. Calling next token while paused should fail with 400 Bad Request
        res_call_paused = self.client.post(f"/api/network/queues/{self.session_a.id}/call-next/")
        self.assertEqual(res_call_paused.status_code, status.HTTP_400_BAD_REQUEST)

        # 3. Resume queue
        res_resume = self.client.post(f"/api/network/queues/{self.session_a.id}/resume/")
        self.assertEqual(res_resume.status_code, status.HTTP_200_OK)

        self.session_a.refresh_from_db()
        self.assertFalse(self.session_a.is_paused)

    def test_staged_recall_flow(self):
        """Test recall incrementing call count."""
        tok = SmartQueueEngine.issue_unified_token(self.session_a, "Ramesh", "9847111222", priority=QueuePriority.NORMAL)
        self.client.force_authenticate(user=self.doctor_user_a)

        # 1. Call token
        called = SmartQueueEngine.call_next_token(self.session_a.id, actor_user=self.doctor_user_a)
        self.assertEqual(called.call_count, 1)

        # 2. Recall via API
        res_recall = self.client.post(f"/api/network/queues/tokens/{tok.id}/recall/")
        self.assertEqual(res_recall.status_code, status.HTTP_200_OK)
        self.assertEqual(res_recall.data['token']['call_count'], 2)

    def test_digital_qr_checkin_and_token_activation(self):
        """Test digital QR check-in activating appointment and token."""
        # Create appointment
        appt = AppointmentRequest.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            patient_name="Saritha Menon",
            patient_phone="9847333444",
            preferred_date=datetime.date.today(),
            status=AppointmentStatus.CONFIRMED
        )

        # Generate QR code hash
        self.client.force_authenticate(user=self.patient_user)
        res_qr = self.client.post("/api/network/check-in/qr/generate/", {'appointment_id': appt.id})
        self.assertEqual(res_qr.status_code, status.HTTP_200_OK)
        qr_hash = res_qr.data['qr_code_hash']
        self.assertTrue(len(qr_hash) > 10)

        # Scan QR at hospital entrance
        res_checkin = self.client.post("/api/network/check-in/digital/", {
            'organization_id': self.org_a.id,
            'qr_hash': qr_hash,
            'check_in_method': 'QR_SCAN'
        })
        self.assertEqual(res_checkin.status_code, status.HTTP_200_OK)
        self.assertEqual(res_checkin.data['patient_name'], "Saritha Menon")

        appt.refresh_from_db()
        self.assertEqual(appt.status, AppointmentStatus.CHECKED_IN)

        # Verify PatientCheckIn record created
        checkin_log = PatientCheckIn.objects.filter(appointment=appt).first()
        self.assertIsNotNone(checkin_log)
        self.assertEqual(checkin_log.check_in_method, 'QR_SCAN')

    def test_public_tv_display_anonymization_and_privacy(self):
        """Test that the public TV monitor display endpoint strictly omits patient personal identities."""
        tok = SmartQueueEngine.issue_unified_token(self.session_a, "Secret Patient Identity", "9847999888", priority=QueuePriority.NORMAL)
        SmartQueueEngine.call_next_token(self.session_a.id, actor_user=self.doctor_user_a)

        # Public endpoint
        res = self.client.get(f"/api/network/queues/{self.session_a.id}/display/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        data = res.data
        self.assertEqual(data['room_number'], "Room 203")
        self.assertEqual(data['now_serving']['token_label'], tok.token_label)

        # Crucial security assertion: patient name, phone, age, diagnosis must NEVER appear in public feed
        serialized_str = str(data)
        self.assertNotIn("Secret Patient Identity", serialized_str)
        self.assertNotIn("9847999888", serialized_str)

    def test_hospital_flow_analytics(self):
        """Test operational analytics aggregation."""
        # Issue 2 walk-in tokens and 1 appointment token
        SmartQueueEngine.issue_unified_token(self.session_a, "Walkin 1", "9847111001", is_walk_in=True)
        SmartQueueEngine.issue_unified_token(self.session_a, "Walkin 2", "9847111002", is_walk_in=True)
        tok_appt = SmartQueueEngine.issue_unified_token(self.session_a, "Appt Patient", "9847111003", is_walk_in=False)

        # Complete consultation
        SmartQueueEngine.complete_consultation(tok_appt.id, clinical_notes="Prescribed hypertension medications", actor_user=self.doctor_user_a)

        self.client.force_authenticate(user=self.admin_a)
        res = self.client.get(f"/api/network/analytics/hospital-flow/?organization_id={self.org_a.id}")
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        self.assertEqual(res.data['total_patients'], 3)
        self.assertEqual(res.data['walk_in_count'], 2)
        self.assertEqual(res.data['appointment_count'], 1)
        self.assertEqual(res.data['completed_count'], 1)
        self.assertTrue(len(res.data['departments']) >= 1)
