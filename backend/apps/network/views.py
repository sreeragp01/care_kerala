import uuid
import datetime
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
    DoctorAvailability,
    DoctorAvailabilityStatus,
    ScheduleException,
    ChangeRequest,
    OrganizationDocument,
    ClaimOrganizationRequest,
    PatientInformationReport,
    AppointmentStatus,
    AppointmentRequest,
    AppointmentStatusHistory,
    TokenStatus,
    QueueSession,
    QueueToken,
    QueueType,
    QueuePriority,
    QueuePauseReason,
    QueuePolicy,
    QueuePause,
    PatientCheckIn,
    WaitingTimeSnapshot,
    DomainEventLog,
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
    DoctorAvailabilitySerializer,
    ScheduleExceptionSerializer,
    AppointmentStatusHistorySerializer,
    QueueSessionSerializer,
    QueueTokenSerializer,
    QueuePauseSerializer,
    QueuePolicySerializer,
    PatientCheckInSerializer,
    DigitalCheckInRequestSerializer,
    QueueTokenIssueRequestSerializer,
    QueueSessionPauseRequestSerializer,
    ChangeRequestSerializer,
    OrganizationDocumentSerializer,
    ClaimOrganizationRequestSerializer,
    PatientInformationReportSerializer,
    AppointmentRequestSerializer,
    DomainEventLogSerializer,
    AppointmentRescheduleSerializer,
    AppointmentCancelSerializer,
    DoctorLeaveImpactResolutionSerializer,
)
from .events import EventDispatcher, DomainEvent, DomainEventType
from .slot_engine import SmartDoctorSlotEngine, DoctorLeaveImpactEngine
from .queue_engine import SmartQueueEngine
from .permissions import (
    IsPlatformAdminOrSuperAdmin,
    IsOrganizationAdminOrOwner,
    IsOrganizationModeratorOrAdmin,
    IsHospitalTeamAdmin,
    IsDocumentAuthorizedTenant,
    CanManageOPDAndQueue,
    IsAssignedDoctorOrHospitalAdmin,
    IsQueueAuthorizedDoctorOrAdmin,
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
            EventDispatcher.dispatch(DomainEvent(
                event_type=DomainEventType.APPOINTMENT_REQUESTED,
                organization_id=appointment.organization_id,
                entity_type='AppointmentRequest',
                entity_id=appointment.id,
                actor_id=request.user.id if request.user and hasattr(request.user, 'id') and request.user.is_authenticated else None,
                actor_username=request.user.username if request.user and hasattr(request.user, 'username') and request.user.is_authenticated else appointment.patient_name,
                title='New Appointment Request Received',
                message=f"Appointment requested by {appointment.patient_name} with Dr. {appointment.doctor.name} for {appointment.preferred_date}.",
                payload={'doctor_id': appointment.doctor_id, 'preferred_date': str(appointment.preferred_date), 'slot': appointment.preferred_time_slot}
            ))
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

# ==========================================
# PHASE 2.4: HOSPITAL OPERATIONS & OPD QUEUES
# ==========================================

class DoctorAvailabilityView(views.APIView):
    """Manage and query date-specific real-time doctor availability (AVAILABLE, ON_LEAVE, HOLIDAY, etc.)"""
    permission_classes = [CanManageOPDAndQueue]

    def get(self, request):
        doctor_id = request.query_params.get('doctor_id')
        org_id = request.query_params.get('organization_id')
        date_str = request.query_params.get('date', timezone.now().strftime('%Y-%m-%d'))

        qs = DoctorAvailability.objects.all()
        if doctor_id:
            qs = qs.filter(doctor_id=doctor_id)
        if org_id:
            qs = qs.filter(organization_id=org_id)
        if date_str:
            qs = qs.filter(date=date_str)

        serializer = DoctorAvailabilitySerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request):
        doctor_id = request.data.get('doctor_id')
        org_id = request.data.get('organization_id')
        date_str = request.data.get('date')
        status_val = request.data.get('status', 'AVAILABLE')
        reason = request.data.get('reason', '')

        if not (doctor_id and org_id and date_str):
            return Response({'error': 'doctor_id, organization_id, and date are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # Cross-tenant and doctor authorization
        user_org = getattr(request.user, 'organization', None)
        user_role = getattr(request.user, 'role', '')
        is_super = request.user.is_superuser or user_role in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN')

        if not is_super and user_org and str(user_org.id) != str(org_id):
            has_membership = request.user.organization_memberships.filter(organization_id=org_id, status='ACTIVE').exists()
            if not has_membership:
                return Response({'error': 'Forbidden: Cross-tenant doctor availability update blocked.'}, status=status.HTTP_403_FORBIDDEN)

        availability, created = DoctorAvailability.objects.update_or_create(
            doctor_id=doctor_id,
            organization_id=org_id,
            date=date_str,
            defaults={'status': status_val, 'reason': reason}
        )

        # Trigger automatic appointment impact flagging if doctor marks leave or unavailable
        if status_val in ['ON_LEAVE', 'UNAVAILABLE', 'EMERGENCY_DUTY', 'HOLIDAY']:
            try:
                date_obj = datetime.datetime.strptime(date_str, '%Y-%m-%d').date() if isinstance(date_str, str) else date_str
                DoctorLeaveImpactEngine.flag_affected_appointments(
                    doctor_id=int(doctor_id),
                    organization_id=int(org_id),
                    exception_date=date_obj,
                    reason=reason,
                    user=request.user
                )
                EventDispatcher.dispatch(DomainEvent(
                    event_type=DomainEventType.DOCTOR_LEAVE_MARKED,
                    organization_id=int(org_id),
                    entity_type='DoctorAvailability',
                    entity_id=availability.id,
                    actor_id=request.user.id if request.user.is_authenticated else None,
                    actor_username=request.user.username if request.user.is_authenticated else 'system',
                    title='Doctor Marked On Leave',
                    message=f"Doctor marked {status_val} on {date_str}. All affected appointments have been flagged for hospital desk review.",
                    payload={'doctor_id': doctor_id, 'date': str(date_str), 'reason': reason}
                ))
            except Exception as e:
                pass

        serializer = DoctorAvailabilitySerializer(availability)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

class ScheduleExceptionView(views.APIView):
    """Manage date-specific exceptions/cancellations for recurring OPD schedules"""
    permission_classes = [CanManageOPDAndQueue]

    def get(self, request):
        affiliation_id = request.query_params.get('affiliation_id')
        qs = ScheduleException.objects.all()
        if affiliation_id:
            qs = qs.filter(affiliation_id=affiliation_id)
        serializer = ScheduleExceptionSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = ScheduleExceptionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AppointmentLifecycleActionView(views.APIView):
    """Execute lifecycle state transitions on appointments with audit logging and queue linking"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request, pk, action):
        try:
            appt = AppointmentRequest.objects.select_related('organization', 'doctor').get(id=pk)
        except AppointmentRequest.DoesNotExist:
            return Response({'error': 'Appointment not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Cross-tenant check
        user_org = getattr(request.user, 'organization', None)
        is_super = request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN')
        
        if not is_super and user_org and user_org.id != appt.organization_id:
            has_membership = request.user.organization_memberships.filter(organization_id=appt.organization_id, status='ACTIVE').exists()
            if not has_membership:
                return Response({'error': 'Forbidden: Cross-tenant appointment action not permitted.'}, status=status.HTTP_403_FORBIDDEN)

        # Doctor role isolation: if logged in as doctor, cannot modify another doctor's appointment
        if hasattr(request.user, 'doctor_profile') and getattr(request.user, 'role', '') in ('doctor', 'DOCTOR'):
            if request.user.doctor_profile.id != appt.doctor_id:
                return Response({'error': 'Forbidden: Doctor can only modify their assigned appointments.'}, status=status.HTTP_403_FORBIDDEN)

        old_status = appt.status
        action = action.lower()
        notes = request.data.get('notes', '')

        if action == 'accept':
            appt.status = AppointmentStatus.ACCEPTED
        elif action == 'confirm':
            appt.status = AppointmentStatus.CONFIRMED
            if not appt.token_number:
                appt.token_number = f"T-{appt.id:03d}"
        elif action == 'check-in':
            appt.status = AppointmentStatus.CHECKED_IN
            # Link or create QueueSession and QueueToken
            today = timezone.now().date()
            session, _ = QueueSession.objects.get_or_create(
                organization=appt.organization,
                doctor=appt.doctor,
                session_date=today,
                defaults={'room_number': 'OPD Room 102'}
            )
            token_count = session.tokens.count() + 1
            token_label = f"A-{token_count:02d}"
            
            queue_token, _ = QueueToken.objects.get_or_create(
                queue_session=session,
                appointment=appt,
                defaults={
                    'token_number': token_count,
                    'token_label': token_label,
                    'patient_name': appt.patient_name,
                    'patient_phone': appt.patient_phone,
                    'status': TokenStatus.WAITING
                }
            )
            session.total_tokens_issued = session.tokens.count()
            session.save(update_fields=['total_tokens_issued'])
            appt.token_number = queue_token.token_label
        elif action == 'cancel':
            appt.status = AppointmentStatus.CANCELLED
        elif action == 'complete':
            appt.status = AppointmentStatus.COMPLETED
        elif action == 'no-show':
            appt.status = AppointmentStatus.NO_SHOW
        else:
            return Response({'error': f'Unsupported action "{action}".'}, status=status.HTTP_400_BAD_REQUEST)

        appt.responded_at = timezone.now()
        appt.responded_by = request.user
        appt.save(update_fields=['status', 'token_number', 'responded_at', 'responded_by', 'updated_at'])

        # Create status audit trail
        AppointmentStatusHistory.objects.create(
            appointment=appt,
            from_status=old_status,
            to_status=appt.status,
            changed_by=request.user,
            notes=notes
        )

        # Emit central domain event
        event_map = {
            'accept': DomainEventType.APPOINTMENT_ACCEPTED,
            'confirm': DomainEventType.APPOINTMENT_CONFIRMED,
            'check-in': DomainEventType.APPOINTMENT_CHECKED_IN,
            'cancel': DomainEventType.APPOINTMENT_CANCELLED,
            'complete': DomainEventType.APPOINTMENT_COMPLETED,
            'no-show': DomainEventType.APPOINTMENT_NO_SHOW,
        }
        event_type = event_map.get(action, DomainEventType.APPOINTMENT_CONFIRMED)
        EventDispatcher.dispatch(DomainEvent(
            event_type=event_type,
            organization_id=appt.organization_id,
            entity_type='AppointmentRequest',
            entity_id=appt.id,
            actor_id=request.user.id if request.user.is_authenticated else None,
            actor_username=request.user.username if request.user.is_authenticated else 'desk_admin',
            title=f"Appointment {appt.status}",
            message=f"Appointment #{appt.id} transitioned to {appt.status}. {notes}".strip(),
            payload={'from_status': old_status, 'to_status': appt.status, 'notes': notes}
        ))

        return Response({
            'success': True,
            'message': f'Appointment #{appt.id} transitioned from {old_status} to {appt.status}.',
            'appointment': AppointmentRequestSerializer(appt).data
        })

class QueueSessionStartView(views.APIView):
    """Start or retrieve today's active OPD Queue Session for a doctor and room"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request):
        doctor_id = request.data.get('doctor_id')
        org_id = request.data.get('organization_id')
        room_number = request.data.get('room_number', 'OPD Room 102')
        today = timezone.now().date()

        if not (doctor_id and org_id):
            return Response({'error': 'doctor_id and organization_id are required.'}, status=status.HTTP_400_BAD_REQUEST)

        session, created = QueueSession.objects.get_or_create(
            doctor_id=doctor_id,
            organization_id=org_id,
            session_date=today,
            defaults={'room_number': room_number, 'is_active': True}
        )

        serializer = QueueSessionSerializer(session)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

class QueueTokenIssueView(views.APIView):
    """Issue a new queue token for a patient (walk-in or check-in)"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request):
        session_id = request.data.get('queue_session_id')
        patient_name = request.data.get('patient_name')
        patient_phone = request.data.get('patient_phone')
        appt_id = request.data.get('appointment_id')

        if not (session_id and patient_name and patient_phone):
            return Response({'error': 'queue_session_id, patient_name, and patient_phone are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            session = QueueSession.objects.get(id=session_id)
        except QueueSession.DoesNotExist:
            return Response({'error': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)

        next_number = session.tokens.count() + 1
        token_label = f"A-{next_number:02d}"

        token = QueueToken.objects.create(
            queue_session=session,
            appointment_id=appt_id,
            token_number=next_number,
            token_label=token_label,
            patient_name=patient_name,
            patient_phone=patient_phone,
            status=TokenStatus.WAITING
        )

        session.total_tokens_issued = session.tokens.count()
        session.save(update_fields=['total_tokens_issued'])

        serializer = QueueTokenSerializer(token)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class QueueTokenCallNextView(views.APIView):
    """Doctor or Desk calls next waiting patient in queue"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request, pk):
        try:
            token = QueueToken.objects.select_related('queue_session', 'queue_session__organization').get(id=pk)
        except QueueToken.DoesNotExist:
            return Response({'error': 'Queue token not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Cross-tenant and doctor checks
        user_org = getattr(request.user, 'organization', None)
        is_super = request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN')
        
        if not is_super and user_org and user_org.id != token.queue_session.organization_id:
            return Response({'error': 'Forbidden: Cross-tenant token calling not permitted.'}, status=status.HTTP_403_FORBIDDEN)

        token.status = TokenStatus.CALLED
        token.called_at = timezone.now()
        token.save(update_fields=['status', 'called_at'])

        session = token.queue_session
        session.current_token_number = token.token_number
        session.save(update_fields=['current_token_number'])

        return Response({
            'success': True,
            'message': f'Token {token.token_label} called to {session.room_number}.',
            'token': QueueTokenSerializer(token).data,
            'current_token_number': session.current_token_number
        })

class QueueTokenConsultationActionView(views.APIView):
    """Doctor consultation actions: start consultation, complete, or skip"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request, pk, action):
        try:
            token = QueueToken.objects.select_related('queue_session', 'appointment').get(id=pk)
        except QueueToken.DoesNotExist:
            return Response({'error': 'Queue token not found.'}, status=status.HTTP_404_NOT_FOUND)

        action = action.lower()
        if action == 'start':
            token.status = TokenStatus.IN_CONSULTATION
            token.consultation_started_at = timezone.now()
            token.save(update_fields=['status', 'consultation_started_at'])
            if token.appointment:
                token.appointment.status = AppointmentStatus.IN_CONSULTATION
                token.appointment.save(update_fields=['status'])
        elif action == 'complete':
            token.status = TokenStatus.COMPLETED
            token.completed_at = timezone.now()
            token.clinical_notes = request.data.get('clinical_notes', '')
            token.save(update_fields=['status', 'completed_at', 'clinical_notes'])
            if token.appointment:
                token.appointment.status = AppointmentStatus.COMPLETED
                token.appointment.save(update_fields=['status'])
        elif action == 'skip':
            token.status = TokenStatus.SKIPPED
            token.save(update_fields=['status'])
        else:
            return Response({'error': f'Invalid action "{action}".'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'success': True,
            'message': f'Token {token.token_label} consultation updated to {token.status}.',
            'token': QueueTokenSerializer(token).data
        })

class PatientLiveQueueTrackerView(views.APIView):
    """Patient real-time live queue and wait-time tracker"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        try:
            token = QueueToken.objects.select_related(
                'queue_session', 'queue_session__doctor', 'queue_session__organization'
            ).get(id=pk)
        except QueueToken.DoesNotExist:
            return Response({'error': 'Token not found.'}, status=status.HTTP_404_NOT_FOUND)

        session = token.queue_session
        doctor = session.doctor
        org = session.organization

        current_token_num = session.current_token_number
        your_token_num = token.token_number
        patients_ahead = max(0, your_token_num - current_token_num - (1 if token.status == TokenStatus.IN_CONSULTATION else 0))
        estimated_wait_minutes = patients_ahead * 10

        return Response({
            'token_id': token.id,
            'token_label': token.token_label,
            'token_number': your_token_num,
            'token_status': token.status,
            'token_status_display': token.get_status_display(),
            'current_token_number': current_token_num,
            'current_token_label': f"A-{current_token_num:02d}" if current_token_num > 0 else "Not Started",
            'patients_ahead': patients_ahead,
            'estimated_wait_minutes': estimated_wait_minutes,
            'doctor_name': f"Dr. {doctor.name}",
            'doctor_specialty': doctor.primary_specialty.name if doctor.primary_specialty else "General OPD",
            'room_number': session.room_number,
            'organization_name': org.name,
            'emergency_phone': org.phone,
            'session_date': str(session.session_date)
        })

class HospitalOperationsSummaryView(views.APIView):
    """Hospital Admin & Desk: Today's aggregated OPD operational statistics"""
    permission_classes = [CanManageOPDAndQueue]

    def get(self, request):
        org_id = request.query_params.get('organization_id')
        user_org = getattr(request.user, 'organization', None)

        if not org_id and user_org:
            org_id = user_org.id

        if not org_id:
            return Response({'error': 'organization_id parameter required.'}, status=status.HTTP_400_BAD_REQUEST)

        today = timezone.now().date()
        
        today_appts = AppointmentRequest.objects.filter(organization_id=org_id, preferred_date=today)
        total_appts = today_appts.count()
        waiting_count = today_appts.filter(status__in=[AppointmentStatus.ACCEPTED, AppointmentStatus.CONFIRMED, AppointmentStatus.CHECKED_IN]).count()
        in_consultation_count = today_appts.filter(status=AppointmentStatus.IN_CONSULTATION).count()
        completed_count = today_appts.filter(status=AppointmentStatus.COMPLETED).count()
        cancelled_count = today_appts.filter(status__in=[AppointmentStatus.CANCELLED, AppointmentStatus.NO_SHOW, AppointmentStatus.REJECTED]).count()

        sessions = QueueSession.objects.filter(organization_id=org_id, session_date=today).select_related('doctor', 'department')
        queue_summaries = []
        for s in sessions:
            queue_summaries.append({
                'session_id': s.id,
                'doctor_name': f"Dr. {s.doctor.name}",
                'department': s.department.name if s.department else "General OPD",
                'room_number': s.room_number,
                'current_token': s.current_token_number,
                'total_tokens': s.total_tokens_issued,
                'waiting_count': s.tokens.filter(status=TokenStatus.WAITING).count(),
                'in_consultation': s.tokens.filter(status=TokenStatus.IN_CONSULTATION).count(),
                'completed_count': s.tokens.filter(status=TokenStatus.COMPLETED).count(),
            })

        return Response({
            'organization_id': org_id,
            'date': str(today),
            'total_appointments_today': total_appts,
            'waiting_patients': waiting_count,
            'in_consultation': in_consultation_count,
            'completed_consultations': completed_count,
            'cancelled_or_noshow': cancelled_count,
            'active_queue_sessions': queue_summaries
        })


# ============================================================================
# PHASE 2.5: SMART SLOTS, APPOINTMENT COORDINATION & LEAVE RESOLUTION
# ============================================================================

class DoctorAvailableSlotsView(views.APIView):
    """Calculate real-time smart available slots for a doctor on a specific date"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        date_str = request.query_params.get('date')
        org_id = request.query_params.get('organization_id')

        if not date_str:
            target_date = timezone.now().date()
        else:
            try:
                target_date = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)

        if not org_id:
            affil = DoctorAffiliation.objects.filter(doctor_id=pk).first()
            if affil:
                org_id = affil.organization_id
            else:
                doc = Doctor.objects.filter(id=pk).first()
                if not doc:
                    return Response({'error': 'Doctor not found.'}, status=status.HTTP_404_NOT_FOUND)
                first_org = Organization.objects.first()
                org_id = first_org.id if first_org else 1

        slot_data = SmartDoctorSlotEngine.calculate_slots(
            doctor_id=pk,
            organization_id=org_id,
            target_date=target_date
        )
        return Response(slot_data)


class AppointmentRescheduleView(views.APIView):
    """Patient or Hospital Desk Reschedule Endpoint"""
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            appt = AppointmentRequest.objects.select_related('organization', 'doctor').get(id=pk)
        except AppointmentRequest.DoesNotExist:
            return Response({'error': 'Appointment not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = AppointmentRescheduleSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        new_date = serializer.validated_data['new_date']
        new_slot = serializer.validated_data['new_time_slot']
        reason = serializer.validated_data.get('reason', '')

        old_status = appt.status
        old_date = appt.preferred_date
        old_slot = appt.preferred_time_slot

        appt.rescheduled_from_date = old_date
        appt.rescheduled_from_slot = old_slot
        appt.preferred_date = new_date
        appt.preferred_time_slot = new_slot
        appt.status = AppointmentStatus.RESCHEDULED
        appt.reschedule_reason = reason
        appt.is_doctor_unavailable_flagged = False
        appt.save(update_fields=[
            'preferred_date', 'preferred_time_slot', 'rescheduled_from_date',
            'rescheduled_from_slot', 'status', 'reschedule_reason',
            'is_doctor_unavailable_flagged', 'updated_at'
        ])

        AppointmentStatusHistory.objects.create(
            appointment=appt,
            from_status=old_status,
            to_status=AppointmentStatus.RESCHEDULED,
            changed_by=request.user if request.user.is_authenticated else None,
            notes=f"Rescheduled from {old_date} ({old_slot}) to {new_date} ({new_slot}). Reason: {reason}"
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.APPOINTMENT_RESCHEDULED,
            organization_id=appt.organization_id,
            entity_type='AppointmentRequest',
            entity_id=appt.id,
            actor_id=request.user.id if request.user.is_authenticated else None,
            actor_username=request.user.username if request.user.is_authenticated else appt.patient_name,
            title='Appointment Rescheduled',
            message=f"Appointment for {appt.patient_name} rescheduled to {new_date} at {new_slot}.",
            payload={'old_date': str(old_date), 'new_date': str(new_date), 'new_slot': new_slot}
        ))

        return Response({
            'success': True,
            'message': f"Appointment rescheduled successfully to {new_date} ({new_slot}).",
            'appointment': AppointmentRequestSerializer(appt).data
        })


class AppointmentCancelView(views.APIView):
    """Patient or Hospital Desk Cancellation Endpoint"""
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            appt = AppointmentRequest.objects.select_related('organization', 'doctor').get(id=pk)
        except AppointmentRequest.DoesNotExist:
            return Response({'error': 'Appointment not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = AppointmentCancelSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        reason = serializer.validated_data['reason']
        old_status = appt.status

        appt.status = AppointmentStatus.CANCELLED
        appt.cancellation_reason = reason
        appt.save(update_fields=['status', 'cancellation_reason', 'updated_at'])

        AppointmentStatusHistory.objects.create(
            appointment=appt,
            from_status=old_status,
            to_status=AppointmentStatus.CANCELLED,
            changed_by=request.user if request.user.is_authenticated else None,
            notes=f"Cancellation reason: {reason}"
        )

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.APPOINTMENT_CANCELLED,
            organization_id=appt.organization_id,
            entity_type='AppointmentRequest',
            entity_id=appt.id,
            actor_id=request.user.id if request.user.is_authenticated else None,
            actor_username=request.user.username if request.user.is_authenticated else appt.patient_name,
            title='Appointment Cancelled',
            message=f"Appointment #{appt.id} for {appt.patient_name} cancelled: {reason}",
            payload={'cancellation_reason': reason}
        ))

        return Response({
            'success': True,
            'message': 'Appointment cancelled successfully.',
            'appointment': AppointmentRequestSerializer(appt).data
        })


class AppointmentHistoryTimelineView(views.APIView):
    """Retrieve full audit status history and timeline for an appointment"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        try:
            appt = AppointmentRequest.objects.select_related('organization', 'doctor', 'substitute_doctor').get(id=pk)
        except AppointmentRequest.DoesNotExist:
            return Response({'error': 'Appointment not found.'}, status=status.HTTP_404_NOT_FOUND)

        history_qs = appt.status_history.all().order_by('created_at')
        events_qs = DomainEventLog.objects.filter(entity_type='AppointmentRequest', entity_id=pk).order_by('created_at')

        return Response({
            'appointment': AppointmentRequestSerializer(appt).data,
            'status_history': AppointmentStatusHistorySerializer(history_qs, many=True).data,
            'domain_events': DomainEventLogSerializer(events_qs, many=True).data
        })


class PatientAppointmentsListView(views.APIView):
    """Patient Appointment Center: retrieve all appointments for a patient grouped/filtered"""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        phone = request.query_params.get('phone', '').strip()
        status_filter = request.query_params.get('status_filter', 'all').lower()

        qs = AppointmentRequest.objects.select_related('organization', 'doctor', 'substitute_doctor')
        if phone:
            qs = qs.filter(patient_phone__icontains=phone)

        today = timezone.now().date()

        if status_filter == 'today':
            qs = qs.filter(preferred_date=today).exclude(status__in=[AppointmentStatus.CANCELLED, AppointmentStatus.REJECTED])
        elif status_filter == 'upcoming':
            qs = qs.filter(preferred_date__gt=today).exclude(status__in=[AppointmentStatus.CANCELLED, AppointmentStatus.REJECTED, AppointmentStatus.COMPLETED])
        elif status_filter == 'past':
            qs = qs.filter(Q(status=AppointmentStatus.COMPLETED) | Q(preferred_date__lt=today)).exclude(status__in=[AppointmentStatus.CANCELLED, AppointmentStatus.NO_SHOW])
        elif status_filter == 'cancelled':
            qs = qs.filter(status__in=[AppointmentStatus.CANCELLED, AppointmentStatus.REJECTED])
        elif status_filter == 'noshow':
            qs = qs.filter(status=AppointmentStatus.NO_SHOW)

        serializer = AppointmentRequestSerializer(qs.order_by('-preferred_date', '-created_at')[:50], many=True)
        return Response({
            'count': qs.count(),
            'status_filter': status_filter,
            'appointments': serializer.data
        })


class HospitalAppointmentDeskView(views.APIView):
    """Hospital Appointment Desk: Aggregated Multi-Filter & Metrics Console for Hospital Staff"""
    permission_classes = [CanManageOPDAndQueue]

    def get(self, request):
        org_id = request.query_params.get('organization_id')
        user_org = getattr(request.user, 'organization', None)

        if not org_id and user_org:
            org_id = user_org.id

        if not org_id:
            first_org = Organization.objects.first()
            org_id = first_org.id if first_org else 1

        today = timezone.now().date()
        date_param = request.query_params.get('date')
        if date_param:
            try:
                filter_date = datetime.datetime.strptime(date_param, '%Y-%m-%d').date()
            except ValueError:
                filter_date = today
        else:
            filter_date = today

        doctor_id = request.query_params.get('doctor_id')
        status_param = request.query_params.get('status')
        search_query = request.query_params.get('search', '').strip()

        base_qs = AppointmentRequest.objects.filter(organization_id=org_id, preferred_date=filter_date).select_related('organization', 'doctor', 'substitute_doctor')

        # Metrics for the day
        metrics = {
            'pending_requests_count': base_qs.filter(status__in=[AppointmentStatus.REQUESTED, AppointmentStatus.PENDING_HOSPITAL]).count(),
            'confirmed_count': base_qs.filter(status__in=[AppointmentStatus.ACCEPTED, AppointmentStatus.CONFIRMED]).count(),
            'checked_in_count': base_qs.filter(status=AppointmentStatus.CHECKED_IN).count(),
            'waiting_count': base_qs.filter(status=AppointmentStatus.CHECKED_IN).count(),
            'in_consultation_count': base_qs.filter(status=AppointmentStatus.IN_CONSULTATION).count(),
            'completed_count': base_qs.filter(status=AppointmentStatus.COMPLETED).count(),
            'cancelled_count': base_qs.filter(status=AppointmentStatus.CANCELLED).count(),
            'noshow_count': base_qs.filter(status=AppointmentStatus.NO_SHOW).count(),
            'doctor_leave_flagged_count': base_qs.filter(is_doctor_unavailable_flagged=True).count(),
            'total_appointments_count': base_qs.count()
        }

        qs = base_qs
        if doctor_id:
            qs = qs.filter(doctor_id=doctor_id)
        if status_param and status_param != 'ALL':
            qs = qs.filter(status=status_param)
        if search_query:
            qs = qs.filter(
                Q(patient_name__icontains=search_query) |
                Q(patient_phone__icontains=search_query) |
                Q(token_number__icontains=search_query) |
                Q(doctor__name__icontains=search_query)
            )

        serializer = AppointmentRequestSerializer(qs.order_by('created_at'), many=True)

        return Response({
            'organization_id': int(org_id),
            'date': str(filter_date),
            'metrics': metrics,
            'appointments': serializer.data
        })


class DoctorLeaveImpactResolutionView(views.APIView):
    """Bulk resolve flagged appointments affected by doctor unavailability or leave"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request):
        serializer = DoctorLeaveImpactResolutionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        org_id = request.data.get('organization_id')
        user_org = getattr(request.user, 'organization', None)
        if not org_id and user_org:
            org_id = user_org.id
        elif not org_id:
            org_id = 1

        result = DoctorLeaveImpactEngine.resolve_impact(
            organization_id=org_id,
            appointment_ids=serializer.validated_data['appointment_ids'],
            action=serializer.validated_data['action'],
            substitute_doctor_id=serializer.validated_data.get('substitute_doctor_id'),
            new_date=serializer.validated_data.get('new_date'),
            notes=serializer.validated_data.get('notes', ''),
            user=request.user
        )

        return Response(result, status=status.HTTP_200_OK)


# =========================================================================
# PHASE 2.6: ADVANCED QUEUE, TOKEN & PATIENT FLOW VIEWS
# =========================================================================

class MultiQueueSessionListView(views.APIView):
    """List or create active multi-department queue sessions (OPD, Emergency, Pharmacy, Lab, Radiology, etc.)"""
    permission_classes = [CanManageOPDAndQueue]

    def get(self, request):
        user_org = getattr(request.user, 'organization', None)
        org_id = request.query_params.get('organization_id')
        if not org_id and user_org:
            org_id = user_org.id
        elif not org_id:
            org_id = 1

        qs = QueueSession.objects.filter(organization_id=org_id).select_related('organization', 'doctor', 'department')
        queue_type = request.query_params.get('queue_type')
        is_active = request.query_params.get('is_active')

        if queue_type:
            qs = qs.filter(queue_type=queue_type)
        if is_active is not None:
            qs = qs.filter(is_active=(is_active.lower() == 'true'))

        serializer = QueueSessionSerializer(qs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        user_org = getattr(request.user, 'organization', None)
        org_id = request.data.get('organization_id') or (user_org.id if user_org else 1)
        doctor_id = request.data.get('doctor_id')
        department_id = request.data.get('department_id')
        queue_type = request.data.get('queue_type', QueueType.OPD)
        room_number = request.data.get('room_number', 'OPD Room 102')
        token_prefix = request.data.get('token_prefix') or SmartQueueEngine.DEFAULT_PREFIXES.get(queue_type, 'C')

        session = QueueSession.objects.create(
            organization_id=org_id,
            doctor_id=doctor_id,
            department_id=department_id,
            queue_type=queue_type,
            token_prefix=token_prefix,
            room_number=room_number,
            session_date=datetime.date.today(),
            is_active=True,
        )

        serializer = QueueSessionSerializer(session)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class QueueSessionDetailStatusView(views.APIView):
    """Retrieve comprehensive operational status for a single queue session"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        try:
            session = QueueSession.objects.select_related('organization', 'doctor', 'department').get(pk=pk)
        except QueueSession.DoesNotExist:
            return Response({'detail': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Cross-tenant check for staff
        user_org = getattr(request.user, 'organization', None)
        if user_org and user_org.id != session.organization_id and not (request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin')):
            return Response({'detail': 'Access denied to other hospital queues.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = QueueSessionSerializer(session)
        return Response(serializer.data, status=status.HTTP_200_OK)


class QueueEstimatedWaitView(views.APIView):
    """Calculate real-time estimated wait time, patients ahead, and queue dynamics for a patient's token"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        try:
            token = QueueToken.objects.select_related('queue_session__organization', 'queue_session__doctor', 'queue_session__department').get(pk=pk)
        except QueueToken.DoesNotExist:
            return Response({'detail': 'Token not found.'}, status=status.HTTP_404_NOT_FOUND)

        wait_info = SmartQueueEngine.calculate_estimated_wait_time(token)
        return Response(wait_info, status=status.HTTP_200_OK)


class QueuePublicDisplayView(views.APIView):
    """Public TV / Kiosk Display monitor feed — strictly anonymized, displaying only token numbers and room directions"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        try:
            display_data = SmartQueueEngine.get_public_display_data(pk)
            return Response(display_data, status=status.HTTP_200_OK)
        except QueueSession.DoesNotExist:
            return Response({'detail': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)


class QueueSessionCallNextView(views.APIView):
    """Doctor or Nurse calls the next highest priority waiting patient to the OPD consultation room"""
    permission_classes = [IsQueueAuthorizedDoctorOrAdmin]

    def post(self, request, pk):
        try:
            session = QueueSession.objects.get(pk=pk)
        except QueueSession.DoesNotExist:
            return Response({'detail': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)

        self.check_object_permissions(request, session)

        try:
            called_token = SmartQueueEngine.call_next_token(session.id, actor_user=request.user)
            if not called_token:
                return Response({'detail': 'No waiting patients in this queue.'}, status=status.HTTP_200_OK)

            serializer = QueueTokenSerializer(called_token)
            return Response({
                'success': True,
                'message': f"Now calling Token {called_token.token_label} ({called_token.get_priority_display()}) to {session.room_number}.",
                'token': serializer.data,
                'current_token_number': session.current_token_number
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class QueueTokenRecallView(views.APIView):
    """Trigger staged recall for an absent patient token before enforcing no-show policy"""
    permission_classes = [IsQueueAuthorizedDoctorOrAdmin]

    def post(self, request, pk):
        try:
            token = QueueToken.objects.select_related('queue_session__organization', 'queue_session__doctor').get(pk=pk)
        except QueueToken.DoesNotExist:
            return Response({'detail': 'Token not found.'}, status=status.HTTP_404_NOT_FOUND)

        self.check_object_permissions(request, token)

        recalled = SmartQueueEngine.recall_token(token.id, actor_user=request.user)
        serializer = QueueTokenSerializer(recalled)
        return Response({
            'success': True,
            'message': f"Recall #{recalled.call_count} alert broadcast for Token {recalled.token_label}.",
            'token': serializer.data
        }, status=status.HTTP_200_OK)


class QueueTokenSkipView(views.APIView):
    """Hold / skip a patient token in the queue"""
    permission_classes = [IsQueueAuthorizedDoctorOrAdmin]

    def post(self, request, pk):
        try:
            token = QueueToken.objects.select_related('queue_session__organization', 'queue_session__doctor').get(pk=pk)
        except QueueToken.DoesNotExist:
            return Response({'detail': 'Token not found.'}, status=status.HTTP_404_NOT_FOUND)

        self.check_object_permissions(request, token)

        reason = request.data.get('reason', 'Patient not present when called')
        token.status = TokenStatus.SKIPPED
        token.clinical_notes = f"[SKIPPED] {reason}"
        token.save(update_fields=['status', 'clinical_notes'])

        EventDispatcher.dispatch(DomainEvent(
            event_type=DomainEventType.QUEUE_TOKEN_SKIPPED,
            organization_id=token.queue_session.organization_id,
            entity_type='QueueToken',
            entity_id=token.id,
            actor_id=request.user.id if request.user else None,
            actor_username=request.user.username if request.user else 'staff',
            title=f"Token {token.token_label} Skipped",
            message=f"Token {token.token_label} skipped: {reason}",
            payload={'token_label': token.token_label, 'reason': reason}
        ))

        return Response({
            'success': True,
            'message': f"Token {token.token_label} marked as skipped.",
            'token': QueueTokenSerializer(token).data
        }, status=status.HTTP_200_OK)


class QueueSessionPauseView(views.APIView):
    """Pause an active OPD session with mandatory clinical/administrative reason"""
    permission_classes = [IsQueueAuthorizedDoctorOrAdmin]

    def post(self, request, pk):
        try:
            session = QueueSession.objects.get(pk=pk)
        except QueueSession.DoesNotExist:
            return Response({'detail': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)

        self.check_object_permissions(request, session)

        serializer = QueueSessionPauseRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            pause = SmartQueueEngine.pause_session(
                session_id=session.id,
                reason=serializer.validated_data['reason'],
                notes=serializer.validated_data.get('notes', ''),
                actor_user=request.user
            )
            return Response({
                'success': True,
                'message': f"Queue session paused ({pause.get_reason_display()}).",
                'pause': QueuePauseSerializer(pause).data
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class QueueSessionResumeView(views.APIView):
    """Resume a paused OPD session"""
    permission_classes = [IsQueueAuthorizedDoctorOrAdmin]

    def post(self, request, pk):
        try:
            session = QueueSession.objects.get(pk=pk)
        except QueueSession.DoesNotExist:
            return Response({'detail': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)

        self.check_object_permissions(request, session)

        resumed = SmartQueueEngine.resume_session(session.id, actor_user=request.user)
        return Response({
            'success': True,
            'message': "Queue session resumed successfully.",
            'session': QueueSessionSerializer(resumed).data
        }, status=status.HTTP_200_OK)


class QueueTokenUnifiedIssueView(views.APIView):
    """Generate a concurrency-safe unified queue token for walk-in or appointment check-in"""
    permission_classes = [CanManageOPDAndQueue]

    def post(self, request):
        serializer = QueueTokenIssueRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            session = QueueSession.objects.get(id=serializer.validated_data['queue_session_id'])
        except QueueSession.DoesNotExist:
            return Response({'detail': 'Queue session not found.'}, status=status.HTTP_404_NOT_FOUND)

        appt = None
        appt_id = serializer.validated_data.get('appointment_id')
        if appt_id:
            appt = AppointmentRequest.objects.filter(id=appt_id).first()

        token = SmartQueueEngine.issue_unified_token(
            queue_session=session,
            patient_name=serializer.validated_data['patient_name'],
            patient_phone=serializer.validated_data['patient_phone'],
            appointment=appt,
            priority=serializer.validated_data['priority'],
            is_walk_in=serializer.validated_data.get('is_walk_in', True),
            actor_user=request.user
        )

        return Response({
            'success': True,
            'token': QueueTokenSerializer(token).data
        }, status=status.HTTP_201_CREATED)


class DigitalCheckInView(views.APIView):
    """Validate digital arrival QR scan at entrance or kiosk and activate token"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = DigitalCheckInRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user_org = getattr(request.user, 'organization', None)
        org_id = request.data.get('organization_id') or (user_org.id if user_org else 1)

        try:
            org = Organization.objects.get(id=org_id)
        except Organization.DoesNotExist:
            return Response({'detail': 'Organization not found.'}, status=status.HTTP_404_NOT_FOUND)

        try:
            result = SmartQueueEngine.process_digital_check_in(
                organization=org,
                qr_hash=serializer.validated_data.get('qr_hash', ''),
                appointment_id=serializer.validated_data.get('appointment_id'),
                check_in_method=serializer.validated_data.get('check_in_method', 'QR_SCAN'),
                verified_by=request.user
            )
            return Response(result, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class GenerateAppointmentQRView(views.APIView):
    """Generate or retrieve tamper-resistant QR code hash for an appointment"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        appt_id = request.data.get('appointment_id')
        if not appt_id:
            return Response({'detail': 'appointment_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            appt = AppointmentRequest.objects.select_related('organization', 'doctor').get(id=appt_id)
        except AppointmentRequest.DoesNotExist:
            return Response({'detail': 'Appointment not found.'}, status=status.HTTP_404_NOT_FOUND)

        token = QueueToken.objects.filter(appointment=appt).first()
        if not token:
            # Find or create active session
            session = QueueSession.objects.filter(
                organization=appt.organization,
                doctor=appt.doctor,
                session_date=datetime.date.today(),
                is_active=True
            ).first()
            if not session:
                session = QueueSession.objects.create(
                    organization=appt.organization,
                    doctor=appt.doctor,
                    department=appt.doctor.department,
                    session_date=datetime.date.today(),
                    room_number='OPD Room 102',
                    queue_type=QueueType.OPD,
                    token_prefix='C'
                )
            token = SmartQueueEngine.issue_unified_token(
                queue_session=session,
                patient_name=appt.patient_name,
                patient_phone=appt.patient_phone,
                appointment=appt,
                priority=QueuePriority.NORMAL,
                is_walk_in=False,
                actor_user=request.user
            )

        qr_payload = f"carelink:checkin:{token.qr_code_hash}"
        return Response({
            'appointment_id': appt.id,
            'token_id': token.id,
            'token_label': token.token_label,
            'qr_code_hash': token.qr_code_hash,
            'qr_payload': qr_payload,
            'patient_name': appt.patient_name,
            'doctor_name': appt.doctor.name,
            'organization_name': appt.organization.name,
            'room_number': token.queue_session.room_number,
        }, status=status.HTTP_200_OK)


class HospitalPatientFlowAnalyticsView(views.APIView):
    """Aggregate hospital throughput, average wait times, consultation durations, and department bottlenecks"""
    permission_classes = [CanManageOPDAndQueue]

    def get(self, request):
        user_org = getattr(request.user, 'organization', None)
        org_id = request.query_params.get('organization_id') or (user_org.id if user_org else 1)

        try:
            org = Organization.objects.get(id=org_id)
        except Organization.DoesNotExist:
            return Response({'detail': 'Organization not found.'}, status=status.HTTP_404_NOT_FOUND)

        date_str = request.query_params.get('date')
        target_date = datetime.date.today()
        if date_str:
            try:
                target_date = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass

        analytics = SmartQueueEngine.get_hospital_flow_analytics(organization=org, target_date=target_date)
        return Response(analytics, status=status.HTTP_200_OK)




