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
    IsDocumentAuthorizedTenant,
)
from apps.organizations.models import Organization

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
