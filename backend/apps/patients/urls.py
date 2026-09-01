from rest_framework.routers import DefaultRouter
from .views import (
    PatientViewSet, CareTeamViewSet, CarePlanViewSet,
    CaregiverAccessViewSet, MedicationPlanViewSet
)

router = DefaultRouter()
router.register(r'care-teams', CareTeamViewSet, basename='care-team')
router.register(r'care-plans', CarePlanViewSet, basename='care-plan')
router.register(r'caregivers', CaregiverAccessViewSet, basename='caregiver-access')
router.register(r'medications', MedicationPlanViewSet, basename='medication-plan')
router.register(r'', PatientViewSet, basename='patient')

urlpatterns = router.urls
