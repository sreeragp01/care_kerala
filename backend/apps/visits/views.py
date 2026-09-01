from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from apps.authentication.models import UserRole
from apps.authentication.permissions import IsSameOrganizationTenant
from apps.patients.models import CareTeam, CareTeamMember, CaregiverAccess, CaregiverPermission
from .models import HomeVisit, HomeVisitRequest, VisitStatus, CareTeamRoute, RouteStop
from .serializers import (
    HomeVisitSerializer, HomeVisitRequestSerializer, CareTeamRouteSerializer,
    RouteStopSerializer
)
from .palliative_engine import PalliativeCareEngine


class HomeVisitRequestViewSet(viewsets.ModelViewSet):
    serializer_class = HomeVisitRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.SUPER_ADMIN:
            return HomeVisitRequest.objects.all().order_by('-id')
        if user.role == UserRole.FAMILY_MEMBER:
            granted_patient_ids = CaregiverAccess.objects.filter(user=user, is_active=True).values_list('patient_id', flat=True)
            return HomeVisitRequest.objects.filter(patient_id__in=granted_patient_ids).order_by('-id')
        if user.organization_id:
            return HomeVisitRequest.objects.filter(organization_id=user.organization_id).order_by('-id')
        return HomeVisitRequest.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(
            organization=user.organization if user.organization else None,
            requested_by_user=user if user.is_authenticated else None,
        )

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        req = self.get_object()
        scheduled_date = request.data.get('scheduled_date')
        scheduled_time = request.data.get('scheduled_time', '10:00 AM')
        assigned_nurse_name = request.data.get('assigned_nurse_name', '')
        care_team_id = request.data.get('care_team_id')

        visit = PalliativeCareEngine.accept_home_visit_request(
            request_id=req.id,
            actor_user=request.user,
            scheduled_date=scheduled_date,
            scheduled_time=scheduled_time,
            assigned_nurse_name=assigned_nurse_name,
            care_team_id=care_team_id,
        )
        return Response(HomeVisitSerializer(visit).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        req = self.get_object()
        reason = request.data.get('rejection_reason', 'Outside service coverage or care team fully booked.')
        req.status = 'REJECTED'
        req.rejection_reason = reason
        req.save()
        return Response({'detail': f'Request #{req.id} rejected.', 'reason': reason})


class HomeVisitViewSet(viewsets.ModelViewSet):
    serializer_class = HomeVisitSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = HomeVisit.objects.all().order_by('-scheduled_date', '-id')

        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.role == UserRole.FAMILY_MEMBER:
                # Caregivers see visits for granted patients if they have VIEW_VISITS permission
                granted_patient_ids = [
                    g.patient_id for g in CaregiverAccess.objects.filter(user=user, is_active=True)
                    if g.has_permission(CaregiverPermission.VIEW_VISITS)
                ]
                queryset = queryset.filter(patient_id__in=granted_patient_ids)
            elif user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
                # Field nurse scoping: Filter by assigned nurse or assigned care teams
                params = getattr(self.request, 'query_params', getattr(self.request, 'GET', {}))
                if user.role == UserRole.NURSE and params.get('my_visits') == 'true':
                    assigned_team_ids = CareTeamMember.objects.filter(user=user).values_list('care_team_id', flat=True)
                    queryset = queryset.filter(
                        care_team_id__in=assigned_team_ids
                    ) | queryset.filter(assigned_nurse_name__icontains=user.username)
            else:
                queryset = HomeVisit.objects.none()

        params = getattr(self.request, 'query_params', getattr(self.request, 'GET', {}))
        status_param = params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)

        date_param = params.get('date')
        if date_param:
            queryset = queryset.filter(scheduled_date=date_param)

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(organization=user.organization if user.is_authenticated else None)

    @action(detail=True, methods=['post'])
    def assign_team(self, request, pk=None):
        visit = self.get_object()
        care_team_id = request.data.get('care_team_id')
        assigned_nurse_name = request.data.get('assigned_nurse_name', '')
        assigned_doctor_name = request.data.get('assigned_doctor_name', '')

        if not care_team_id:
            return Response({'detail': 'care_team_id is required.'}, status=400)

        updated_visit = PalliativeCareEngine.assign_care_team(
            visit_id=visit.id,
            care_team_id=int(care_team_id),
            actor_user=request.user,
            assigned_nurse_name=assigned_nurse_name,
            assigned_doctor_name=assigned_doctor_name,
        )
        return Response(HomeVisitSerializer(updated_visit).data)

    @action(detail=True, methods=['post'], url_path='dispatch')
    def dispatch_team(self, request, pk=None):
        visit = self.get_object()
        updated_visit = PalliativeCareEngine.dispatch_care_team(
            visit_id=visit.id,
            actor_user=request.user,
        )
        return Response(HomeVisitSerializer(updated_visit).data)

    @action(detail=True, methods=['post'])
    def arrive(self, request, pk=None):
        visit = self.get_object()
        gps_location = request.data.get('gps_location_name', 'Patient Home Coordinates')
        gps_time = request.data.get('gps_check_in_time', 'GPS Verified')

        updated_visit = PalliativeCareEngine.record_visit_arrival(
            visit_id=visit.id,
            actor_user=request.user,
            gps_location_name=gps_location,
            gps_check_in_time=gps_time,
        )
        return Response(HomeVisitSerializer(updated_visit).data)

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        visit = self.get_object()
        symptoms = request.data.get('symptoms_observed', '')
        assessment = request.data.get('assessment_notes', '')
        care = request.data.get('care_provided', '')
        medication = request.data.get('medication_administered', '')
        equipment = request.data.get('equipment_used', '')
        follow_up = request.data.get('follow_up_instructions', '')
        clinical = request.data.get('clinical_notes', '')
        vitals = request.data.get('vitals')
        next_date = request.data.get('next_visit_date')

        updated_visit = PalliativeCareEngine.complete_home_visit(
            visit_id=visit.id,
            actor_user=request.user,
            symptoms_observed=symptoms,
            assessment_notes=assessment,
            care_provided=care,
            medication_administered=medication,
            equipment_used=equipment,
            follow_up_instructions=follow_up,
            clinical_notes=clinical,
            vitals_data=vitals,
            next_visit_date=next_date,
        )
        return Response(HomeVisitSerializer(updated_visit).data)

    @action(detail=True, methods=['post'])
    def complete_visit(self, request, pk=None):
        """Legacy alias for complete."""
        return self.complete(request, pk)

    @action(detail=True, methods=['post'])
    def gps_check_in(self, request, pk=None):
        """Legacy alias for arrive."""
        return self.arrive(request, pk)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        visit = self.get_object()
        reason = request.data.get('reason', 'Cancelled by hospital / patient.')
        updated_visit = PalliativeCareEngine.cancel_home_visit(
            visit_id=visit.id,
            actor_user=request.user,
            reason=reason,
        )
        return Response(HomeVisitSerializer(updated_visit).data)

    @action(detail=True, methods=['post'])
    def doctor_review(self, request, pk=None):
        user = request.user
        if user.role not in [UserRole.DOCTOR, UserRole.SUPER_ADMIN, UserRole.ORG_ADMIN]:
            return Response({'detail': 'Only medical doctors or org admins can sign off on clinical doctor reviews.'}, status=403)

        visit = self.get_object()
        visit.status = VisitStatus.CLOSED
        visit.doctor_review_notes = request.data.get('doctor_review_notes', 'Reviewed & Approved by Doctor.')
        visit.doctor_signed_off = True
        visit.doctor_signoff_timestamp = timezone.now()
        visit.save()
        return Response(HomeVisitSerializer(visit).data)


