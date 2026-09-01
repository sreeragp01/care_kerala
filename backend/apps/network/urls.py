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
    DoctorAvailableSlotsView,
    AppointmentRescheduleView,
    AppointmentCancelView,
    AppointmentHistoryTimelineView,
    PatientAppointmentsListView,
    HospitalAppointmentDeskView,
    DoctorLeaveImpactResolutionView,
    MultiQueueSessionListView,
    QueueSessionDetailStatusView,
    QueueEstimatedWaitView,
    QueuePublicDisplayView,
    QueueSessionCallNextView,
    QueueTokenRecallView,
    QueueTokenSkipView,
    QueueSessionPauseView,
    QueueSessionResumeView,
    QueueTokenUnifiedIssueView,
    DigitalCheckInView,
    GenerateAppointmentQRView,
    HospitalPatientFlowAnalyticsView,
)

urlpatterns = [
    # Public Directory & Discovery
    path('directory/', PublicDirectoryListView.as_view(), name='network_directory'),
    path('hospitals/<int:pk>/', HospitalDetailView.as_view(), name='hospital_detail'),
    path('doctors/', DoctorDirectoryListView.as_view(), name='doctor_directory'),
    path('doctors/<int:pk>/available-slots/', DoctorAvailableSlotsView.as_view(), name='doctor_available_slots'),
    
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

    # Real-time Doctor Availability & OPD Schedule Exceptions
    path('doctors/availability/', DoctorAvailabilityView.as_view(), name='doctor_availability'),
    path('opd/exceptions/', ScheduleExceptionView.as_view(), name='opd_exceptions'),
    path('opd/exceptions/resolve-impact/', DoctorLeaveImpactResolutionView.as_view(), name='doctor_leave_impact_resolve'),

    # Complete Appointment Lifecycle & Patient Center Endpoints
    path('appointments/request/', AppointmentRequestCreateView.as_view(), name='appointment_request'),
    path('appointments/patient/', PatientAppointmentsListView.as_view(), name='patient_appointments_list'),
    path('appointments/desk/', HospitalAppointmentDeskView.as_view(), name='hospital_appointment_desk'),
    path('appointments/<int:pk>/status/', AppointmentStatusUpdateView.as_view(), name='appointment_status_update'),
    path('appointments/<int:pk>/reschedule/', AppointmentRescheduleView.as_view(), name='appointment_reschedule'),
    path('appointments/<int:pk>/cancel/', AppointmentCancelView.as_view(), name='appointment_cancel'),
    path('appointments/<int:pk>/history/', AppointmentHistoryTimelineView.as_view(), name='appointment_history_timeline'),
    path('appointments/<int:pk>/action/<str:action>/', AppointmentLifecycleActionView.as_view(), name='appointment_lifecycle_action'),

    # Live OPD & Multi-Queue Engine (Phase 2.6)
    path('queues/', MultiQueueSessionListView.as_view(), name='multi_queue_list'),
    path('queues/<int:pk>/status/', QueueSessionDetailStatusView.as_view(), name='queue_detail_status'),
    path('queues/<int:pk>/estimated-wait/', QueueEstimatedWaitView.as_view(), name='queue_estimated_wait'),
    path('queues/<int:pk>/display/', QueuePublicDisplayView.as_view(), name='queue_public_display'),
    path('queues/<int:pk>/call-next/', QueueSessionCallNextView.as_view(), name='queue_call_next'),
    path('queues/<int:pk>/pause/', QueueSessionPauseView.as_view(), name='queue_session_pause'),
    path('queues/<int:pk>/resume/', QueueSessionResumeView.as_view(), name='queue_session_resume'),
    path('queues/tokens/issue/', QueueTokenUnifiedIssueView.as_view(), name='queue_token_unified_issue'),
    path('queues/tokens/<int:pk>/recall/', QueueTokenRecallView.as_view(), name='queue_token_recall'),
    path('queues/tokens/<int:pk>/skip/', QueueTokenSkipView.as_view(), name='queue_token_skip'),
    path('queue/sessions/start/', QueueSessionStartView.as_view(), name='queue_session_start'),
    path('queue/tokens/issue/', QueueTokenIssueView.as_view(), name='queue_token_issue'),
    path('queue/tokens/<int:pk>/call-next/', QueueTokenCallNextView.as_view(), name='queue_token_call_next'),
    path('queue/tokens/<int:pk>/consultation/<str:action>/', QueueTokenConsultationActionView.as_view(), name='queue_token_consultation'),
    path('queue/live/<int:pk>/', PatientLiveQueueTrackerView.as_view(), name='patient_live_queue'),

    # Digital Check-in & QR Endpoints (Phase 2.6)
    path('check-in/digital/', DigitalCheckInView.as_view(), name='digital_check_in'),
    path('check-in/qr/generate/', GenerateAppointmentQRView.as_view(), name='generate_appointment_qr'),

    # Hospital Operations & Patient Flow Analytics
    path('operations/summary/', HospitalOperationsSummaryView.as_view(), name='operations_summary'),
    path('analytics/hospital-flow/', HospitalPatientFlowAnalyticsView.as_view(), name='hospital_flow_analytics'),

    # Governance & Change Requests
    path('change-requests/', ChangeRequestListView.as_view(), name='change_requests_list'),
    path('change-requests/<int:pk>/review/', ChangeRequestReviewView.as_view(), name='change_request_review'),
    path('documents/<int:pk>/', OrganizationDocumentDetailView.as_view(), name='organization_document_detail'),
    path('report-inaccuracy/', PatientInformationReportView.as_view(), name='report_inaccuracy'),
    
    # Platform Administration
    path('admin/dashboard/', PlatformAdminDashboardView.as_view(), name='network_admin_dashboard'),
]

