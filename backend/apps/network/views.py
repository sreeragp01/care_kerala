import uuid
from datetime import timedelta
from django.contrib.auth import get_user_model
from rest_framework import status, views, permissions
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q
from django.utils import timezone
from .models import (
    Specialty,
    Department,
    HealthcareService,
    Facility,
    HealthcareProfile,
    HealthcareProspect,
    OrganizationInvitation,
    OrganizationMembership,
    HospitalTeamInvitation,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
    ChangeRequest,
    OrganizationDocument,
    ClaimOrganizationRequest,
    PatientInformationReport,
    AppointmentRequest,
)
from .serializers import (
    SpecialtySerializer,
    DepartmentSerializer,
    HealthcareServiceSerializer,
    FacilitySerializer,
    HealthcareProfilePublicSerializer,
    HealthcareProfileAdminSerializer,
    HealthcareProspectSerializer,
    OrganizationInvitationSerializer,
    OrganizationMembershipSerializer,
    HospitalTeamInvitationSerializer,
    DoctorPublicSerializer,
    DoctorScheduleSerializer,
    ChangeRequestSerializer,
    OrganizationDocumentSerializer,
    ClaimOrganizationRequestSerializer,
    PatientInformationReportSerializer,
    AppointmentRequestSerializer,
)
from .permissions import (
    IsPlatformAdminOrSuperAdmin,
    IsOrganizationAdminOrOwner,
    IsOrganizationModeratorOrAdmin,
    IsHospitalTeamAdmin,
    IsDocumentAuthorizedTenant,
)
from apps.organizations.models import Organization

User = get_user_model()

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class PublicDirectoryListView(views.APIView):
    """Public Search API for Hospitals, Clinics, and Healthcare Providers across Kerala"""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        queryset = HealthcareProfile.objects.select_related(
            'organization'
        ).prefetch_related(
            'specialties',
            'services',
            'facilities',
            'organization__departments',
            'organization__doctor_affiliations__doctor__primary_specialty',
            'organization__doctor_affiliations__schedules'
        )

        # Filter by District
        district = request.query_params.get('district')
        if district and district != 'All Districts':
            queryset = queryset.filter(Q(district__iexact=district) | Q(organization__district__iexact=district))

        # Filter by Organization Type
        org_type = request.query_params.get('organization_type')
        if org_type:
            queryset = queryset.filter(organization_type=org_type)

        # Filter by Ownership Type
        ownership = request.query_params.get('ownership')
        if ownership:
            queryset = queryset.filter(ownership_type=ownership)

        # Filter by Specialty
        specialty = request.query_params.get('specialty')
        if specialty:
            queryset = queryset.filter(specialties__name__icontains=specialty)

        # Filter by 24x7 Emergency Services
        emergency = request.query_params.get('emergency')
        if emergency and emergency.lower() in ('true', '1', 'yes'):
            queryset = queryset.filter(is_24x7_emergency=True)

        # Filter by Verification Status
        verified_only = request.query_params.get('verified')
        if verified_only and verified_only.lower() in ('true', '1', 'yes'):
            queryset = queryset.filter(verification_status='VERIFIED')

        # Search Query (name, address, services, specialties)
        q = request.query_params.get('search')
        if q:
            queryset = queryset.filter(
                Q(organization__name__icontains=q) |
                Q(address__icontains=q) |
                Q(description__icontains=q) |
                Q(specialties__name__icontains=q) |
                Q(services__name__icontains=q)
            ).distinct()

        # Strict Public Directory Quarantine:
        # Exclude draft/incomplete/unreviewed lifecycle states unless requester is platform superadmin
        is_platform_admin = bool(
            request.user and request.user.is_authenticated and (
                request.user.is_superuser or
                getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN')
            )
        )
        if not is_platform_admin:
            queryset = queryset.exclude(
                lifecycle_status__in=['PROSPECT', 'INVITED', 'ACTIVATED', 'PROFILE_INCOMPLETE', 'SUBMITTED_FOR_REVIEW', 'ACTION_REQUIRED', 'SUSPENDED']
            )

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(queryset, request)
        if page is not None:
            serializer = HealthcareProfilePublicSerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)

        serializer = HealthcareProfilePublicSerializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'results': serializer.data
        })

