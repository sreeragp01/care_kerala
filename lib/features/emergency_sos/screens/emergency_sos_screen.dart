import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';

class EmergencySosScreen extends StatefulWidget {
  final AppStateProvider state;
  final String? initialTriggerMethod;
  final String? targetPatientId;

  const EmergencySosScreen({
    super.key,
    required this.state,
    this.initialTriggerMethod,
    this.targetPatientId,
  });

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _tripleTapCount = 0;
  Timer? _tripleTapResetTimer;
  bool _isListeningVoice = false;
  String _voiceRecognizedText = '';
  Timer? _voiceSimulationTimer;

  // Active Broadcast Countdown (5s cancel safety window)
  int _cancelCountdownSeconds = 5;
  Timer? _cancelCountdownTimer;
  bool _isCountdownActive = false;
  EmergencySosEvent? _activeSosEvent;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // If an initial trigger method is provided (e.g. from rapid shortcut), fire immediately
    if (widget.initialTriggerMethod != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerEmergencySos(widget.initialTriggerMethod!);
      });
    } else if (widget.state.activeSosEvent != null) {
      _activeSosEvent = widget.state.activeSosEvent;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tripleTapResetTimer?.cancel();
    _voiceSimulationTimer?.cancel();
    _cancelCountdownTimer?.cancel();
    super.dispose();
  }

  void _handleTripleTap() {
    _tripleTapCount++;
    _tripleTapResetTimer?.cancel();
    _tripleTapResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _tripleTapCount = 0);
    });

    if (_tripleTapCount >= 3) {
      _tripleTapCount = 0;
      _triggerEmergencySos('Triple Tap Emergency Shortcut');
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS Tap $_tripleTapCount/3 recorded. Tap ${3 - _tripleTapCount} more time(s) to broadcast SOS!'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _startVoiceEmergencyListening() {
    setState(() {
      _isListeningVoice = true;
      _voiceRecognizedText = 'Listening for "Emergency", "Ambulance", or "സഹായം"...';
    });

    _voiceSimulationTimer?.cancel();
    _voiceSimulationTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _voiceRecognizedText = 'Recognized: "Ambulance Need Help Immediately" (ആംബുലൻസ് വേണം)';
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _isListeningVoice = false);
        _triggerEmergencySos('Voice Command ("Ambulance Help")');
      });
    });
  }

  void _triggerEmergencySos(String method) {
    setState(() {
      _isCountdownActive = true;
      _cancelCountdownSeconds = 5;
    });

    _cancelCountdownTimer?.cancel();
    _cancelCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cancelCountdownSeconds--;
        if (_cancelCountdownSeconds <= 0) {
          timer.cancel();
          _isCountdownActive = false;
          _activeSosEvent = widget.state.triggerEmergencySos(
            triggerMethod: method,
            patientId: widget.targetPatientId,
          );
        }
      });
    });
  }

  void _cancelSosCountdown() {
    _cancelCountdownTimer?.cancel();
    setState(() {
      _isCountdownActive = false;
      _cancelCountdownSeconds = 5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency SOS broadcast was successfully aborted.'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _shareSosOnWhatsApp(EmergencySosEvent sos) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚨 Emergency SOS Dispatch link copied:\n"Urgent Palliative Emergency for ${sos.patientName} (${sos.bloodGroup}) at Ward ${sos.ward}, ${sos.district}. GPS: ${sos.gpsCoordinates}. Caregiver: ${sos.emergencyContactPhone}."',
        ),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final activeSos = _activeSosEvent ?? widget.state.activeSosEvent;

        final isMalayalam = widget.state.locale.languageCode == 'ml';

        return Scaffold(
          appBar: AppBar(
            title: Text(isMalayalam ? 'അടിയന്തര ആംബുലൻസ് & SOS സഹായം' : 'Emergency Ambulance & SOS Help'),
            backgroundColor: activeSos != null || _isCountdownActive ? AppColors.danger : null,
            foregroundColor: activeSos != null || _isCountdownActive ? Colors.white : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // If countdown is active
                if (_isCountdownActive) _buildCountdownSafetyBanner(isDark, isMalayalam),

                // If active SOS is broadcasting
                if (activeSos != null && !_isCountdownActive)
                  _buildActiveBroadcastView(activeSos, isDark, isMalayalam)
                else if (!_isCountdownActive)
                  _buildReadyTriggerView(isDark, isMalayalam),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownSafetyBanner(bool isDark, bool isMalayalam) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B1515) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(
                isMalayalam ? 'അടിയന്തര സന്ദേശം അയക്കുന്നു (SOS)' : 'BROADCASTING EMERGENCY SOS',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              Text(
                isMalayalam
                    ? '108 ആംബുലൻസ്, ഡ്യൂട്ടി ഡോക്ടർ, സിസ്റ്റർ അനിത, വാർഡ് വളണ്ടിയർ എന്നിവർക്ക് തത്സമയ ജിപിഎസ് ലൊക്കേഷൻ അയക്കുന്നു:'
                    : 'Broadcasting live GPS location & medical case to 108 Ambulance, Assigned Doctor, Sister Anitha, & Ward Volunteer in:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.danger,
                child: Text(
                  '$_cancelCountdownSeconds',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancelSosCountdown,
                  icon: const Icon(Icons.cancel_rounded, color: Colors.white),
                  label: Text(
                    isMalayalam ? 'റദ്ദാക്കുക (അബദ്ധത്തിൽ അമർത്തിയത്)' : 'Cancel SOS (False Alarm)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyTriggerView(bool isDark, bool isMalayalam) {
    final patient = widget.state.patients.firstWhere(
      (p) => p.id == widget.targetPatientId,
      orElse: () => widget.state.patients.first,
    );

    final districtName = AppLocalizations.getDistrictName(patient.district, isMalayalam: isMalayalam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient Header Info Card
        Card(
          color: isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.danger,
                  child: Icon(Icons.person_pin_circle_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMalayalam
                            ? 'രോഗി: ${patient.name} (${patient.bloodGroup})'
                            : 'Patient: ${patient.name} (${patient.bloodGroup})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMalayalam
                            ? 'സ്ഥലം: ${patient.ward}, $districtName (11.2680° N, 75.7910° E)'
                            : 'Location: ${patient.ward}, ${patient.district} (11.2680° N, 75.7910° E)',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Method 1: Big Triple-Tap / Long-Press Pulsing SOS Button
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1.0 + (_pulseController.value * 0.06);
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: _handleTripleTap,
                  onLongPress: () => _triggerEmergencySos(isMalayalam ? '3 സെക്കൻഡ് ലോംഗ് പ്രസ്സ് SOS' : '3-Second SOS Long Press'),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.5),
                          blurRadius: 20 + (_pulseController.value * 15),
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emergency_rounded, color: Colors.white, size: 54),
                        const SizedBox(height: 4),
                        Text(
                          isMalayalam ? 'അടിയന്തര SOS' : 'TRIPLE-TAP SOS',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                        ),
                        Text(
                          _tripleTapCount > 0
                              ? (isMalayalam ? 'ടാപ്പുകൾ: $_tripleTapCount/3' : 'Taps: $_tripleTapCount/3')
                              : (isMalayalam ? '3 തവണ ടാപ്പ് അല്ലെങ്കിൽ 3 സെക്കൻഡ് ഹോൾഡ്' : 'or Hold 3 Seconds'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Method 2: Voice Command Emergency Activation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMalayalam ? 'വോയ്സ് കമാൻഡ് അടിയന്തര സഹായം' : 'Voice Command Shortcut',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            isMalayalam ? '"Emergency", "Ambulance" അല്ലെങ്കിൽ "സഹായം വേണം" എന്ന് പറയുക' : 'Say "Emergency", "Ambulance", or "സഹായം"',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isListeningVoice) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_voiceRecognizedText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isListeningVoice ? null : _startVoiceEmergencyListening,
                    icon: const Icon(Icons.mic_none_rounded, color: Colors.purple, size: 18),
                    label: Text(
                      _isListeningVoice
                          ? (isMalayalam ? 'ശബ്ദം ശ്രവിക്കുന്നു...' : 'Listening to Voice...')
                          : (isMalayalam ? 'വോയ്സ് SOS പ്രവർത്തിപ്പിക്കുക' : 'Activate Voice Emergency SOS'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Method 3: Instant 1-Touch 108 Ambulance Call
        Card(
          color: isDark ? const Color(0xFF1E2822) : const Color(0xFFE8F5E9),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              child: Icon(Icons.call_rounded, color: Colors.white),
            ),
            title: Text(
              isMalayalam ? 'കേരള 108 ആംബുലൻസ് നേരിട്ട് വിളിക്കുക' : 'Direct Call Kerala 108 Ambulance',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen),
            ),
            subtitle: Text(
              isMalayalam ? 'ടോൾ-ഫ്രീ 24/7 സർക്കാർ അടിയന്തര മെഡിക്കൽ സർവീസ്' : 'Toll-Free 24/7 Government Emergency Medical Service',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGreen),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isMalayalam ? '108 ആംബുലൻസ് സർവീസിലേക്ക് വിളിക്കുന്നു...' : 'Dialing 108 (Kerala Emergency Ambulance Service)...'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBroadcastView(EmergencySosEvent sos, bool isDark, bool isMalayalam) {
    final districtName = AppLocalizations.getDistrictName(sos.district, isMalayalam: isMalayalam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live SOS Active Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B1515) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMalayalam ? 'അടിയന്തര സന്ദേശം തത്സമയം പ്രക്ഷേപണം ചെയ്യുന്നു' : 'ACTIVE EMERGENCY BROADCAST',
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isMalayalam
                    ? 'സന്ദേശ രീതി: ${sos.triggerMethod} (${sos.timestamp})'
                    : 'Triggered via: ${sos.triggerMethod} at ${sos.timestamp}',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Live Multi-Channel Dispatch Checkmarks
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? 'മൾട്ടി-പാർട്ടി ഡിസ്പാച്ച് നിലവാരം:' : 'Multi-Party Dispatch Status:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Divider(height: 16),
                _buildDispatchStatusRow(
                  isMalayalam ? '1. തത്സമയ ജിപിഎസ് ലൊക്കേഷൻ പങ്കിട്ടു' : '1. Live GPS Location Shared',
                  '${sos.ward}, $districtName (${sos.gpsCoordinates})',
                  Icons.gps_fixed_rounded,
                  AppColors.success,
                ),
                const SizedBox(height: 10),
                _buildDispatchStatusRow(
                  isMalayalam ? '2. ഏറ്റവും അടുത്തുള്ള ആംബുലൻസ് തിരിച്ചു' : '2. Nearest Ambulance Dispatched',
                  '${sos.dispatchedAmbulanceVehicle} • ${isMalayalam ? 'ഡ്രൈവർ' : 'Driver'}: ${sos.dispatchedAmbulanceDriver} (ETA 4 mins)',
                  Icons.airport_shuttle_rounded,
                  AppColors.success,
                ),
                const SizedBox(height: 10),
                _buildDispatchStatusRow(
                  isMalayalam ? '3. പാലിയേറ്റീവ് നേഴ്സിനും ഡോക്ടർക്കും സന്ദേശം അയച്ചു' : '3. Palliative Nurse & Doctor Notified',
                  '${sos.assignedNurseName} & ${sos.assignedDoctorName}',
                  Icons.medical_services_rounded,
                  AppColors.success,
                ),
                const SizedBox(height: 10),
                _buildDispatchStatusRow(
                  isMalayalam ? '4. വാർഡ് വളണ്ടിയർ അലേർട്ട്' : '4. Ward Volunteer Alerted',
                  sos.wardVolunteerName,
                  Icons.volunteer_activism_rounded,
                  AppColors.success,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isMalayalam ? 'ഡ്രൈവർ ${sos.dispatchedAmbulanceDriver}-നെ വിളിക്കുന്നു (${sos.dispatchedAmbulancePhone})...' : 'Calling Driver ${sos.dispatchedAmbulanceDriver} (${sos.dispatchedAmbulancePhone})...')),
                  );
                },
                icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                label: Text(
                  isMalayalam ? 'ആംബുലൻസ് വിളിക്കുക' : 'Call Ambulance',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareSosOnWhatsApp(sos),
                icon: const Icon(Icons.share_rounded, size: 16, color: Colors.teal),
                label: Text(
                  isMalayalam ? 'ലിങ്ക് പങ്കിടുക' : 'Share Link',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              widget.state.resolveEmergencySos(sos.id);
              setState(() => _activeSosEvent = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isMalayalam ? 'അടിയന്തര SOS പരിഹരിച്ചു.' : 'Emergency SOS marked as resolved.')),
              );
            },
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.blueGrey),
            label: Text(
              isMalayalam ? 'പ്രശ്നം പരിഹരിച്ചു / രോഗിയുടെ അവസ്ഥ സുരക്ഷിതം' : 'Mark Emergency Resolved / Patient Stabilized',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchStatusRow(String title, String desc, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 1),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
      ],
    );
  }
}
