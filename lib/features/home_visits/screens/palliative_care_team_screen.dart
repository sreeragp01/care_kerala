import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/clinical_models.dart';

class PalliativeCareTeamScreen extends StatefulWidget {
  final AppStateProvider? state;

  const PalliativeCareTeamScreen({super.key, this.state});

  @override
  State<PalliativeCareTeamScreen> createState() => _PalliativeCareTeamScreenState();
}

class _PalliativeCareTeamScreenState extends State<PalliativeCareTeamScreen> {
  CareTeamModel? _selectedTeam;

  void _showAddMemberDialog(BuildContext context, AppStateProvider state, CareTeamModel team) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'Field Nurse';

    final roles = [
      'Doctor (Palliative Lead)',
      'Field Nurse',
      'Physiotherapist',
      'Medical Social Worker',
      'Counselor',
      'Community Volunteer',
    ];

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
                  const Icon(Icons.person_add_alt_1_rounded, color: AppColors.emeraldLight, size: 22),
                  const SizedBox(width: 8),
                  Text('Add Member to ${team.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name & Credentials', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0D1B1E),
                        hintText: 'e.g. Dr. Kavitha MSW',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Role in Multi-Disciplinary Team', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0D1B1E),
                          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedRole = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Contact Phone', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    if (nameCtrl.text.trim().isNotEmpty) {
                      state.addCareTeamMember(
                        team.id,
                        CareTeamMemberModel(
                          id: 'CTM-${DateTime.now().millisecondsSinceEpoch}',
                          memberName: nameCtrl.text.trim(),
                          role: selectedRole,
                          phone: phoneCtrl.text.trim(),
                        ),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.emerald,
                          content: Text('Added ${nameCtrl.text.trim()} to ${team.name}!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        final careTeams = state.careTeams;
        if (_selectedTeam == null && careTeams.isNotEmpty) {
          _selectedTeam = careTeams.first;
        } else if (_selectedTeam != null) {
          // Re-sync selected team with provider list
          _selectedTeam = careTeams.firstWhere((t) => t.id == _selectedTeam!.id, orElse: () => careTeams.first);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF132A2F),
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.groups_rounded, color: AppColors.emeraldLight, size: 24),
                SizedBox(width: 10),
                Text(
                  'Multi-Disciplinary Care Teams',
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
                // Team Selector Card
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
                      const Text('Select Palliative Care Unit', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CareTeamModel>(
                            value: _selectedTeam,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF0D1B1E),
                            items: careTeams.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTeam = val);
                            },
                          ),
                        ),
                      ),
                      if (_selectedTeam != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.map_rounded, color: AppColors.emeraldLight, size: 16),
                            const SizedBox(width: 6),
                            Text('Coverage: ${_selectedTeam!.areaCoverage}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (_selectedTeam != null) ...[
                  // Team Summary Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Team Roster (${_selectedTeam!.members.length} Specialists)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        label: const Text('Add Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddMemberDialog(context, state, _selectedTeam!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lead Doctor & Primary Nurse Highlights
                  Row(
                    children: [
                      Expanded(
                        child: _buildLeadershipCard(
                          title: 'Lead Doctor',
                          name: _selectedTeam!.leadDoctorName,
                          icon: Icons.local_hospital_rounded,
                          color: AppColors.emeraldLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLeadershipCard(
                          title: 'Primary Field Nurse',
                          name: _selectedTeam!.primaryNurseName,
                          icon: Icons.health_and_safety_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Team Members List
                  const Text('All Registered Team Members', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ..._selectedTeam!.members.map((member) => _buildMemberCard(member)),

                  const SizedBox(height: 20),

                  // Role Scoping & Privacy Enforcement Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.emeraldLight, size: 18),
                            SizedBox(width: 8),
                            Text('Strict Access & Security Scoping', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Field Nurses only receive schedules and vitals records for patients assigned to this care team.\n• Doctors review and approve symptom treatment plans for assigned home cases.\n• Social workers & volunteers have access restricted to social welfare and logistics.',
                          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
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

  Widget _buildLeadershipCard({
    required String title,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF132A2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(CareTeamMemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF132A2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: member.role.contains('Doctor')
                ? AppColors.emerald.withValues(alpha: 0.3)
                : member.role.contains('Nurse')
                    ? AppColors.secondary.withValues(alpha: 0.3)
                    : Colors.purple.withValues(alpha: 0.3),
            child: Icon(
              member.role.contains('Doctor')
                  ? Icons.medical_services_rounded
                  : member.role.contains('Nurse')
                      ? Icons.health_and_safety_rounded
                      : member.role.contains('Physio')
                          ? Icons.accessibility_new_rounded
                          : Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.memberName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (member.isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PRIMARY', style: TextStyle(color: AppColors.emeraldLight, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(member.role, style: const TextStyle(color: AppColors.emeraldLight, fontSize: 12)),
                const SizedBox(height: 2),
                Text(member.phone, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppColors.emeraldLight, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${member.memberName} (${member.phone})...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