class HospitalDetailView(views.APIView):
    """Retrieve public detailed hospital profile with departments, doctors, and facilities"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        try:
            profile = HealthcareProfile.objects.select_related('organization').prefetch_related(
                'specialties',
                'services',
                'facilities',
                'organization__departments',
                'organization__doctor_affiliations__doctor__primary_specialty',
                'organization__doctor_affiliations__schedules'
            ).get(Q(id=pk) | Q(organization__id=pk))
            serializer = HealthcareProfilePublicSerializer(profile)
            return Response(serializer.data)
        except HealthcareProfile.DoesNotExist:
            return Response({'detail': 'Hospital not found.'}, status=status.HTTP_404_NOT_FOUND)

class DoctorDirectoryListView(views.APIView):
    """Public Search API for Doctors and Specialists in Kerala"""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        queryset = Doctor.objects.filter(is_active=True).select_related(
            'primary_specialty'
        ).prefetch_related(
            'affiliations__organization',
            'affiliations__department',
            'affiliations__schedules'
        )

        specialty = request.query_params.get('specialty')
        if specialty:
            queryset = queryset.filter(Q(primary_specialty__name__icontains=specialty) | Q(sub_specialties__icontains=specialty))

        district = request.query_params.get('district')
        if district and district != 'All Districts':
            queryset = queryset.filter(affiliations__organization__district__iexact=district)

        mode = request.query_params.get('mode')
        if mode:
            queryset = queryset.filter(Q(affiliations__consultation_mode=mode) | Q(affiliations__consultation_mode='ALL'))

        search = request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(qualification__icontains=search) |
                Q(primary_specialty__name__icontains=search) |
                Q(affiliations__organization__name__icontains=search)
            ).distinct()

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(queryset.distinct(), request)
        if page is not None:
            serializer = DoctorPublicSerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)

        serializer = DoctorPublicSerializer(queryset.distinct(), many=True)
        return Response({
            'count': queryset.count(),
            'results': serializer.data
        })

class JoinCareLinkView(views.APIView):
    """Organization Registration with duplicate detection (Name + District + Phone)"""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        data = request.data
        name = data.get('name', '').strip()
        district = data.get('district', '').strip()
        phone = data.get('phone', '').strip()
        reg_number = data.get('registration_number', '').strip()

        if not name or not district or not phone:
            return Response({'error': 'Name, District, and Phone are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Duplicate Detection Check
        duplicate_check = Organization.objects.filter(
            Q(name__iexact=name, district__iexact=district) |
            Q(phone=phone) |
            (Q(registration_number=reg_number) if reg_number else Q())
        ).first()

        if duplicate_check and not data.get('force_create', False):
            return Response({
                'duplicate_detected': True,
                'existing_organization_id': duplicate_check.id,
                'existing_organization_name': duplicate_check.name,
                'message': f"An organization matching '{duplicate_check.name}' in {duplicate_check.district} already exists. Would you like to claim it instead?"
            }, status=status.HTTP_409_CONFLICT)

        # 2. Create Core Organization
        org = Organization.objects.create(
            name=name,
            district=district,
            phone=phone,
            registration_number=reg_number or f"REG-{timezone.now().strftime('%Y%m%d%H%M%S')}",
            status='UNDER_REVIEW'
        )

        # 3. Create Healthcare Profile
        profile = HealthcareProfile.objects.create(
            organization=org,
            organization_type=data.get('organization_type', 'HOSPITAL'),
            ownership_type=data.get('ownership_type', 'PRIVATE'),
            verification_status='PARTIALLY_VERIFIED',
            address=data.get('address', ''),
            pincode=data.get('pincode', '673001'),
            email=data.get('email', ''),
            website=data.get('website', ''),
            emergency_phone=data.get('emergency_phone', phone),
            is_24x7_emergency=data.get('is_24x7_emergency', False),
            total_beds=data.get('total_beds', 0),
            icu_beds=data.get('icu_beds', 0),
            ambulance_available=data.get('ambulance_available', False),
            description=data.get('description', ''),
            established_year=data.get('established_year', 2020),
            profile_completeness_score=60
        )

        return Response({
            'success': True,
            'message': 'Application submitted successfully. It is now under review by CareLink verification authorities.',
            'organization_id': org.id,
            'status': org.status
        }, status=status.HTTP_201_CREATED)

class ClaimOrganizationView(views.APIView):
    """Submit a claim for an existing organization profile or list pending claims for platform admin"""

    def get_permissions(self):
        if self.request.method == 'GET':
            return [IsPlatformAdminOrSuperAdmin()]
        return [permissions.IsAuthenticated()]

    def get(self, request):
        claims = ClaimOrganizationRequest.objects.select_related('organization', 'claimant').all()
        serializer = ClaimOrganizationRequestSerializer(claims, many=True)
        return Response(serializer.data)

    def post(self, request):
        data = request.data
        org_id = data.get('organization_id')
        try:
            org = Organization.objects.get(id=org_id)
        except Organization.DoesNotExist:
            return Response({'error': 'Organization not found.'}, status=status.HTTP_404_NOT_FOUND)

        claim = ClaimOrganizationRequest.objects.create(
            organization=org,
            claimant=request.user,
            claimant_designation=data.get('claimant_designation', 'Authorized Officer'),
            official_email=data.get('official_email', request.user.email),
            official_phone=data.get('official_phone', getattr(request.user, 'phone', '')),
            proof_document_url=data.get('proof_document_url', ''),
            status='PENDING'
        )

        return Response({
            'success': True,
            'message': f"Claim for '{org.name}' submitted. CareLink Admins will verify your official credentials.",
            'claim_id': claim.id
        }, status=status.HTTP_201_CREATED)

class ClaimOrganizationReviewView(views.APIView):
    """Super Admin / Platform Admin endpoint to Approve or Reject a Claim"""
    permission_classes = [IsPlatformAdminOrSuperAdmin]

    def post(self, request, pk):
        try:
            claim = ClaimOrganizationRequest.objects.select_related('organization', 'claimant').get(id=pk)
        except ClaimOrganizationRequest.DoesNotExist:
            return Response({'error': 'Claim request not found.'}, status=status.HTTP_404_NOT_FOUND)

        action = request.data.get('action') # 'APPROVE' or 'REJECT'
        notes = request.data.get('notes', '')

        if action == 'APPROVE':
            claim.status = 'APPROVED'
            claim.reviewed_by = request.user
            claim.reviewed_at = timezone.now()
            claim.reviewer_notes = notes
            claim.save()

            # Automatic Role Promotion & Tenant Linkage
            claimant = claim.claimant
            claimant.organization = claim.organization
            if hasattr(claimant, 'role'):
                claimant.role = 'orgAdmin'
            claimant.save()

            return Response({
                'success': True,
                'message': f"Claim approved! {claimant.username} is now registered as Organization Admin for '{claim.organization.name}'."
            })
        elif action == 'REJECT':
            claim.status = 'REJECTED'
            claim.reviewed_by = request.user
            claim.reviewed_at = timezone.now()
            claim.reviewer_notes = notes
            claim.save()
            return Response({'success': True, 'message': 'Claim rejected.'})
        else:
            return Response({'error': 'Invalid action. Must be APPROVE or REJECT.'}, status=status.HTTP_400_BAD_REQUEST)

class ChangeRequestListView(views.APIView):
    """List and submit change proposals (Moderator -> Org Admin governance)"""
    permission_classes = [IsOrganizationModeratorOrAdmin]

    def get(self, request):
        user = request.user
        queryset = ChangeRequest.objects.select_related('organization', 'requested_by', 'reviewed_by').all()
        if not user.is_superuser and getattr(user, 'role', '') not in ('superAdmin', 'platformAdmin'):
            if user.organization:
                queryset = queryset.filter(organization=user.organization)
            else:
                queryset = queryset.none()
        serializer = ChangeRequestSerializer(queryset, many=True)
        return Response(serializer.data)

    def post(self, request):
        data = request.data
        user = request.user
        org_id = data.get('organization_id') or (user.organization.id if user.organization else None)
        if not org_id:
            return Response({'error': 'Organization ID is required.'}, status=status.HTTP_400_BAD_REQUEST)

        # Cross-Tenant Barrier Check
        if not user.is_superuser and getattr(user, 'role', '') not in ('superAdmin', 'platformAdmin'):
            if not user.organization or str(user.organization.id) != str(org_id):
                return Response({'error': 'Forbidden: You cannot submit change requests for another organization.'}, status=status.HTTP_403_FORBIDDEN)

        org = Organization.objects.get(id=org_id)
        cr = ChangeRequest.objects.create(
            organization=org,
            requested_by=user,
            entity_type=data.get('entity_type', 'DOCTOR_SCHEDULE'),
            entity_id=data.get('entity_id', ''),
            change_summary=data.get('change_summary', 'Update consultation hours'),
            old_data=data.get('old_data', {}),
            new_data=data.get('new_data', {}),
            reason=data.get('reason', ''),
            status='PENDING'
        )
        return Response(ChangeRequestSerializer(cr).data, status=status.HTTP_201_CREATED)

class ChangeRequestReviewView(views.APIView):
    """Approve or Reject a moderator change request (Strict Org Admin RBAC + Anti-Self-Approval)"""
    permission_classes = [IsOrganizationAdminOrOwner]

    def post(self, request, pk):
        try:
            cr = ChangeRequest.objects.select_related('organization', 'requested_by').get(id=pk)
        except ChangeRequest.DoesNotExist:
            return Response({'error': 'Change Request not found.'}, status=status.HTTP_404_NOT_FOUND)

        # 1. Cross-Tenant Barrier Check
        if not request.user.is_superuser and getattr(request.user, 'role', '') not in ('superAdmin', 'platformAdmin'):
            if not request.user.organization or request.user.organization.id != cr.organization.id:
                return Response({'error': 'Forbidden: Cannot review change requests belonging to another hospital.'}, status=status.HTTP_403_FORBIDDEN)

        # 2. Anti-Self-Approval Check (Moderators cannot approve their own requests)
        if cr.requested_by == request.user and not request.user.is_superuser:
            return Response({'error': 'Forbidden: Governance violation. You cannot approve your own change request.'}, status=status.HTTP_403_FORBIDDEN)

        action = request.data.get('action') # 'APPROVE' or 'REJECT'
        notes = request.data.get('notes', '')

        if action == 'APPROVE':
            cr.status = 'APPROVED'
            cr.reviewed_by = request.user
            cr.reviewed_at = timezone.now()
            cr.reviewer_notes = notes
            cr.save()
            return Response({'success': True, 'message': 'Change request approved and published.'})
        elif action == 'REJECT':
            cr.status = 'REJECTED'
            cr.reviewed_by = request.user
            cr.reviewed_at = timezone.now()
            cr.reviewer_notes = notes
            cr.save()
            return Response({'success': True, 'message': 'Change request rejected.'})
        else:
            return Response({'error': 'Invalid action. Must be APPROVE or REJECT.'}, status=status.HTTP_400_BAD_REQUEST)

class AppointmentRequestCreateView(views.APIView):
    """Patient consultation request with idempotency protection against duplicate submissions"""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        idempotency_key = request.data.get('idempotency_key')
        if idempotency_key:
            existing = AppointmentRequest.objects.filter(
                idempotency_key=idempotency_key,
                created_at__gte=timezone.now() - timezone.timedelta(hours=24)
            ).first()
            if existing:
                return Response({
                    'success': True,
                    'message': 'Appointment request already received (idempotent duplicate suppressed).',
                    'appointment_id': existing.id,
                    'is_duplicate_suppressed': True
                }, status=status.HTTP_200_OK)

        serializer = AppointmentRequestSerializer(data=request.data)
        if serializer.is_valid():
            appointment = serializer.save(status='REQUESTED')
            return Response({
                'success': True,
                'message': 'Appointment request submitted. The hospital desk will confirm your token.',
                'appointment_id': appointment.id,
                'is_duplicate_suppressed': False
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AppointmentStatusUpdateView(views.APIView):
    """Hospital Admin endpoint to Accept, Reject, Reschedule, or Complete an Appointment"""
    permission_classes = [IsOrganizationAdminOrOwner]

    def post(self, request, pk):
        try:
            appointment = AppointmentRequest.objects.select_related('organization', 'doctor').get(id=pk)
        except AppointmentRequest.DoesNotExist:
            return Response({'error': 'Appointment request not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Cross-Tenant Barrier Check
        if not request.user.is_superuser and getattr(request.user, 'role', '') not in ('superAdmin', 'platformAdmin'):
            if not request.user.organization or request.user.organization.id != appointment.organization.id:
                return Response({'error': 'Forbidden: Cannot manage appointments for another hospital.'}, status=status.HTTP_403_FORBIDDEN)

        new_status = request.data.get('status')
        if new_status not in ['ACCEPTED', 'REJECTED', 'RESCHEDULED', 'CANCELLED', 'COMPLETED']:
            return Response({'error': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)

        appointment.status = new_status
        appointment.responded_at = timezone.now()
        appointment.responded_by = request.user
        appointment.save()

        return Response({
            'success': True,
            'message': f"Appointment status updated to '{new_status}'.",
            'appointment_id': appointment.id,
            'status': appointment.status,
            'responded_at': appointment.responded_at
        })

class OrganizationDocumentDetailView(views.APIView):
    """Retrieve private compliance/license documents (Strict Object-Level Tenant Isolation)"""
    permission_classes = [IsDocumentAuthorizedTenant]

    def get(self, request, pk):
        try:
            doc = OrganizationDocument.objects.select_related('organization').get(id=pk)
        except OrganizationDocument.DoesNotExist:
            return Response({'error': 'Document not found.'}, status=status.HTTP_404_NOT_FOUND)

        self.check_object_permissions(request, doc)
        serializer = OrganizationDocumentSerializer(doc)
        return Response(serializer.data)

class PatientInformationReportView(views.APIView):
    """Submit community feedback on outdated/incorrect information"""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PatientInformationReportSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'Thank you! Your feedback has been sent to the CareLink moderation desk.'
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PlatformAdminDashboardView(views.APIView):
    """CareLink Super Admin / Platform Overview (Strictly restricted to Platform/Super Admins)"""
    permission_classes = [IsPlatformAdminOrSuperAdmin]

    def get(self, request):
        total_orgs = Organization.objects.count()
        verified_orgs = HealthcareProfile.objects.filter(verification_status='VERIFIED').count()
        pending_orgs = Organization.objects.filter(status__in=['PENDING', 'UNDER_REVIEW']).count()
        total_doctors = Doctor.objects.count()
        pending_cr = ChangeRequest.objects.filter(status='PENDING').count()
        pending_claims = ClaimOrganizationRequest.objects.filter(status='PENDING').count()

        return Response({
            'total_organizations': total_orgs,
            'verified_organizations': verified_orgs,
            'pending_verifications': pending_orgs,
            'total_doctors': total_doctors,
            'pending_change_requests': pending_cr,
            'pending_claims': pending_claims,
            'status': 'OPERATIONAL'
        })

# ==========================================
# CARELINK PLATFORM GOVERNANCE & PROSPECTS
# ==========================================

class ProspectListCreateView(views.APIView):
    """Platform Admin: Manage prospective Kerala hospitals for acquisition"""
    permission_classes = [IsPlatformAdminOrSuperAdmin]

    def get(self, request):
        prospects = HealthcareProspect.objects.all()
        serializer = HealthcareProspectSerializer(prospects, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = HealthcareProspectSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(created_by=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PlatformOrganizationInviteAdminView(views.APIView):
    """Platform Admin: Create an organization and issue single-use secure invitation token to the Hospital Admin"""
    permission_classes = [IsPlatformAdminOrSuperAdmin]

    def post(self, request):
        org_name = request.data.get('name')
        district = request.data.get('district', 'Kozhikode')
        registration_number = request.data.get('registration_number')
        phone = request.data.get('phone', '')
        org_type = request.data.get('organization_type', 'HOSPITAL')
        ownership_type = request.data.get('ownership_type', 'PRIVATE')
        
        recipient_name = request.data.get('recipient_name')
        recipient_email = request.data.get('recipient_email')
        recipient_phone = request.data.get('recipient_phone', phone)
        recipient_designation = request.data.get('recipient_designation', 'Authorized Hospital Administrator')
        prospect_id = request.data.get('prospect_id')

        if not org_name or not recipient_email or not recipient_name:
            return Response({'error': 'Organization name, recipient name, and recipient email are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if not registration_number:
            registration_number = f"KL-{district[:3].upper()}-{uuid.uuid4().hex[:6].upper()}"

        org, created = Organization.objects.get_or_create(
            registration_number=registration_number,
            defaults={'name': org_name, 'district': district, 'phone': phone, 'status': 'UNDER_REVIEW'}
        )

        profile, _ = HealthcareProfile.objects.get_or_create(
            organization=org,
            defaults={
                'organization_type': org_type,
                'ownership_type': ownership_type,
                'district': district,
                'phone': phone,
                'email': recipient_email,
                'verification_status': 'UNVERIFIED',
                'lifecycle_status': 'INVITED',
                'is_published': False,
                'profile_completeness_percentage': 15,
            }
        )

        # Generate secure unique invitation token
        token = uuid.uuid4().hex + uuid.uuid4().hex[:16]
        expires_at = timezone.now() + timedelta(days=7)

        prospect = None
        if prospect_id:
            prospect = HealthcareProspect.objects.filter(id=prospect_id).first()
            if prospect:
                prospect.status = 'INVITED'
                prospect.save(update_fields=['status', 'updated_at'])

        invitation = OrganizationInvitation.objects.create(
            organization=org,
            prospect=prospect,
            recipient_name=recipient_name,
            recipient_email=recipient_email,
            recipient_phone=recipient_phone,
            recipient_designation=recipient_designation,
            token=token,
            status='PENDING',
            invited_by=request.user,
            expires_at=expires_at
        )

        serializer = OrganizationInvitationSerializer(invitation)
        return Response({
            'success': True,
            'message': f'Invitation generated for {recipient_name} at {org.name}',
            'invitation': serializer.data,
            'activation_url': f'/api/network/invitations/{token}/activate/',
            'token': token
        }, status=status.HTTP_201_CREATED)

class CareLinkReviewDecisionView(views.APIView):
    """Platform Admin: Formal audit review decision on a submitted hospital profile"""
    permission_classes = [IsPlatformAdminOrSuperAdmin]

    def post(self, request, pk):
        try:
            profile = HealthcareProfile.objects.select_related('organization').get(organization_id=pk)
        except HealthcareProfile.DoesNotExist:
            return Response({'error': 'Healthcare organization profile not found.'}, status=status.HTTP_404_NOT_FOUND)

        action = request.data.get('action') # 'APPROVE', 'REQUEST_CHANGES', 'REJECT', 'SUSPEND'
        notes = request.data.get('review_notes', '')

        if action == 'APPROVE':
            profile.lifecycle_status = 'PUBLISHED'
            profile.is_published = True
            profile.verification_status = 'VERIFIED'
            profile.approved_at = timezone.now()
            profile.last_verified_at = timezone.now()
            profile.verified_by = request.user
            profile.review_notes = notes
            profile.save()

            profile.organization.status = 'ACTIVE'
            profile.organization.save(update_fields=['status'])

            # Promote invited org admins to active
            profile.organization.memberships.filter(role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']).update(
                status='ACTIVE',
                approved_by=request.user,
                approved_at=timezone.now()
            )

            return Response({
                'success': True,
                'message': f'{profile.organization.name} is now approved, published, and CareLink Verified!',
                'lifecycle_status': profile.lifecycle_status,
                'verification_status': profile.verification_status
            })

        elif action == 'REQUEST_CHANGES':
            profile.lifecycle_status = 'ACTION_REQUIRED'
            profile.review_notes = notes
            profile.save(update_fields=['lifecycle_status', 'review_notes', 'updated_at'])
            return Response({
                'success': True,
                'message': 'Changes requested. Hospital admin has been flagged to address review notes.',
                'lifecycle_status': profile.lifecycle_status
            })

        elif action == 'REJECT':
            profile.lifecycle_status = 'SUSPENDED'
            profile.review_notes = notes
            profile.is_published = False
            profile.save(update_fields=['lifecycle_status', 'review_notes', 'is_published', 'updated_at'])
            return Response({
                'success': True,
                'message': 'Organization application rejected.',
                'lifecycle_status': profile.lifecycle_status
            })

        return Response({'error': 'Invalid action. Must be APPROVE, REQUEST_CHANGES, or REJECT.'}, status=status.HTTP_400_BAD_REQUEST)

# ==========================================
# INVITATION VALIDATION & ACTIVATION
# ==========================================

class InvitationValidateView(views.APIView):
    """Invited Admin / User: Validates token validity before account setup"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, token):
        invitation = OrganizationInvitation.objects.filter(token=token).select_related('organization').first()
        if not invitation:
            # Check team invitation
            team_inv = HospitalTeamInvitation.objects.filter(token=token).select_related('organization', 'department').first()
            if not team_inv:
                return Response({'error': 'Invalid or expired invitation token.'}, status=status.HTTP_404_NOT_FOUND)
            if team_inv.status != 'PENDING' or team_inv.expires_at < timezone.now():
                return Response({'error': 'This invitation token has expired or already been used.'}, status=status.HTTP_400_BAD_REQUEST)
            return Response({
                'type': 'TEAM_MEMBER',
                'organization_name': team_inv.organization.name,
                'recipient_name': team_inv.recipient_name,
                'recipient_email': team_inv.recipient_email,
                'role': team_inv.role,
                'role_display': team_inv.get_role_display(),
                'department_name': team_inv.department.name if team_inv.department else '',
                'is_valid': True
            })

        if invitation.status != 'PENDING' or invitation.expires_at < timezone.now():
            return Response({'error': 'This invitation token has expired or already been used.'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'type': 'ORGANIZATION_ADMIN',
            'organization_id': invitation.organization.id,
            'organization_name': invitation.organization.name,
            'district': invitation.organization.district,
            'recipient_name': invitation.recipient_name,
            'recipient_email': invitation.recipient_email,
            'recipient_designation': invitation.recipient_designation,
            'is_valid': True
        })

