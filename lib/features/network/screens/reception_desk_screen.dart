import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

class ReceptionDeskScreen extends StatefulWidget {
  final String hospitalName;

  const ReceptionDeskScreen({
    super.key,
    this.hospitalName = 'Calicut Medical Center',
  });

  @override
  State<ReceptionDeskScreen> createState() => _ReceptionDeskScreenState();
}

class _ReceptionDeskScreenState extends State<ReceptionDeskScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _todayAppointments = [
    {'id': 'APP-101', 'name': 'Rahul Narayanan', 'phone': '+919876543210', 'doctor': 'Dr. Priya Varma (Cardiology)', 'time': '10:00 AM', 'status': 'IN_CONSULTATION', 'token': 'A-18'},
    {'id': 'APP-102', 'name': 'Fatima Zahra', 'phone': '+919876543211', 'doctor': 'Dr. Priya Varma (Cardiology)', 'time': '10:20 AM', 'status': 'WAITING', 'token': 'A-19'},
    {'id': 'APP-103', 'name': 'George Joseph', 'phone': '+919876543212', 'doctor': 'Dr. Priya Varma (Cardiology)', 'time': '10:40 AM', 'status': 'WAITING', 'token': 'A-20'},
    {'id': 'APP-104', 'name': 'Ananya Das', 'phone': '+919876543215', 'doctor': 'Dr. Narayanan Kutty (Oncology)', 'time': '11:00 AM', 'status': 'CONFIRMED', 'token': 'B-04'},
    {'id': 'APP-105', 'name': 'K. Balakrishnan', 'phone': '+919876543216', 'doctor': 'Dr. Narayanan Kutty (Oncology)', 'time': '11:30 AM', 'status': 'CONFIRMED', 'token': 'B-05'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showIssueTokenModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedDoctor = 'Dr. Priya Varma (Cardiology)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Issue Walk-in OPD Token', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Instant token generation for unregistered walk-in patients', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Patient Full Name', hintText: 'e.g. Sreedharan Nair')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Phone Number', hintText: '+919876543210')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDoctor,
                items: const [
                  DropdownMenuItem(value: 'Dr. Priya Varma (Cardiology)', child: Text('Dr. Priya Varma (Cardiology)')),
                  DropdownMenuItem(value: 'Dr. Narayanan Kutty (Oncology)', child: Text('Dr. Narayanan Kutty (Oncology)')),
                  DropdownMenuItem(value: 'Dr. K. Mathew (Palliative Care)', child: Text('Dr. K. Mathew (Palliative Care)')),
                ],
                onChanged: (v) => setModalState(() => selectedDoctor = v!),
                decoration: const InputDecoration(labelText: 'Consulting Doctor / OPD'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal, minimumSize: const Size(double.infinity, 46)),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    setState(() {
                      _todayAppointments.add({
                        'id': 'APP-${_todayAppointments.length + 101}',
                        'name': nameCtrl.text,
                        'phone': phoneCtrl.text,
                        'doctor': selectedDoctor,
                        'time': 'Walk-in',
                        'status': 'WAITING',
                        'token': 'A-${_todayAppointments.length + 1}',
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.brandTeal,
                        content: Text('Walk-in Token A-${_todayAppointments.length} issued for ${nameCtrl.text}!'),
                      ),
                    );
                  }
                },
                child: const Text('Generate Token & Print Slip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkInAppointment(Map<String, dynamic> appt) {
    setState(() {
      appt['status'] = 'WAITING';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.brandHealthGreen,
        content: Text('Patient ${appt['name']} checked in. Token ${appt['token']} added to live queue!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reception & Token Desk', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.hospitalName, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined, color: AppColors.brandTeal),
            tooltip: 'Issue Walk-in Token',
            onPressed: _showIssueTokenModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics
            Row(
              children: [
                Expanded(child: _statCard('Appointments', '${_todayAppointments.length}', AppColors.brandNavy, isDark)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Checked-In', '${_todayAppointments.where((a) => a['status'] != 'CONFIRMED').length}', AppColors.brandTeal, isDark)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Waiting', '${_todayAppointments.where((a) => a['status'] == 'WAITING').length}', Colors.orange, isDark)),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Issue Token Action
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by patient name, phone, or token...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text('Walk-in Token', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _showIssueTokenModal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Department Queue Stations
            Text('Department OPD Queues', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildDepartmentCard('Cardiology OPD • Room 102', 'Dr. Priya Varma', 'Now Serving: A-18', 'Waiting: 4', AppColors.brandTeal, isDark),
            _buildDepartmentCard('Oncology OPD • Room 105', 'Dr. Narayanan Kutty', 'Now Serving: B-02', 'Waiting: 3', Colors.purple, isDark),
            _buildDepartmentCard('Palliative Care Desk • Room 108', 'Dr. K. Mathew', 'Now Serving: P-01', 'Waiting: 1', AppColors.brandHealthGreen, isDark),
            const SizedBox(height: 20),

            // Today's Patient Appointment & Token Roster
            Text('Today\'s Appointments & Arrivals', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._todayAppointments.map((appt) => _appointmentRow(appt, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(String dept, String doctor, String serving, String waiting, Color color, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.local_hospital_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(doctor, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(serving, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
              const SizedBox(height: 2),
              Text(waiting, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appointmentRow(Map<String, dynamic> appt, bool isDark) {
    final isConfirmed = appt['status'] == 'CONFIRMED';
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(appt['token'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.brandTeal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${appt['doctor']} • Slot: ${appt['time']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (isConfirmed)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandHealthGreen,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => _checkInAppointment(appt),
              child: const Text('Check-In', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appt['status'] == 'IN_CONSULTATION'
                    ? AppColors.brandHealthGreen.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                appt['status'] == 'IN_CONSULTATION' ? 'In Consultation' : 'Waiting Queue',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: appt['status'] == 'IN_CONSULTATION' ? AppColors.brandHealthGreen : Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
