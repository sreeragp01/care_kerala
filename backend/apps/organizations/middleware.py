import uuid
from .models import Organization

class RequestCorrelationMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = request.headers.get('X-Request-ID') or f"REQ-{uuid.uuid4().hex[:8].upper()}"
        request.request_id = request_id
        response = self.get_response(request)
        response['X-Request-ID'] = request_id
        return response

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tenant_id = request.headers.get('X-Tenant-ID')
        request.tenant = None
        if tenant_id:
            try:
                request.tenant = Organization.objects.get(id=tenant_id)
            except Organization.DoesNotExist:
                pass
        return self.get_response(request)

class SecurityHeadersMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        response['Cross-Origin-Opener-Policy'] = 'same-origin'
        return response


