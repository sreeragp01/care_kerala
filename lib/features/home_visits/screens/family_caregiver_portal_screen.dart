import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';
import 'home_visit_request_screen.dart';
import 'medication_tracker_screen.dart';

class FamilyCaregiverPortalScreen extends StatefulWidget {
  final AppStateProvider? state;

  const FamilyCaregiverPortalScreen({super.key, this.state});

  @override
  State<FamilyCaregiverPortalScreen> createState() => _FamilyCaregiverPortalScreenState();
}

class _FamilyCaregiverPortalScreenState extends State<FamilyCaregiverPortalScreen> {
  PatientModel? _selectedPatient;

  void _showGrantAccessDialog(BuildContext context, AppStateProvider state) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'Family Member');
    final Map<String, bool> permissionToggles = {
      'VIEW_BASIC_INFO': true,
      'VIEW_APPOINTMENTS': true,
      'VIEW_VISITS': true,
      'VIEW_VITALS': true,
      'VIEW_CARE_PLAN': false,
      'RECEIVE_ALERTS': true,
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF132A2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: AppColors.emeraldLight, size: 22),
                  SizedBox(width: 8),
                  Text('Grant Caregiver Consent', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Family Member Name', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0D1B1E),
                        hintText: 'e.g. Radhakrishnan (Brother)',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Phone Number', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: phoneCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0D1B1E),
                        hintText: '+91 98470 XXXXX',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Relationship', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: relCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0D1B1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Explicit Permission Consents:', style: TextStyle(color: AppColors.emeraldLight, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...permissionToggles.keys.map((perm) {
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.emerald,
                        title: Text(perm.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        subtitle: Text(
                          perm == 'VIEW_CARE_PLAN'
                              ? 'Includes sensitive medical diagnosis & DNR notes'
                              : 'Standard patient monitoring data',
                          style: TextStyle(color: perm == 'VIEW_CARE_PLAN' ? AppColors.warning : Colors.white38, fontSize: 10),
                        ),
                        value: permissionToggles[perm],
                        onChanged: (val) {
                          setDialogState(() => permissionToggles[perm] = val ?? false);
                        },
                      );
                    }),
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
                    if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                      final selectedPerms = permissionToggles.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();

                      final patient = _selectedPatient ?? (state.patients.isNotEmpty ? state.patients.first : null);
                      if (patient != null) {
                        state.grantCaregiverAccess(
                          patientId: patient.id,
                          caregiverName: nameCtrl.text.trim(),
                          caregiverPhone: phoneCtrl.text.trim(),
                          relationship: relCtrl.text.trim(),
                          permissions: selectedPerms,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.emerald,
                            content: Text('Access consent granted to ${nameCtrl.text.trim()}!'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Grant Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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
        final patients = state.patients;
        if (_selectedPatient == null && patients.isNotEmpty) {
          _selectedPatient = patients.first;
        }

        final patient = _selectedPatient;
        final caregiverGrants = state.caregiverGrants;
        final latestVitals = (patient != null && patient.vitalsHistory.isNotEmpty)
            ? patient.vitalsHistory.first
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF132A2F),
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.family_restroom_rounded, color: AppColors.emeraldLight, size: 24),
                SizedBox(width: 10),
                Text(
                  'Family & Caregiver Portal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Emergency Palliative Desk',
                icon: const Icon(Icons.emergency_rounded, color: AppColors.danger),
                onPressed: () {
                  if (patient != null) {
                    state.triggerPalliativeEmergencyEscalation(
                      patient.id,
                      'Family member triggered 1-tap emergency request via portal.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.danger,
                        content: Text('PALLIATIVE EMERGENCY ALERT: Care team & desk notified immediately!'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Selector Header
                if (patient != null) ...[
                  Container(
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
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.emerald.withValues(alpha: 0.25),
                              radius: 24,
                              child: Text(
                                patient.name.substring(0, 1),
                                style: const TextStyle(color: AppColors.emeraldLight, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(patient.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${patient.age} yrs • ${patient.gender} • ${patient.categoryTier}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                  Text(patient.diagnosis, style: const TextStyle(color: AppColors.emeraldLight, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),

                        // 1-Tap Action Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 16),
                                label: const Text('Request Visit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => HomeVisitRequestScreen(state: state)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.emeraldLight,
                                  side: const BorderSide(color: AppColors.emeraldLight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.medication_liquid_rounded, size: 16),
                                label: const Text('Medications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MedicationTrackerScreen(state: state)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Latest Vitals Snapshot
                  const Text('Latest Recorded Vitals', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (latestVitals != null) ...[
                    Row(
                      children: [
                        Expanded(child: _buildVitalBox('Blood Pressure', latestVitals.bp, Icons.favorite_rounded, AppColors.emeraldLight)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildVitalBox(
                            'SpO₂ Oxygen',
                            '${latestVitals.spo2}%',
                            Icons.air_rounded,
                            latestVitals.spo2 < 92 ? AppColors.danger : AppColors.emeraldLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildVitalBox('Pulse', '${latestVitals.pulse} bpm', Icons.timeline_rounded, AppColors.secondary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildVitalBox(
                            'Pain Scale',
                            '${latestVitals.painScale}/10',
                            Icons.sentiment_very_dissatisfied_rounded,
                            latestVitals.painScale >= 7 ? AppColors.warning : AppColors.emeraldLight,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF132A2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No vitals recorded yet. First visit will record baseline measurements.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Granular Caregiver Consent Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Family Consent Grants', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        icon: const Icon(Icons.add_moderator_rounded, color: AppColors.emeraldLight, size: 16),
                        label: const Text('Grant New Member', style: TextStyle(color: AppColors.emeraldLight, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showGrantAccessDialog(context, state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...caregiverGrants.map((grant) => _buildGrantCard(grant, state)),

                  const SizedBox(height: 20),

                  // 24x7 Help Desk Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A2F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, color: AppColors.emeraldLight, size: 32),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('24x7 Palliative Support Line', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Immediate assistance for breakthrough pain, catheter emergencies, or equipment guidance.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.emeraldLight),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dialing 24x7 Palliative Desk: +91 495 272 1000...')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF132A2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildGrantCard(CaregiverAccessModel grant, AppStateProvider state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF132A2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: grant.isActive ? Colors.white12 : AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${grant.caregiverName} (${grant.relationship})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: grant.isActive
                      ? AppColors.emerald.withValues(alpha: 0.2)
                      : AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  grant.isActive ? 'ACTIVE' : 'REVOKED',
                  style: TextStyle(
                    color: grant.isActive ? AppColors.emeraldLight : AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Phone: ${grant.caregiverPhone} • Granted by: ${grant.grantedBy}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 10),

          // Permissions Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: grant.permissions.map((perm) {
              final isCarePlan = perm == 'VIEW_CARE_PLAN';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCarePlan ? Colors.purple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isCarePlan ? Colors.purple : Colors.white24),
                ),
                child: Text(
                  perm.replaceAll('_', ' '),
                  style: TextStyle(
                    color: isCarePlan ? Colors.purpleAccent : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          if (grant.isActive) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.block_rounded, size: 14),
                label: const Text('Revoke Consent', style: TextStyle(fontSize: 11)),
                onPressed: () => state.revokeCaregiverAccess(grant.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
