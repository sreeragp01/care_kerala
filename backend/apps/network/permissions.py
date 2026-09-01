from rest_framework import permissions

class IsPlatformAdminOrSuperAdmin(permissions.BasePermission):
    """Allows access only to Platform Administrators or Super Admins."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return (
            request.user.is_superuser or
            getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'PLATFORM_ADMIN', 'SUPER_ADMIN')
        )

class IsOrganizationAdminOrOwner(permissions.BasePermission):
    """Allows access only to Organization Admins, Owners, or Platform Super Admins."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return (
            request.user.is_superuser or
            getattr(request.user, 'role', '') in (
                'superAdmin', 'platformAdmin', 'orgAdmin', 'organizationOwner', 'hospitalAdmin', 'admin',
                'SUPER_ADMIN', 'PLATFORM_ADMIN', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN'
            )
        )

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        # Check organization boundary
        target_org = getattr(obj, 'organization', obj)
        user_org = getattr(request.user, 'organization', None)
        return user_org and target_org and user_org.id == target_org.id

class IsOrganizationModeratorOrAdmin(permissions.BasePermission):
    """Allows access to Org Admins, Org Owners, and Moderators of that specific organization."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return (
            request.user.is_superuser or
            getattr(request.user, 'role', '') in (
                'superAdmin', 'platformAdmin', 'orgAdmin', 'organizationOwner', 'moderator', 'hospitalAdmin',
                'SUPER_ADMIN', 'PLATFORM_ADMIN', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'MODERATOR', 'HOSPITAL_ADMIN'
            )
        )

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        target_org = getattr(obj, 'organization', obj)
        user_org = getattr(request.user, 'organization', None)
        return user_org and target_org and user_org.id == target_org.id

class IsHospitalTeamAdmin(permissions.BasePermission):
    """Allows access only to the Hospital Admin / Owner of that specific hospital or Platform Super Admin."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        # Check user role or active admin membership
        user_role = getattr(request.user, 'role', '')
        if user_role in ('orgAdmin', 'organizationOwner', 'hospitalAdmin', 'admin', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN'):
            return True

        return request.user.organization_memberships.filter(
            role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN'],
            status='ACTIVE'
        ).exists()

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        target_org = getattr(obj, 'organization', obj)
        user_org = getattr(request.user, 'organization', None)

        if user_org and target_org and user_org.id == target_org.id:
            return True

        return request.user.organization_memberships.filter(
            organization=target_org,
            role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN'],
            status='ACTIVE'
        ).exists()

class IsDocumentAuthorizedTenant(permissions.BasePermission):
    """Strict object-level permission for accessing institutional compliance & verification documents."""

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        target_org = getattr(obj, 'organization', None)
        user_org = getattr(request.user, 'organization', None)
        user_role = getattr(request.user, 'role', '')

        if not target_org or not user_org or user_org.id != target_org.id:
            return False

        # Only Org Admin or Org Owner can view sensitive documents
        return user_role in ('orgAdmin', 'organizationOwner', 'hospitalAdmin', 'admin', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN')

class CanManageOPDAndQueue(permissions.BasePermission):
    """Allows Org Admins, Receptionists, Doctors, and Moderators to manage daily OPD and patient queues."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        user_role = getattr(request.user, 'role', '')
        if user_role in ('orgAdmin', 'organizationOwner', 'hospitalAdmin', 'admin', 'doctor', 'receptionist', 'nurse', 'staff', 'moderator',
                         'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN', 'DOCTOR', 'RECEPTION', 'NURSE', 'STAFF', 'MODERATOR'):
            return True

        return request.user.organization_memberships.filter(
            status='ACTIVE'
        ).exists()

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        target_org = getattr(obj, 'organization', None)
        if not target_org and hasattr(obj, 'queue_session'):
            target_org = obj.queue_session.organization

        user_org = getattr(request.user, 'organization', None)
        if user_org and target_org and user_org.id == target_org.id:
            return True

        if target_org:
            return request.user.organization_memberships.filter(
                organization=target_org,
                status='ACTIVE'
            ).exists()
        return False

class IsAssignedDoctorOrHospitalAdmin(permissions.BasePermission):
    """Allows Hospital Admin to access all appointments, and Doctors to access only their assigned appointments."""

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        target_org = getattr(obj, 'organization', None)
        user_org = getattr(request.user, 'organization', None)
        user_role = getattr(request.user, 'role', '')

        # Hospital Admin / Owner gets full access within organization
        if (user_role in ('orgAdmin', 'organizationOwner', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER') or
            request.user.organization_memberships.filter(organization=target_org, role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'], status='ACTIVE').exists()):
            return user_org and target_org and user_org.id == target_org.id

        # Reception / Staff can manage check-in and queue
        if user_role in ('receptionist', 'nurse', 'staff', 'RECEPTION', 'NURSE', 'STAFF'):
            return user_org and target_org and user_org.id == target_org.id

        # Doctor check
        doctor = getattr(obj, 'doctor', None)
        if hasattr(request.user, 'doctor_profile') and doctor:
            return request.user.doctor_profile.id == doctor.id

        return False

class IsQueueAuthorizedDoctorOrAdmin(permissions.BasePermission):
    """Guarantees strict isolation:

    1. Platform Admins have full access.
    2. Hospital Admins & Staff can only manage queue sessions of their own hospital.
    3. Doctors can only operate (call, recall, pause, skip) their own assigned queue sessions.
    """

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or getattr(request.user, 'role', '') in ('superAdmin', 'platformAdmin', 'SUPER_ADMIN', 'PLATFORM_ADMIN'):
            return True

        # Extract target organization and doctor
        target_org = getattr(obj, 'organization', None)
        target_doctor = getattr(obj, 'doctor', None)

        if not target_org and hasattr(obj, 'queue_session'):
            target_org = obj.queue_session.organization
            target_doctor = obj.queue_session.doctor

        user_org = getattr(request.user, 'organization', None)
        user_role = getattr(request.user, 'role', '')

        # Cross-tenant check: if user belongs to an org, it MUST match target_org
        if user_org and target_org and user_org.id != target_org.id:
            return False

        # Hospital Admin / Owner full access within their org
        if user_role in ('orgAdmin', 'organizationOwner', 'hospitalAdmin', 'admin', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'HOSPITAL_ADMIN', 'ADMIN', 'ORG_ADMIN'):
            return user_org and target_org and user_org.id == target_org.id

        # Reception / Staff access within their org
        if user_role in ('receptionist', 'nurse', 'staff', 'RECEPTION', 'NURSE', 'STAFF'):
            return user_org and target_org and user_org.id == target_org.id

        # Doctor check: must be the doctor assigned to this queue session or doctor in same org
        if user_role in ('doctor', 'DOCTOR'):
            if hasattr(request.user, 'doctor_profile') and target_doctor:
                return request.user.doctor_profile.id == target_doctor.id
            return user_org and target_org and user_org.id == target_org.id

        return False


