import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/core/state/app_state_provider.dart';

void main() {
  group('Emergency SOS & Multi-Party Broadcast Unit Tests', () {
    late AppStateProvider state;

    setUp(() {
      state = AppStateProvider();
    });

    test('Trigger Emergency SOS creates broadcast event and notifies all parties', () {
      expect(state.activeSosEvent, isNull);

      final sos = state.triggerEmergencySos(
        triggerMethod: 'Triple-Tap Emergency',
        patientId: 'PAT-101',
      );

      expect(sos.patientName, 'Karthyayani Amma');
      expect(sos.triggerMethod, 'Triple-Tap Emergency');
      expect(sos.status, 'Ambulance En-Route');
      expect(sos.dispatchedAmbulanceDriver, isNotEmpty);
      expect(sos.dispatchedAmbulancePhone, isNotEmpty);
      expect(sos.assignedNurseName, contains('Sister Anitha'));
      expect(sos.assignedDoctorName, contains('Dr. Suresh Menon'));
      expect(sos.wardVolunteerName, contains('Shyam Mohan'));

      expect(state.activeSosEvent, isNotNull);
      expect(state.sosEvents.length, 1);
      expect(state.notifications.first, contains('EMERGENCY SOS'));
    });

    test('Trigger Emergency SOS via Voice Command', () {
      final sos = state.triggerEmergencySos(
        triggerMethod: 'Voice Command ("Ambulance Help")',
        patientId: 'PAT-102',
      );

      expect(sos.patientName, 'Vaidyanathan Nair');
      expect(sos.triggerMethod, contains('Voice Command'));
      expect(sos.gpsCoordinates, contains('11.2680° N'));
    });

    test('Cancel and Resolve Emergency SOS workflows', () {
      final sos = state.triggerEmergencySos(
        triggerMethod: 'Quick SOS Bar',
      );

      expect(state.activeSosEvent, isNotNull);

      state.cancelEmergencySos(sos.id);
      expect(state.activeSosEvent, isNull);
      expect(sos.status, 'Cancelled');

      // Trigger new SOS and resolve
      final sos2 = state.triggerEmergencySos(triggerMethod: '108 Ambulance Button');
      expect(state.activeSosEvent, isNotNull);

      state.resolveEmergencySos(sos2.id);
      expect(state.activeSosEvent, isNull);
      expect(state.sosEvents.first.status, 'Resolved');
    });
  });
}
