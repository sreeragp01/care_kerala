import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/clinical_models.dart';

class MedicationTrackerScreen extends StatefulWidget {
  final AppStateProvider? state;

  const MedicationTrackerScreen({super.key, this.state});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  void _showLogDoseDialog(BuildContext context, AppStateProvider state, MedicationPlanModel plan, String slot) {
    String status = 'TAKEN';
    final notesCtrl = TextEditingController();
    bool isNurseVerified = state.currentUser.role.name.toLowerCase().contains('nurse') ||
        state.currentUser.role.name.toLowerCase().contains('doctor');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF132A2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.medication_rounded, color: AppColors.emeraldLight, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Log Dose: ${plan.medicineName}', style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosage: ${plan.dosage} • Time Slot: $slot', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    const Text('Dose Status', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusOption('TAKEN', status, (val) => setDialogState(() => status = val), AppColors.emerald),
                        const SizedBox(width: 8),
                        _buildStatusOption('MISSED', status, (val) => setDialogState(() => status = val), AppColors.warning),
                        const SizedBox(width: 8),
                        _buildStatusOption('REFUSED', status, (val) => setDialogState(() => status = val), AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.emerald,
                      title: const Text('Verified by Nurse on Home Visit', style: TextStyle(color: Colors.white, fontSize: 12)),
                      value: isNurseVerified,
                      onChanged: (val) => setDialogState(() => isNurseVerified = val ?? false),
                    ),
                    const SizedBox(height: 8),
                    const Text('Observation / Notes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0D1B1E),
                        hintText: 'e.g. Taken with milk; mild nausea noted',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                  onPressed: () {
                    state.logMedicationDose(
                      plan.id,
                      slot,
                      status: status,
                      isNurseVerified: isNurseVerified,
                      notes: notesCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.emerald,
                        content: Text('Logged $status for ${plan.medicineName} ($slot)!'),
                      ),
                    );
                  },
                  child: const Text('Record Dose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusOption(String label, String currentStatus, Function(String) onSelect, Color color) {
    final isSelected = currentStatus == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF0D1B1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.white24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state == null) {
      return const Scaffold(body: Center(child: Text('AppStateProvider not provided')));
    }

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final plans = state.medicationPlans;

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF132A2F),
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.medication_liquid_rounded, color: AppColors.emeraldLight, size: 24),
                SizedBox(width: 10),
                Text(
                  'Palliative Medication & Adherence',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WHO Analgesic Ladder Protocol Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A2F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: AppColors.emeraldLight, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Palliative Pain Protocol & Adherence',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Administer scheduled analgesics strictly "by the clock" to prevent pain breakthrough. Doses confirmed during nurse home visits are marked as VERIFIED.',
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const Text('Active Medication Plans', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),

                if (plans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF132A2F), borderRadius: BorderRadius.circular(12)),
                    child: const Text('No active medication plans registered.', style: TextStyle(color: Colors.white54)),
                  )
                else
                  ...plans.map((plan) => _buildPlanCard(plan, state)),

                const SizedBox(height: 20),

                // Recent Adherence History
                const Text('Today\'s Administration Log', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),

                _buildDailyLogStream(plans),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(MedicationPlanModel plan, AppStateProvider state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF132A2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.medicineName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  plan.frequency,
                  style: const TextStyle(color: AppColors.emeraldLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Dosage: ${plan.dosage} • Route: ${plan.route} • Prescribed by: ${plan.prescribedByDoctor}',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Instructions: ${plan.instructions}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 12),

          // Time Slots & Quick Log Buttons
          const Text('Scheduled Dose Slots:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: plan.timeSlots.map((slot) {
              final isLogged = plan.administrations.any((a) => a.timeSlot == slot);

              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLogged ? AppColors.emerald.withValues(alpha: 0.3) : const Color(0xFF0D1B1E),
                  side: BorderSide(color: isLogged ? AppColors.emerald : Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(
                  isLogged ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  color: isLogged ? AppColors.emeraldLight : Colors.white70,
                  size: 14,
                ),
                label: Text(
                  slot,
                  style: TextStyle(
                    color: isLogged ? AppColors.emeraldLight : Colors.white,
                    fontSize: 11,
                    fontWeight: isLogged ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onPressed: () => _showLogDoseDialog(context, state, plan, slot),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogStream(List<MedicationPlanModel> plans) {
    final allAdmins = <MedicationAdministrationModel>[];
    for (final p in plans) {
      allAdmins.addAll(p.administrations);
    }

    if (allAdmins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF132A2F), borderRadius: BorderRadius.circular(12)),
        child: const Text('No doses recorded yet today.', style: TextStyle(color: Colors.white38, fontSize: 12)),
      );
    }

    return Column(
      children: allAdmins.map((admin) {
        final isTaken = admin.status == 'TAKEN';
        final isNurse = admin.verifiedByNurse;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF132A2F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Icon(
                isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isTaken ? AppColors.emeraldLight : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${admin.medicineName} (${admin.timeSlot})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isNurse ? Colors.blue.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isNurse ? 'NURSE VERIFIED' : 'PATIENT REPORTED',
                            style: TextStyle(
                              color: isNurse ? Colors.lightBlueAccent : Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (admin.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(admin.notes, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              Text(admin.administeredAt, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
