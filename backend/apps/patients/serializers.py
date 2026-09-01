from rest_framework import serializers
from .models import (
    Patient, VitalsReading, EquipmentIssued, FamilyMemberContact,
    PatientAuditLog, CarePlan, CareTeam, CareTeamMember, PatientCareGoal,
    CaregiverAccess, MedicationPlan, MedicationAdministration
)


class CareTeamMemberSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = CareTeamMember
        fields = ['id', 'care_team', 'user', 'username', 'member_name', 'role', 'phone', 'is_primary', 'created_at']
        read_only_fields = ['care_team']


class CareTeamSerializer(serializers.ModelSerializer):
    members = CareTeamMemberSerializer(many=True, read_only=True)
    lead_doctor_name = serializers.CharField(source='lead_doctor.username', read_only=True)
    primary_nurse_name = serializers.CharField(source='primary_nurse.username', read_only=True)
    organization_name = serializers.CharField(source='organization.name', read_only=True)

    class Meta:
        model = CareTeam
        fields = [
            'id', 'organization', 'organization_name', 'name', 'lead_doctor', 'lead_doctor_name',
            'primary_nurse', 'primary_nurse_name', 'area_coverage', 'is_active', 'members', 'created_at'
        ]
        read_only_fields = ['organization']


class PatientCareGoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientCareGoal
        fields = ['id', 'patient', 'category', 'description', 'target_date', 'is_achieved', 'achieved_at', 'notes', 'created_at']
        read_only_fields = ['patient']


class CaregiverAccessSerializer(serializers.ModelSerializer):
    class Meta:
        model = CaregiverAccess
        fields = [
            'id', 'patient', 'user', 'caregiver_name', 'caregiver_phone',
            'relationship', 'permissions', 'is_active', 'granted_by', 'granted_at'
        ]
        read_only_fields = ['patient', 'granted_by']


class MedicationAdministrationSerializer(serializers.ModelSerializer):
    medicine_name = serializers.CharField(source='medication_plan.medicine_name', read_only=True)
    dosage = serializers.CharField(source='medication_plan.dosage', read_only=True)

    class Meta:
        model = MedicationAdministration
        fields = [
            'id', 'medication_plan', 'medicine_name', 'dosage', 'patient',
            'scheduled_date', 'time_slot', 'status', 'recorded_by_caregiver',
            'verified_by_nurse', 'verified_nurse_name', 'administered_at', 'notes'
        ]
        read_only_fields = ['patient']


class MedicationPlanSerializer(serializers.ModelSerializer):
    administrations = MedicationAdministrationSerializer(many=True, read_only=True)

    class Meta:
        model = MedicationPlan
        fields = [
            'id', 'patient', 'medicine_name', 'dosage', 'route', 'frequency',
            'time_slots', 'prescribed_by_doctor', 'start_date', 'end_date',
            'instructions', 'is_active', 'administrations', 'created_at'
        ]
        read_only_fields = ['patient']


class CarePlanSerializer(serializers.ModelSerializer):
    care_team_details = CareTeamSerializer(source='care_team', read_only=True)

    class Meta:
        model = CarePlan
        fields = [
            'id', 'patient', 'care_team', 'care_team_details', 'primary_nurse_name',
            'assigned_doctor_name', 'care_goals', 'pain_assessment_protocol',
            'mobility_status', 'dietary_instructions', 'psychological_support_notes',
            'visit_frequency', 'emergency_escalation_notes', 'dnr_or_advanced_directives',
            'review_frequency_days', 'last_reviewed_date', 'created_at'
        ]
        read_only_fields = ['patient']


class VitalsReadingSerializer(serializers.ModelSerializer):
    class Meta:
        model = VitalsReading
        fields = '__all__'
        read_only_fields = ['patient', 'recorded_by']

    def validate_spo2(self, value):
        if value < 0 or value > 100:
            raise serializers.ValidationError("SpO2 must be between 0 and 100%")
        return value

    def validate_pain_scale(self, value):
        if value < 0 or value > 10:
            raise serializers.ValidationError("Pain scale must be between 0 and 10")
        return value


class EquipmentIssuedSerializer(serializers.ModelSerializer):
    class Meta:
        model = EquipmentIssued
        fields = '__all__'


class FamilyMemberContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = FamilyMemberContact
        fields = '__all__'


class PatientSerializer(serializers.ModelSerializer):
    care_plan = CarePlanSerializer(read_only=True)
    care_goals = PatientCareGoalSerializer(many=True, read_only=True)
    vitals_history = VitalsReadingSerializer(many=True, read_only=True)
    medication_plans = MedicationPlanSerializer(many=True, read_only=True)
    caregiver_grants = CaregiverAccessSerializer(many=True, read_only=True)
    equipment_issued = EquipmentIssuedSerializer(many=True, read_only=True)
    family_members = FamilyMemberContactSerializer(many=True, read_only=True)

    class Meta:
        model = Patient
        fields = '__all__'
        read_only_fields = ['organization']


class PatientAuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientAuditLog
        fields = '__all__'
