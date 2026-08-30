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
                'superAdmin', 'platformAdmin', 'orgAdmin', 'organizationOwner',
                'SUPER_ADMIN', 'PLATFORM_ADMIN', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'
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
                'superAdmin', 'platformAdmin', 'orgAdmin', 'organizationOwner', 'moderator',
                'SUPER_ADMIN', 'PLATFORM_ADMIN', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER', 'MODERATOR'
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
        if user_role in ('orgAdmin', 'organizationOwner', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'):
            return True

        return request.user.organization_memberships.filter(
            role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'],
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
            role__in=['ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER'],
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
        return user_role in ('orgAdmin', 'organizationOwner', 'ORGANIZATION_ADMIN', 'ORGANIZATION_OWNER')
