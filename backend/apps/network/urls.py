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
    OrganizationDocumentDetailView,
    PatientInformationReportView,
    PlatformAdminDashboardView,
    ProspectListCreateView,
    PlatformOrganizationInviteAdminView,
    CareLinkReviewDecisionView,
    InvitationValidateView,
    InvitationActivateView,
    HospitalSetupWizardView,
    HospitalSubmitReviewView,
    HospitalTeamListView,
    HospitalTeamPendingApprovalListView,
    HospitalTeamInviteView,
    HospitalTeamApprovalDecisionView,
    HospitalTeamMemberRevokeView,
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
    
    # Platform Governance & Prospect Pipeline
    path('platform/prospects/', ProspectListCreateView.as_view(), name='platform_prospects'),
    path('platform/organizations/invite-admin/', PlatformOrganizationInviteAdminView.as_view(), name='platform_invite_admin'),
    path('admin/organizations/<int:pk>/review-decision/', CareLinkReviewDecisionView.as_view(), name='carelink_review_decision'),
    
    # Invitation & Account Activation
    path('invitations/<str:token>/validate/', InvitationValidateView.as_view(), name='invitation_validate'),
    path('invitations/<str:token>/activate/', InvitationActivateView.as_view(), name='invitation_activate'),
    
    # 10-Step Hospital Setup Wizard
    path('onboarding/wizard/', HospitalSetupWizardView.as_view(), name='hospital_setup_wizard'),
    path('onboarding/submit/', HospitalSubmitReviewView.as_view(), name='hospital_submit_review'),
    
    # Hospital Team Governance & Approvals
    path('team/', HospitalTeamListView.as_view(), name='hospital_team_list'),
    path('team/pending/', HospitalTeamPendingApprovalListView.as_view(), name='hospital_team_pending'),
    path('team/invite/', HospitalTeamInviteView.as_view(), name='hospital_team_invite'),
    path('team/<int:pk>/decision/', HospitalTeamApprovalDecisionView.as_view(), name='hospital_team_decision'),
    path('team/<int:pk>/revoke/', HospitalTeamMemberRevokeView.as_view(), name='hospital_team_revoke'),

    # Governance & Change Requests
    path('change-requests/', ChangeRequestListView.as_view(), name='change_requests_list'),
    path('change-requests/<int:pk>/review/', ChangeRequestReviewView.as_view(), name='change_request_review'),
    
    # Consultation & Appointments
    path('appointments/request/', AppointmentRequestCreateView.as_view(), name='appointment_request'),
    path('appointments/<int:pk>/status/', AppointmentStatusUpdateView.as_view(), name='appointment_status_update'),
    path('documents/<int:pk>/', OrganizationDocumentDetailView.as_view(), name='organization_document_detail'),
    path('report-inaccuracy/', PatientInformationReportView.as_view(), name='report_inaccuracy'),
    
    # Platform Administration
    path('admin/dashboard/', PlatformAdminDashboardView.as_view(), name='network_admin_dashboard'),
]

