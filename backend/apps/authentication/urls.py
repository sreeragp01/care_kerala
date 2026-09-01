from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    CustomTokenObtainPairView,
    UserProfileView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    StaffRegistrationView,
    TestEmailView,
    SendPhoneOtpView,
    VerifyPhoneOtpView,
)

urlpatterns = [
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('password-reset/request/', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('phone-otp/send/', SendPhoneOtpView.as_view(), name='phone_otp_send'),
    path('phone-otp/verify/', VerifyPhoneOtpView.as_view(), name='phone_otp_verify'),
    path('staff-register/', StaffRegistrationView.as_view(), name='staff_register'),
    path('test-email/', TestEmailView.as_view(), name='test_email'),
]


