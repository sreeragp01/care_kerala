from rest_framework import status, views, permissions
from rest_framework.response import Response
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
    HealthcareProfileSerializer,
    DoctorSerializer,
    DoctorScheduleSerializer,
    ChangeRequestSerializer,
    OrganizationDocumentSerializer,
    ClaimOrganizationRequestSerializer,
    PatientInformationReportSerializer,
    AppointmentRequestSerializer,
)
from apps.organizations.models import Organization

class PublicDirectoryListView(views.APIView):
    """Public Search API for Hospitals, Clinics, and Healthcare Providers across Kerala"""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        queryset = HealthcareProfile.objects.select_related('organization', 'verified_by').prefetch_related('specialties', 'services', 'facilities', 'organization__departments')

        # Filter by District
        district = request.query_params.get('district')
        if district:
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

        # Search Query (name, address, services, doctors)
        q = request.query_params.get('search')
        if q:
            queryset = queryset.filter(
                Q(organization__name__icontains=q) |
                Q(address__icontains=q) |
                Q(description__icontains=q) |
                Q(specialties__name__icontains=q) |
                Q(services__name__icontains=q)
            ).distinct()

        serializer = HealthcareProfileSerializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'results': serializer.data
        })

class HospitalDetailView(views.APIView):
    """Retrieve full detailed hospital profile with departments, doctors, and facilities"""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        try:
            profile = HealthcareProfile.objects.select_related('organization').prefetch_related('specialties', 'services', 'facilities', 'organization__departments').get(Q(id=pk) | Q(organization__id=pk))
            serializer = HealthcareProfileSerializer(profile)
            return Response(serializer.data)
        except HealthcareProfile.DoesNotExist:
            return Response({'detail': 'Hospital not found.'}, status=status.HTTP_404_NOT_FOUND)

class DoctorDirectoryListView(views.APIView):
    """Public Search API for Doctors and Specialists in Kerala"""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        queryset = Doctor.objects.filter(is_active=True).select_related('primary_specialty').prefetch_related('affiliations', 'affiliations__organization', 'affiliations__schedules')

        specialty = request.query_params.get('specialty')
        if specialty:
            queryset = queryset.filter(Q(primary_specialty__name__icontains=specialty) | Q(sub_specialties__icontains=specialty))

        district = request.query_params.get('district')
        if district:
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

        serializer = DoctorSerializer(queryset.distinct(), many=True)
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
            Q(registration_number=reg_number)
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
    """Submit a claim for an existing organization profile"""
    permission_classes = [permissions.IsAuthenticated]

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
            official_phone=data.get('official_phone', request.user.phone or ''),
            proof_document_url=data.get('proof_document_url', ''),
            status='PENDING'
        )

        return Response({
            'success': True,
            'message': f"Claim for '{org.name}' submitted. CareLink Admins will verify your official credentials.",
            'claim_id': claim.id
        }, status=status.HTTP_201_CREATED)

class ChangeRequestListView(views.APIView):
    """List and submit change proposals (Moderator -> Org Admin governance)"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        queryset = ChangeRequest.objects.all()
        if user.organization:
            queryset = queryset.filter(organization=user.organization)
        serializer = ChangeRequestSerializer(queryset, many=True)
        return Response(serializer.data)

    def post(self, request):
        data = request.data
        user = request.user
        org_id = data.get('organization_id') or (user.organization.id if user.organization else None)
        if not org_id:
            return Response({'error': 'Organization ID is required.'}, status=status.HTTP_400_BAD_REQUEST)

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
    """Approve or Reject a moderator change request"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            cr = ChangeRequest.objects.get(id=pk)
        except ChangeRequest.DoesNotExist:
            return Response({'error': 'Change Request not found.'}, status=status.HTTP_404_NOT_FOUND)

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
    """Patient consultation request"""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = AppointmentRequestSerializer(data=request.data)
        if serializer.is_valid():
            appointment = serializer.save(status='REQUESTED')
            return Response({
                'success': True,
                'message': 'Appointment request submitted. The hospital desk will confirm your token.',
                'appointment_id': appointment.id
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

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
    """CareLink Super Admin / Platform Overview"""
    permission_classes = [permissions.IsAuthenticated]

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
