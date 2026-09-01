import 'package:flutter/material.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/network_models.dart';

class AppointmentQrCheckinScreen extends StatefulWidget {
  final AppointmentRequestModel appointment;
  final AppStateProvider? state;

  const AppointmentQrCheckinScreen({super.key, required this.appointment, this.state});

  @override
  State<AppointmentQrCheckinScreen> createState() => _AppointmentQrCheckinScreenState();
}

class _AppointmentQrCheckinScreenState extends State<AppointmentQrCheckinScreen> {
  bool _isCheckingIn = false;
  PatientCheckInResultModel? _checkInResult;
  late AppStateProvider _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.state ?? AppStateProvider();
  }

  void _handleSimulatedKioskScan() {
    setState(() {
      _isCheckingIn = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        final result = _appState.performDigitalCheckIn(
          appointmentId: widget.appointment.id,
          qrHash: 'QR-APPT-${widget.appointment.id}-${widget.appointment.patientPhone.hashCode}',
        );

        setState(() {
          _isCheckingIn = false;
          _checkInResult = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arrival verified! Assigned ${result.tokenLabel} • Proceed to ${result.roomNumber}'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final appt = widget.appointment;
        final isCheckedIn = _checkInResult != null || appt.status == 'CHECKED_IN' || appt.status == 'IN_CONSULTATION';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            title: const Text('Digital OPD Pass & Check-In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Patient & Doctor Pass Card
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pass Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isCheckedIn ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCheckedIn ? Icons.verified_user_rounded : Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCheckedIn ? 'CHECKED-IN & QUEUED' : 'OFFICIAL OPD ENTRY PASS',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                                  ),
                                  Text(
                                    appt.organizationName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                appt.tokenNumber,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // QR Code Visual Box
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Stylized QR Matrix Simulation
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        crossAxisSpacing: 3,
                                        mainAxisSpacing: 3,
                                      ),
                                      itemCount: 49,
                                      itemBuilder: (context, index) {
                                        // Corner markers
                                        final isCorner = (index < 3 || (index >= 4 && index <= 6) || index == 7 || index == 13 || index == 14 || index == 20) ||
                                            (index >= 35 && index <= 37) ||
                                            index == 42 ||
                                            index == 48;
                                        final isPattern = (index * 7 + 13) % 3 == 0 || isCorner;
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isPattern ? Colors.black : Colors.white,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (isCheckedIn)
                                    Container(
                                      width: 190,
                                      height: 190,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669).withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 64),
                                          SizedBox(height: 8),
                                          Text(
                                            'VERIFIED',
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Secure Hash: SHA256-${appt.id.hashCode.toRadixString(16).toUpperCase()}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),

                      // Dashed Divider
                      Row(
                        children: List.generate(
                          20,
                          (index) => Expanded(
                            child: Container(
                              height: 2,
                              color: index.isEven ? const Color(0xFF334155) : Colors.transparent,
                            ),
                          ),
                        ),
                      ),

                      // Patient & Appointment Details
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildPassRow('Patient Name', appt.patientName, Icons.person_rounded),
                            const SizedBox(height: 12),
                            _buildPassRow('Doctor / Specialist', appt.doctorName, Icons.medical_services_rounded),
                            const SizedBox(height: 12),
                            _buildPassRow('Appointment Slot', '${appt.preferredDate} • ${appt.preferredTimeSlot}', Icons.calendar_today_rounded),
                            const SizedBox(height: 12),
                            _buildPassRow('Consultation Mode', appt.consultationMode, Icons.local_hospital_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Live Check-in Feedback or Action
                if (isCheckedIn) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF059669)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_walk_rounded, color: Color(0xFF34D399), size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Where to proceed now:',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF022C22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.room_rounded, color: Color(0xFF10B981), size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please proceed to OPD 2nd Floor, Room 102. Your Token is ${appt.tokenNumber}.',
                                  style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  children: [
                                    Text('Patients Ahead', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                    SizedBox(height: 4),
                                    Text('2 Patients', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  children: [
                                    Text('Est. Wait Time', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                    SizedBox(height: 4),
                                    Text('~ 14 mins', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Action Button for Kiosk Simulation
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingIn ? null : _handleSimulatedKioskScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: _isCheckingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.sensor_occupied_rounded, size: 24),
                      label: Text(
                        _isCheckingIn ? 'Scanning at Hospital Kiosk...' : 'Scan QR at Hospital Entrance Kiosk',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Instructions Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Arrival check-in activates your token in the live doctor consultation queue. Please arrive 15 minutes before your time slot.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPassRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
