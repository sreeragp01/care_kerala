from rest_framework import serializers, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from apps.authentication.models import UserRole
from apps.authentication.permissions import IsSameOrganizationTenant
from .models import BloodDonor, BloodRequest

class BloodDonorSerializer(serializers.ModelSerializer):
    is_eligible = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)

    class Meta:
        model = BloodDonor
        fields = '__all__'

class BloodRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = BloodRequest
        fields = '__all__'

class BloodDonorViewSet(viewsets.ModelViewSet):
    serializer_class = BloodDonorSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = BloodDonor.objects.all()

        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = BloodDonor.objects.none()

        blood_group = self.request.query_params.get('blood_group')
        district = self.request.query_params.get('district')
        if blood_group and blood_group != 'All':
            queryset = queryset.filter(blood_group=blood_group)
        if district:
            queryset = queryset.filter(district=district)
        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(organization=user.organization if user.is_authenticated else None)

    @action(detail=True, methods=['post'])
    def record_donation(self, request, pk=None):
        donor = self.get_object()
        donor.last_donation_date = timezone.now().date()
        donor.total_donations += 1
        donor.save()
        return Response(BloodDonorSerializer(donor).data)

class BloodRequestViewSet(viewsets.ModelViewSet):
    serializer_class = BloodRequestSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = BloodRequest.objects.all()

        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = BloodRequest.objects.none()

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(organization=user.organization if user.is_authenticated else None)

    @action(detail=True, methods=['post'])
    def notify_matching_donors(self, request, pk=None):
        req = self.get_object()
        matching = BloodDonor.objects.filter(blood_group=req.blood_group, district=req.district, is_available=True)
        eligible_count = [d for d in matching if d.is_eligible]
        return Response({
            'message': f'Emergency alert broadcasted to {len(eligible_count)} eligible {req.blood_group} donors in {req.district} district.',
            'notified_count': len(eligible_count),
        })

