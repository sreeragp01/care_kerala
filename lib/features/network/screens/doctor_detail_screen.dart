import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorModel doctor;
  final AppStateProvider state;

  const DoctorDetailScreen({super.key, required this.doctor, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final isDark = state.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            title: Text(
              doctor.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Hero Profile Card
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
                            child: Text(
                              doctor.name.split(' ').length > 1 ? doctor.name.split(' ')[1][0] : 'D',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.brandTeal),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doctor.name,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.verified_rounded, size: 18, color: AppColors.brandHealthGreen),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doctor.qualification,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandTeal),
                                ),
                                Text(
                                  '${doctor.specialty} • ${doctor.designation}',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      // Medical Council Registration & Experience Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProfileStat('Experience', '${doctor.experienceYears} Years', Icons.history_edu_rounded, isDark),
                          _buildProfileStat('Council Reg', doctor.registrationNumber, Icons.verified_user_rounded, isDark),
                          _buildProfileStat('Languages', doctor.languages.split(',').first, Icons.language_rounded, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hospital Affiliation
                _buildSectionTitle('Hospital Affiliation', isDark),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_rounded, color: AppColors.brandNavy, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.organizationName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${doctor.district}, Kerala • Mode: ${doctor.consultationMode}',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Weekly Consultation Schedule & Timetable
                _buildSectionTitle('Consultation Hours & OPD Timetable', isDark),
                const SizedBox(height: 8),
                if (doctor.schedules.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No consultation hours currently scheduled for this doctor.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...doctor.schedules.map((sch) => _buildScheduleCard(sch, isDark)),
                const SizedBox(height: 16),

                // Doctor Biography
                if (doctor.biography.isNotEmpty) ...[
                  _buildSectionTitle('About Doctor', isDark),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      doctor.biography,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Consultation Fee & Direct Request Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Mode',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            Text(
                              doctor.consultationFee > 0 ? '₹${doctor.consultationFee.toInt()} / session' : 'Free / Trust Supported',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: doctor.consultationFee == 0 ? AppColors.brandHealthGreen : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAppointmentBottomSheet(context, isDark),
                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                        label: const Text('Request Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.brandTeal),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(DoctorScheduleModel sch, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Icon(Icons.event_available_rounded, size: 16, color: AppColors.brandTeal),
                const SizedBox(height: 2),
                Text(
                  sch.dayOfWeek.length > 3 ? sch.dayOfWeek.substring(0, 3) : sch.dayOfWeek,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandTeal),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sch.startTime} - ${sch.endTime}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${sch.consultationType} • ${sch.locationRoom}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandHealthGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Active',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen),
            ),
          ),
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

  void _showAppointmentBottomSheet(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final complaintController = TextEditingController();
    String selectedMode = 'In-Person Hospital OPD';
    String selectedSlot = 'Morning (09:00 AM - 01:00 PM)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Consultation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'with ${doctor.name}',
                              style: const TextStyle(fontSize: 12, color: AppColors.brandTeal, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Patient Full Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSlot,
                      decoration: const InputDecoration(
                        labelText: 'Preferred OPD Slot',
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Morning (09:00 AM - 01:00 PM)', child: Text('Morning (09:00 AM - 01:00 PM)')),
                        DropdownMenuItem(value: 'Evening (04:00 PM - 07:00 PM)', child: Text('Evening (04:00 PM - 07:00 PM)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSlot = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Consultation Mode',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'In-Person Hospital OPD', child: Text('In-Person Hospital OPD')),
                        DropdownMenuItem(value: 'Telemedicine Video Consultation', child: Text('Telemedicine Video Consultation')),
                        DropdownMenuItem(value: 'Palliative Home Care Visit', child: Text('Palliative Home Care Visit')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedMode = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: complaintController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Brief Symptoms / Chief Complaint',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty && phoneController.text.trim().isNotEmpty) {
                          final appointment = AppointmentRequestModel(
                            id: 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            patientName: nameController.text.trim(),
                            patientPhone: phoneController.text.trim(),
                            doctorName: doctor.name,
                            doctorSpecialty: doctor.specialty,
                            preferredDate: DateTime.now().add(const Duration(days: 2)).toString().split(' ').first,
                            preferredTimeSlot: selectedSlot,
                            consultationMode: selectedMode,
                            chiefComplaint: complaintController.text.trim(),
                            status: 'REQUESTED',
                            tokenNumber: 'TK-05',
                          );
                          state.requestDoctorAppointment(appointment);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.brandHealthGreen,
                              content: Text('Appointment requested for ${nameController.text}. Token #TK-05 issued pending confirmation.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandNavy,
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      child: const Text('Confirm Appointment Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
