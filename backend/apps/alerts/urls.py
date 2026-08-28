from rest_framework.routers import DefaultRouter
from .views import ClinicalAlertViewSet, UserDeviceViewSet, NotificationPreferenceViewSet

router = DefaultRouter()
router.register(r'devices', UserDeviceViewSet, basename='user-device')
router.register(r'preferences', NotificationPreferenceViewSet, basename='notification-preference')
router.register(r'', ClinicalAlertViewSet, basename='clinical-alert')

urlpatterns = router.urls
