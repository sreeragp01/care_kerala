import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/services/network_database_service.dart';
import '../../../core/state/app_state_provider.dart';
import '../../network/screens/patient_live_queue_tracker_screen.dart';
import '../../network/screens/hospital_appointment_desk_screen.dart';

class PatientAppointmentCenterScreen extends StatefulWidget {
  final AppStateProvider state;

  const PatientAppointmentCenterScreen({super.key, required this.state});

  @override
  State<PatientAppointmentCenterScreen> createState() => _PatientAppointmentCenterScreenState();
}

class _PatientAppointmentCenterScreenState extends State<PatientAppointmentCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final todayList = widget.state.patientTodayAppointments;
        final upcomingList = widget.state.patientUpcomingAppointments;
        final pastList = widget.state.patientPastAppointments;
        final cancelledList = widget.state.patientCancelledAppointments;
        final noShowList = widget.state.patientNoShowAppointments;

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Appointment Center',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'CareLink Kerala • Smart OPD & Doctor Coordination',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Hospital Appointment Desk',
                icon: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primaryGreen),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HospitalAppointmentDeskScreen(state: widget.state),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Book Smart Slot',
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primaryGreen),
                onPressed: () => _openSmartSlotBookingBottomSheet(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primaryGreen,
              labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.today_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text("Today (${todayList.length})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.upcoming_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text("Upcoming (${upcomingList.length})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text("Past (${pastList.length})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text("Cancelled (${cancelledList.length})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_disabled_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text("No-Show (${noShowList.length})"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(todayList, isDark),
              _buildAppointmentListTab(upcomingList, isDark, emptyMessage: 'No upcoming appointments scheduled.'),
              _buildAppointmentListTab(pastList, isDark, emptyMessage: 'No past consultations found.', isPast: true),
              _buildAppointmentListTab(cancelledList, isDark, emptyMessage: 'No cancelled appointments.', isCancelled: true),
              _buildAppointmentListTab(noShowList, isDark, emptyMessage: 'No missed or no-show appointments.', isNoShow: true),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Book Appointment Slot', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openSmartSlotBookingBottomSheet(context),
          ),
        );
      },
    );
  }

  Widget _buildTodayTab(List<AppointmentRequestModel> todayList, bool isDark) {
    if (todayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available_rounded, size: 64, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
              const SizedBox(height: 16),
              const Text('No Appointments Scheduled for Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Book a 20-minute smart slot with a specialist doctor or check your upcoming schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => _openSmartSlotBookingBottomSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Book New Appointment'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Active Token Check-in Banner for the first today appointment
        _buildTodayHeroCard(todayList.first, isDark),
        const SizedBox(height: 16),
        if (todayList.length > 1) ...[
          const Text('Other Today Consultations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...todayList.skip(1).map((appt) => _buildAppointmentCard(appt, isDark)),
        ],
      ],
    );
  }

  Widget _buildTodayHeroCard(AppointmentRequestModel appt, bool isDark) {
    final isCheckedIn = appt.status == 'CHECKED_IN' || appt.status == 'IN_CONSULTATION';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F382A), const Color(0xFF062017)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record_rounded, size: 10, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "TODAY'S CONSULTATION",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.confirmation_number_rounded, size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      appt.tokenNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            appt.doctorName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${appt.doctorSpecialty} • ${appt.organizationName}',
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: _buildHeroMetric(Icons.access_time_rounded, 'Time Slot', appt.preferredTimeSlot.split('(').first.trim())),
                Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.3)),
                Expanded(child: _buildHeroMetric(Icons.room_rounded, 'Location', 'OPD Room 101')),
                Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.3)),
                Expanded(child: _buildHeroMetric(Icons.medical_services_outlined, 'Mode', appt.consultationMode.split(' ').first)),
              ],
            ),
          ),
          if (appt.isDoctorUnavailableFlagged) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Doctor is on leave for this slot. Hospital desk is reviewing substitute coverage or auto-rescheduling.',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                  ),
                  icon: const Icon(Icons.timeline_rounded, size: 18),
                  label: const Text('Status Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showStatusTimelineModal(context, appt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn ? const Color(0xFF0288D1) : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(isCheckedIn ? Icons.live_tv_rounded : Icons.login_rounded, size: 18),
                  label: Text(
                    isCheckedIn ? 'Live Queue Tracker' : 'Arrival Check-In',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (isCheckedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientLiveQueueTrackerScreen(),
                        ),
                      );
                    } else {
                      widget.state.deskCheckInAppointment(appt.id, notes: 'Patient checked in via mobile arrival portal.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Checked in successfully! You are now in the live OPD queue with Token ${appt.tokenNumber}.'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildAppointmentListTab(
    List<AppointmentRequestModel> list,
    bool isDark, {
    required String emptyMessage,
    bool isPast = false,
    bool isCancelled = false,
    bool isNoShow = false,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCancelled ? Icons.cancel_outlined : (isNoShow ? Icons.hourglass_disabled_rounded : Icons.calendar_today_outlined),
                size: 56,
                color: isDark ? AppColors.darkTextLight : AppColors.textLight,
              ),
              const SizedBox(height: 12),
              Text(emptyMessage, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        return _buildAppointmentCard(list[i], isDark, isPast: isPast, isCancelled: isCancelled, isNoShow: isNoShow);
      },
    );
  }

  Widget _buildAppointmentCard(
    AppointmentRequestModel appt,
    bool isDark, {
    bool isPast = false,
    bool isCancelled = false,
    bool isNoShow = false,
  }) {
    final statusColor = _getStatusColor(appt.status, isDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        '${appt.doctorName} • ${appt.doctorSpecialty}',
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      if (appt.substituteDoctorName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Substitute Specialist: ${appt.substituteDoctorName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0288D1), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    appt.statusDisplay,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.event_rounded, size: 15, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(appt.preferredDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 14),
                Icon(Icons.schedule_rounded, size: 15, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    appt.preferredTimeSlot,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (appt.tokenNumber.isNotEmpty && appt.tokenNumber != 'Pending') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Token: ${appt.tokenNumber}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ],
            ),
            if (appt.chiefComplaint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Complaint: "${appt.chiefComplaint}"',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ],
            if (appt.cancellationReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${appt.cancellationReason}',
                        style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (appt.hospitalNotes.isNotEmpty && !isCancelled) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${appt.hospitalNotes}',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Timeline', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showStatusTimelineModal(context, appt),
                ),
                if (!isPast && !isCancelled && !isNoShow) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Cancel', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showCancelDialog(context, appt),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                    label: const Text('Reschedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showRescheduleDialog(context, appt),
                  ),
                ],
                if (isCancelled || isNoShow) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 14),
                    label: const Text('Re-Book Slot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _openSmartSlotBookingBottomSheet(context),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        return isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
      case 'CHECKED_IN':
      case 'IN_CONSULTATION':
        return const Color(0xFF0288D1);
      case 'COMPLETED':
        return const Color(0xFF00897B);
      case 'RESCHEDULED':
        return const Color(0xFF8E24AA);
      case 'CANCELLED':
        return Colors.redAccent;
      case 'NO_SHOW':
        return Colors.deepOrange;
      default:
        return const Color(0xFFE65100);
    }
  }

  // ==========================================
  // SMART SLOT BOOKING BOTTOM SHEET
  // ==========================================
  void _openSmartSlotBookingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SmartSlotBookingSheet(state: widget.state),
    );
  }

  // ==========================================
  // RESCHEDULE APPOINTMENT DIALOG
  // ==========================================
  void _showRescheduleDialog(BuildContext context, AppointmentRequestModel appt) {
    final dateController = TextEditingController(text: appt.preferredDate);
    final reasonController = TextEditingController();
    String selectedSlot = '10:00 AM - 10:20 AM';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_calendar_rounded, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                const Text('Reschedule Appointment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient: ${appt.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Doctor: ${appt.doctorName} (${appt.doctorSpecialty})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  const Text('Select New Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                          dateController.text = picked.toString().split(' ').first;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Text(dateController.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Select New Slot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSlot,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: '09:00 AM - 09:20 AM', child: Text('09:00 AM - 09:20 AM (Morning)')),
                      DropdownMenuItem(value: '09:40 AM - 10:00 AM', child: Text('09:40 AM - 10:00 AM (Morning)')),
                      DropdownMenuItem(value: '10:00 AM - 10:20 AM', child: Text('10:00 AM - 10:20 AM (Morning)')),
                      DropdownMenuItem(value: '11:00 AM - 11:20 AM', child: Text('11:00 AM - 11:20 AM (Morning)')),
                      DropdownMenuItem(value: '04:00 PM - 04:20 PM', child: Text('04:00 PM - 04:20 PM (Evening)'))
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedSlot = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Reason for Rescheduling:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Transportation issue or medical reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                onPressed: () {
                  final reason = reasonController.text.trim().isNotEmpty
                      ? reasonController.text.trim()
                      : 'Rescheduled by patient request';
                  widget.state.rescheduleAppointment(appt.id, dateController.text, selectedSlot, reason);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment rescheduled to ${dateController.text} ($selectedSlot).'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                },
                child: const Text('Confirm Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CANCEL APPOINTMENT DIALOG
  // ==========================================
  void _showCancelDialog(BuildContext context, AppointmentRequestModel appt) {
    String selectedReason = 'Patient feeling better / issue resolved';
    final customReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Cancel Appointment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to cancel the appointment for ${appt.patientName} with ${appt.doctorName}?'),
                const SizedBox(height: 14),
                const Text('Reason for Cancellation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Patient feeling better / issue resolved', child: Text('Issue Resolved')),
                    DropdownMenuItem(value: 'Unable to travel due to weather / transport', child: Text('Travel / Transport Constraints')),
                    DropdownMenuItem(value: 'Consulted alternate local hospital', child: Text('Consulted Alternate Hospital')),
                    DropdownMenuItem(value: 'Personal / Family emergency', child: Text('Personal Emergency')),
                    DropdownMenuItem(value: 'Other', child: Text('Other Reason')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedReason = val);
                    }
                  },
                ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      hintText: 'Please specify reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: () {
                  final finalReason = selectedReason == 'Other' && customReasonController.text.trim().isNotEmpty
                      ? customReasonController.text.trim()
                      : selectedReason;
                  widget.state.cancelAppointment(appt.id, finalReason);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment successfully cancelled.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
                child: const Text('Confirm Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // STATUS TIMELINE MODAL
  // ==========================================
  void _showStatusTimelineModal(BuildContext context, AppointmentRequestModel appt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = appt.statusHistory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Appointment #${appt.id} Audit Timeline',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(
              'Patient: ${appt.patientName} • Token: ${appt.tokenNumber}',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const Divider(height: 24),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No historical status records available for this request.'),
              )
            else
              ...List.generate(history.length, (index) {
                final item = history[index];
                final isLast = index == history.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isLast ? AppColors.primaryGreen : Colors.grey.withOpacity(0.3),
                          child: Icon(
                            isLast ? Icons.check : Icons.circle,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 48,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.toStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isLast ? AppColors.primaryGreen : null,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  item.createdAt,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'By ${item.changedByUsername}',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '"${item.notes}"',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// SMART SLOT BOOKING BOTTOM SHEET COMPONENT
// =======================================================
class _SmartSlotBookingSheet extends StatefulWidget {
  final AppStateProvider state;

  const _SmartSlotBookingSheet({required this.state});

  @override
  State<_SmartSlotBookingSheet> createState() => _SmartSlotBookingSheetState();
}

class _SmartSlotBookingSheetState extends State<_SmartSlotBookingSheet> {
  late DoctorModel _selectedDoctor;
  late DateTime _selectedDate;
  AvailableSlotModel? _selectedSlot;
  String _consultationMode = 'In-Person Hospital OPD';
  String _bookingFor = 'Myself';
  late final TextEditingController _patientNameController;
  late final TextEditingController _phoneController;
  final _ageController = TextEditingController();
  final _complaintController = TextEditingController();

  late DoctorAvailableSlotsResponseModel _slotsResponse;

  @override
  void initState() {
    super.initState();
    _selectedDoctor = widget.state.doctors.first;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _patientNameController = TextEditingController(text: widget.state.currentUser.name);
    _phoneController = TextEditingController(text: widget.state.currentUser.phone);
    _refreshSlots();
  }

  void _refreshSlots() {
    _slotsResponse = NetworkDatabaseService.calculateSlotsForDoctor(
      doctor: _selectedDoctor,
      date: _selectedDate,
    );
    _selectedSlot = _slotsResponse.slots.where((s) => s.isAvailable).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Handle & Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  'Smart Doctor Slot Booking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Doctor Selector
                const Text('1. Select Doctor Specialist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<DoctorModel>(
                  value: _selectedDoctor,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primaryGreen),
                  ),
                  items: widget.state.doctors.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(
                        '${d.name} (${d.specialty})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDoctor = val;
                        _refreshSlots();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. Horizontal Date Selector
                const Text('2. Select Consultation Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    itemBuilder: (ctx, idx) {
                      final d = DateTime.now().add(Duration(days: idx));
                      final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
                      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = d;
                            _refreshSlots();
                          });
                        },
                        child: Container(
                          width: 64,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : (isDark ? AppColors.darkSurfaceLight : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGreen : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayNames[d.weekday - 1],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Doctor Availability & Slot Capacity Warning
                if (!_slotsResponse.isWorkingDay || !_slotsResponse.isAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _slotsResponse.availabilityReason,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Available Slots Matrix
                Text(
                  '3. Choose 20-Minute Time Slot (${_slotsResponse.availableSlotsCount} available)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (_slotsResponse.slots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No slots scheduled for this date. Please pick another day.'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slotsResponse.slots.map((slot) {
                      final isSelected = _selectedSlot?.slotId == slot.slotId;
                      final isAvail = slot.isAvailable;

                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: isAvail
                            ? (val) {
                                setState(() {
                                  _selectedSlot = slot;
                                });
                              }
                            : null,
                        label: Text(slot.slotLabel),
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: isAvail
                            ? (isDark ? AppColors.darkSurfaceLight : Colors.white)
                            : (isDark ? Colors.grey[900] : Colors.grey[200]),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : (isAvail ? null : Colors.grey),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // 4. Consultation Mode
                const Text('4. Consultation Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildModeChip('In-Person Hospital OPD', Icons.local_hospital_rounded),
                    _buildModeChip('Telemedicine Video', Icons.videocam_rounded),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Patient Details & Booking For Selector
                const Text('5. Who is this Consultation for?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Myself',
                      'Daughter',
                      'Son',
                      'Mother',
                      'Father',
                      'Spouse',
                      'Other Family',
                    ].map((relation) {
                      final isSelected = _bookingFor == relation;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            relation == 'Myself' ? 'Myself (${widget.state.currentUser.name})' : relation,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryGreen,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _bookingFor = relation;
                                if (relation == 'Myself') {
                                  _patientNameController.text = widget.state.currentUser.name;
                                  _phoneController.text = widget.state.currentUser.phone;
                                } else {
                                  _patientNameController.text = '';
                                }
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _patientNameController,
                  decoration: InputDecoration(
                    labelText: _bookingFor == 'Myself' ? 'Patient Full Name' : '$_bookingFor\'s Full Name *',
                    hintText: _bookingFor == 'Myself' ? widget.state.currentUser.name : 'Enter $_bookingFor\'s Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                if (_bookingFor != 'Myself') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age (Years)',
                            hintText: 'e.g. 14',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            prefixIcon: const Icon(Icons.cake_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Contact / Parent Phone',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _complaintController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Chief Complaint / Health Issue',
                    hintText: 'e.g., Spine pain follow-up, pediatric fever, BP check',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm Booking Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _selectedSlot == null || !_slotsResponse.isAvailable
                      ? null
                      : () {
                          final enteredName = _patientNameController.text.trim();
                          final patientDisplayName = _bookingFor == 'Myself'
                              ? (enteredName.isNotEmpty ? enteredName : widget.state.currentUser.name)
                              : '${enteredName.isNotEmpty ? enteredName : "Family Member"} ($_bookingFor of ${widget.state.currentUser.name})';

                          final ageInfo = _ageController.text.trim().isNotEmpty ? 'Age: ${_ageController.text.trim()}y' : '';
                          final complaintWithAge = [
                            if (ageInfo.isNotEmpty) ageInfo,
                            if (_complaintController.text.trim().isNotEmpty) _complaintController.text.trim(),
                          ].join(' • ');

                          final newAppt = AppointmentRequestModel(
                            id: 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            organizationId: _selectedDoctor.organizationId,
                            organizationName: _selectedDoctor.organizationName,
                            doctorId: _selectedDoctor.id,
                            doctorName: _selectedDoctor.name,
                            doctorSpecialty: _selectedDoctor.specialty,
                            patientName: patientDisplayName,
                            patientPhone: _phoneController.text.trim(),
                            preferredDate: _selectedDate.toString().split(' ').first,
                            preferredTimeSlot: _selectedSlot!.slotLabel,
                            consultationMode: _consultationMode,
                            chiefComplaint: complaintWithAge,
                            status: 'CONFIRMED',
                            statusDisplay: 'Confirmed & Token Issued',
                            tokenNumber: 'TK-${widget.state.appointmentRequests.length + 15}',
                            hospitalNotes: 'Booked for $_bookingFor via smart slot engine for Room ${_selectedSlot!.roomNumber}.',
                            statusHistory: [
                              AppointmentStatusHistoryModel(
                                id: 'H-${DateTime.now().millisecondsSinceEpoch}',
                                fromStatus: 'NONE',
                                toStatus: 'CONFIRMED',
                                changedByUsername: widget.state.currentUser.name,
                                notes: 'Dynamic slot booked for $patientDisplayName at ${_selectedSlot!.slotLabel}',
                                createdAt: DateTime.now().toString().split('.').first,
                              ),
                            ],
                          );

                          widget.state.bookDoctorSmartAppointment(newAppt);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Appointment confirmed! Token ${newAppt.tokenNumber} generated for $patientDisplayName.'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                  child: const Text(
                    'Confirm & Generate Token',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, IconData icon) {
    final isSelected = _consultationMode == mode;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _consultationMode = mode);
      },
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primaryGreen),
      label: Text(mode),
      selectedColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
