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
import '../../../core/widgets/glass_card.dart';
import '../../network/screens/healthcare_directory_screen.dart';

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
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 8,
            title: Row(
              children: [
                // Official Brand Icon Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [AppColors.brandNavy, AppColors.brandTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandTeal.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Care',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: widget.state.isDarkMode ? Colors.white : AppColors.brandNavy,
                              ),
                            ),
                            const Text(
                              'Link',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandTeal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.brandTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'KERALA',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: AppColors.brandTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isPatient
                            ? (isMalayalam ? 'രോഗി: ${user.name} • ${AppLocalizations.getDistrictName(user.district, isMalayalam: true)}' : 'Patient: ${user.name} • ${user.district}')
                            : (org?.name ?? 'Palliative Care Unit • ${user.role.displayName}'),
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.state.isDarkMode ? const Color(0xFFA7F3D0) : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            actions: [
              // Emergency Rapid SOS Shortcut
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Emergency SOS & Ambulance Help',
                icon: const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmergencySosScreen(state: widget.state),
                    ),
                  );
                },
              ),

              // Offline Sync Indicator Badge
              if (!isPatient && widget.state.pendingOfflineSyncCount > 0)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: '${widget.state.pendingOfflineSyncCount} Offline Drafts Cached',
                  icon: Badge(
                    label: Text('${widget.state.pendingOfflineSyncCount}'),
                    backgroundColor: AppColors.warning,
                    child: const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 20),
                  ),
                  onPressed: () => widget.state.syncOfflineQueue(),
                ),

              // Theme Mode Toggle (Bright / Dark)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: widget.state.isDarkMode ? 'Switch to Bright Mode' : 'Switch to Dark Mode',
                icon: Icon(
                  widget.state.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: widget.state.isDarkMode ? AppColors.accentGold : AppColors.brandNavy,
                  size: 20,
                ),
                onPressed: () => widget.state.toggleDarkMode(),
              ),

              // Compact Language Toggle Badge
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 2.0),
                child: InkWell(
                  onTap: () {
                    widget.state.setLocale(
                      isMalayalam ? const Locale('en') : const Locale('ml'),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.brandNavy).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.brandNavy).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isMalayalam ? 'EN' : 'മല',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.brandNavy,
                      ),
                    ),
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
          body: GlassScaffoldBackground(
            child: isPatient
                ? PatientPortalView(state: widget.state)
                : _buildDashboardContent(context, loc),
          ),
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
          const SizedBox(height: 12),

          // CareLink Network 2.0 Feature Banner Card
          GlassCard(
            blur: 16,
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            customFillColor: (isDark ? AppColors.brandNavy : AppColors.brandPeaceBlue).withValues(alpha: 0.35),
            customBorderColor: AppColors.brandTeal.withValues(alpha: 0.4),
            hasGlow: true,
            glowColor: AppColors.brandTeal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HealthcareDirectoryScreen(state: widget.state)),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: AppColors.brandTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'CareLink Network',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.brandNavy,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brandHealthGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('v2.0', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find Verified Hospitals, Doctors & 24x7 Emergency Care',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brandTeal),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Triage Status Glowing Pills Bar (Critical, High Risk, Monitored)
          _buildTriagePillsBar(context, isDark),
          const SizedBox(height: 14),

          // Role-Based Workspace Hub Quick Launch Card
          _buildRoleWorkspaceCard(context, isDark),
          const SizedBox(height: 14),

          // Prominent Glowing Crimson Emergency SOS Bar
          _buildEmergencySosActionBar(context, isDark),
          const SizedBox(height: 16),

          // Schedule Banner for Nurse/Volunteer
          if (widget.state.currentUser.role == UserRole.nurse || widget.state.currentUser.role == UserRole.volunteer)
            _buildScheduleBanner(context, isDark),

          // Upcoming Home Visits Glass Feed
          if (widget.state.currentUser.role == UserRole.nurse || widget.state.currentUser.role == UserRole.volunteer || widget.state.currentUser.role.isAdmin)
            _buildUpcomingVisitsFeed(context, isDark),

          // KPI Stats Cards Grid
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: screenWidth > 900
                ? 4
                : (screenWidth > 600 ? 3 : 2),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: screenWidth > 900
                ? 1.45
                : (screenWidth > 600 ? 1.35 : 1.20),
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
                childAspectRatio: screenWidth > 600 ? 1.08 : 0.94,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: shortcuts,
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Activity Feed Glass Card
          GlassCard(
            borderRadius: 18,
            blur: 14,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Community Activity',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _showNotificationsBottomSheet(context),
                      child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Divider(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                ...widget.state.notifications.take(4).map(
                      (note) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                            size: 16,
                          ),
                        ),
                        title: Text(note, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriagePillsBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            blur: 10,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            customFillColor: const Color(0x2EE11D48),
            customBorderColor: const Color(0x66E11D48),
            hasGlow: true,
            glowColor: AppColors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientListScreen(state: widget.state, initialFilterTier: 'High Risk'),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Critical (${widget.state.criticalPatientsCount})',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            blur: 10,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            customFillColor: const Color(0x2ED97706),
            customBorderColor: const Color(0x66D97706),
            hasGlow: true,
            glowColor: AppColors.warning,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientListScreen(state: widget.state, initialFilterTier: 'High Risk'),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'High Risk (${widget.state.patients.where((p) => p.riskLevel == "High Risk").length})',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            blur: 10,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            customFillColor: const Color(0x2E10B981),
            customBorderColor: const Color(0x6610B981),
            hasGlow: true,
            glowColor: AppColors.primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientListScreen(state: widget.state),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34D399), size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Monitored (${widget.state.activePatientsCount})',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencySosActionBar(BuildContext context, bool isDark) {
    return GlassCard(
      blur: 16,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      customFillColor: const Color(0x38EF4444),
      customBorderColor: const Color(0x75EF4444),
      hasGlow: true,
      glowColor: AppColors.danger,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmergencySosScreen(state: widget.state)),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_rounded, color: Color(0xFFFCA5A5), size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'SOS EMERGENCY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildScheduleBanner(BuildContext context, bool isDark) {
    return GlassCard(
      borderRadius: 14,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      customFillColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.08),
      customBorderColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 20),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Start', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  Widget _buildUpcomingVisitsFeed(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'UPCOMING HOME VISITS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen(state: widget.state))),
              icon: Icon(Icons.map_outlined, size: 14, color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen),
              label: Text('Live Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...widget.state.visits.take(3).map((visit) {
          return GlassCard(
            blur: 14,
            borderRadius: 16,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            customFillColor: isDark
                ? const Color(0x350F372B)
                : const Color(0xF2FFFFFF),
            customBorderColor: isDark
                ? const Color(0x3A52B788)
                : const Color(0xFFE2E8F0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            visit.scheduledTime,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              visit.patientName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Follow-up: Routine Palliative Assessment',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '[${visit.assignedNurseName}]',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF6EE7B7) : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen(state: widget.state))),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF10B981) : AppColors.primaryGreen).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? const Color(0xFF34D399) : AppColors.primaryGreen).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }


  Widget _buildModuleShortcut(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      borderRadius: 16,
      blur: 12,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleWorkspaceCard(BuildContext context, bool isDark) {

    final user = widget.state.currentUser;

    return GlassCard(
      blur: 16,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      customFillColor: isDark
          ? const Color(0x350F372B)
          : const Color(0xE6FFFFFF),
      customBorderColor: isDark
          ? const Color(0x3A52B788)
          : const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROLE WORKSPACE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quick Launch',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.role.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF34D399) : AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Role Quick Launch Bar matching preview mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRoleQuickLaunchButton(
                context,
                title: 'Doctor',
                icon: Icons.medical_services_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorWorkspaceScreen(state: widget.state))),
                isSelected: user.role == UserRole.doctor,
                isDark: isDark,
              ),
              _buildRoleQuickLaunchButton(
                context,
                title: 'Nurse',
                icon: Icons.person_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NurseOperationsScreen(state: widget.state))),
                isSelected: user.role == UserRole.nurse,
                isDark: isDark,
              ),
              _buildRoleQuickLaunchButton(
                context,
                title: 'Coordinator',
                icon: Icons.groups_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoordinatorWorkspaceScreen(state: widget.state))),
                isSelected: user.role == UserRole.volunteer || user.role == UserRole.reception,
                isDark: isDark,
              ),
              _buildRoleQuickLaunchButton(
                context,
                title: 'Admin',
                icon: Icons.verified_user_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminControlCenterScreen(state: widget.state))),
                isSelected: user.role.isAdmin,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleQuickLaunchButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF047857)],
                    )
                  : (isDark
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x5010B981), Color(0x30064E3B)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE6F4EE), Color(0xFFD1FAE5)],
                        )),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF34D399)
                    : (isDark ? const Color(0x4034D399) : const Color(0xFF10B981).withValues(alpha: 0.3)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF34D399) : AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.textPrimary)
                  : (isDark ? const Color(0xFFA7F3D0) : AppColors.textSecondary),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
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
              leading: const Icon(Icons.local_hospital_rounded, color: AppColors.brandTeal),
              title: const Text('Find Healthcare & Hospitals'),
              subtitle: const Text('CareLink Network 2.0', style: TextStyle(fontSize: 10, color: AppColors.brandTeal)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => HealthcareDirectoryScreen(state: widget.state)));
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
          ListTile(
            leading: const Icon(Icons.local_hospital_rounded, color: AppColors.brandTeal),
            title: const Text('CareLink Network Directory'),
            subtitle: const Text('Verified Hospitals, Clinics & Doctors', style: TextStyle(fontSize: 10, color: AppColors.brandTeal)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => HealthcareDirectoryScreen(state: widget.state)));
            },
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
}
