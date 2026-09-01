from django.test import TestCase
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import (
    Patient, CarePlan, CareTeam, CareTeamMember, CareTeamRole,
    PatientCareGoal, CaregiverAccess, CaregiverPermission,
    MedicationPlan, MedicationAdministration, VitalsReading, PatientAuditLog
)
from apps.visits.models import (
    HomeVisit, HomeVisitRequest, VisitStatus, VisitType, VisitUrgency,
    HomeVisitStatusHistory, CareTeamRoute, RouteStop
)
from apps.alerts.models import ClinicalAlert, AlertType, AlertSeverity
from apps.visits.palliative_engine import PalliativeCareEngine
from apps.network.models import DomainEventLog


class PalliativeAndHomeHealthcareTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Hospital A: Calicut Medical Center (CMC)
        self.cmc_org = Organization.objects.create(
            name="Calicut Medical Center",
            district="Kozhikode",
            registration_number="KL-CMC-01",
        )
        self.cmc_admin = User.objects.create_user(
            username="admin_cmc", password="password123", role=UserRole.ORG_ADMIN, organization=self.cmc_org
        )
        self.cmc_doctor = User.objects.create_user(
            username="dr_anilkumar", password="password123", role=UserRole.DOCTOR, organization=self.cmc_org
        )
        self.cmc_nurse = User.objects.create_user(
            username="nurse_anitha", password="password123", role=UserRole.NURSE, organization=self.cmc_org
        )
        self.cmc_physio = User.objects.create_user(
            username="physio_rahul", password="password123", role=UserRole.VOLUNTEER, organization=self.cmc_org
        )

        # Hospital B: Aster Malabar (For Multi-Tenant Isolation)
        self.aster_org = Organization.objects.create(
            name="Aster Malabar Institute",
            district="Kozhikode",
            registration_number="KL-AST-02",
        )
        self.aster_admin = User.objects.create_user(
            username="admin_aster", password="password123", role=UserRole.ORG_ADMIN, organization=self.aster_org
        )
        self.aster_nurse = User.objects.create_user(
            username="nurse_bhavana", password="password123", role=UserRole.NURSE, organization=self.aster_org
        )

        # Patients
        self.patient_basheer = Patient.objects.create(
            organization=self.cmc_org,
            patient_id_code="PAL-KZD-001",
            name="Muhammed Basheer",
            age=78,
            gender="Male",
            blood_group="B+",
            district="Kozhikode",
            ward="Feroke Ward 04",
            address="Peace Haven, Feroke, Kozhikode",
            phone="+919847233445",
            diagnosis="Stage IV Lung Carcinoma with Skeletal Metastases",
            category_tier="Category A (Bedridden)",
            risk_level="High Risk",
            emergency_contact_name="Fathima Basheer",
            emergency_contact_phone="+919847233446",
        )

        # Caregiver (Family Member)
        self.caregiver_user = User.objects.create_user(
            username="fathima_caregiver", password="password123", role=UserRole.FAMILY_MEMBER, phone="+919847233446"
        )

        # Multi-Disciplinary Care Team
        self.care_team = CareTeam.objects.create(
            organization=self.cmc_org,
            name="Feroke Palliative Care Team A",
            lead_doctor=self.cmc_doctor,
            primary_nurse=self.cmc_nurse,
            area_coverage="Feroke, Ramanattukara, Kadalundi",
        )
        CareTeamMember.objects.create(
            care_team=self.care_team, user=self.cmc_doctor, member_name="Dr. Anil Kumar", role=CareTeamRole.DOCTOR, phone="+919847000001"
        )
        CareTeamMember.objects.create(
            care_team=self.care_team, user=self.cmc_nurse, member_name="Nurse Anitha", role=CareTeamRole.NURSE, phone="+919847000002", is_primary=True
        )
        CareTeamMember.objects.create(
            care_team=self.care_team, user=self.cmc_physio, member_name="Physio Rahul", role=CareTeamRole.PHYSIOTHERAPIST, phone="+919847000003"
        )

        # Comprehensive Care Plan
        self.care_plan = CarePlan.objects.create(
            patient=self.patient_basheer,
            care_team=self.care_team,
            primary_nurse_name="Nurse Anitha",
            assigned_doctor_name="Dr. Anil Kumar",
            care_goals="Intensive palliative pain management, bedsore dressing prevention, respiratory support, and family counseling.",
            pain_assessment_protocol="WHO Step 3 Analgesic Ladder; Morphine syrup titration; Breakthrough pain protocol.",
            mobility_status="Bedridden (Category A)",
            dietary_instructions="Soft high-protein pureed diet; strict aspiration precautions.",
            visit_frequency="Weekly",
            emergency_escalation_notes="Contact 24x7 Palliative Desk: +91 495 272 1000",
            dnr_or_advanced_directives="Patient and family counselled; focus on symptom relief and dignified comfort care.",
        )

    def test_01_home_visit_request_lifecycle(self):
        """Patient/family requests home visit -> Hospital accepts -> Scheduled HomeVisit is created."""
        req = PalliativeCareEngine.request_home_visit(
            patient_id=self.patient_basheer.id,
            preferred_date=timezone.now().date() + timedelta(days=2),
            reason_and_symptoms="Severe breakthrough pain and catheter drainage review.",
            requester_name="Fathima Basheer",
            requester_phone="+919847233446",
            requester_relationship="Daughter",
            visit_type=VisitType.PAIN_MANAGEMENT,
            urgency=VisitUrgency.URGENT,
            requested_by_user=self.caregiver_user,
        )

        self.assertEqual(req.status, 'PENDING')
        self.assertEqual(req.urgency, VisitUrgency.URGENT)

        # Hospital Admin accepts request
        visit = PalliativeCareEngine.accept_home_visit_request(
            request_id=req.id,
            actor_user=self.cmc_admin,
            scheduled_date=req.preferred_date,
            scheduled_time="11:00 AM",
            care_team_id=self.care_team.id,
        )

        self.assertEqual(visit.status, VisitStatus.SCHEDULED)
        self.assertEqual(visit.assigned_nurse_name, "nurse_anitha")
        self.assertEqual(visit.visit_type, VisitType.PAIN_MANAGEMENT)
        req.refresh_from_db()
        self.assertEqual(req.status, 'ACCEPTED')

        # Status History check
        history = HomeVisitStatusHistory.objects.filter(visit=visit)
        self.assertTrue(history.exists())
        self.assertEqual(history.first().to_status, VisitStatus.SCHEDULED)

    def test_02_care_team_assignment_and_role_scoping(self):
        """Care team members can be managed and verified for a palliative care unit."""
        self.client.force_authenticate(user=self.cmc_admin)

        # API check on care teams
        response = self.client.get('/api/patients/care-teams/')
        self.assertEqual(response.status_code, 200)
        results = response.data.get('results', response.data)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['name'], "Feroke Palliative Care Team A")
        self.assertEqual(len(results[0]['members']), 3)

        # Add Counselor to team
        add_res = self.client.post(f'/api/patients/care-teams/{self.care_team.id}/add_member/', {
            'member_name': 'Counselor Divya MSW',
            'role': 'COUNSELOR',
            'phone': '+919847000004'
        })
        self.assertEqual(add_res.status_code, 201)
        self.assertEqual(self.care_team.members.count(), 4)

    def test_03_field_nurse_visit_execution_with_vitals(self):
        """Nurse dispatches, arrives at patient home, records vitals and completes visit."""
        visit = HomeVisit.objects.create(
            organization=self.cmc_org,
            patient=self.patient_basheer,
            care_team=self.care_team,
            assigned_nurse_name="Nurse Anitha",
            scheduled_date=timezone.now().date(),
            scheduled_time="10:00 AM",
            status=VisitStatus.SCHEDULED,
        )

        # 1. Dispatch
        PalliativeCareEngine.dispatch_care_team(visit.id, self.cmc_nurse)
        visit.refresh_from_db()
        self.assertEqual(visit.status, VisitStatus.TEAM_DISPATCHED)
        self.assertIsNotNone(visit.dispatch_timestamp)

        # 2. Arrive
        PalliativeCareEngine.record_visit_arrival(
            visit.id, self.cmc_nurse, gps_location_name="Feroke Coordinates (11.168, 75.834)"
        )
        visit.refresh_from_db()
        self.assertEqual(visit.status, VisitStatus.IN_PROGRESS)
        self.assertIsNotNone(visit.arrival_timestamp)

        # 3. Complete with Vitals
        vitals_dict = {
            'bp': '118/76',
            'pulse': 82,
            'spo2': 96,
            'temperature': 98.4,
            'pain_scale': 4,
            'respiratory_rate': 18,
            'blood_sugar': 130,
        }
        PalliativeCareEngine.complete_home_visit(
            visit_id=visit.id,
            actor_user=self.cmc_nurse,
            symptoms_observed="Patient rested; mild leg edema.",
            assessment_notes="Catheter patent, dressing clean and intact.",
            care_provided="Wound cleaning, catheter flush, analgesic adjustment instructions.",
            medication_administered="Morphine 10mg PO, Paracetamol 500mg",
            vitals_data=vitals_dict,
        )

        visit.refresh_from_db()
        self.assertEqual(visit.status, VisitStatus.COMPLETED)
        self.assertIsNotNone(visit.vitals_reading)
        self.assertEqual(visit.vitals_reading.spo2, 96)
        self.assertEqual(visit.vitals_reading.pain_scale, 4)

    def test_04_vitals_deterministic_alert_triggering(self):
        """Abnormal vitals recorded during home visit trigger deterministic ClinicalAlerts."""
        visit = HomeVisit.objects.create(
            organization=self.cmc_org,
            patient=self.patient_basheer,
            care_team=self.care_team,
            assigned_nurse_name="Nurse Anitha",
            scheduled_date=timezone.now().date(),
            scheduled_time="10:00 AM",
            status=VisitStatus.IN_PROGRESS,
        )

        # Complete visit with SpO2 = 88% (< 92%) and Pain Scale = 9 (>= 8)
        abnormal_vitals = {
            'bp': '90/60',
            'pulse': 115,
            'spo2': 88, # Critical trigger
            'temperature': 100.2,
            'pain_scale': 9, # High pain trigger
            'respiratory_rate': 26,
        }

        PalliativeCareEngine.complete_home_visit(
            visit_id=visit.id,
            actor_user=self.cmc_nurse,
            care_provided="Oxygen administered via concentrator. Immediate doctor alerted.",
            vitals_data=abnormal_vitals,
        )

        # Check that ClinicalAlerts were generated
        alerts = ClinicalAlert.objects.filter(patient=self.patient_basheer, organization=self.cmc_org)
        self.assertTrue(alerts.exists())
        critical_alert = alerts.filter(severity=AlertSeverity.CRITICAL).first()
        self.assertIsNotNone(critical_alert)
        self.assertIn("Low Oxygen Saturation", critical_alert.title)

    def test_05_palliative_emergency_escalation(self):
        """Explicit emergency escalation by clinician generates critical alert and domain event."""
        alert = PalliativeCareEngine.evaluate_palliative_emergency_escalation(
            patient_id=self.patient_basheer.id,
            alert_reason="Sudden onset severe respiratory distress and uncontrolled pain crisis.",
            actor_user=self.cmc_nurse,
        )

        self.assertEqual(alert.severity, AlertSeverity.CRITICAL)
        self.assertEqual(alert.patient, self.patient_basheer)

        # Verify domain event log
        event_log = DomainEventLog.objects.filter(
            event_type='PALLIATIVE_EMERGENCY_ESCALATED', organization_id=self.cmc_org.id
        ).first()
        self.assertIsNotNone(event_log)

    def test_06_medication_plan_and_adherence_logging(self):
        """Medication plans track schedules and dose administrations (patient-reported & nurse-verified)."""
        med_plan = MedicationPlan.objects.create(
            patient=self.patient_basheer,
            medicine_name="Oral Morphine Syrup (10mg/5ml)",
            dosage="5ml (10mg)",
            route="Oral",
            frequency="Every 4 Hours",
            time_slots=["06:00 AM", "10:00 AM", "02:00 PM", "06:00 PM", "10:00 PM"],
            prescribed_by_doctor="Dr. Anil Kumar",
            start_date=timezone.now().date(),
        )

        # Patient/Family logs morning dose
        admin_1 = PalliativeCareEngine.record_medication_intake(
            medication_plan_id=med_plan.id,
            time_slot="06:00 AM",
            status="TAKEN",
            actor_user=self.caregiver_user,
            is_nurse_verified=False,
            notes="Given with warm water as prescribed.",
        )
        self.assertEqual(admin_1.status, "TAKEN")
        self.assertTrue(admin_1.recorded_by_caregiver)
        self.assertFalse(admin_1.verified_by_nurse)

        # Nurse verifies and logs 10:00 AM dose during home visit
        admin_2 = PalliativeCareEngine.record_medication_intake(
            medication_plan_id=med_plan.id,
            time_slot="10:00 AM",
            status="TAKEN",
            actor_user=self.cmc_nurse,
            is_nurse_verified=True,
            notes="Administered directly during home visit.",
        )
        self.assertTrue(admin_2.verified_by_nurse)
        self.assertEqual(admin_2.verified_nurse_name, "nurse_anitha")

    def test_07_caregiver_access_and_privacy_enforcement(self):
        """Caregiver can view allowed info (visits, vitals) but is blocked from raw clinical records without permission."""
        # Grant caregiver VIEW_VISITS and VIEW_VITALS
        grant = PalliativeCareEngine.grant_caregiver_access(
            patient_id=self.patient_basheer.id,
            caregiver_name="Fathima Basheer",
            caregiver_phone="+919847233446",
            permissions=[CaregiverPermission.VIEW_BASIC_INFO, CaregiverPermission.VIEW_VISITS, CaregiverPermission.VIEW_VITALS],
            actor_user=self.cmc_admin,
            relationship="Daughter",
            caregiver_user=self.caregiver_user,
        )

        self.assertTrue(grant.has_permission(CaregiverPermission.VIEW_VISITS))
        self.assertFalse(grant.has_permission(CaregiverPermission.VIEW_CARE_PLAN))

        # Caregiver logs in
        self.client.force_authenticate(user=self.caregiver_user)

        # 1. Caregiver can view patient list (their granted patient)
        p_res = self.client.get('/api/patients/')
        self.assertEqual(p_res.status_code, 200)
        p_results = p_res.data.get('results', p_res.data)
        self.assertEqual(len(p_results), 1)

        # 2. Caregiver cannot access CarePlan directly without VIEW_CARE_PLAN permission
        cp_res = self.client.get('/api/patients/care-plans/')
        self.assertEqual(cp_res.status_code, 200)
        cp_results = cp_res.data.get('results', cp_res.data)
        self.assertEqual(len(cp_results), 0)

    def test_08_multi_tenant_isolation(self):
        """Hospital Aster staff cannot view or mutate CMC's palliative patients or visits."""
        self.client.force_authenticate(user=self.aster_nurse)

        # Aster nurse tries to view CMC patients
        p_res = self.client.get('/api/patients/')
        self.assertEqual(p_res.status_code, 200)
        p_results = p_res.data.get('results', p_res.data)
        self.assertEqual(len(p_results), 0)

        # Aster nurse tries to view CMC visits
        v_res = self.client.get('/api/visits/')
        self.assertEqual(v_res.status_code, 200)
        v_results = v_res.data.get('results', v_res.data)
        self.assertEqual(len(v_results), 0)

        # Aster nurse tries to view CMC care teams
        ct_res = self.client.get('/api/patients/care-teams/')
        self.assertEqual(ct_res.status_code, 200)
        ct_results = ct_res.data.get('results', ct_res.data)
        self.assertEqual(len(ct_results), 0)

    def test_09_care_team_daily_route_planning(self):
        """Daily visit routes sequence multiple stops for field nurses."""
        # Create 3 visits for today
        v1 = HomeVisit.objects.create(
            organization=self.cmc_org, patient=self.patient_basheer, care_team=self.care_team,
            assigned_nurse_name="Nurse Anitha", scheduled_date=timezone.now().date(), scheduled_time="09:30 AM"
        )
        v2 = HomeVisit.objects.create(
            organization=self.cmc_org, patient=self.patient_basheer, care_team=self.care_team,
            assigned_nurse_name="Nurse Anitha", scheduled_date=timezone.now().date(), scheduled_time="11:00 AM"
        )

        self.client.force_authenticate(user=self.cmc_admin)
        route_res = self.client.post('/api/visits/routes/plan_route/', {
            'care_team_id': self.care_team.id,
            'route_date': str(timezone.now().date()),
            'visit_ids': [v1.id, v2.id],
        }, format='json')

        self.assertEqual(route_res.status_code, 201)
        self.assertEqual(route_res.data['total_stops'], 2)
        self.assertEqual(len(route_res.data['stops']), 2)
        self.assertEqual(route_res.data['stops'][0]['sequence_order'], 1)
        self.assertEqual(route_res.data['stops'][1]['sequence_order'], 2)

    def test_10_audit_log_verification(self):
        """All palliative actions, vitals additions, visits, and caregiver grants generate audit log entries."""
        logs_count_before = PatientAuditLog.objects.filter(patient=self.patient_basheer).count()

        # Add vitals via API
        self.client.force_authenticate(user=self.cmc_nurse)
        self.client.post(f'/api/patients/{self.patient_basheer.id}/add_vitals/', {
            'bp': '124/80',
            'pulse': 76,
            'spo2': 97,
            'temperature': 98.6,
            'pain_scale': 2,
            'respiratory_rate': 16,
        })

        logs_count_after = PatientAuditLog.objects.filter(patient=self.patient_basheer).count()
        self.assertGreater(logs_count_after, logs_count_before)
        latest_log = PatientAuditLog.objects.filter(patient=self.patient_basheer).latest('timestamp')
        self.assertEqual(latest_log.action, 'ADD_VITALS')
