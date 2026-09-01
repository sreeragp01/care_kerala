import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import 'queue_management_screen.dart';
import 'hospital_queue_analytics_screen.dart';

class HospitalAppointmentDeskScreen extends StatefulWidget {
  final AppStateProvider state;

  const HospitalAppointmentDeskScreen({super.key, required this.state});

  @override
  State<HospitalAppointmentDeskScreen> createState() => _HospitalAppointmentDeskScreenState();
}

class _HospitalAppointmentDeskScreenState extends State<HospitalAppointmentDeskScreen> {
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';
  String? _selectedDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final allAppts = widget.state.appointmentRequests;

        // Metric calculations
        final pendingCount = allAppts.where((a) => a.status == 'REQUESTED').length;
        final confirmedCount = allAppts.where((a) => a.status == 'CONFIRMED' || a.status == 'ACCEPTED').length;
        final checkedInCount = allAppts.where((a) => a.status == 'CHECKED_IN' || a.status == 'IN_CONSULTATION').length;
        final completedCount = allAppts.where((a) => a.status == 'COMPLETED').length;
        final flaggedLeaveAppts = allAppts.where((a) => a.isDoctorUnavailableFlagged).toList();

        // Filtered list
        final filteredAppts = widget.state.getDeskAppointments(
          statusFilter: _selectedStatusFilter,
          query: _searchQuery,
          date: _selectedDate,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital Appointment Desk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  'Live OPD Intake, Tokens & Doctor Exception Resolution',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Multi-Queue Management Desk',
                icon: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF38BDF8)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QueueManagementScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Patient Flow Analytics',
                icon: const Icon(Icons.analytics_rounded, color: Color(0xFF34D399)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HospitalQueueAnalyticsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Mark Doctor Leave Exception',
                icon: const Icon(Icons.event_busy_rounded, color: Colors.amber),
                onPressed: () => _openMarkDoctorLeaveDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Top Operational Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMetricCard('Pending Requests', pendingCount, Colors.amber, isDark, () {
                        setState(() => _selectedStatusFilter = 'REQUESTED');
                      }),
                      const SizedBox(width: 8),
                      _buildMetricCard('Confirmed / Token Issued', confirmedCount, AppColors.primaryGreen, isDark, () {
                        setState(() => _selectedStatusFilter = 'CONFIRMED');
                      }),
                      const SizedBox(width: 8),
                      _buildMetricCard('Checked In / In OPD', checkedInCount, const Color(0xFF0288D1), isDark, () {
                        setState(() => _selectedStatusFilter = 'CHECKED_IN');
                      }),
                      const SizedBox(width: 8),
                      _buildMetricCard('Completed Consultations', completedCount, const Color(0xFF00897B), isDark, () {
                        setState(() => _selectedStatusFilter = 'COMPLETED');
                      }),
                      if (flaggedLeaveAppts.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildMetricCard('Doctor Leave Flagged', flaggedLeaveAppts.length, Colors.redAccent, isDark, () {
                          setState(() => _selectedStatusFilter = 'FLAGGED_LEAVE');
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              // 2. Doctor Leave Impact Alert Banner
              if (flaggedLeaveAppts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.red.withOpacity(0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${flaggedLeaveAppts.length} appointments affected by Doctor Leave exceptions.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                        label: const Text('1-Click Bulk Resolve'),
                        onPressed: () => _openBulkLeaveResolutionModal(context, flaggedLeaveAppts),
                      ),
                    ],
                  ),
                ),
              ],

              // 3. Search and Date Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search patient name, phone, doctor, or token...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedDate != null,
                      avatar: const Icon(Icons.date_range_rounded, size: 16),
                      label: Text(_selectedDate ?? 'All Dates'),
                      onSelected: (val) async {
                        if (_selectedDate != null) {
                          setState(() => _selectedDate = null);
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked.toString().split(' ').first);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 4. Status Filter Horizontal Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('ALL', 'All (${allAppts.length})'),
                    _buildFilterChip('REQUESTED', 'Pending ($pendingCount)'),
                    _buildFilterChip('CONFIRMED', 'Confirmed ($confirmedCount)'),
                    _buildFilterChip('CHECKED_IN', 'Checked In ($checkedInCount)'),
                    _buildFilterChip('COMPLETED', 'Completed ($completedCount)'),
                    if (flaggedLeaveAppts.isNotEmpty)
                      _buildFilterChip('FLAGGED_LEAVE', 'Flagged Leave (${flaggedLeaveAppts.length})'),
                    _buildFilterChip('RESCHEDULED', 'Rescheduled'),
                    _buildFilterChip('CANCELLED', 'Cancelled'),
                    _buildFilterChip('NO_SHOW', 'No-Show'),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 5. Appointments List
              Expanded(
                child: filteredAppts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 54, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                            const SizedBox(height: 12),
                            const Text('No matching appointments found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAppts.length,
                        itemBuilder: (ctx, i) => _buildDeskAppointmentCard(filteredAppts[i], isDark),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, int count, Color color, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppColors.primaryGreen,
        onSelected: (val) {
          if (val) setState(() => _selectedStatusFilter = key);
        },
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildDeskAppointmentCard(AppointmentRequestModel appt, bool isDark) {
    final isPending = appt.status == 'REQUESTED';
    final isConfirmed = appt.status == 'CONFIRMED' || appt.status == 'ACCEPTED';
    final isCheckedIn = appt.status == 'CHECKED_IN';
    final isFlagged = appt.isDoctorUnavailableFlagged;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFlagged
            ? const BorderSide(color: Colors.redAccent, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Text('(${appt.patientAge}y, ${appt.patientGender})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phone: ${appt.patientPhone} • ${appt.district}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Doctor: ${appt.doctorName} (${appt.doctorSpecialty})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (appt.substituteDoctorName.isNotEmpty) ...[
                        Text(
                          'Covered by: ${appt.substituteDoctorName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0288D1), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getDeskStatusColor(appt.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getDeskStatusColor(appt.status).withOpacity(0.3)),
                      ),
                      child: Text(
                        appt.statusDisplay,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getDeskStatusColor(appt.status)),
                      ),
                    ),
                    if (appt.tokenNumber.isNotEmpty && appt.tokenNumber != 'Pending') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Token: ${appt.tokenNumber}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(appt.preferredDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 14),
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(appt.preferredTimeSlot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  appt.consultationMode,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
            if (appt.chiefComplaint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Complaint: "${appt.chiefComplaint}"',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
            if (isFlagged) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.redAccent, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Flagged: Doctor on leave for this schedule.',
                        style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Desk Actions Toolbar
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (isPending) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('Accept Request'),
                    onPressed: () {
                      widget.state.deskAcceptAppointment(appt.id, notes: 'Accepted by Hospital Desk');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Accepted appointment for ${appt.patientName}.')),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Reject'),
                    onPressed: () => _showRejectDialog(context, appt),
                  ),
                ],
                if (isConfirmed) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 14),
                    label: const Text('Check-In Patient'),
                    onPressed: () {
                      widget.state.deskCheckInAppointment(appt.id, notes: 'Patient checked in at hospital intake.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Checked-in ${appt.patientName} into live queue.')),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    icon: const Icon(Icons.person_off_rounded, size: 14),
                    label: const Text('Mark No-Show'),
                    onPressed: () {
                      widget.state.deskMarkNoShowAppointment(appt.id, notes: 'Patient missed scheduled time window.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked ${appt.patientName} as No-Show.')),
                      );
                    },
                  ),
                ],
                if (isCheckedIn) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 14),
                    label: const Text('Complete Consultation'),
                    onPressed: () {
                      widget.state.deskCompleteAppointment(appt.id, notes: 'Consultation concluded by doctor.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Completed consultation for ${appt.patientName}.')),
                      );
                    },
                  ),
                ],
                if (isFlagged) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                    label: const Text('Resolve Leave'),
                    onPressed: () => _openBulkLeaveResolutionModal(context, [appt]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDeskStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        return AppColors.primaryGreen;
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
        return Colors.amber;
    }
  }

  // ==========================================
  // REJECT REQUEST DIALOG
  // ==========================================
  void _showRejectDialog(BuildContext context, AppointmentRequestModel appt) {
    final reasonController = TextEditingController(text: 'Doctor schedule full / Emergency surgery');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Appointment Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject appointment for ${appt.patientName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (will be sent to patient via SMS)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              widget.state.deskRejectAppointment(appt.id, reason: reasonController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Appointment rejected for ${appt.patientName}.')),
              );
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MARK DOCTOR LEAVE DIALOG
  // ==========================================
  void _openMarkDoctorLeaveDialog(BuildContext context) {
    DoctorModel selectedDoc = widget.state.doctors.first;
    DateTime selectedLeaveDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController(text: 'National Medical Conference Attendance');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Mark Doctor Leave', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Doctor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<DoctorModel>(
                  value: selectedDoc,
                  isExpanded: true,
                  items: widget.state.doctors.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedDoc = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Leave Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedLeaveDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedLeaveDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(selectedLeaveDate.toString().split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Leave Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Emergency Duty or Medical Leave',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
              onPressed: () {
                final dateStr = selectedLeaveDate.toString().split(' ').first;
                widget.state.markDoctorLeaveAndFlagAppointments(
                  selectedDoc.id,
                  selectedDoc.name,
                  dateStr,
                  reasonController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Doctor leave logged for ${selectedDoc.name} on $dateStr. Affected appointments flagged.'),
                    backgroundColor: Colors.amber[900],
                  ),
                );
              },
              child: const Text('Save & Flag Appointments'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BULK DOCTOR LEAVE RESOLUTION MODAL
  // ==========================================
  void _openBulkLeaveResolutionModal(BuildContext context, List<AppointmentRequestModel> affectedAppts) {
    String resolutionAction = 'REASSIGN_SUBSTITUTE';
    DoctorModel substituteDoc = widget.state.doctors.length > 1 ? widget.state.doctors[1] : widget.state.doctors.first;
    DateTime newRescheduleDate = DateTime.now().add(const Duration(days: 4));
    final notesController = TextEditingController(text: 'Assigned to Senior Specialist');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high_rounded, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resolve ${affectedAppts.length} Affected Appointments',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              const Divider(),
              const Text('1. Select Resolution Strategy:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Reassign to Substitute Doctor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Transfers patients to on-duty specialist with same token order.', style: TextStyle(fontSize: 11)),
                value: 'REASSIGN_SUBSTITUTE',
                groupValue: resolutionAction,
                onChanged: (val) => setModalState(() => resolutionAction = val!),
              ),
              RadioListTile<String>(
                title: const Text('Auto-Reschedule to Next Available OPD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Shifts all appointments to new date and sends push notification.', style: TextStyle(fontSize: 11)),
                value: 'RESCHEDULE',
                groupValue: resolutionAction,
                onChanged: (val) => setModalState(() => resolutionAction = val!),
              ),
              RadioListTile<String>(
                title: const Text('Cancel Appointments with Notice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Cancels slots and triggers automated SMS/CareLink refund/notice.', style: TextStyle(fontSize: 11)),
                value: 'CANCEL',
                groupValue: resolutionAction,
                onChanged: (val) => setModalState(() => resolutionAction = val!),
              ),
              const SizedBox(height: 10),

              if (resolutionAction == 'REASSIGN_SUBSTITUTE') ...[
                const Text('Select Substitute Doctor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<DoctorModel>(
                  value: substituteDoc,
                  isExpanded: true,
                  items: widget.state.doctors.map((d) {
                    return DropdownMenuItem(value: d, child: Text('${d.name} (${d.specialty})', overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => substituteDoc = val);
                  },
                ),
              ] else if (resolutionAction == 'RESCHEDULE') ...[
                const Text('Select Rescheduled Target Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: newRescheduleDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) setModalState(() => newRescheduleDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(newRescheduleDate.toString().split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Resolution Notes / SMS Notification:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Execute Resolution for ${affectedAppts.length} Patients',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    widget.state.resolveDoctorLeaveImpact(
                      appointmentIds: affectedAppts.map((a) => a.id).toList(),
                      action: resolutionAction,
                      substituteDoctorName: substituteDoc.name,
                      newDate: newRescheduleDate.toString().split(' ').first,
                      notes: notesController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully resolved ${affectedAppts.length} appointments via $resolutionAction.'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
