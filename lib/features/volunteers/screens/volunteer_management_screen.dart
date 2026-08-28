import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';

class VolunteerManagementScreen extends StatelessWidget {
  final AppStateProvider state;

  const VolunteerManagementScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final volunteers = state.volunteers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Volunteer Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: AppColors.primaryGreen),
                onPressed: () => _showAddVolunteerDialog(context),
              ),
            ],
          ),
          body: volunteers.isEmpty
              ? const Center(child: Text('No registered volunteers found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: volunteers.length,
                  itemBuilder: (ctx, i) {
                    final vol = volunteers[i];
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                                  child: Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vol.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${vol.ward}, ${vol.district} • ${vol.phone}',
                                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => state.toggleVolunteerVerification(vol.id),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: vol.isVerified
                                          ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                                          : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      vol.isVerified ? 'Verified ✓' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: vol.isVerified
                                            ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              children: [
                                Expanded(child: _buildStatPill('Assigned Patients', '${vol.assignedPatientsCount}', isDark)),
                                Expanded(child: _buildStatPill('Total Hours', '${vol.totalHoursLogged} hrs', isDark)),
                                Expanded(child: _buildStatPill('Tasks Done', '${vol.tasksCompleted}', isDark)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => state.toggleVolunteerVerification(vol.id),
                                    icon: Icon(vol.isVerified ? Icons.cancel_outlined : Icons.verified_user_outlined, size: 14),
                                    label: Text(vol.isVerified ? 'Unverify' : 'Verify', style: const TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => state.logVolunteerTask(vol.id, 3),
                                    icon: const Icon(Icons.add_task_rounded, size: 14),
                                    label: const Text('+3 Service Hrs', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            onPressed: () => _showAddVolunteerDialog(context),
            child: const Icon(Icons.person_add_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showAddVolunteerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 94471 ');
    final wardCtrl = TextEditingController(text: 'Ward 4, Kozhikode');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Register Community Volunteer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Volunteer Full Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 10),
                TextField(controller: wardCtrl, decoration: const InputDecoration(labelText: 'Ward & Locality', prefixIcon: Icon(Icons.location_on_outlined))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                state.addVolunteer(
                  VolunteerModel(
                    id: 'VOL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    ward: wardCtrl.text.trim(),
                    district: state.activeOrganization?.district ?? 'Kozhikode',
                    assignedPatientsCount: 0,
                    totalHoursLogged: 0,
                    tasksCompleted: 0,
                    isVerified: true,
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Volunteer ${nameCtrl.text.trim()} registered successfully!')),
                );
              }
            },
            child: const Text('Register Volunteer'),
          ),
        ],
      ),
    );
  }
}
