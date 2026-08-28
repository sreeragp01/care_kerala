from rest_framework import permissions
from .models import UserRole

class IsSuperAdmin(permissions.BasePermission):
    """Allows access only to Super Admins."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.SUPER_ADMIN)

class IsOrgAdmin(permissions.BasePermission):
    """Allows access to Super Admins and Organization Admins."""
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and 
            request.user.role in [UserRole.SUPER_ADMIN, UserRole.ORG_ADMIN]
        )

class IsClinicalStaff(permissions.BasePermission):
    """Allows access to Doctors, Nurses, and Admins."""
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and 
            request.user.role in [UserRole.SUPER_ADMIN, UserRole.ORG_ADMIN, UserRole.DOCTOR, UserRole.NURSE]
        )

class IsSameOrganizationTenant(permissions.BasePermission):
    """Ensures user only accesses records belonging to their assigned organization unless Super Admin."""
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.role == UserRole.SUPER_ADMIN:
            return True
        
        # Check if target object belongs to the user's organization
        obj_org = getattr(obj, 'organization', None)
        if obj_org is None and hasattr(obj, 'patient'):
            obj_org = getattr(obj.patient, 'organization', None)
            
        return bool(obj_org and obj_org.id == request.user.organization_id)
