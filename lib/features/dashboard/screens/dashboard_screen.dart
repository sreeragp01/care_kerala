import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../patients/screens/patient_list_screen.dart';
import '../../home_visits/screens/visit_schedule_screen.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../volunteers/screens/volunteer_management_screen.dart';
import '../../blood_donors/screens/blood_donor_directory_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../ambulance/screens/ambulance_dispatch_screen.dart';
import '../../donations/screens/donations_screen.dart';
import '../../fundraising/screens/medical_fundraising_screen.dart';
import '../../maps/screens/field_map_screen.dart';
import '../../emergency_sos/screens/emergency_sos_screen.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../../reports/analytics_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/stats_card.dart';
import '../../../core/widgets/sync_status_bar.dart';
import '../../alerts/screens/alert_center_screen.dart';
import '../../admin/screens/admin_control_center_screen.dart';
import '../../doctor/screens/doctor_workspace_screen.dart';
import '../../nurse/screens/nurse_operations_screen.dart';
import '../../coordinator/screens/coordinator_workspace_screen.dart';
import '../widgets/patient_portal_view.dart';

class DashboardScreen extends StatefulWidget {
  final AppStateProvider state;

  const DashboardScreen({super.key, required this.state});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final loc = AppLocalizations.of(context);
        final user = widget.state.currentUser;
        final org = widget.state.activeOrganization;
        final isMalayalam = widget.state.locale.languageCode == 'ml';
        final isPatient = user.role.isPatientOrFamily;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPatient
                      ? (isMalayalam ? 'കെയർലിങ്ക് കേരളം — രോഗി പോർട്ടൽ' : 'CareLink Kerala — Patient Portal')
                      : (org?.name ?? loc.translate('app_title')),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isPatient
                      ? (isMalayalam ? 'രോഗി: ${user.name} • ${AppLocalizations.getDistrictName(user.district, isMalayalam: true)}' : 'Patient: ${user.name} • ${user.district}')
                      : (isMalayalam ? 'പങ്ക്: ${user.role.displayName} • ${AppLocalizations.getDistrictName(user.district, isMalayalam: true)}' : 'Role: ${user.role.displayName} • ${user.district}'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              // Emergency Rapid SOS Shortcut
              IconButton(
                tooltip: 'Emergency SOS & Ambulance Help',
                icon: const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmergencySosScreen(state: widget.state),
                    ),
                  );
                },
              ),

              // Offline Sync Indicator Badge (only for staff who record offline clinical notes)
              if (!isPatient && widget.state.pendingOfflineSyncCount > 0)
                IconButton(
                  tooltip: '${widget.state.pendingOfflineSyncCount} Offline Drafts Cached',
                  icon: Badge(
                    label: Text('${widget.state.pendingOfflineSyncCount}'),
                    backgroundColor: AppColors.warning,
                    child: const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 22),
                  ),
                  onPressed: () => widget.state.syncOfflineQueue(),
                ),

              // Quick Demo Persona Switcher
              IconButton(
                tooltip: 'Switch Demo Role Persona',
                icon: const Icon(Icons.switch_account_rounded, size: 22, color: AppColors.accentGold),
                onPressed: () => _showPersonaSwitchBottomSheet(context),
              ),

              // Theme Mode Toggle (Light / Dark)
              IconButton(
                tooltip: widget.state.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                icon: Icon(
                  widget.state.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: widget.state.isDarkMode ? AppColors.accentGold : AppColors.primaryGreen,
                  size: 22,
                ),
                onPressed: () => widget.state.toggleDarkMode(),
              ),

              // Language Toggle
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  widget.state.setLocale(
                    isMalayalam ? const Locale('en') : const Locale('ml'),
                  );
                },
                child: Text(
                  isMalayalam ? 'EN' : 'മലയാളം',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                  ),
                ),
              ),

              // Notifications Menu
              IconButton(
                icon: Badge(
                  label: Text('${widget.state.notifications.length}'),
                  child: const Icon(Icons.notifications_outlined, size: 22),
                ),
                onPressed: () => _showNotificationsBottomSheet(context),
              ),
            ],
          ),
          drawer: _buildDrawer(context, loc, isPatient),
          body: isPatient
              ? PatientPortalView(state: widget.state)
              : _buildDashboardContent(context, loc),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiAssistantScreen(state: widget.state),
                ),
              );
            },
            backgroundColor: AppColors.primaryGreen,
            icon: const Icon(Icons.psychology_rounded, color: Colors.white),
            label: Text(
              loc.translate('ai_assistant'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          bottomNavigationBar: (!isPatient && MediaQuery.of(context).size.width < 800)
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _navigateToTab(index);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded, color: AppColors.primaryGreen),
                      label: loc.translate('dashboard'),
                    ),
                    if (user.role.canAccessClinicalRecords)
                      NavigationDestination(
                        icon: const Icon(Icons.people_outline),
                        selectedIcon: const Icon(Icons.people_rounded, color: AppColors.primaryGreen),
                        label: loc.translate('patients'),
                      ),
                    if (user.role == UserRole.nurse || user.role == UserRole.volunteer || user.role.isAdmin)
                      NavigationDestination(
                        icon: const Icon(Icons.home_work_outlined),
                        selectedIcon: const Icon(Icons.home_work_rounded, color: AppColors.primaryGreen),
                        label: loc.translate('home_visits'),
                      ),
                    NavigationDestination(
                      icon: const Icon(Icons.opacity_outlined),
                      selectedIcon: const Icon(Icons.opacity_rounded, color: AppColors.primaryGreen),
                      label: loc.translate('blood_donors'),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, AppLocalizations loc) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase 6: Persistent Offline & Sync Status Bar
          SyncStatusBar(state: widget.state),
          const SizedBox(height: 14),

          // Role-Based Workspace Hub Quick Launch Card
          _buildRoleWorkspaceCard(context, isDark),
          const SizedBox(height: 16),

          // Schedule Banner for Nurse/Volunteer
          if (widget.state.currentUser.role == UserRole.nurse || widget.state.currentUser.role == UserRole.volunteer)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkPrimaryGreen.withValues(alpha: 0.5) : AppColors.secondaryGreen),
              ),

              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_walk_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 24),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Today's Field Schedule Active",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.state.todaysVisitsCount} Patients scheduled for home visit in ${widget.state.currentUser.district}.',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => VisitScheduleScreen(state: widget.state)));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Start Schedule', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Icon(Icons.directions_walk_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Field Schedule Active",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.state.todaysVisitsCount} Patients scheduled for home visit in ${widget.state.currentUser.district}.',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => VisitScheduleScreen(state: widget.state)));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Start Schedule', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  );
                },
              ),
            ),

          // KPI Stats Cards Grid
          GridView.count(
            crossAxisCount: screenWidth > 900
                ? 4
                : (screenWidth > 600 ? 3 : 2),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: screenWidth > 900
                ? 1.45
                : (screenWidth > 600 ? 1.35 : 1.28),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatsCard(
                title: loc.translate('todays_visits'),
                value: '${widget.state.todaysVisitsCount}',
                icon: Icons.calendar_today_rounded,
                color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitScheduleScreen(state: widget.state))),
              ),
              StatsCard(
                title: loc.translate('active_patients'),
                value: '${widget.state.activePatientsCount}',
                icon: Icons.personal_injury_rounded,
                color: AppColors.info,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state))),
              ),
              StatsCard(
                title: loc.translate('critical_alerts'),
                value: '${widget.state.criticalPatientsCount}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state, initialFilterTier: 'High Risk'))),
              ),
              StatsCard(
                title: loc.translate('low_stock'),
                value: '${widget.state.lowStockMedicinesCount}',
                icon: Icons.medication_liquid_rounded,
                color: AppColors.warning,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(state: widget.state))),
              ),
              StatsCard(
                title: loc.translate('emergency_blood'),
                value: '${widget.state.activeBloodRequestsCount}',
                icon: Icons.bloodtype_rounded,
                color: AppColors.danger,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: widget.state))),
              ),
              StatsCard(
                title: loc.translate('fund_total'),
                value: '₹${widget.state.totalDonationsFund.toInt()}',
                icon: Icons.volunteer_activism_rounded,
                color: AppColors.accentGold,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonationsScreen(state: widget.state))),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Module Actions Grid
          const Text(
            'Core Platform Modules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Builder(
            builder: (context) {
              final user = widget.state.currentUser;
              final shortcuts = <Widget>[
                _buildModuleShortcut(context, 'Emergency SOS', Icons.emergency_rounded, AppColors.danger, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencySosScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'Alert Center', Icons.notifications_active_rounded, AppColors.danger, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertCenterScreen(state: widget.state)))),
                if (user.role.canAccessClinicalRecords)
                  _buildModuleShortcut(context, 'Patients', Icons.people_rounded, AppColors.primaryGreen, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state))))
                else
                  _buildModuleShortcut(context, 'Refer Patient', Icons.person_add_alt_1_rounded, AppColors.primaryGreen, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state)))),
                if (user.role == UserRole.nurse || user.role == UserRole.volunteer || user.role.isAdmin)
                  _buildModuleShortcut(context, 'Visits', Icons.home_work_rounded, AppColors.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitScheduleScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'Field Map', Icons.map_rounded, const Color(0xFF2E7D32), () => Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen(state: widget.state)))),
                if (user.role.canAccessClinicalRecords)
                  _buildModuleShortcut(context, 'Appointments', Icons.event_note_rounded, AppColors.secondaryGreen, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsScreen(state: widget.state)))),
                if (user.role.isVolunteer || user.role.isAdmin)
                  _buildModuleShortcut(context, 'Volunteers', Icons.groups_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerManagementScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'Blood Donors', Icons.water_drop_rounded, AppColors.danger, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: widget.state)))),
                if (user.role.canManageInventory)
                  _buildModuleShortcut(context, 'Inventory', Icons.inventory_2_rounded, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(state: widget.state)))),
                if (user.role.canDispatchAmbulance)
                  _buildModuleShortcut(context, 'Ambulance', Icons.airport_shuttle_rounded, Colors.deepOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AmbulanceDispatchScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'Crowdfunding', Icons.campaign_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalFundraisingScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'Palliative Fund', Icons.savings_rounded, AppColors.accentGold, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonationsScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'AI Assistant', Icons.psychology_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(state: widget.state)))),
                if (user.role.isAdmin)
                  _buildModuleShortcut(context, 'Analytics', Icons.bar_chart_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsScreen(state: widget.state)))),
                _buildModuleShortcut(context, 'Settings', Icons.settings_rounded, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(state: widget.state)))),
              ];

              return GridView.count(
                crossAxisCount: screenWidth > 900 ? 6 : (screenWidth > 600 ? 4 : 3),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: screenWidth > 600 ? 1.05 : 0.96,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: shortcuts,
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent Activity Feed Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Community Activity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => _showNotificationsBottomSheet(context),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...widget.state.notifications.take(4).map(
                        (note) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            child: Icon(Icons.notifications_active_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 18),
                          ),
                          title: Text(note, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleShortcut(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleWorkspaceCard(BuildContext context, bool isDark) {
    final user = widget.state.currentUser;

    if (user.role.isAdmin) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                  : [const Color(0xFFE8F5E9), const Color(0xFFF1F8F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Master Control Center',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Full governance: Banking & QR, Patient Master, Inventory Catalog & Staff Roles',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminControlCenterScreen(state: widget.state)));
                    },
                    icon: const Icon(Icons.tune_rounded, size: 15),
                    label: const Text('Open Master Control Console', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (user.role == UserRole.doctor) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                  : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Doctor Clinical Workbench',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Accept consultation requests, edit care plans, prescribe opioids & review SOS alarms',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorWorkspaceScreen(state: widget.state)));
                },
                icon: const Icon(Icons.medical_information_rounded, size: 15),
                label: const Text('Open Doctor Workbench', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (user.role == UserRole.nurse) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                  : [const Color(0xFFDCFCE7), const Color(0xFFF1F8F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nurse Home Care Hub',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Accept visit queue, log bedside vitals & catheter care, and dispense medicines',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NurseOperationsScreen(state: widget.state)));
                },
                icon: const Icon(Icons.home_work_rounded, size: 15),
                label: const Text('Open Nurse Home Care Hub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (user.role == UserRole.volunteer || user.role == UserRole.reception) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                  : [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Community Coordinator & Volunteer Desk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Triage patient nominations, moderate medical appeals, and allocate relief kits',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CoordinatorWorkspaceScreen(state: widget.state)));
                },
                icon: const Icon(Icons.volunteer_activism_rounded, size: 15),
                label: const Text('Open Coordinator Desk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations loc, bool isPatient) {
    final user = widget.state.currentUser;


    if (isPatient) {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryGreen),
              accountName: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text('Patient / Family Portal • ${user.district}'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppColors.accentGold,
                child: Icon(Icons.person, color: Colors.white, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: AppColors.primaryGreen),
              title: const Text('My Health Portal'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryGreen),
              title: const Text('Nominate Patient in Need'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_rounded),
              title: const Text('Doctor Appointments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsScreen(state: widget.state)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_rounded, color: AppColors.primaryGreen),
              title: const Text('Community Depot & Route Map'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen(state: widget.state)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_rounded, color: AppColors.danger),
              title: const Text('Blood Donor Help'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: widget.state)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_rounded, color: Colors.purple),
              title: Text(loc.translate('ai_assistant')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(state: widget.state)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(loc.translate('settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(state: widget.state)));
              },
            ),
          ],
        ),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryGreen),
            accountName: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text('${user.role.displayName} • ${widget.state.activeOrganization?.name}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.accentGold,
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: Text(loc.translate('dashboard')),
            onTap: () => Navigator.pop(context),
          ),
          if (user.role.canAccessClinicalRecords)
            ListTile(
              leading: const Icon(Icons.people_rounded),
              title: Text(loc.translate('patients')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state)));
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded),
              title: const Text('Refer Patient in Need'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state)));
              },
            ),
          if (user.role == UserRole.nurse || user.role == UserRole.volunteer || user.role.isAdmin)
            ListTile(
              leading: const Icon(Icons.home_work_rounded),
              title: Text(loc.translate('home_visits')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => VisitScheduleScreen(state: widget.state)));
              },
            ),
          ListTile(
            leading: const Icon(Icons.map_rounded, color: AppColors.primaryGreen),
            title: const Text('Live Field Map & GPS Navigation'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen(state: widget.state)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_drop_rounded),
            title: Text(loc.translate('blood_donors')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: widget.state)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign_rounded, color: Colors.purple),
            title: const Text('Medical Crowdfunding'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalFundraisingScreen(state: widget.state)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.savings_rounded, color: AppColors.accentGold),
            title: Text(loc.translate('donations')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => DonationsScreen(state: widget.state)));
            },
          ),
          if (user.role.canManageInventory)
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: Text(loc.translate('inventory')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(state: widget.state)));
              },
            ),
          // Role-Specific Workspaces
          if (user.role.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryGreen),
              title: const Text('Master Control Center (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminControlCenterScreen(state: widget.state)));
              },
            ),
          if (user.role == UserRole.doctor || user.role.isAdmin)
            ListTile(
              leading: const Icon(Icons.medical_services_rounded, color: Colors.teal),
              title: const Text('Doctor Clinical Workbench', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorWorkspaceScreen(state: widget.state)));
              },
            ),
          if (user.role == UserRole.nurse || user.role.isAdmin)
            ListTile(
              leading: const Icon(Icons.home_work_rounded, color: Colors.green),
              title: const Text('Nurse Home Care Hub', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => NurseOperationsScreen(state: widget.state)));
              },
            ),
          if (user.role == UserRole.volunteer || user.role.isAdmin)
            ListTile(
              leading: const Icon(Icons.volunteer_activism_rounded, color: AppColors.accentGold),
              title: const Text('Coordinator & Volunteer Desk', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CoordinatorWorkspaceScreen(state: widget.state)));
              },
            ),

          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text(loc.translate('settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(state: widget.state)));
            },
          ),

        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PatientListScreen(state: widget.state)));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VisitScheduleScreen(state: widget.state)));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: widget.state)));
    }
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Activity & Risk Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.state.notifications.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.primaryGreen),
                    title: Text(widget.state.notifications[i], style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonaSwitchBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.switch_account_rounded, color: AppColors.accentGold, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Switch Demo Role Persona',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Instant 1-click switch to test permissions & tailored views across all 10 roles:',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.state.demoUsers.length,
                  itemBuilder: (ctx, i) {
                    final u = widget.state.demoUsers[i];
                    final isSelected = widget.state.currentUser.role == u.role;

                    return Card(
                      color: isSelected
                          ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                              : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                              : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSand),
                          child: Icon(
                            _getRoleIcon(u.role),
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextLight : AppColors.primaryGreen),
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                u.role.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          u.email,
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 22)
                            : OutlinedButton(
                                onPressed: () {
                                  widget.state.loginAsUser(u);
                                  Navigator.pop(ctx);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Switch', style: TextStyle(fontSize: 11)),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return Icons.personal_injury_rounded;
      case UserRole.familyMember:
        return Icons.family_restroom_rounded;
      case UserRole.nurse:
        return Icons.medical_services_rounded;
      case UserRole.doctor:
        return Icons.health_and_safety_rounded;
      case UserRole.volunteer:
        return Icons.groups_rounded;
      case UserRole.ambulanceDriver:
        return Icons.airport_shuttle_rounded;
      case UserRole.pharmacist:
        return Icons.medication_rounded;
      case UserRole.orgAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.superAdmin:
        return Icons.shield_rounded;
      case UserRole.palliativeMember:
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
