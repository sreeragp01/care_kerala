import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';

class HospitalManagementDashboard extends StatefulWidget {
  final AppStateProvider state;

  const HospitalManagementDashboard({super.key, required this.state});

  @override
  State<HospitalManagementDashboard> createState() => _HospitalManagementDashboardState();
}

class _HospitalManagementDashboardState extends State<HospitalManagementDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final isDark = state.isDarkMode;
        final user = state.currentUser;
        final org = state.activeOrganization;
        final pendingCr = state.changeRequests.where((c) => c.status == 'PENDING').length;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org?.name ?? 'Hospital Management Console',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Role: ${user.role.displayName} • District: ${org?.district ?? "Kozhikode"}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.brandTeal,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.brandTeal,
              indicatorWeight: 3,
              isScrollable: true,
              tabs: [
                const Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Overview'),
                const Tab(icon: Icon(Icons.medical_services_rounded, size: 18), text: 'Doctors & OPD'),
                const Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'Hospital Team'),
                Tab(
                  icon: Badge(
                    isLabelVisible: pendingCr > 0,
                    label: Text('$pendingCr'),
                    child: const Icon(Icons.fact_check_rounded, size: 18),
                  ),
                  text: 'Change Requests',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(state, isDark),
              _buildDoctorsTab(state, isDark),
              _buildTeamTab(state, isDark),
              _buildChangeRequestsTab(state, isDark),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddChangeRequestModal(context, state, isDark),
            backgroundColor: AppColors.brandNavy,
            icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
            label: const Text('Propose Schedule Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(AppStateProvider state, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Completeness',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandHealthGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '92% Complete',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.92,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandHealthGreen),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '✓ Basic Information Verified\n✓ 24x7 Emergency Contact Configured\n✓ 3 Doctor Schedules Active\n⚠ Upload NABH Accreditation Certificate to reach 100%',
                  style: TextStyle(fontSize: 11, height: 1.4, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatTile('Active Doctors', '${state.doctors.length}', Icons.medical_services_rounded, AppColors.brandTeal, isDark),
              const SizedBox(width: 10),
              _buildStatTile('Pending Changes', '${state.changeRequests.where((c) => c.status == "PENDING").length}', Icons.pending_actions_rounded, Colors.orangeAccent, isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatTile('Appt Requests', '${state.appointmentRequests.length}', Icons.calendar_month_rounded, AppColors.brandNavy, isDark),
              const SizedBox(width: 10),
              _buildStatTile('Verification Status', 'Verified 🟢', Icons.verified_rounded, AppColors.brandHealthGreen, isDark),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('CareLink Network Governance Principles', isDark),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleItem('1. Real-time Freshness', 'Doctor consultation hours and OPD timings should be updated immediately if a doctor goes on leave.'),
                _buildRuleItem('2. Moderator Approval Flow', 'Updates proposed by healthcare moderators require Organization Admin approval before publishing.'),
                _buildRuleItem('3. Accurate Triage', 'Never publish inaccurate 24x7 emergency contacts or unavailable clinical services.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab(AppStateProvider state, bool isDark) {
    final docs = state.doctors;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final d = docs[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
                    child: Text(d.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text('${d.specialty} • Reg: ${d.registrationNumber}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandHealthGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Weekly OPD Slots:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandTeal),
              ),
              const SizedBox(height: 4),
              ...d.schedules.map((s) => Text(
                '• ${s.dayOfWeek}: ${s.startTime} - ${s.endTime} (${s.locationRoom})',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamTab(AppStateProvider state, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Team Management Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital Team & Staff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Sovereign member approvals and role scopes',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal),
              icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
              label: const Text('Invite Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _showInviteTeamMemberModal(context, state, isDark),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sovereign Pending Approval Queue
        Text(
          'Pending Admin Approvals (Queue)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_outline, color: Colors.orange),
                ),
                title: const Text('Dr. Priya Varma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Consultant Cardiologist • Reg: TCMC/64291/K\nRequested: Today (31 Aug 2026)', style: TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membership request rejected.')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.brandHealthGreen),
                      tooltip: 'Approve as Active Member',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.brandTeal,
                            content: Text('Dr. Priya Varma approved as Active Hospital Team Member!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Active Team Roster
        Text(
          'Active Team Members',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildMemberCard('Dr. Narayanan Kutty', 'Head of Oncology • Lead Consultant', 'Doctor', 'ACTIVE', isDark),
        _buildMemberCard('Arjun Das', 'Department Content Moderator', 'Moderator', 'ACTIVE', isDark),
        _buildMemberCard('Sujith Kumar', 'OPD Reception & Token Desk', 'Reception Staff', 'ACTIVE', isDark),
        _buildMemberCard('Anjali Nair', 'Palliative Community Nurse', 'Nurse', 'ACTIVE', isDark),
      ],
    );
  }

  Widget _buildMemberCard(String name, String designation, String role, String status, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(designation, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (val) {
              if (val == 'REVOKE') {
                _showRevokeDialog(name);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'PERMISSIONS', child: Text('Manage Permissions')),
              const PopupMenuItem(value: 'REVOKE', child: Text('Revoke Access', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Hospital Access?'),
        content: Text('Revoking access will remove $name from this hospital\'s team. Their user account will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Access revoked for $name.')),
              );
            },
            child: const Text('Revoke Access', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInviteTeamMemberModal(BuildContext context, AppStateProvider state, bool isDark) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    String selectedRole = 'DOCTOR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invite Hospital Team Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Issues a secure invitation token for staff / practitioner onboarding', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Dr. Anand Sharma')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Official Email', hintText: 'anand@hospital.org')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'DOCTOR', child: Text('Doctor / Specialist Consultant')),
                  DropdownMenuItem(value: 'DEPARTMENT_MODERATOR', child: Text('Department Moderator')),
                  DropdownMenuItem(value: 'NURSE', child: Text('Clinical / Palliative Nurse')),
                  DropdownMenuItem(value: 'RECEPTION', child: Text('Reception Desk Staff')),
                  DropdownMenuItem(value: 'STAFF', child: Text('General Healthcare Staff')),
                ],
                onChanged: (v) => setModalState(() => selectedRole = v!),
                decoration: const InputDecoration(labelText: 'Role Scope'),
              ),
              const SizedBox(height: 12),
              TextField(controller: desigCtrl, decoration: const InputDecoration(labelText: 'Designation / Department', hintText: 'e.g. Senior Pediatrician')),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal, minimumSize: const Size(double.infinity, 46)),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.brandTeal,
                        content: Text('Invitation token generated and sent to ${emailCtrl.text}.'),
                      ),
                    );
                  }
                },
                child: const Text('Send Team Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeRequestsTab(AppStateProvider state, bool isDark) {
    final list = state.changeRequests;
    if (list.isEmpty) {
      return Center(
        child: Text('No change requests pending review.', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cr = list[index];
        final isPending = cr.status == 'PENDING';

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Request #${cr.id}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withValues(alpha: 0.15)
                          : (cr.status == 'APPROVED' ? AppColors.brandHealthGreen.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cr.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPending
                            ? Colors.orange
                            : (cr.status == 'APPROVED' ? AppColors.brandHealthGreen : Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Proposed by: ${cr.requestedByName} • ${cr.createdAt}',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                cr.changeSummary,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.brandPeaceBlue : AppColors.brandNavy,
                ),
              ),
              if (cr.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Reason: "${cr.reason}"',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Old: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        Expanded(child: Text('${cr.oldData}', style: const TextStyle(fontSize: 11))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
                        Expanded(child: Text('${cr.newData}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => state.rejectChangeRequest(cr.id),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => state.approveChangeRequest(cr.id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandHealthGreen),
                        child: const Text('Approve & Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
          Text(desc, style: const TextStyle(fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }

  void _showAddChangeRequestModal(BuildContext context, AppStateProvider state, bool isDark) {
    final summaryController = TextEditingController();
    final reasonController = TextEditingController();
    final newTimingController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Propose Schedule Update',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Moderators can propose schedule or timing changes. Hospital Admins will review before publishing.',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'Change Summary *',
                  hintText: 'e.g. Update Dr. Priya Varma Thursday OPD to 11:00 AM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newTimingController,
                decoration: const InputDecoration(
                  labelText: 'New Schedule Timing *',
                  hintText: 'e.g. Thursday 11:00 AM - 03:00 PM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason for Modification',
                  hintText: 'e.g. OT Schedule adjustment',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (summaryController.text.trim().isNotEmpty) {
                    final cr = ChangeRequestModel(
                      id: 'CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      organizationId: 'org_kozhikode',
                      organizationName: 'Calicut Medical Center',
                      requestedByName: 'Arjun Das (Moderator)',
                      entityType: 'Doctor Schedule Update',
                      changeSummary: summaryController.text.trim(),
                      oldData: const {'timing': '10:00 AM - 02:00 PM'},
                      newData: {'timing': newTimingController.text.trim()},
                      reason: reasonController.text.trim(),
                      status: 'PENDING',
                      createdAt: '31 Aug 2026',
                    );
                    state.submitChangeRequest(cr);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.brandTeal,
                        content: Text('Change request submitted for Hospital Admin review.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Submit Change Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
