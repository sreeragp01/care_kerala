from rest_framework import serializers
from .models import Patient, VitalsReading, EquipmentIssued, FamilyMemberContact, PatientAuditLog, CarePlan

class CarePlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarePlan
        fields = '__all__'

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
    vitals_history = VitalsReadingSerializer(many=True, read_only=True)
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


