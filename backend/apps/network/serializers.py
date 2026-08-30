from rest_framework import serializers
from .models import (
    Specialty,
    Department,
    HealthcareService,
    Facility,
    HealthcareProfile,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
    ChangeRequest,
    OrganizationDocument,
    ClaimOrganizationRequest,
    PatientInformationReport,
    AppointmentRequest,
)
from apps.organizations.models import Organization

class SpecialtySerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialty
        fields = '__all__'

class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = '__all__'

class HealthcareServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthcareService
        fields = '__all__'

class FacilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Facility
        fields = '__all__'

class DoctorScheduleSerializer(serializers.ModelSerializer):
    day_name = serializers.CharField(source='get_day_of_week_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DoctorSchedule
        fields = '__all__'

class DoctorAffiliationSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    organization_district = serializers.CharField(source='organization.district', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    schedules = DoctorScheduleSerializer(many=True, read_only=True)
    consultation_mode_display = serializers.CharField(source='get_consultation_mode_display', read_only=True)

    class Meta:
        model = DoctorAffiliation
        fields = '__all__'

class DoctorSerializer(serializers.ModelSerializer):
    primary_specialty_name = serializers.CharField(source='primary_specialty.name', read_only=True)
    primary_specialty_icon = serializers.CharField(source='primary_specialty.icon_name', read_only=True)
    affiliations = DoctorAffiliationSerializer(many=True, read_only=True)

    class Meta:
        model = Doctor
        fields = '__all__'

class HealthcareProfileSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    organization_district = serializers.CharField(source='organization.district', read_only=True)
    organization_phone = serializers.CharField(source='organization.phone', read_only=True)
    organization_reg_number = serializers.CharField(source='organization.registration_number', read_only=True)
    organization_type_display = serializers.CharField(source='get_organization_type_display', read_only=True)
    ownership_type_display = serializers.CharField(source='get_ownership_type_display', read_only=True)
    verification_status_display = serializers.CharField(source='get_verification_status_display', read_only=True)
    
    specialties = SpecialtySerializer(many=True, read_only=True)
    services = HealthcareServiceSerializer(many=True, read_only=True)
    facilities = FacilitySerializer(many=True, read_only=True)
    departments = DepartmentSerializer(source='organization.departments', many=True, read_only=True)
    doctors = serializers.SerializerMethodField()

    class Meta:
        model = HealthcareProfile
        fields = '__all__'

    def get_doctors(self, obj):
        affiliations = DoctorAffiliation.objects.filter(organization=obj.organization, is_active=True).select_related('doctor', 'doctor__primary_specialty')
        result = []
        for aff in affiliations:
            d = aff.doctor
            result.append({
                'id': d.id,
                'affiliation_id': aff.id,
                'name': d.name,
                'qualification': d.qualification,
                'specialty': d.primary_specialty.name,
                'designation': aff.designation,
                'consultation_mode': aff.get_consultation_mode_display(),
                'consultation_fee': str(aff.consultation_fee),
                'experience_years': d.experience_years,
                'languages': d.languages,
                'is_verified': aff.verification_status == 'VERIFIED',
                'schedules': [
                    {
                        'id': s.id,
                        'day': s.get_day_of_week_display(),
                        'time': f"{s.start_time} - {s.end_time}",
                        'room': s.location_room,
                        'status': s.status,
                    }
                    for s in aff.schedules.all()
                ]
            })
        return result

class ChangeRequestSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.CharField(source='requested_by.username', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.username', read_only=True)
    entity_type_display = serializers.CharField(source='get_entity_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = ChangeRequest
        fields = '__all__'

class OrganizationDocumentSerializer(serializers.ModelSerializer):
    document_type_display = serializers.CharField(source='get_document_type_display', read_only=True)
    verification_status_display = serializers.CharField(source='get_verification_status_display', read_only=True)

    class Meta:
        model = OrganizationDocument
        fields = '__all__'

class ClaimOrganizationRequestSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    claimant_username = serializers.CharField(source='claimant.username', read_only=True)

    class Meta:
        model = ClaimOrganizationRequest
        fields = '__all__'

class PatientInformationReportSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    doctor_name = serializers.CharField(source='doctor.name', read_only=True)
    report_type_display = serializers.CharField(source='get_report_type_display', read_only=True)

    class Meta:
        model = PatientInformationReport
        fields = '__all__'

class AppointmentRequestSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    doctor_name = serializers.CharField(source='doctor.name', read_only=True)
    doctor_specialty = serializers.CharField(source='doctor.primary_specialty.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = AppointmentRequest
        fields = '__all__'