class InvitationActivateView(views.APIView):
    """Invited Admin / User: Sets secure password, activates personal user, creates membership"""
    permission_classes = [permissions.AllowAny]

    def post(self, request, token):
        password = request.data.get('password')
        if not password or len(password) < 6:
            return Response({'error': 'Password must be at least 6 characters long.'}, status=status.HTTP_400_BAD_REQUEST)

        invitation = OrganizationInvitation.objects.filter(token=token).select_related('organization').first()
        if invitation:
            if invitation.status != 'PENDING' or invitation.expires_at < timezone.now():
                return Response({'error': 'Invalid or expired invitation token.'}, status=status.HTTP_400_BAD_REQUEST)

            username = invitation.recipient_email.split('@')[0]
            # Create or update user
            user, created = User.objects.get_or_create(
                email=invitation.recipient_email,
                defaults={
                    'username': username,
                    'first_name': invitation.recipient_name.split(' ')[0],
                    'role': 'orgAdmin',
                    'organization': invitation.organization,
                    'district': invitation.organization.district,
                    'is_active': True
                }
            )
            user.set_password(password)
            user.role = 'orgAdmin'
            user.organization = invitation.organization
            user.save()

            # Create or activate OrganizationMembership
            membership, _ = OrganizationMembership.objects.get_or_create(
                user=user,
                organization=invitation.organization,
                defaults={
                    'role': 'ORGANIZATION_ADMIN',
                    'status': 'PENDING_APPROVAL',
                    'designation': invitation.recipient_designation,
                    'invited_by': invitation.invited_by,
                    'joined_at': timezone.now()
                }
            )

            invitation.status = 'ACCEPTED'
            invitation.accepted_at = timezone.now()
            invitation.save(update_fields=['status', 'accepted_at'])

            # Update profile lifecycle
            profile = getattr(invitation.organization, 'healthcare_profile', None)
            if profile and profile.lifecycle_status == 'INVITED':
                profile.lifecycle_status = 'ACTIVATED'
                profile.save(update_fields=['lifecycle_status', 'updated_at'])

            return Response({
                'success': True,
                'message': f'Welcome to CareLink Network! Your administrator account for {invitation.organization.name} is now activated.',
                'username': user.username,
                'organization_id': invitation.organization.id,
                'next_step': 'WIZARD_SETUP'
            }, status=status.HTTP_200_OK)

        # Check team member invitation
        team_inv = HospitalTeamInvitation.objects.filter(token=token).select_related('organization', 'department').first()
        if team_inv:
            if team_inv.status != 'PENDING' or team_inv.expires_at < timezone.now():
                return Response({'error': 'Invalid or expired invitation token.'}, status=status.HTTP_400_BAD_REQUEST)

            username = team_inv.recipient_email.split('@')[0]
            user, _ = User.objects.get_or_create(
                email=team_inv.recipient_email,
                defaults={
                    'username': username,
                    'first_name': team_inv.recipient_name.split(' ')[0],
                    'role': 'doctor' if team_inv.role == 'DOCTOR' else 'nurse',
                    'organization': team_inv.organization,
                    'district': team_inv.organization.district,
                    'is_active': True
                }
            )
            user.set_password(password)
            user.save()

            membership, _ = OrganizationMembership.objects.get_or_create(
                user=user,
                organization=team_inv.organization,
                defaults={
                    'role': team_inv.role,
                    'department': team_inv.department,
                    'designation': team_inv.designation,
                    'status': 'PENDING_APPROVAL',
                    'invited_by': team_inv.invited_by,
                    'joined_at': timezone.now()
                }
            )

            team_inv.status = 'ACCEPTED'
            team_inv.save(update_fields=['status'])

            return Response({
                'success': True,
                'message': f'Invitation accepted. Your membership at {team_inv.organization.name} is pending Hospital Admin approval.',
                'status': 'PENDING_APPROVAL'
            })

        return Response({'error': 'Invitation token not found.'}, status=status.HTTP_404_NOT_FOUND)

