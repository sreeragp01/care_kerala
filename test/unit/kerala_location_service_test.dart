import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/core/services/kerala_location_service.dart';

void main() {
  group('KeralaLocationService Statewide LSGD, Medicare & Club Directory Tests', () {
    test('All 14 Kerala districts are available', () {
      final districts = KeralaLocationService.districts;
      expect(districts.length, 14);
      expect(districts, contains('Kozhikode'));
      expect(districts, contains('Ernakulam'));
      expect(districts, contains('Wayanad'));
      expect(districts, contains('Thiruvananthapuram'));
      expect(districts, contains('Kasaragod'));
      expect(districts, contains('Thrissur'));
      expect(districts, contains('Malappuram'));
      expect(districts, contains('Kannur'));
      expect(districts, contains('Palakkad'));
      expect(districts, contains('Kollam'));
      expect(districts, contains('Alappuzha'));
      expect(districts, contains('Kottayam'));
      expect(districts, contains('Pathanamthitta'));
      expect(districts, contains('Idukki'));
    });

    test('Fetch Local Bodies for Kozhikode, Malappuram and Ernakulam', () {
      final kzdBodies = KeralaLocationService.getLocalBodies('Kozhikode');
      expect(kzdBodies.isNotEmpty, true);
      expect(kzdBodies.any((b) => b.name == 'Kozhikode Corporation'), true);
      expect(kzdBodies.any((b) => b.name == 'Mavoor Grama Panchayat'), true);
      expect(kzdBodies.any((b) => b.name == 'Feroke Municipality'), true);

      final mlpBodies = KeralaLocationService.getLocalBodies('Malappuram');
      expect(mlpBodies.isNotEmpty, true);
      expect(mlpBodies.any((b) => b.name == 'Manjeri Municipality'), true);
      expect(mlpBodies.any((b) => b.name == 'Perinthalmanna Municipality'), true);

      final ekmBodies = KeralaLocationService.getLocalBodies('Ernakulam');
      expect(ekmBodies.isNotEmpty, true);
      expect(ekmBodies.any((b) => b.name == 'Kochi Corporation'), true);
      expect(ekmBodies.any((b) => b.name == 'Aluva Municipality'), true);
    });

    test('Fetch Medicare Centers and Registered Clubs', () {
      final medCenters = KeralaLocationService.getMedicareCenters(
        district: 'Kozhikode',
        localBodyName: 'Kozhikode Corporation',
      );
      expect(medCenters.isNotEmpty, true);
      expect(medCenters, contains('Government Medical College Hospital, Calicut'));

      final clubs = KeralaLocationService.getRegisteredClubs(
        district: 'Kozhikode',
        localBodyName: 'Kozhikode Corporation',
      );
      expect(clubs.isNotEmpty, true);
      expect(clubs.any((c) => c.contains('Rotary')), true);
    });

    test('Live Search matches across Hospitals, Clubs, Units and Panchayats', () {
      final hospitalResults = KeralaLocationService.searchLocations('Medical College');
      expect(hospitalResults.isNotEmpty, true);

      final clubResults = KeralaLocationService.searchLocations('Rotary');
      expect(clubResults.isNotEmpty, true);

      final tribalResults = KeralaLocationService.searchLocations('Tribal');
      expect(tribalResults.isNotEmpty, true);
      expect(tribalResults.any((r) => r.district == 'Wayanad'), true);

      final palliumResults = KeralaLocationService.searchLocations('Pallium');
      expect(palliumResults.isNotEmpty, true);
      expect(palliumResults.first.district, 'Thiruvananthapuram');
    });
  });
}
