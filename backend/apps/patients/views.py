from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from apps.authentication.models import UserRole, User
from apps.authentication.permissions import IsSameOrganizationTenant
from .models import (
    Patient, CarePlan, CareTeam, CareTeamMember, CareTeamRole, PatientCareGoal,
    CaregiverAccess, CaregiverPermission, MedicationPlan, MedicationAdministration,
    VitalsReading, PatientAuditLog
)
from .serializers import (
    PatientSerializer, CarePlanSerializer, CareTeamSerializer, CareTeamMemberSerializer,
    PatientCareGoalSerializer, CaregiverAccessSerializer, MedicationPlanSerializer,
    MedicationAdministrationSerializer, VitalsReadingSerializer, PatientAuditLogSerializer
)
from apps.visits.palliative_engine import PalliativeCareEngine


class PatientViewSet(viewsets.ModelViewSet):
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def _log_audit(self, request, patient, action_name, details=''):
        try:
            ip = request.META.get('REMOTE_ADDR', '')
            user = request.user
            PatientAuditLog.objects.create(
                patient=patient,
                user_username=user.username if user.is_authenticated else 'Anonymous',
                user_role=getattr(user, 'role', ''),
                organization_name=user.organization.name if getattr(user, 'organization', None) else '',
                action=action_name,
                ip_address=ip,
                details=details,
            )
        except Exception:
            pass

    def get_queryset(self):
        user = self.request.user
        queryset = Patient.objects.all().order_by('-id')

        # Multi-Tenant & Role Scoping
        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.role == UserRole.FAMILY_MEMBER:
                # Caregivers only see patients they have active grant for
                granted_patient_ids = CaregiverAccess.objects.filter(
                    user=user, is_active=True
                ).values_list('patient_id', flat=True)
                queryset = queryset.filter(id__in=granted_patient_ids)
            elif user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
                # Field nurse scoping: If nurse is assigned to specific care teams, prioritize their patients
                if user.role == UserRole.NURSE:
                    assigned_team_ids = CareTeamMember.objects.filter(user=user).values_list('care_team_id', flat=True)
                    if assigned_team_ids:
                        # Allow filtering by my_team=true
                        if self.request.query_params.get('my_team') == 'true':
                            queryset = queryset.filter(care_plan__care_team_id__in=assigned_team_ids)
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
        
        # Privacy check for family members
        if request.user.role == UserRole.FAMILY_MEMBER:
            grant = CaregiverAccess.objects.filter(patient=instance, user=request.user, is_active=True).first()
            if not grant or not grant.has_permission(CaregiverPermission.VIEW_BASIC_INFO):
                return Response({'detail': 'You do not have permission to view this patient profile.'}, status=403)

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

            # Evaluate deterministic clinical rules
            try:
                from apps.alerts.services import ClinicalRulesEngine
                ClinicalRulesEngine.evaluate_vitals(vitals)
            except Exception:
                pass

            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    @action(detail=True, methods=['post'])
    def escalate_emergency(self, request, pk=None):
        patient = self.get_object()
        reason = request.data.get('reason', 'Emergency vital signs or clinical distress reported.')
        alert = PalliativeCareEngine.evaluate_palliative_emergency_escalation(
            patient_id=patient.id,
            alert_reason=reason,
            actor_user=request.user,
        )
        self._log_audit(request, patient, 'ESCALATE_EMERGENCY', f"Palliative Emergency Escalated: {reason}")
        return Response({'detail': 'Palliative emergency escalated to care team.', 'alert_id': alert.id}, status=200)

    @action(detail=True, methods=['get'])
    def audit_logs(self, request, pk=None):
        patient = self.get_object()
        logs = patient.audit_logs.all()[:50]
        serializer = PatientAuditLogSerializer(logs, many=True)
        return Response(serializer.data)


class CareTeamViewSet(viewsets.ModelViewSet):
    serializer_class = CareTeamSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.SUPER_ADMIN:
            return CareTeam.objects.all()
        if user.organization_id:
            return CareTeam.objects.filter(organization_id=user.organization_id)
        return CareTeam.objects.none()

    def perform_create(self, serializer):
        serializer.save(organization=self.request.user.organization)

    @action(detail=True, methods=['post'])
    def add_member(self, request, pk=None):
        care_team = self.get_object()
        user_id = request.data.get('user_id')
        member_name = request.data.get('member_name', '')
        role = request.data.get('role', CareTeamRole.NURSE)
        phone = request.data.get('phone', '')
        is_primary = request.data.get('is_primary', False)

        user_obj = User.objects.filter(id=user_id, organization=care_team.organization).first() if user_id else None
        if not member_name and user_obj:
            member_name = user_obj.get_full_name() or user_obj.username

        member, created = CareTeamMember.objects.update_or_create(
            care_team=care_team,
            user=user_obj,
            defaults={
                'member_name': member_name or 'Care Team Member',
                'role': role,
                'phone': phone,
                'is_primary': is_primary,
            }
        )
        return Response(CareTeamMemberSerializer(member).data, status=status.HTTP_201_CREATED)


