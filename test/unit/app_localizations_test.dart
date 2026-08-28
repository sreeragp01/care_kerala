import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Full-Screen Malayalam & English Tests', () {
    test('Translates standard app keys in English', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.translate('app_title'), 'CareLink Kerala');
      expect(loc.translate('dashboard'), 'Dashboard');
      expect(loc.translate('patients'), 'Patients');
      expect(loc.translate('home_visits'), 'Home Visits');
      expect(loc.translate('emergency_sos'), 'Emergency SOS');
      expect(loc.translate('district_label'), '1. District (ജില്ല)');
      expect(loc.translate('local_body_label'), '2. Municipality / Panchayat / Corporation');
      expect(loc.translate('palliative_unit_label'), '3. Palliative Care Unit / Pain Clinic');
      expect(loc.translate('medicare_center_label'), '4. Associated Medicare Centre / Hospital / FHC');
      expect(loc.translate('registered_club_label'), '5. Registered Volunteer Club / Kudumbashree Desk');
      expect(loc.translate('summary_units'), 'Palliative Units');
      expect(loc.translate('summary_medicare'), 'Medicare Centres');
      expect(loc.translate('summary_clubs'), 'Registered Clubs');
      expect(loc.translate('summary_wards'), 'Wards');
    });

    test('Translates standard app keys in Malayalam', () {
      final loc = AppLocalizations(const Locale('ml'));
      expect(loc.translate('app_title'), 'കെയർലിങ്ക് കേരളം');
      expect(loc.translate('dashboard'), 'ഡാഷ്‌ബോർഡ്');
      expect(loc.translate('patients'), 'രോഗികൾ');
      expect(loc.translate('home_visits'), 'ഹോം വിസിറ്റ്');
      expect(loc.translate('emergency_sos'), 'അടിയന്തര സഹായം (SOS)');
      expect(loc.translate('district_label'), '1. ജില്ല (District)');
      expect(loc.translate('local_body_label'), '2. നഗരസഭ / ഗ്രാമപഞ്ചായത്ത് / കോർപ്പറേഷൻ');
      expect(loc.translate('palliative_unit_label'), '3. പാലിയേറ്റീവ് കെയർ യൂണിറ്റ് / പെയിൻ ക്ലിനിക്ക്');
      expect(loc.translate('medicare_center_label'), '4. ആരോഗ്യ കേന്ദ്രം / ആശുപത്രി / FHC / CHC');
      expect(loc.translate('registered_club_label'), '5. സന്നദ്ധ സംഘടന / കുടുംബശ്രീ / ക്ലബ്ബ് ഡെസ്ക്');
      expect(loc.translate('summary_units'), 'സാന്ത്വന കേന്ദ്രങ്ങൾ');
      expect(loc.translate('summary_medicare'), 'ആശുപത്രികൾ');
      expect(loc.translate('summary_clubs'), 'സന്നദ്ധ ക്ലബ്ബുകൾ');
      expect(loc.translate('summary_wards'), 'വാർഡുകൾ');
    });

    test('District name translation translates all 14 Kerala districts accurately', () {
      expect(AppLocalizations.getDistrictName('Kozhikode', isMalayalam: true), 'കോഴിക്കോട്');
      expect(AppLocalizations.getDistrictName('Ernakulam', isMalayalam: true), 'എറണാകുളം');
      expect(AppLocalizations.getDistrictName('Thiruvananthapuram', isMalayalam: true), 'തിരുവനന്തപുരം');
      expect(AppLocalizations.getDistrictName('Malappuram', isMalayalam: true), 'മലപ്പുറം');
      expect(AppLocalizations.getDistrictName('Thrissur', isMalayalam: true), 'തൃശ്ശൂർ');
      expect(AppLocalizations.getDistrictName('Palakkad', isMalayalam: true), 'പാലക്കാട്');
      expect(AppLocalizations.getDistrictName('Kannur', isMalayalam: true), 'കണ്ണൂർ');
      expect(AppLocalizations.getDistrictName('Kollam', isMalayalam: true), 'കൊല്ലം');
      expect(AppLocalizations.getDistrictName('Alappuzha', isMalayalam: true), 'ആലപ്പുഴ');
      expect(AppLocalizations.getDistrictName('Kottayam', isMalayalam: true), 'കോട്ടയം');
      expect(AppLocalizations.getDistrictName('Idukki', isMalayalam: true), 'ഇടുക്കി');
      expect(AppLocalizations.getDistrictName('Wayanad', isMalayalam: true), 'വയനാട്');
      expect(AppLocalizations.getDistrictName('Kasaragod', isMalayalam: true), 'കാസർഗോഡ്');
      expect(AppLocalizations.getDistrictName('Pathanamthitta', isMalayalam: true), 'പത്തനംതിട്ട');

      // In English mode, returns original
      expect(AppLocalizations.getDistrictName('Kozhikode', isMalayalam: false), 'Kozhikode');
    });
  });
}
