import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/payment_gateway_dialog.dart';
import '../../auth/screens/login_screen.dart';


class SettingsScreen extends StatelessWidget {
  final AppStateProvider state;

  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final loc = AppLocalizations.of(context);
        final isMalayalam = state.locale.languageCode == 'ml';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final user = state.currentUser;
        final isAdmin = user.role.isAdmin;
        final isPatient = user.role.isPatientOrFamily;

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.translate('settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SECTION: Appearance & Localization
              _buildSectionHeader('Appearance & Localization', Icons.palette_outlined),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      ),
                      title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(isDark ? 'Kerala Slate Dark Theme active' : 'Natural Light Theme active', style: const TextStyle(fontSize: 12)),
                      value: state.isDarkMode,
                      activeThumbColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      onChanged: (_) => state.toggleDarkMode(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.language_rounded,
                        color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      ),
                      title: Text(loc.translate('language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(isMalayalam ? 'മലയാളം (Malayalam)' : 'English', style: const TextStyle(fontSize: 12)),
                      value: isMalayalam,
                      activeThumbColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      onChanged: (val) {
                        state.setLocale(val ? const Locale('ml') : const Locale('en'));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: Multi-Tenancy & User Identity
              _buildSectionHeader(
                isPatient ? 'Patient Account Profile' : 'Tenant Organization & Account',
                isPatient ? Icons.account_circle_outlined : Icons.domain_rounded,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            child: Icon(
                              isPatient ? Icons.person_rounded : Icons.business_rounded,
                              color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPatient ? 'Assigned Palliative Unit' : 'Active Organization Tenant',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(state.activeOrganization?.name ?? 'Kozhikode Care Society', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('District: ${state.activeOrganization?.district ?? "Kozhikode"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            OutlinedButton(
                              onPressed: () => _showTenantPicker(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Switch Org', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            child: Icon(Icons.badge_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPatient ? 'Patient Care Profile' : 'Active User Role',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(user.role.displayName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            OutlinedButton(
                              onPressed: () => _showRolePicker(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Switch Role', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: Organization Official Banking & Payment Gateway (Admins)
              if (isAdmin && state.activeOrganization != null) ...[
                _buildSectionHeader('Organization Main Banking & Payment Gateway', Icons.account_balance_wallet_rounded),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                              child: Icon(Icons.qr_code_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Official Org Account QR & UPI VPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    state.activeOrganization!.upiId.isNotEmpty
                                        ? state.activeOrganization!.upiId
                                        : 'kozhikodepalliative@sbi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              tooltip: 'Edit Banking Details',
                              onPressed: () => _showEditBankingDialog(context),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          'A/C Holder: ${state.activeOrganization!.bankAccountName.isNotEmpty ? state.activeOrganization!.bankAccountName : state.activeOrganization!.name}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bank: ${state.activeOrganization!.bankName.isNotEmpty ? state.activeOrganization!.bankName : "SBI"} • A/C No: ${state.activeOrganization!.bankAccountNumber.isNotEmpty ? state.activeOrganization!.bankAccountNumber : "389201948201"} • IFSC: ${state.activeOrganization!.ifscCode.isNotEmpty ? state.activeOrganization!.ifscCode : "SBIN0001234"}',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Razorpay Key: ${state.activeOrganization!.razorpayKeyId.isNotEmpty ? state.activeOrganization!.razorpayKeyId : "rzp_test_palliative2026"} (Verified Merchant)',
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showEditBankingDialog(context),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Update Bank Info', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  PaymentGatewayDialog.show(
                                    context,
                                    state: state,
                                    title: '${state.activeOrganization!.name} Main Fund',
                                    category: 'General Palliative Fund',
                                    defaultAmount: 500.0,
                                  );
                                },
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                label: const Text('View / Test Org QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],


              // SECTION: Backend API & Synchronization (Admins Only)
              if (user.role.canConfigureBackend) ...[
                _buildSectionHeader('Django REST Framework Backend (Admin)', Icons.cloud_sync_rounded),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                              child: Icon(Icons.api_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Backend API Server Endpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.apiBaseUrl,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, size: 22),
                              tooltip: 'Edit Server URL',
                              onPressed: () => _showEditApiUrlDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showEditApiUrlDialog(context),
                                icon: const Icon(Icons.tune_rounded, size: 16),
                                label: const Text('Configure IP', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Testing connection & syncing with Django REST API...')),
                                  );
                                  await state.syncWithDjangoBackend();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Django REST Server Connected & Synced!'),
                                        backgroundColor: Colors.teal,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sync_rounded, size: 16),
                                label: const Text('Test & Sync', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // SECTION: Offline Storage & Cache Maintenance (Staff & Admins)
              if (!isPatient) ...[
                _buildSectionHeader('Offline Queue & Data Maintenance', Icons.storage_rounded),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: state.pendingOfflineSyncCount > 0
                                  ? (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface)
                                  : (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface),
                              child: Icon(
                                Icons.offline_pin_rounded,
                                color: state.pendingOfflineSyncCount > 0 ? AppColors.warning : AppColors.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Offline Local Drafts Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${state.pendingOfflineSyncCount} items queued for cloud sync.',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (state.pendingOfflineSyncCount > 0)
                              ElevatedButton(
                                onPressed: () => state.syncOfflineQueue(),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        if (isAdmin) ...[
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmClearCache(context),
                                  icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                                  label: const Text('Clear Cache', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmResetData(context),
                                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                  label: const Text('Reset Mock Data', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // SECTION: Alert & Notification Preferences
              _buildSectionHeader('Notification & Alert Settings', Icons.notifications_active_outlined),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Emergency Blood Donation Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Immediate alerts for emergency donor requests', style: TextStyle(fontSize: 11)),
                      value: state.notifyEmergencyBlood,
                      activeThumbColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      onChanged: (val) => state.toggleEmergencyBloodNotification(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('High-Risk Clinical Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Notify when high-risk vitals or pain scores are logged', style: TextStyle(fontSize: 11)),
                      value: state.notifyCriticalPatients,
                      activeThumbColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      onChanged: (val) => state.toggleCriticalPatientsNotification(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Low Medicine Stock Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Notify when clinic medicines reach reorder thresholds', style: TextStyle(fontSize: 11)),
                      value: state.notifyLowStock,
                      activeThumbColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      onChanged: (val) => state.toggleLowStockNotification(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: About & App Info
              _buildSectionHeader('About Platform', Icons.info_outline_rounded),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.health_and_safety_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 24),
                          const SizedBox(width: 10),
                          const Text('CareLink Kerala v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AI-Powered Palliative & Community Healthcare Platform. Engineered for Kerala Kudumbashree, ASHA, and Palliative Nursing Networks.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen(state: state)),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                label: const Text('Sign Out of Session', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showEditApiUrlDialog(BuildContext context) {
    final urlCtrl = TextEditingController(text: state.apiBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Django REST Server Endpoint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the backend base URL (e.g. http://127.0.0.1:8000/api or your local network IP):',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Base API URL',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                state.setApiBaseUrl(urlCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backend API URL updated to: ${urlCtrl.text.trim()}')),
                );
              }
            },
            child: const Text('Save Endpoint'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Clear Local Cache?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('This will clear local offline drafts and notification activity logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              state.clearCache();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local cache cleared.')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Reset All Mock Data?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('This will reload fresh default records for patients, visits, inventory, and donors.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              state.resetToDefaultData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset to default demo data completed.')),
              );
            },
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  void _showTenantPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => ListView.builder(
        itemCount: state.organizations.length,
        itemBuilder: (ctx, i) {
          final org = state.organizations[i];
          final isSelected = org.id == state.activeOrganization?.id;
          return ListTile(
            leading: Icon(Icons.business_rounded, color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary),
            title: Text(org.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text('District: ${org.district} • Reg #${org.registrationNumber}'),
            trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen) : null,
            onTap: () {
              state.switchOrganization(org);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  void _showRolePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => ListView(
        children: UserRole.values.map((role) {
          final isSelected = role == state.currentUser.role;
          return ListTile(
            leading: Icon(Icons.person_outline, color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary),
            title: Text(role.displayName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen) : null,
            onTap: () {
              state.switchRole(role);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showEditBankingDialog(BuildContext context) {
    final org = state.activeOrganization;
    if (org == null) return;

    final upiCtrl = TextEditingController(text: org.upiId);
    final accNameCtrl = TextEditingController(text: org.bankAccountName);
    final accNumCtrl = TextEditingController(text: org.bankAccountNumber);
    final ifscCtrl = TextEditingController(text: org.ifscCode);
    final bankNameCtrl = TextEditingController(text: org.bankName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text('Edit Banking & UPI: ${org.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 460 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Official Organization UPI ID (VPA) *',
                    hintText: 'e.g. kozhikodepalliative@sbi',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account Holder Name *',
                    prefixIcon: Icon(Icons.badge_outlined),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accNumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account Number *',
                    prefixIcon: Icon(Icons.numbers_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ifscCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code *',
                    hintText: 'e.g. SBIN0001234',
                    prefixIcon: Icon(Icons.domain_verification_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bankNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bank & Branch Name *',
                    hintText: 'e.g. State Bank of India, Calicut Main',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (upiCtrl.text.isNotEmpty && accNumCtrl.text.isNotEmpty) {
                state.updateOrganizationBankingInfo(
                  orgId: org.id,
                  upiId: upiCtrl.text.trim(),
                  bankAccountName: accNameCtrl.text.trim().isNotEmpty ? accNameCtrl.text.trim() : org.name,
                  bankAccountNumber: accNumCtrl.text.trim(),
                  ifscCode: ifscCtrl.text.trim().toUpperCase(),
                  bankName: bankNameCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Banking & UPI updated for ${org.name}!'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Save Banking Profile'),
          ),
        ],
      ),
    );
  }
}