# ==========================================
# 10-STEP HOSPITAL PROFILE SETUP WIZARD
# ==========================================

class HospitalSetupWizardView(views.APIView):
    """Hospital Admin: Interactive multi-step setup wizard tracking profile completeness (0-100%)"""
    permission_classes = [IsHospitalTeamAdmin]

    def get(self, request):
        user_org = getattr(request.user, 'organization', None)
        if not user_org:
            # Look up active membership
            active_m = request.user.organization_memberships.filter(
                role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']
            ).first()
            if active_m:
                user_org = active_m.organization
        if not user_org:
            return Response({'error': 'No organization attached to this account.'}, status=status.HTTP_400_BAD_REQUEST)

        profile, _ = HealthcareProfile.objects.get_or_create(
            organization=user_org,
            defaults={'district': user_org.district, 'phone': user_org.phone}
        )

        serializer = HealthcareProfileAdminSerializer(profile)
        return Response({
            'organization': {
                'id': user_org.id,
                'name': user_org.name,
                'district': user_org.district,
                'phone': user_org.phone,
                'status': user_org.status
            },
            'profile': serializer.data,
            'completeness_percentage': profile.profile_completeness_percentage or 35,
            'lifecycle_status': profile.lifecycle_status,
            'review_notes': profile.review_notes
        })

    def post(self, request):
        user_org = getattr(request.user, 'organization', None)
        if not user_org:
            active_m = request.user.organization_memberships.filter(
                role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']
            ).first()
            if active_m:
                user_org = active_m.organization
        if not user_org:
            return Response({'error': 'No organization attached to this account.'}, status=status.HTTP_400_BAD_REQUEST)

        profile, _ = HealthcareProfile.objects.get_or_create(organization=user_org)

        # Update step fields
        for field in ['address', 'district', 'pincode', 'phone', 'email', 'website',
                      'emergency_phone', 'description', 'logo_url', 'cover_image_url',
                      'is_24x7_emergency', 'trauma_care_available', 'ambulance_available',
                      'total_beds', 'icu_beds', 'established_year', 'organization_type', 'ownership_type']:
            if field in request.data:
                setattr(profile, field, request.data[field])

        # Compute dynamic completeness score
        score = 0
        if profile.address and profile.district and profile.pincode:
            score += 20
        if profile.phone and profile.email:
            score += 15
        if profile.emergency_phone or profile.is_24x7_emergency:
            score += 15
        if user_org.departments.count() > 0:
            score += 15
        if user_org.doctor_affiliations.count() > 0:
            score += 15
        if profile.services.count() > 0:
            score += 10
        if user_org.documents.count() > 0:
            score += 10

        profile.profile_completeness_percentage = min(score, 100)
        if profile.lifecycle_status in ['ACTIVATED', 'INVITED']:
            profile.lifecycle_status = 'PROFILE_INCOMPLETE' if profile.profile_completeness_percentage < 80 else 'ACTIVATED'
        profile.save()

        return Response({
            'success': True,
            'completeness_percentage': profile.profile_completeness_percentage,
            'lifecycle_status': profile.lifecycle_status,
            'message': 'Profile step saved successfully.'
        })

