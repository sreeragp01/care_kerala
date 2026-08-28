from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from apps.authentication.models import UserRole
from apps.authentication.permissions import IsSameOrganizationTenant
from .models import ClinicalAlert, AlertStatus, UserDevice, NotificationPreference
from .serializers import ClinicalAlertSerializer, UserDeviceSerializer, NotificationPreferenceSerializer

class ClinicalAlertViewSet(viewsets.ModelViewSet):
    serializer_class = ClinicalAlertSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = ClinicalAlert.objects.all()

        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = ClinicalAlert.objects.none()

        severity = self.request.query_params.get('severity')
        alert_status = self.request.query_params.get('status')

        if severity:
            queryset = queryset.filter(severity=severity)
        if alert_status:
            queryset = queryset.filter(status=alert_status)

        return queryset

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        alert = self.get_object()
        alert.status = AlertStatus.ACKNOWLEDGED
        alert.acknowledged_at = timezone.now()
        alert.acknowledged_by = request.user.username
        alert.save()
        return Response(ClinicalAlertSerializer(alert).data)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        alert = self.get_object()
        alert.status = AlertStatus.RESOLVED
        alert.save()
        return Response(ClinicalAlertSerializer(alert).data)

class UserDeviceViewSet(viewsets.ModelViewSet):
    serializer_class = UserDeviceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserDevice.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(user=user, organization=user.organization)

    @action(detail=False, methods=['post'])
    def register(self, request):
        user = request.user
        device_id = request.data.get('device_id')
        fcm_token = request.data.get('fcm_token')
        platform = request.data.get('platform', 'flutter_android')

        if not device_id or not fcm_token:
            return Response({'error': 'device_id and fcm_token are required'}, status=status.HTTP_400_BAD_REQUEST)

        device, created = UserDevice.objects.update_or_create(
            user=user,
            device_id=device_id,
            defaults={
                'organization': user.organization,
                'fcm_token': fcm_token,
                'platform': platform,
                'is_active': True,
                'last_seen_at': timezone.now()
            }
        )
        return Response(UserDeviceSerializer(device).data, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)

class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return NotificationPreference.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get', 'put', 'patch'])
    def my_preferences(self, request):
        user = request.user
        pref, _ = NotificationPreference.objects.get_or_create(user=user)
        if request.method in ['PUT', 'PATCH']:
            serializer = NotificationPreferenceSerializer(pref, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        return Response(NotificationPreferenceSerializer(pref).data)