class CareTeamRouteViewSet(viewsets.ModelViewSet):
    serializer_class = CareTeamRouteSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.SUPER_ADMIN:
            return CareTeamRoute.objects.all().order_by('-route_date')
        if user.organization_id:
            return CareTeamRoute.objects.filter(organization_id=user.organization_id).order_by('-route_date')
        return CareTeamRoute.objects.none()

    @action(detail=False, methods=['post'])
    def plan_route(self, request):
        care_team_id = request.data.get('care_team_id')
        route_date = request.data.get('route_date', str(timezone.now().date()))
        visit_ids = request.data.get('visit_ids', [])

        care_team = CareTeam.objects.get(id=care_team_id, organization=request.user.organization)
        route, created = CareTeamRoute.objects.get_or_create(
            organization=request.user.organization,
            care_team=care_team,
            route_date=route_date,
            defaults={
                'primary_nurse_name': care_team.primary_nurse.username if care_team.primary_nurse else 'Nurse',
                'status': 'PLANNED',
                'total_stops': len(visit_ids),
            }
        )

        for idx, vid in enumerate(visit_ids):
            visit = HomeVisit.objects.filter(id=vid, organization=request.user.organization).first()
            if visit:
                RouteStop.objects.update_or_create(
                    route=route,
                    visit=visit,
                    defaults={
                        'sequence_order': idx + 1,
                        'location_area': visit.patient.ward or visit.patient.district,
                    }
                )

        route.total_stops = route.stops.count()
        route.save()
        return Response(CareTeamRouteSerializer(route).data, status=status.HTTP_201_CREATED)