class CarePlanViewSet(viewsets.ModelViewSet):
    serializer_class = CarePlanSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.SUPER_ADMIN:
            return CarePlan.objects.all()
        if user.role == UserRole.FAMILY_MEMBER:
            granted_ids = [
                g.patient_id for g in CaregiverAccess.objects.filter(user=user, is_active=True)
                if g.has_permission(CaregiverPermission.VIEW_CARE_PLAN)
            ]
            return CarePlan.objects.filter(patient_id__in=granted_ids)
        if user.organization_id:
            return CarePlan.objects.filter(patient__organization_id=user.organization_id)
        return CarePlan.objects.none()

    @action(detail=True, methods=['post'])
    def assign_care_team(self, request, pk=None):
        care_plan = self.get_object()
        care_team_id = request.data.get('care_team_id')
        care_team = CareTeam.objects.get(id=care_team_id, organization=care_plan.patient.organization)
        care_plan.care_team = care_team
        if care_team.lead_doctor:
            care_plan.assigned_doctor_name = care_team.lead_doctor.username
        if care_team.primary_nurse:
            care_plan.primary_nurse_name = care_team.primary_nurse.username
        care_plan.save()
        return Response(CarePlanSerializer(care_plan).data)


class CaregiverAccessViewSet(viewsets.ModelViewSet):
    serializer_class = CaregiverAccessSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.SUPER_ADMIN:
            return CaregiverAccess.objects.all()
        if user.role == UserRole.FAMILY_MEMBER:
            return CaregiverAccess.objects.filter(user=user, is_active=True)
        if user.organization_id:
            return CaregiverAccess.objects.filter(patient__organization_id=user.organization_id)
        return CaregiverAccess.objects.none()

    @action(detail=False, methods=['post'])
    def grant(self, request):
        patient_id = request.data.get('patient_id')
        caregiver_name = request.data.get('caregiver_name')
        caregiver_phone = request.data.get('caregiver_phone')
        permissions_list = request.data.get('permissions', ['VIEW_BASIC_INFO', 'VIEW_VISITS', 'VIEW_VITALS'])
        relationship = request.data.get('relationship', 'Family Member')
        caregiver_user_id = request.data.get('caregiver_user_id')

        caregiver_user = User.objects.filter(id=caregiver_user_id).first() if caregiver_user_id else None

        grant = PalliativeCareEngine.grant_caregiver_access(
            patient_id=int(patient_id),
            caregiver_name=caregiver_name,
            caregiver_phone=caregiver_phone,
            permissions=permissions_list,
            actor_user=request.user,
            relationship=relationship,
            caregiver_user=caregiver_user,
        )
        return Response(CaregiverAccessSerializer(grant).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        grant = self.get_object()
        grant.is_active = False
        grant.save()
        return Response({'detail': f'Caregiver access for {grant.caregiver_name} revoked.'})


class MedicationPlanViewSet(viewsets.ModelViewSet):
    serializer_class = MedicationPlanSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.SUPER_ADMIN:
            return MedicationPlan.objects.all()
        if user.role == UserRole.FAMILY_MEMBER:
            granted_ids = CaregiverAccess.objects.filter(user=user, is_active=True).values_list('patient_id', flat=True)
            return MedicationPlan.objects.filter(patient_id__in=granted_ids)
        if user.organization_id:
            return MedicationPlan.objects.filter(patient__organization_id=user.organization_id)
        return MedicationPlan.objects.none()

    @action(detail=True, methods=['post'])
    def log_dose(self, request, pk=None):
        plan = self.get_object()
        time_slot = request.data.get('time_slot', 'MORNING')
        dose_status = request.data.get('status', 'TAKEN')
        notes = request.data.get('notes', '')
        is_nurse = request.user.role in [UserRole.NURSE, UserRole.DOCTOR, UserRole.ORG_ADMIN]

        admin_log = PalliativeCareEngine.record_medication_intake(
            medication_plan_id=plan.id,
            time_slot=time_slot,
            status=dose_status,
            actor_user=request.user,
            is_nurse_verified=is_nurse,
            notes=notes,
        )
        return Response(MedicationAdministrationSerializer(admin_log).data, status=status.HTTP_201_CREATED)
