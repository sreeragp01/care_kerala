from rest_framework import serializers
from django.utils import timezone
from .models import (
    Specialty,
    Department,
    HealthcareService,
    Facility,
    HealthcareProfile,
    HealthcareProspect,
    OrganizationInvitation,
    OrganizationMembership,
    HospitalTeamInvitation,
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
        fields = ['id', 'name', 'category', 'description', 'icon_name', 'is_active']

class DepartmentSerializer(serializers.ModelSerializer):
    head_of_department_name = serializers.CharField(source='head_of_department.name', read_only=True)

    class Meta:
        model = Department
        fields = ['id', 'name', 'code', 'floor_location', 'phone_extension', 'head_of_department_name', 'is_active']

class HealthcareServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthcareService
        fields = ['id', 'name', 'category', 'description', 'is_emergency_service']

class FacilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Facility
        fields = ['id', 'name', 'category', 'icon_name']

class DoctorScheduleSerializer(serializers.ModelSerializer):
    day_name = serializers.CharField(source='get_day_of_week_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DoctorSchedule
        fields = [
            'id', 'day_of_week', 'day_name', 'start_time', 'end_time',
            'consultation_type', 'location_room', 'max_tokens',
            'appointment_required', 'status', 'status_display', 'last_verified_at'
        ]

    def validate(self, data):
        start = data.get('start_time')
        end = data.get('end_time')
        if start and end and start.strip() == end.strip():
            raise serializers.ValidationError({'end_time': 'End time cannot be identical to start time.'})
        return data

class DoctorAffiliationPublicSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    organization_district = serializers.CharField(source='organization.district', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    schedules = serializers.SerializerMethodField()
    consultation_mode_display = serializers.CharField(source='get_consultation_mode_display', read_only=True)

    class Meta:
        model = DoctorAffiliation
        fields = [
            'id', 'organization', 'organization_name', 'organization_district',
            'department_name', 'designation', 'consultation_mode', 'consultation_mode_display',
            'consultation_fee', 'schedules'
        ]

    def get_schedules(self, obj):
        # Expose only active schedules in public search
        active_schedules = obj.schedules.filter(status='ACTIVE')
        return DoctorScheduleSerializer(active_schedules, many=True).data

class DoctorPublicSerializer(serializers.ModelSerializer):
    """Public safe doctor profile for search directory"""
    primary_specialty_name = serializers.CharField(source='primary_specialty.name', read_only=True)
    primary_specialty_icon = serializers.CharField(source='primary_specialty.icon_name', read_only=True)
    affiliations = DoctorAffiliationPublicSerializer(many=True, read_only=True)

    class Meta:
        model = Doctor
        fields = [
            'id', 'name', 'profile_photo_url', 'qualification',
            'primary_specialty', 'primary_specialty_name', 'primary_specialty_icon',
            'sub_specialties', 'experience_years', 'languages',
            'registration_authority', 'registration_number', 'is_reg_verified',
            'biography', 'affiliations'
        ]

class HealthcareProfilePublicSerializer(serializers.ModelSerializer):
    """Public Search API Serializer (Zero leakage of internal documents or reviewer IDs)"""
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    organization_district = serializers.CharField(source='organization.district', read_only=True)
    organization_phone = serializers.CharField(source='organization.phone', read_only=True)
    organization_type_display = serializers.CharField(source='get_organization_type_display', read_only=True)
    ownership_type_display = serializers.CharField(source='get_ownership_type_display', read_only=True)
    verification_status_display = serializers.CharField(source='get_verification_status_display', read_only=True)
    data_freshness_tier = serializers.CharField(read_only=True)
    data_freshness_label = serializers.SerializerMethodField()

    specialties = SpecialtySerializer(many=True, read_only=True)
    services = HealthcareServiceSerializer(many=True, read_only=True)
    facilities = FacilitySerializer(many=True, read_only=True)
    departments = DepartmentSerializer(source='organization.departments', many=True, read_only=True)
    doctors = serializers.SerializerMethodField()

    class Meta:
        model = HealthcareProfile
        fields = [
            'id', 'organization', 'organization_name', 'organization_district',
            'organization_phone', 'organization_type', 'organization_type_display',
            'ownership_type', 'ownership_type_display', 'verification_status',
            'verification_status_display', 'is_carelink_verified', 'data_freshness_tier',
            'data_freshness_label', 'address', 'district', 'pincode', 'latitude', 'longitude',
            'emergency_phone', 'is_24x7_emergency', 'total_beds', 'icu_beds', 'ambulance_available',
            'description', 'established_year', 'profile_completeness_score', 'last_verified_at',
            'specialties', 'services', 'facilities', 'departments', 'doctors'
        ]

    def get_data_freshness_label(self, obj):
        tier = obj.data_freshness_tier
        if tier == 'CURRENT':
            return 'Verified & Active 🟢'
        elif tier == 'REVIEW_RECOMMENDED':
            return 'Periodic Review Recommended 🟡'
        elif tier == 'VERIFICATION_REQUIRED':
            return 'Re-Verification Required 🟠'
        return 'Unverified / Draft Profile 🔴'

    def get_doctors(self, obj):
        affiliations = DoctorAffiliation.objects.filter(
            organization=obj.organization, is_active=True, doctor__is_active=True
        ).select_related('doctor', 'doctor__primary_specialty').prefetch_related('schedules')
        
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
                    for s in aff.schedules.filter(status='ACTIVE')
                ]
            })
        return result

class HealthcareProfileAdminSerializer(serializers.ModelSerializer):
    """Admin-level serializer with internal audit fields, documents, and reviewer details"""
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    organization_district = serializers.CharField(source='organization.district', read_only=True)
    organization_phone = serializers.CharField(source='organization.phone', read_only=True)
    verified_by_username = serializers.CharField(source='verified_by.username', read_only=True)
    data_freshness_tier = serializers.CharField(read_only=True)

    class Meta:
        model = HealthcareProfile
        fields = '__all__'

    def validate_total_beds(self, value):
        if value < 0:
            raise serializers.ValidationError("Total beds cannot be negative.")
        return value

    def validate_icu_beds(self, value):
        if value < 0:
            raise serializers.ValidationError("ICU beds cannot be negative.")
        return value

    def validate_pincode(self, value):
        if value and (not value.isdigit() or len(value) != 6):
            raise serializers.ValidationError("Pincode must be a valid 6-digit numeric code.")
        return value

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
    status_display = serializers.CharField(source='get_status_display', read_only=True)

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

    def validate_patient_phone(self, value):
        cleaned = ''.join(filter(str.isdigit, value or ''))
        if len(cleaned) < 7:
            raise serializers.ValidationError("Please provide a valid contact phone number with at least 7 digits.")
        return value

    def validate_patient_age(self, value):
        if value is not None and (value < 0 or value > 125):
            raise serializers.ValidationError("Patient age must be between 0 and 125.")
        return value

class HealthcareProspectSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = HealthcareProspect
        fields = '__all__'

class OrganizationInvitationSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    invited_by_username = serializers.CharField(source='invited_by.username', read_only=True)

    class Meta:
        model = OrganizationInvitation
        fields = '__all__'

class OrganizationMembershipSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    approved_by_username = serializers.CharField(source='approved_by.username', read_only=True)

    class Meta:
        model = OrganizationMembership
        fields = '__all__'

class HospitalTeamInvitationSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    invited_by_username = serializers.CharField(source='invited_by.username', read_only=True)

    class Meta:
        model = HospitalTeamInvitation
        fields = '__all__'
