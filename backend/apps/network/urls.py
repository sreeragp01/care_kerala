from django.urls import path
from .views import (
    PublicDirectoryListView,
    HospitalDetailView,
    DoctorDirectoryListView,
    JoinCareLinkView,
    ClaimOrganizationView,
    ClaimOrganizationReviewView,
    ChangeRequestListView,
    ChangeRequestReviewView,
    AppointmentRequestCreateView,
    AppointmentStatusUpdateView,
    PatientInformationReportView,
    PlatformAdminDashboardView,
)

urlpatterns = [
    # Public Directory & Discovery
    path('directory/', PublicDirectoryListView.as_view(), name='network_directory'),
    path('hospitals/<int:pk>/', HospitalDetailView.as_view(), name='hospital_detail'),
    path('doctors/', DoctorDirectoryListView.as_view(), name='doctor_directory'),
    
    # Organization Onboarding & Claims
    path('organizations/register/', JoinCareLinkView.as_view(), name='join_carelink'),
    path('organizations/claim/', ClaimOrganizationView.as_view(), name='claim_organization'),
    path('organizations/claims/<int:pk>/review/', ClaimOrganizationReviewView.as_view(), name='claim_organization_review'),
    
    # Governance & Change Requests
    path('change-requests/', ChangeRequestListView.as_view(), name='change_requests_list'),
    path('change-requests/<int:pk>/review/', ChangeRequestReviewView.as_view(), name='change_request_review'),
    
    # Consultation & Appointments
    path('appointments/request/', AppointmentRequestCreateView.as_view(), name='appointment_request'),
    path('appointments/<int:pk>/status/', AppointmentStatusUpdateView.as_view(), name='appointment_status_update'),
    path('report-inaccuracy/', PatientInformationReportView.as_view(), name='report_inaccuracy'),
    
    # Platform Administration
    path('admin/dashboard/', PlatformAdminDashboardView.as_view(), name='network_admin_dashboard'),
]
