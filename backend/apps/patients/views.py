from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.authentication.models import UserRole
from apps.authentication.permissions import IsSameOrganizationTenant
from .models import Patient, VitalsReading, PatientAuditLog
from .serializers import PatientSerializer, VitalsReadingSerializer, PatientAuditLogSerializer

class PatientViewSet(viewsets.ModelViewSet):
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def _log_audit(self, request, patient, action, details=''):
        try:
            ip = request.META.get('REMOTE_ADDR', '')
            user = request.user
            PatientAuditLog.objects.create(
                patient=patient,
                user_username=user.username if user.is_authenticated else 'Anonymous',
                user_role=getattr(user, 'role', ''),
                organization_name=user.organization.name if getattr(user, 'organization', None) else '',
                action=action,
                ip_address=ip,
                details=details,
            )
        except Exception:
            pass

    def get_queryset(self):
        user = self.request.user
        queryset = Patient.objects.all().order_by('-id')


        # Multi-Tenant Scoping: Non-SuperAdmins only see patients belonging to their organization
        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = Patient.objects.none()

        district = self.request.query_params.get('district')
        tier = self.request.query_params.get('tier')
        risk = self.request.query_params.get('risk')

        if district:
            queryset = queryset.filter(district=district)
        if tier:
            queryset = queryset.filter(category_tier__icontains=tier)
        if risk:
            queryset = queryset.filter(risk_level=risk)

        return queryset

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        self._log_audit(request, instance, 'VIEW', 'Viewed patient profile and medical record')
        return super().retrieve(request, *args, **kwargs)

    def perform_create(self, serializer):
        user = self.request.user
        patient = serializer.save(organization=user.organization if user.is_authenticated else None)
        self._log_audit(self.request, patient, 'CREATE', f'Registered patient {patient.name}')

    def perform_update(self, serializer):
        patient = serializer.save()
        self._log_audit(self.request, patient, 'UPDATE', f'Updated profile for {patient.name}')

    @action(detail=True, methods=['post'])
    def add_vitals(self, request, pk=None):
        patient = self.get_object()
        serializer = VitalsReadingSerializer(data=request.data)
        if serializer.is_valid():
            vitals = serializer.save(patient=patient, recorded_by=request.user.username if request.user.is_authenticated else 'Staff')
            self._log_audit(request, patient, 'ADD_VITALS', f'Recorded vitals: BP {vitals.bp}, SpO2 {vitals.spo2}%')


            # Phase 7: Evaluate deterministic clinical rules
            try:
                from apps.alerts.services import ClinicalRulesEngine
                ClinicalRulesEngine.evaluate_vitals(vitals)
            except Exception as e:
                pass

            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)


    @action(detail=True, methods=['get'])
    def audit_logs(self, request, pk=None):
        patient = self.get_object()
        logs = patient.audit_logs.all()[:50]
        serializer = PatientAuditLogSerializer(logs, many=True)
        return Response(serializer.data)

