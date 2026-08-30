from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from apps.organizations.models import Organization
from apps.network.models import (
    Specialty,
    Department,
    HealthcareProfile,
    HealthcareProspect,
    OrganizationInvitation,
    OrganizationMembership,
    HospitalTeamInvitation,
    Doctor,
    DoctorAffiliation,
)

User = get_user_model()

class TeamGovernanceAndOnboardingTests(TestCase):
    """End-to-End Governance, Invitation Security, Multi-Tenant Sovereign Approval, and Public Quarantine Tests"""

    def setUp(self):
        self.client = APIClient()

        # 1. Super Admin
        self.superadmin = User.objects.create_superuser(
            username='carelink_superadmin',
            email='superadmin@carelink.in',
            password='AdminPassword123#',
            role='superAdmin'
        )

        # 2. Existing Hospital A (Calicut Medical Center)
        self.org_a = Organization.objects.create(
            name='Calicut Medical Center',
            district='Kozhikode',
            phone='+914952111111',
            registration_number='CMC/2024/01',
            status='ACTIVE'
        )
        self.profile_a = HealthcareProfile.objects.create(
            organization=self.org_a,
            organization_type='HOSPITAL',
            verification_status='VERIFIED',
            lifecycle_status='PUBLISHED',
            is_published=True,
            district='Kozhikode'
        )
        self.admin_a = User.objects.create_user(
            username='cmc_admin',
            email='admin@cmc.in',
            password='Password123#',
            role='orgAdmin',
            organization=self.org_a
        )
        self.membership_a = OrganizationMembership.objects.create(
            user=self.admin_a,
            organization=self.org_a,
            role='ORGANIZATION_ADMIN',
            status='ACTIVE'
        )

        # 3. Existing Hospital B (Kochi Aster Hospital)
        self.org_b = Organization.objects.create(
            name='Kochi Aster Hospital',
            district='Ernakulam',
            phone='+914842222222',
            registration_number='AST/2024/02',
            status='ACTIVE'
        )
        self.profile_b = HealthcareProfile.objects.create(
            organization=self.org_b,
            organization_type='HOSPITAL',
            verification_status='VERIFIED',
            lifecycle_status='PUBLISHED',
            is_published=True,
            district='Ernakulam'
        )
        self.admin_b = User.objects.create_user(
            username='aster_admin',
            email='admin@aster.in',
            password='Password123#',
            role='orgAdmin',
            organization=self.org_b
        )
        self.membership_b = OrganizationMembership.objects.create(
            user=self.admin_b,
            organization=self.org_b,
            role='ORGANIZATION_ADMIN',
            status='ACTIVE'
        )

        # 4. Specialty & Department
        self.cardiology = Specialty.objects.create(name='Cardiology', category='Clinical Specialty')
        self.dept_cardio_a = Department.objects.create(organization=self.org_a, name='Cardiology Department')
        self.dept_cardio_b = Department.objects.create(organization=self.org_b, name='Cardiology Department')

    def test_prospect_pipeline_creation_and_invitation(self):
        """Platform Super Admin tracks prospective hospital and issues token invitation"""
        self.client.force_authenticate(user=self.superadmin)

        # 1. Create Prospect
        resp_p = self.client.post('/api/network/platform/prospects/', {
            'name': 'Malabar Hospital Manjeri',
            'district': 'Malappuram',
            'organization_type': 'HOSPITAL',
            'ownership_type': 'PRIVATE',
            'contact_person': 'Dr. Faizal Rahman',
            'contact_designation': 'Medical Superintendent',
            'contact_phone': '+914832731111',
            'contact_email': 'faizal@malabarhospital.in',
            'status': 'CONTACTED',
            'internal_notes': 'Interested in joining CareLink Network'
        })
        self.assertEqual(resp_p.status_code, status.HTTP_201_CREATED)
        prospect_id = resp_p.data['id']

        # 2. Issue Invitation Token
        resp_inv = self.client.post('/api/network/platform/organizations/invite-admin/', {
            'name': 'Malabar Hospital Manjeri',
            'district': 'Malappuram',
            'phone': '+914832731111',
            'recipient_name': 'Dr. Faizal Rahman',
            'recipient_email': 'faizal@malabarhospital.in',
            'recipient_designation': 'Medical Superintendent',
            'prospect_id': prospect_id
        })
        self.assertEqual(resp_inv.status_code, status.HTTP_201_CREATED)
        token = resp_inv.data['token']
        self.assertTrue(len(token) > 20)

        # 3. Validate Token Publicly
        self.client.logout()
        resp_val = self.client.get(f'/api/network/invitations/{token}/validate/')
        self.assertEqual(resp_val.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_val.data['recipient_name'], 'Dr. Faizal Rahman')
        self.assertEqual(resp_val.data['is_valid'], True)

        # 4. Activate Account & Set Password
        resp_act = self.client.post(f'/api/network/invitations/{token}/activate/', {
            'password': 'DrFaizalSecurePass123#'
        })
        self.assertEqual(resp_act.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_act.data['next_step'], 'WIZARD_SETUP')

        # Check User & Membership Created
        user_faizal = User.objects.get(email='faizal@malabarhospital.in')
        self.assertTrue(user_faizal.check_password('DrFaizalSecurePass123#'))
        membership = OrganizationMembership.objects.get(user=user_faizal)
        self.assertEqual(membership.role, 'ORGANIZATION_ADMIN')

    def test_setup_wizard_completion_and_quarantine_before_approval(self):
        """Unpublished hospital completing wizard is quarantined from public directory search until SuperAdmin approval"""
        # Create unverified/invited hospital
        org_c = Organization.objects.create(
            name='Travancore Clinic Kollam',
            district='Kollam',
            phone='+914742777777',
            registration_number='TCK/2024/03',
            status='UNDER_REVIEW'
        )
        profile_c = HealthcareProfile.objects.create(
            organization=org_c,
            lifecycle_status='ACTIVATED',
            verification_status='UNVERIFIED',
            is_published=False,
            district='Kollam'
        )
        admin_c = User.objects.create_user(
            username='tck_admin',
            email='admin@tck.in',
            password='Password123#',
            role='orgAdmin',
            organization=org_c
        )
        OrganizationMembership.objects.create(
            user=admin_c,
            organization=org_c,
            role='ORGANIZATION_ADMIN',
            status='PENDING_APPROVAL'
        )

        self.client.force_authenticate(user=admin_c)

        # 1. Update Wizard Steps
        resp_wiz = self.client.post('/api/network/onboarding/wizard/', {
            'address': 'Main Road, Beach Road',
            'district': 'Kollam',
            'pincode': '691001',
            'phone': '+914742777777',
            'email': 'admin@tck.in',
            'emergency_phone': '+914742777999',
            'is_24x7_emergency': True,
            'total_beds': 120,
            'icu_beds': 15
        })
        self.assertEqual(resp_wiz.status_code, status.HTTP_200_OK)
        self.assertTrue(resp_wiz.data['completeness_percentage'] >= 50)

        # 2. Hospital Admin attempts self-publishing -> REJECTED (403)
        resp_self_pub = self.client.post('/api/network/onboarding/submit/', {'action': 'PUBLISH'})
        self.assertEqual(resp_self_pub.status_code, status.HTTP_403_FORBIDDEN)

        # 3. Hospital Admin submits for CareLink Review
        resp_sub = self.client.post('/api/network/onboarding/submit/')
        self.assertEqual(resp_sub.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_sub.data['lifecycle_status'], 'SUBMITTED_FOR_REVIEW')

        # 4. Strict Public Quarantine: Anonymous user searches Kollam -> 0 results
        self.client.logout()
        resp_search = self.client.get('/api/network/directory/?district=Kollam')
        self.assertEqual(resp_search.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_search.data['results']), 0)

        # 5. Super Admin Review & Approval
        self.client.force_authenticate(user=self.superadmin)
        resp_appr = self.client.post(f'/api/network/admin/organizations/{org_c.id}/review-decision/', {
            'action': 'APPROVE',
            'review_notes': 'Documents and infrastructure verified.'
        })
        self.assertEqual(resp_appr.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_appr.data['lifecycle_status'], 'PUBLISHED')
        self.assertEqual(resp_appr.data['verification_status'], 'VERIFIED')

        # 6. Now visible in public search with Verified status
        self.client.logout()
        resp_search_after = self.client.get('/api/network/directory/?district=Kollam')
        self.assertEqual(resp_search_after.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_search_after.data['results']), 1)
        self.assertEqual(resp_search_after.data['results'][0]['organization_name'], 'Travancore Clinic Kollam')
        self.assertEqual(resp_search_after.data['results'][0]['is_carelink_verified'], True)

    def test_hospital_team_invite_security_and_role_hierarchy(self):
        """Hospital Admin cannot grant Platform Super Admin roles"""
        self.client.force_authenticate(user=self.admin_a)

        # Attempt to grant SUPER_ADMIN
        resp_bad = self.client.post('/api/network/team/invite/', {
            'name': 'Hacker Admin',
            'email': 'hacker@test.com',
            'role': 'SUPER_ADMIN'
        })
        self.assertEqual(resp_bad.status_code, status.HTTP_403_FORBIDDEN)

        # Successfully invite Doctor
        resp_good = self.client.post('/api/network/team/invite/', {
            'name': 'Dr. Priya Varma',
            'email': 'priya.varma@med.in',
            'phone': '+919847111222',
            'role': 'DOCTOR',
            'department_id': self.dept_cardio_a.id,
            'designation': 'Consultant Cardiologist'
        })
        self.assertEqual(resp_good.status_code, status.HTTP_201_CREATED)
        self.assertTrue(len(resp_good.data['token']) > 10)

    def test_multi_hospital_doctor_and_cross_tenant_sovereign_approval(self):
        """A doctor can belong to multiple hospitals, but each hospital admin can only approve for their own hospital"""
        # Create Doctor User
        dr_priya = User.objects.create_user(
            username='dr_priya',
            email='priya.varma@med.in',
            password='Password123#',
            role='doctor'
        )

        # 1. Membership at Hospital A (Pending Approval)
        m_a = OrganizationMembership.objects.create(
            user=dr_priya,
            organization=self.org_a,
            role='DOCTOR',
            department=self.dept_cardio_a,
            status='PENDING_APPROVAL'
        )

        # 2. Membership at Hospital B (Pending Approval)
        m_b = OrganizationMembership.objects.create(
            user=dr_priya,
            organization=self.org_b,
            role='DOCTOR',
            department=self.dept_cardio_b,
            status='PENDING_APPROVAL'
        )

        # ATTACK: Hospital B Admin attempts to approve Hospital A's membership -> 403 FORBIDDEN
        self.client.force_authenticate(user=self.admin_b)
        resp_attack = self.client.post(f'/api/network/team/{m_a.id}/decision/', {'action': 'APPROVE'})
        self.assertEqual(resp_attack.status_code, status.HTTP_403_FORBIDDEN)

        # Hospital A Admin approves Dr. Priya for Hospital A -> 200 OK
        self.client.force_authenticate(user=self.admin_a)
        resp_appr_a = self.client.post(f'/api/network/team/{m_a.id}/decision/', {'action': 'APPROVE'})
        self.assertEqual(resp_appr_a.status_code, status.HTTP_200_OK)

        m_a.refresh_from_db()
        m_b.refresh_from_db()
        self.assertEqual(m_a.status, 'ACTIVE')
        self.assertEqual(m_b.status, 'PENDING_APPROVAL') # Hospital B still pending!

        # Hospital B Admin approves Dr. Priya for Hospital B -> 200 OK
        self.client.force_authenticate(user=self.admin_b)
        resp_appr_b = self.client.post(f'/api/network/team/{m_b.id}/decision/', {'action': 'APPROVE'})
        self.assertEqual(resp_appr_b.status_code, status.HTTP_200_OK)

        m_b.refresh_from_db()
        self.assertEqual(m_b.status, 'ACTIVE')
        self.assertEqual(dr_priya.organization_memberships.filter(status='ACTIVE').count(), 2)

    def test_team_member_revocation_preserves_user_account(self):
        """Revoking a team member sets status to REVOKED without deleting the user account"""
        dr_rahul = User.objects.create_user(
            username='dr_rahul',
            email='rahul@med.in',
            password='Password123#',
            role='doctor'
        )
        m_a = OrganizationMembership.objects.create(
            user=dr_rahul,
            organization=self.org_a,
            role='DOCTOR',
            status='ACTIVE'
        )
        m_b = OrganizationMembership.objects.create(
            user=dr_rahul,
            organization=self.org_b,
            role='DOCTOR',
            status='ACTIVE'
        )

        self.client.force_authenticate(user=self.admin_a)
        resp_revoke = self.client.post(f'/api/network/team/{m_a.id}/revoke/')
        self.assertEqual(resp_revoke.status_code, status.HTTP_200_OK)

        m_a.refresh_from_db()
        m_b.refresh_from_db()
        self.assertEqual(m_a.status, 'REVOKED')
        self.assertEqual(m_b.status, 'ACTIVE')

        # User account is still active and intact
        user_check = User.objects.filter(username='dr_rahul').first()
        self.assertIsNotNone(user_check)
