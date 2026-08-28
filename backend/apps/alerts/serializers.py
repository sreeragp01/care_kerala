from rest_framework import serializers
from .models import ClinicalAlert, UserDevice, NotificationPreference

class ClinicalAlertSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.name', read_only=True, default='')

    class Meta:
        model = ClinicalAlert
        fields = '__all__'
        read_only_fields = ['organization', 'created_at', 'acknowledged_at', 'acknowledged_by']

class UserDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDevice
        fields = '__all__'
        read_only_fields = ['user', 'organization', 'created_at', 'last_seen_at']

class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = '__all__'
        read_only_fields = ['user']
