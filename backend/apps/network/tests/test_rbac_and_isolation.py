from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from apps.organizations.models import Organization
from apps.network.models import (
    Specialty,
    HealthcareProfile,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
    ChangeRequest,
    ClaimOrganizationRequest,
    AppointmentRequest,
)

User = get_user_model()

class NetworkRBACAndIsolationTests(TestCase):
    """Rigorous RBAC, cross-tenant isolation, and public/private data separation test suite"""

    def setUp(self):
        self.client = APIClient()

        # 1. Super Admin
        self.superadmin = User.objects.create_superuser(
            username='superadmin',
            email='superadmin@carelink.kerala.gov.in',
            password='AdminPassword123#',
            role='superAdmin'
        )

        # 2. Hospital A (Calicut Medical Center) & Users
        self.org_a = Organization.objects.create(
            name='Calicut Medical Center',
            district='Kozhikode',
            phone='+914952800100',
            registration_number='CMC/KZD/2024/01',
            status='ACTIVE'
        )
        self.admin_a = User.objects.create_user(
            username='admin_a',
            email='admin_a@cmc.org',
            password='Password123#',
            role='orgAdmin',
            organization=self.org_a
        )
        self.moderator_a = User.objects.create_user(
            username='moderator_a',
            email='moderator_a@cmc.org',
            password='Password123#',
            role='moderator',
            organization=self.org_a
        )

        # 3. Hospital B (Kochi Specialty Care) & Users
        self.org_b = Organization.objects.create(
            name='Kochi Specialty Care',
            district='Ernakulam',
            phone='+914842900200',
            registration_number='KSC/EKM/2024/02',
            status='ACTIVE'
        )
        self.admin_b = User.objects.create_user(
            username='admin_b',
            email='admin_b@ksc.org',
            password='Password123#',
            role='orgAdmin',
            organization=self.org_b
        )

        # 4. Public Patient
        self.patient = User.objects.create_user(
            username='patient_user',
            email='patient@gmail.com',
            password='Password123#',
            role='patient'
        )

        # 5. Core Catalog & Profile for Org A
        self.specialty_palliative = Specialty.objects.create(
            name='Palliative Medicine',
            category='Clinical Care'
        )
        self.profile_a = HealthcareProfile.objects.create(
            organization=self.org_a,
            organization_type='HOSPITAL',
            verification_status='VERIFIED',
            district='Kozhikode',
            phone=self.org_a.phone,
            emergency_phone='+914952800999',
            is_24x7_emergency=True,
            total_beds=200,
            icu_beds=20
        )
        self.profile_a.specialties.add(self.specialty_palliative)

        # 6. Doctor & Affiliation at Org A
        self.doctor_a = Doctor.objects.create(
            name='Dr. Priya Varma',
            qualification='MBBS, MD (Palliative Medicine)',
            primary_specialty=self.specialty_palliative,
            registration_number='TCMC/64291/K'
        )
        self.aff_a = DoctorAffiliation.objects.create(
            doctor=self.doctor_a,
            organization=self.org_a,
            designation='Lead Consultant',
            consultation_fee=0.00
        )
        self.schedule_a = DoctorSchedule.objects.create(
            affiliation=self.aff_a,
            day_of_week='MONDAY',
            start_time='09:00 AM',
            end_time='01:00 PM',
            location_room='Room 101'
        )

        # 7. Change Request for Org A
        self.cr_a = ChangeRequest.objects.create(
            organization=self.org_a,
            requested_by=self.moderator_a,
            entity_type='DOCTOR_SCHEDULE',
            change_summary='Update Monday OPD to 10:00 AM',
            status='PENDING'
        )

        # 8. Appointment Request for Org A
        self.appt_a = AppointmentRequest.objects.create(
            organization=self.org_a,
            doctor=self.doctor_a,
            patient_name='Rahul Menon',
            patient_phone='+919847000000',
            preferred_date='2026-09-05',
            status='REQUESTED'
        )

    def test_public_directory_accessible_unauthenticated(self):
        """Public patients can query directory without auth"""
        response = self.client.get('/api/network/directory/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data['count'], 1)
        # Verify no internal fields leaked
        first = response.data['results'][0]
        self.assertIn('organization_name', first)
        self.assertIn('data_freshness_tier', first)
        self.assertNotIn('verified_by', first)

    def test_cross_tenant_isolation_change_requests(self):
        """Org Admin B CANNOT review or approve Org A's change request (Must return 403)"""
        self.client.force_authenticate(user=self.admin_b)
        response = self.client.post(
            f'/api/network/change-requests/{self.cr_a.id}/review/',
            {'action': 'APPROVE', 'notes': 'Unauthorized attempt'}
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.cr_a.refresh_from_db()
        self.assertEqual(self.cr_a.status, 'PENDING')

    def test_anti_self_approval_for_moderators(self):
        """Moderator A CANNOT approve their own change request (Must return 403)"""
        self.client.force_authenticate(user=self.moderator_a)
        response = self.client.post(
            f'/api/network/change-requests/{self.cr_a.id}/review/',
            {'action': 'APPROVE', 'notes': 'Self-approval attempt'}
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.cr_a.refresh_from_db()
        self.assertEqual(self.cr_a.status, 'PENDING')

    def test_org_admin_can_approve_own_org_change_request(self):
        """Org Admin A CAN approve change request belonging to Org A"""
        self.client.force_authenticate(user=self.admin_a)
        response = self.client.post(
            f'/api/network/change-requests/{self.cr_a.id}/review/',
            {'action': 'APPROVE', 'notes': 'Approved by CMC Administrator'}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.cr_a.refresh_from_db()
        self.assertEqual(self.cr_a.status, 'APPROVED')
        self.assertEqual(self.cr_a.reviewed_by, self.admin_a)

    def test_cross_tenant_isolation_appointments(self):
        """Org Admin B CANNOT manage appointments for Org A (Must return 403)"""
        self.client.force_authenticate(user=self.admin_b)
        response = self.client.post(
            f'/api/network/appointments/{self.appt_a.id}/status/',
            {'status': 'ACCEPTED'}
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.appt_a.refresh_from_db()
        self.assertEqual(self.appt_a.status, 'REQUESTED')

    def test_org_admin_can_accept_own_appointment(self):
        """Org Admin A CAN accept appointments for Org A"""
        self.client.force_authenticate(user=self.admin_a)
        response = self.client.post(
            f'/api/network/appointments/{self.appt_a.id}/status/',
            {'status': 'ACCEPTED'}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.appt_a.refresh_from_db()
        self.assertEqual(self.appt_a.status, 'ACCEPTED')

    def test_platform_admin_dashboard_restricted(self):
        """Patients and Org Admins CANNOT access platform dashboard; Super Admins CAN"""
        # 1. Patient fails
        self.client.force_authenticate(user=self.patient)
        resp = self.client.get('/api/network/admin/dashboard/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

        # 2. Org Admin fails
        self.client.force_authenticate(user=self.admin_a)
        resp = self.client.get('/api/network/admin/dashboard/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

        # 3. Super Admin succeeds
        self.client.force_authenticate(user=self.superadmin)
        resp = self.client.get('/api/network/admin/dashboard/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('total_organizations', resp.data)

    def test_claim_organization_workflow_and_role_promotion(self):
        """Claim submission by new user, followed by Super Admin approval promotes user to Org Admin"""
        claimant = User.objects.create_user(
            username='doctor_claimant',
            email='claimant@ksc.org',
            password='Password123#',
            role='doctor'
        )
        self.client.force_authenticate(user=claimant)

        # Submit claim
        claim_resp = self.client.post('/api/network/organizations/claim/', {
            'organization_id': self.org_b.id,
            'claimant_designation': 'Medical Director',
            'official_email': 'claimant@ksc.org',
            'proof_document_url': 'https://storage.supabase.co/license_ksc.pdf'
        })
        self.assertEqual(claim_resp.status_code, status.HTTP_201_CREATED)
        claim_id = claim_resp.data['claim_id']

        # Super Admin approves claim
        self.client.force_authenticate(user=self.superadmin)
        review_resp = self.client.post(f'/api/network/organizations/claims/{claim_id}/review/', {
            'action': 'APPROVE',
            'notes': 'Official Medical Council License verified.'
        })
        self.assertEqual(review_resp.status_code, status.HTTP_200_OK)

        # Verify claimant was promoted to Org Admin of Org B
        claimant.refresh_from_db()
        self.assertEqual(claimant.organization, self.org_b)
        self.assertEqual(claimant.role, 'orgAdmin')
