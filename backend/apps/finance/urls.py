from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import (
    DonationViewSet,
    MedicalFundraiserViewSet,
    CreateRazorpayOrderView,
    VerifyRazorpayPaymentView,
)

router = DefaultRouter()
router.register(r'fundraisers', MedicalFundraiserViewSet, basename='fundraiser')
router.register(r'donations', DonationViewSet, basename='donation')
router.register(r'', DonationViewSet, basename='donation-root')

urlpatterns = [
    path('razorpay/create-order/', CreateRazorpayOrderView.as_view(), name='razorpay-create-order'),
    path('razorpay/verify-payment/', VerifyRazorpayPaymentView.as_view(), name='razorpay-verify-payment'),
] + router.urls