class HospitalSubmitReviewView(views.APIView):
    """Hospital Admin: Submits completed profile to CareLink platform for verification review"""
    permission_classes = [IsHospitalTeamAdmin]

    def post(self, request):
        user_org = getattr(request.user, 'organization', None)
        if not user_org:
            active_m = request.user.organization_memberships.filter(
                role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']
            ).first()
            if active_m:
                user_org = active_m.organization
        if not user_org:
            return Response({'error': 'No organization found.'}, status=status.HTTP_400_BAD_REQUEST)

        profile = getattr(user_org, 'healthcare_profile', None)
        if not profile:
            return Response({'error': 'Profile not configured.'}, status=status.HTTP_400_BAD_REQUEST)

        # Prevent Hospital Admin from directly self-publishing
        if request.data.get('action') == 'PUBLISH' and not request.user.is_superuser:
            return Response({'error': 'Hospital Admins cannot self-publish. Profile must be submitted for CareLink review.'}, status=status.HTTP_403_FORBIDDEN)

        profile.lifecycle_status = 'SUBMITTED_FOR_REVIEW'
        profile.submitted_at = timezone.now()
        profile.save(update_fields=['lifecycle_status', 'submitted_at', 'updated_at'])

        return Response({
            'success': True,
            'message': 'Your organization profile has been submitted for CareLink platform review!',
            'lifecycle_status': profile.lifecycle_status
        })

