from rest_framework import serializers
from .models import HomeVisit, HomeVisitRequest, HomeVisitStatusHistory, CareTeamRoute, RouteStop
from apps.patients.serializers import VitalsReadingSerializer


class HomeVisitRequestSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.name', read_only=True)
    patient_phone = serializers.CharField(source='patient.phone', read_only=True)
    organization_name = serializers.CharField(source='organization.name', read_only=True)

    class Meta:
        model = HomeVisitRequest
        fields = '__all__'
        read_only_fields = ['organization', 'status', 'rejection_reason']


class HomeVisitStatusHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = HomeVisitStatusHistory
        fields = '__all__'


class HomeVisitSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.name', read_only=True)
    patient_phone = serializers.CharField(source='patient.phone', read_only=True)
    patient_address = serializers.CharField(source='patient.address', read_only=True)
    patient_tier = serializers.CharField(source='patient.category_tier', read_only=True)
    care_team_name = serializers.CharField(source='care_team.name', read_only=True)
    vitals_reading = VitalsReadingSerializer(read_only=True)
    status_history = HomeVisitStatusHistorySerializer(many=True, read_only=True)

    class Meta:
        model = HomeVisit
        fields = '__all__'
        read_only_fields = ['organization']


class RouteStopSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='visit.patient.name', read_only=True)
    patient_address = serializers.CharField(source='visit.patient.address', read_only=True)
    patient_phone = serializers.CharField(source='visit.patient.phone', read_only=True)
    visit_type = serializers.CharField(source='visit.visit_type', read_only=True)

    class Meta:
        model = RouteStop
        fields = [
            'id', 'route', 'visit', 'patient_name', 'patient_address',
            'patient_phone', 'visit_type', 'sequence_order', 'location_area',
            'estimated_arrival_time', 'is_completed'
        ]
        read_only_fields = ['route']


class CareTeamRouteSerializer(serializers.ModelSerializer):
    care_team_name = serializers.CharField(source='care_team.name', read_only=True)
    stops = RouteStopSerializer(many=True, read_only=True)

    class Meta:
        model = CareTeamRoute
        fields = [
            'id', 'organization', 'care_team', 'care_team_name', 'route_date',
            'primary_nurse_name', 'status', 'total_stops', 'notes', 'stops', 'created_at'
        ]
        read_only_fields = ['organization']
