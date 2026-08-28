import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/features/maps/models/map_marker_model.dart';
import 'package:carelink_kerala/core/models/clinical_models.dart';

void main() {
  group('Map & GPS Navigation System Unit Tests', () {
    test('MapMarkerModel properties and color mapping', () {
      const patientMarker = MapMarkerModel(
        id: 'PAT-01',
        title: 'Karthyayani Amma',
        subtitle: 'Ward 12, Mavoor, Kozhikode',
        latitude: 11.2680,
        longitude: 75.7910,
        type: MapMarkerType.patientCategoryA,
        categoryTier: 'Category A',
        phone: '+91 98470 12345',
        distanceKm: 2.8,
        etaMinutes: 9,
      );

      expect(patientMarker.title, 'Karthyayani Amma');
      expect(patientMarker.distanceKm, 2.8);
      expect(patientMarker.etaMinutes, 9);
      expect(patientMarker.color.toARGB32(), 0xFFD32F2F); // Red for Category A
    });

    test('MapMarkerModel ambulance types and statuses', () {
      const availableAmb = MapMarkerModel(
        id: 'AMB-01',
        title: 'Ambulance KL-11-AV-9012',
        subtitle: 'Driver: Rajesh Kumar',
        latitude: 11.2640,
        longitude: 75.7880,
        type: MapMarkerType.ambulanceAvailable,
        distanceKm: 1.4,
        etaMinutes: 4,
      );

      const dispatchedAmb = MapMarkerModel(
        id: 'AMB-02',
        title: 'Ambulance KL-11-EM-1108',
        subtitle: 'Driver: Faisal K.',
        latitude: 11.2710,
        longitude: 75.7940,
        type: MapMarkerType.ambulanceDispatched,
        distanceKm: 3.1,
        etaMinutes: 8,
      );

      expect(availableAmb.type, MapMarkerType.ambulanceAvailable);
      expect(dispatchedAmb.type, MapMarkerType.ambulanceDispatched);
      expect(availableAmb.color.toARGB32(), 0xFF00897B); // Teal
      expect(dispatchedAmb.color.toARGB32(), 0xFFFF6D00); // Orange
    });

    test('Waypoints sequential order and distance', () {
      const waypoints = [
        MapWaypoint(
          latitude: 11.2588,
          longitude: 75.7804,
          instruction: 'Start from Kozhikode Palliative Health Hub',
          roadName: 'Beach Road',
          distanceMeters: 200,
        ),
        MapWaypoint(
          latitude: 11.2680,
          longitude: 75.7910,
          instruction: 'Arriving at Patient Residence',
          roadName: 'Mavoor Road',
          distanceMeters: 2800,
        ),
      ];

      expect(waypoints.length, 2);
      expect(waypoints.first.distanceMeters, 200);
      expect(waypoints.last.instruction, contains('Arriving at Patient Residence'));
    });

    test('GPS check-in update on VisitModel', () {
      final visit = VisitModel(
        id: 'VISIT-101',
        patientId: 'PAT-01',
        patientName: 'Karthyayani Amma',
        patientAddress: 'Ward 12, Mavoor',
        assignedNurseName: 'Anitha R. (Palliative Nurse)',
        scheduledDate: '2026-08-28',
        scheduledTime: '10:00 AM',
      );

      expect(visit.gpsCheckInTime, isNull);
      expect(visit.gpsLocationName, isNull);

      visit.gpsCheckInTime = '10:05 AM';
      visit.gpsLocationName = 'Karthyayani Amma Residence (11.2680° N, 75.7910° E)';

      expect(visit.gpsCheckInTime, '10:05 AM');
      expect(visit.gpsLocationName, contains('11.2680° N'));
    });
  });
}