# ==========================================
# HOSPITAL TEAM GOVERNANCE & APPROVALS
# ==========================================

class HospitalTeamListView(views.APIView):
    """Hospital Admin: List all team memberships for their hospital"""
    permission_classes = [IsHospitalTeamAdmin]

    def get(self, request):
        user_org = getattr(request.user, 'organization', None)
        if not user_org:
            active_m = request.user.organization_memberships.filter(role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']).first()
            if active_m:
                user_org = active_m.organization
        if not user_org:
            return Response({'error': 'No organization found.'}, status=status.HTTP_400_BAD_REQUEST)

        memberships = OrganizationMembership.objects.filter(organization=user_org).select_related('user', 'department', 'approved_by')
        serializer = OrganizationMembershipSerializer(memberships, many=True)
        return Response(serializer.data)

class HospitalTeamPendingApprovalListView(views.APIView):
    """Hospital Admin: List pending membership requests for their hospital"""
    permission_classes = [IsHospitalTeamAdmin]

    def get(self, request):
        user_org = getattr(request.user, 'organization', None)
        if not user_org:
            active_m = request.user.organization_memberships.filter(role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']).first()
            if active_m:
                user_org = active_m.organization
        if not user_org:
            return Response({'error': 'No organization found.'}, status=status.HTTP_400_BAD_REQUEST)

        memberships = OrganizationMembership.objects.filter(organization=user_org, status='PENDING_APPROVAL').select_related('user', 'department')
        serializer = OrganizationMembershipSerializer(memberships, many=True)
        return Response(serializer.data)

class HospitalTeamInviteView(views.APIView):
    """Hospital Admin: Invite a doctor, moderator, or staff member to their hospital"""
    permission_classes = [IsHospitalTeamAdmin]

    def post(self, request):
        user_org = getattr(request.user, 'organization', None)
        if not user_org:
            active_m = request.user.organization_memberships.filter(role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER']).first()
            if active_m:
                user_org = active_m.organization
        if not user_org:
            return Response({'error': 'No organization found.'}, status=status.HTTP_400_BAD_REQUEST)

        role = request.data.get('role', 'STAFF')
        # Hard Security Rule: Hospital Admin CANNOT grant SUPER_ADMIN or PLATFORM_ADMIN
        if role in ('SUPER_ADMIN', 'PLATFORM_ADMIN', 'superAdmin', 'platformAdmin'):
            return Response({'error': 'Hospital Admins cannot grant Platform Super Admin privileges.'}, status=status.HTTP_403_FORBIDDEN)

        recipient_name = request.data.get('name')
        recipient_email = request.data.get('email')
        recipient_phone = request.data.get('phone', '')
        designation = request.data.get('designation', '')
        department_id = request.data.get('department_id')

        if not recipient_name or not recipient_email:
            return Response({'error': 'Name and email are required.'}, status=status.HTTP_400_BAD_REQUEST)

        dept = None
        if department_id:
            dept = Department.objects.filter(id=department_id, organization=user_org).first()

        token = uuid.uuid4().hex
        expires_at = timezone.now() + timedelta(days=14)

        inv = HospitalTeamInvitation.objects.create(
            organization=user_org,
            recipient_name=recipient_name,
            recipient_email=recipient_email,
            recipient_phone=recipient_phone,
            role=role,
            department=dept,
            designation=designation,
            token=token,
            invited_by=request.user,
            expires_at=expires_at
        )

        serializer = HospitalTeamInvitationSerializer(inv)
        return Response({
            'success': True,
            'message': f'Invitation generated for {recipient_name}',
            'invitation': serializer.data,
            'token': token
        }, status=status.HTTP_201_CREATED)

class HospitalTeamApprovalDecisionView(views.APIView):
    """Hospital Admin: Sovereign approval or rejection of team membership (Strict Cross-Tenant Isolation)"""
    permission_classes = [IsHospitalTeamAdmin]

    def post(self, request, pk):
        try:
            membership = OrganizationMembership.objects.select_related('organization', 'user').get(id=pk)
        except OrganizationMembership.DoesNotExist:
            return Response({'error': 'Team membership record not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Cross-Tenant Barrier Check: Only the admin of THIS specific hospital can approve!
        user_org = getattr(request.user, 'organization', None)
        user_admin_orgs = request.user.organization_memberships.filter(
            role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'],
            status='ACTIVE'
        ).values_list('organization_id', flat=True)

        is_authorized = (
            request.user.is_superuser or
            (user_org and user_org.id == membership.organization_id) or
            (membership.organization_id in user_admin_orgs)
        )

        if not is_authorized:
            return Response({'error': 'Forbidden: You do not have authority to approve members for this hospital.'}, status=status.HTTP_403_FORBIDDEN)

        action = request.data.get('action') # 'APPROVE', 'REJECT'
        if action == 'APPROVE':
            membership.status = 'ACTIVE'
            membership.approved_by = request.user
            membership.approved_at = timezone.now()
            membership.save(update_fields=['status', 'approved_by', 'approved_at', 'updated_at'])

            return Response({
                'success': True,
                'message': f'{membership.user.username} is now an ACTIVE team member of {membership.organization.name}.',
                'membership': OrganizationMembershipSerializer(membership).data
            })

        elif action == 'REJECT':
            membership.status = 'REJECTED'
            membership.save(update_fields=['status', 'updated_at'])
            return Response({
                'success': True,
                'message': 'Membership request rejected.',
                'status': 'REJECTED'
            })

        return Response({'error': 'Invalid action. Must be APPROVE or REJECT.'}, status=status.HTTP_400_BAD_REQUEST)

class HospitalTeamMemberRevokeView(views.APIView):
    """Hospital Admin: Revoke hospital access without deleting the user account"""
    permission_classes = [IsHospitalTeamAdmin]

    def post(self, request, pk):
        try:
            membership = OrganizationMembership.objects.select_related('organization').get(id=pk)
        except OrganizationMembership.DoesNotExist:
            return Response({'error': 'Membership not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Cross-tenant check
        user_org = getattr(request.user, 'organization', None)
        user_admin_orgs = request.user.organization_memberships.filter(
            role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'],
            status='ACTIVE'
        ).values_list('organization_id', flat=True)

        is_authorized = (
            request.user.is_superuser or
            (user_org and user_org.id == membership.organization_id) or
            (membership.organization_id in user_admin_orgs)
        )

        if not is_authorized:
            return Response({'error': 'Forbidden: Cross-tenant revocation not permitted.'}, status=status.HTTP_403_FORBIDDEN)

        membership.status = 'REVOKED'
        membership.revoked_at = timezone.now()
        membership.save(update_fields=['status', 'revoked_at', 'updated_at'])

        return Response({
            'success': True,
            'message': f'Access revoked for {membership.user.username} at {membership.organization.name}. User account preserved.',
            'status': 'REVOKED'
        })

