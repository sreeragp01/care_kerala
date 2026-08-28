from rest_framework.routers import DefaultRouter
from .views import BloodDonorViewSet, BloodRequestViewSet

router = DefaultRouter()
router.register(r'requests', BloodRequestViewSet, basename='blood-request')
router.register(r'', BloodDonorViewSet, basename='blood-donor')

urlpatterns = router.urls
