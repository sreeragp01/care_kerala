from rest_framework.routers import DefaultRouter
from .views import HomeVisitViewSet

router = DefaultRouter()
router.register(r'', HomeVisitViewSet, basename='visit')

urlpatterns = router.urls
