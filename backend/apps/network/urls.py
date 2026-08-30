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
    DoctorAvailabilityView,
    ScheduleExceptionView,
    AppointmentLifecycleActionView,
    QueueSessionStartView,
    QueueTokenIssueView,
    QueueTokenCallNextView,
    QueueTokenConsultationActionView,
    PatientLiveQueueTrackerView,
    HospitalOperationsSummaryView,
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

    # Phase 2.4: Real-time Doctor Availability & OPD Schedule Exceptions
    path('doctors/availability/', DoctorAvailabilityView.as_view(), name='doctor_availability'),
    path('opd/exceptions/', ScheduleExceptionView.as_view(), name='opd_exceptions'),

    # Phase 2.4: Full Appointment Lifecycle Engine
    path('appointments/request/', AppointmentRequestCreateView.as_view(), name='appointment_request'),
    path('appointments/<int:pk>/status/', AppointmentStatusUpdateView.as_view(), name='appointment_status_update'),
    path('appointments/<int:pk>/action/<str:action>/', AppointmentLifecycleActionView.as_view(), name='appointment_lifecycle_action'),

    # Phase 2.4: Live OPD Queue & Token Caller Engine
    path('queue/sessions/start/', QueueSessionStartView.as_view(), name='queue_session_start'),
    path('queue/tokens/issue/', QueueTokenIssueView.as_view(), name='queue_token_issue'),
    path('queue/tokens/<int:pk>/call-next/', QueueTokenCallNextView.as_view(), name='queue_token_call_next'),
    path('queue/tokens/<int:pk>/consultation/<str:action>/', QueueTokenConsultationActionView.as_view(), name='queue_token_consultation'),
    path('queue/live/<int:pk>/', PatientLiveQueueTrackerView.as_view(), name='patient_live_queue'),

    # Phase 2.4: Hospital Operations Summary Dashboard
    path('operations/summary/', HospitalOperationsSummaryView.as_view(), name='operations_summary'),

    # Governance & Change Requests
    path('change-requests/', ChangeRequestListView.as_view(), name='change_requests_list'),
    path('change-requests/<int:pk>/review/', ChangeRequestReviewView.as_view(), name='change_request_review'),
    path('documents/<int:pk>/', OrganizationDocumentDetailView.as_view(), name='organization_document_detail'),
    path('report-inaccuracy/', PatientInformationReportView.as_view(), name='report_inaccuracy'),
    
    # Platform Administration
    path('admin/dashboard/', PlatformAdminDashboardView.as_view(), name='network_admin_dashboard'),
]

