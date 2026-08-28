from django.contrib import admin
from django.urls import path, include

from apps.visits.sync_views import SyncPushView, SyncPullView

from apps.authentication.views import LivenessHealthView, ReadinessHealthView, SystemMetricsView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/live/', LivenessHealthView.as_view(), name='health-liveness'),
    path('health/ready/', ReadinessHealthView.as_view(), name='health-readiness'),
    path('api/health/metrics/', SystemMetricsView.as_view(), name='health-metrics'),
    path('api/orgs/', include('apps.organizations.urls')),
    path('api/auth/', include('apps.authentication.urls')),
    path('api/patients/', include('apps.patients.urls')),
    path('api/visits/', include('apps.visits.urls')),
    path('api/blood-donors/', include('apps.blood_donors.urls')),
    path('api/inventory/', include('apps.inventory.urls')),
    path('api/finance/', include('apps.finance.urls')),
    path('api/ai/', include('apps.ai_services.urls')),
    path('api/alerts/', include('apps.alerts.urls')),
    path('api/sync/push/', SyncPushView.as_view(), name='sync-push'),
    path('api/sync/pull/', SyncPullView.as_view(), name='sync-pull'),
]



