from rest_framework.routers import DefaultRouter
from .views import HomeVisitViewSet, HomeVisitRequestViewSet, CareTeamRouteViewSet

router = DefaultRouter()
router.register(r'requests', HomeVisitRequestViewSet, basename='visit-request')
router.register(r'routes', CareTeamRouteViewSet, basename='team-route')
router.register(r'', HomeVisitViewSet, basename='visit')

urlpatterns = router.urls
