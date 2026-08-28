from rest_framework import serializers, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.authentication.models import UserRole
from apps.authentication.permissions import IsSameOrganizationTenant
from .models import HomeVisit

class HomeVisitSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.name', read_only=True)
    patient_address = serializers.CharField(source='patient.address', read_only=True)

    class Meta:
        model = HomeVisit
        fields = '__all__'
        read_only_fields = ['organization']


class HomeVisitViewSet(viewsets.ModelViewSet):
    serializer_class = HomeVisitSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = HomeVisit.objects.all()

        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = HomeVisit.objects.none()

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(organization=user.organization if user.is_authenticated else None)

    @action(detail=True, methods=['post'])
    def gps_check_in(self, request, pk=None):
        visit = self.get_object()
        visit.status = 'In Progress'
        visit.gps_check_in_time = request.data.get('gps_check_in_time', 'GPS Verified')
        visit.gps_location_name = request.data.get('gps_location_name', 'Patient Home Coordinates')
        visit.save()
        return Response(HomeVisitSerializer(visit).data)

    @action(detail=True, methods=['post'])
    def complete_visit(self, request, pk=None):
        visit = self.get_object()
        visit.status = 'Completed'
        visit.clinical_notes = request.data.get('clinical_notes', visit.clinical_notes)
        visit.symptoms_observed = request.data.get('symptoms_observed', visit.symptoms_observed)
        visit.assessment_notes = request.data.get('assessment_notes', visit.assessment_notes)
        visit.care_provided = request.data.get('care_provided', visit.care_provided)
        visit.medication_administered = request.data.get('medication_administered', visit.medication_administered)
        visit.equipment_used = request.data.get('equipment_used', visit.equipment_used)
        visit.follow_up_instructions = request.data.get('follow_up_instructions', visit.follow_up_instructions)
        visit.save()
        return Response(HomeVisitSerializer(visit).data)

    @action(detail=True, methods=['post'])
    def doctor_review(self, request, pk=None):
        from django.utils import timezone
        user = request.user
        if user.role not in [UserRole.DOCTOR, UserRole.SUPER_ADMIN, UserRole.ORG_ADMIN]:
            return Response({'detail': 'Only medical doctors or org admins can sign off on clinical doctor reviews.'}, status=403)

        visit = self.get_object()
        visit.status = 'Closed'
        visit.doctor_review_notes = request.data.get('doctor_review_notes', 'Reviewed & Approved by Doctor.')
        visit.doctor_signed_off = True
        visit.doctor_signoff_timestamp = timezone.now()
        visit.save()
        return Response(HomeVisitSerializer(visit).data)



