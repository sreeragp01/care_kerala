import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';

class AppointmentsScreen extends StatelessWidget {
  final AppStateProvider state;

  const AppointmentsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final appointments = state.appointments;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Doctor Appointments'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryGreen),
                onPressed: () => _showBookAppointmentDialog(context),
              ),
            ],
          ),
          body: appointments.isEmpty
              ? const Center(child: Text('No appointments booked yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (ctx, i) {
                    final apt = appointments[i];
                    final isConfirmed = apt.status == 'Confirmed';
                    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                                  backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(apt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Doctor: ${apt.doctorName}',
                                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${apt.date} at ${apt.time} • ${apt.type}',
                                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isConfirmed
                                        ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                                        : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSand),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    apt.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isConfirmed
                                          ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isConfirmed) ...[
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => state.updateAppointmentStatus(apt.id, 'Cancelled'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(color: AppColors.danger),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => state.updateAppointmentStatus(apt.id, 'Completed'),
                                    icon: const Icon(Icons.check_circle_outline, size: 14),
                                    label: const Text('Mark Completed', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            onPressed: () => _showBookAppointmentDialog(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showBookAppointmentDialog(BuildContext context) {
    final patientCtrl = TextEditingController(text: 'Karthyayani Amma');
    final doctorCtrl = TextEditingController(text: 'Dr. Suresh Kumar');
    String appointmentType = 'Home Consultation';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: const Text('Schedule Doctor Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: patientCtrl,
                  decoration: const InputDecoration(labelText: 'Patient Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: doctorCtrl,
                  decoration: const InputDecoration(labelText: 'Palliative Doctor Name', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: appointmentType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Consultation Type'),
                  items: ['Home Consultation', 'Clinic Consultation', 'Tele-Consultation'].map((type) => DropdownMenuItem(value: type, child: Text(type, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => appointmentType = val!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (patientCtrl.text.isNotEmpty) {
                state.addAppointment(
                  AppointmentModel(
                    id: 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    patientName: patientCtrl.text.trim(),
                    doctorName: doctorCtrl.text.trim(),
                    date: '2026-08-10',
                    time: '10:30 AM',
                    type: appointmentType,
                    status: 'Confirmed',
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Confirm Appointment'),
          ),
        ],
      ),
    );
  }
}
