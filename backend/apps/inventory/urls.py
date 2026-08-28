from rest_framework.routers import DefaultRouter
from .views import MedicineViewSet, EquipmentViewSet

router = DefaultRouter()
router.register(r'medicines', MedicineViewSet, basename='medicine')
router.register(r'equipment', EquipmentViewSet, basename='equipment')

urlpatterns = router.urls
