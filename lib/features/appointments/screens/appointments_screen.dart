import 'package:flutter/material.dart';
import '../../../core/state/app_state_provider.dart';
import 'patient_appointment_center_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  final AppStateProvider state;

  const AppointmentsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return PatientAppointmentCenterScreen(state: state);
  }
}
