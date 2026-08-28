import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';

class BloodDonorDirectoryScreen extends StatefulWidget {
  final AppStateProvider state;

  const BloodDonorDirectoryScreen({super.key, required this.state});

  @override
  State<BloodDonorDirectoryScreen> createState() => _BloodDonorDirectoryScreenState();
}

class _BloodDonorDirectoryScreenState extends State<BloodDonorDirectoryScreen> {
  String _selectedGroup = 'All';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final donors = widget.state.bloodDonors.where((d) {
          if (_selectedGroup == 'All') return true;
          return d.bloodGroup == _selectedGroup;
        }).toList();

        final activeRequests = widget.state.bloodRequests;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Blood Donor Directory'),
            actions: [
              IconButton(
                icon: Icon(Icons.person_add_alt_1_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                onPressed: () => _showRegisterDonorDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Emergency Requests Banner Card
              if (activeRequests.isNotEmpty)
                Container(
                  color: isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: activeRequests.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'EMERGENCY: ${req.unitsNeeded} units ${req.bloodGroup} at ${req.hospitalName}!',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.danger),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              widget.state.createEmergencyBloodRequest(req);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Notify', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),

              // Filter Bar
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+'].map((group) {
                      final isSelected = _selectedGroup == group;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(group),
                          selected: isSelected,
                          selectedColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                          onSelected: (_) => setState(() => _selectedGroup = group),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),

              // Donor List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: donors.length,
                  itemBuilder: (ctx, i) {
                    final donor = donors[i];
                    final isEligible = donor.isEligible;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isEligible
                                      ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                                      : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                                  child: Text(
                                    donor.bloodGroup,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isEligible
                                          ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(donor.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${donor.locality}, ${donor.district}',
                                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isEligible
                                        ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                                        : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isEligible ? 'Eligible' : '${donor.daysRemaining}d wait',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isEligible
                                          ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.history_rounded, size: 15, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${donor.totalDonations} donations',
                                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.phone_outlined, size: 15, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      donor.phone,
                                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => widget.state.recordDonation(donor.id),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Record Donation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.danger,
            onPressed: () => _showEmergencyRequestDialog(context),
            icon: const Icon(Icons.emergency_rounded, color: Colors.white),
            label: const Text('Post Emergency Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  void _showRegisterDonorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Register Blood Donor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Donor Full Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                widget.state.registerBloodDonor(
                  BloodDonorModel(
                    id: 'DON-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    name: nameCtrl.text.trim(),
                    bloodGroup: 'O+',
                    district: widget.state.currentUser.district,
                    locality: 'Kozhikode City',
                    phone: phoneCtrl.text.isEmpty ? '+91 98470 99999' : phoneCtrl.text.trim(),
                    lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
                    totalDonations: 1,
                    isAvailable: true,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Register Donor'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyRequestDialog(BuildContext context) {
    final patientCtrl = TextEditingController(text: 'Urgent Care Patient');
    final hospitalCtrl = TextEditingController(text: 'Kozhikode Govt Medical College');
    String bloodGroup = 'O+';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Create Emergency Blood Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: patientCtrl, decoration: const InputDecoration(labelText: 'Patient / Case Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 10),
                TextField(controller: hospitalCtrl, decoration: const InputDecoration(labelText: 'Hospital Name & Ward', prefixIcon: Icon(Icons.local_hospital_outlined))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: bloodGroup,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Blood Group Required'),
                  items: ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+'].map((bg) => DropdownMenuItem(value: bg, child: Text(bg, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => bloodGroup = val!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              widget.state.createEmergencyBloodRequest(
                BloodRequestModel(
                  id: 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  patientName: patientCtrl.text.trim(),
                  bloodGroup: bloodGroup,
                  hospitalName: hospitalCtrl.text.trim(),
                  district: widget.state.currentUser.district,
                  unitsNeeded: 2,
                  urgency: 'Emergency',
                  requestedDate: '2026-08-06',
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Send Emergency Alerts'),
          ),
        ],
      ),
    );
  }
}
