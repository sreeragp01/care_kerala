import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static final Map<String, String> _malayalamDistricts = {
    'Thiruvananthapuram': 'തിരുവനന്തപുരം',
    'Kollam': 'കൊല്ലം',
    'Pathanamthitta': 'പത്തനംതിട്ട',
    'Alappuzha': 'ആലപ്പുഴ',
    'Kottayam': 'കോട്ടയം',
    'Idukki': 'ഇടുക്കി',
    'Ernakulam': 'എറണാകുളം',
    'Thrissur': 'തൃശ്ശൂർ',
    'Palakkad': 'പാലക്കാട്',
    'Malappuram': 'മലപ്പുറം',
    'Kozhikode': 'കോഴിക്കോട്',
    'Wayanad': 'വയനാട്',
    'Kannur': 'കണ്ണൂർ',
    'Kasaragod': 'കാസർഗോഡ്',
  };

  static String getDistrictName(String englishDistrict, {bool isMalayalam = false}) {
    if (!isMalayalam) return englishDistrict;
    return _malayalamDistricts[englishDistrict] ?? englishDistrict;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'CareLink Kerala',
      'tagline': 'AI-Powered Community & Palliative Care Platform',
      'login': 'Login',
      'register_org': 'Register Organization',
      'select_org': 'Select Organization Tenant',
      'role': 'Role',
      'switch_role': 'Switch Demo Role',
      'dashboard': 'Dashboard',
      'patients': 'Patients',
      'home_visits': 'Home Visits',
      'appointments': 'Appointments',
      'volunteers': 'Volunteers',
      'blood_donors': 'Blood Donors',
      'inventory': 'Inventory & Equipment',
      'ambulance': 'Ambulance Dispatch',
      'donations': 'Finance & Donations',
      'crowdfunding': 'Medical Crowdfunding',
      'ai_assistant': 'AI Healthcare Assistant',
      'reports': 'Reports & Analytics',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'malayalam': 'മലയാളം',
      'todays_visits': "Today's Visits",
      'active_patients': 'Active Patients',
      'critical_alerts': 'Critical Alerts',
      'low_stock': 'Low Stock Alert',
      'emergency_blood': 'Emergency Blood Requests',
      'fund_total': 'Palliative Fund',
      'add_patient': 'Add Patient',
      'search_patients': 'Search by name, district, or tier...',
      'patient_profile': 'Patient Profile',
      'medical_history': 'Medical History',
      'vitals': 'Vitals Timeline',
      'equipment_issued': 'Equipment Issued',
      'family_contacts': 'Family & Emergency Contacts',
      'ai_health_summary': 'AI Clinical Health Summary',
      'gps_checkin': 'GPS Check-In at Patient Location',
      'voice_note': 'Voice Record Visit Notes',
      'offline_sync': 'Offline Visits Cached (Auto-Syncing)',
      'eligible': 'Eligible',
      'not_eligible': 'Not Eligible',
      'emergency_request': 'Emergency Blood Request',
      'stock_available': 'In Stock',
      'loaned': 'Loaned to Patient',
      'speech_to_text': 'Voice-to-Text Clinical Assistant',
      'export_report': 'Export PDF/Excel Report',

      // Emergency SOS
      'emergency_sos': 'Emergency SOS',
      'rapid_sos_trigger': 'Rapid Ambulance & Nurse SOS',
      'tap_3_times': 'Triple-tap or hold 3s for emergency broadcast',
      'voice_sos': 'Voice SOS',
      'broadcast_sent': 'Emergency Broadcast Dispatched!',
      'cancel_safety': 'Cancel within 5 seconds if false alarm',

      // Kerala Location Selector
      'search_location_hint': 'Search Location / Panchayat / Clinic / Hospital / Club...',
      'district_label': '1. District (ജില്ല)',
      'local_body_label': '2. Municipality / Panchayat / Corporation',
      'palliative_unit_label': '3. Palliative Care Unit / Pain Clinic',
      'medicare_center_label': '4. Associated Medicare Centre / Hospital / FHC',
      'registered_club_label': '5. Registered Volunteer Club / Kudumbashree Desk',
      'ward_label': '6. Ward / Locality (വാർഡ്)',
      'category_lsgd': 'Local Self Government (LSGD)',
      'category_palliative': 'Palliative Unit',
      'category_medicare': 'Medicare & Hospital',
      'category_club': 'Registered Club & Society',
      'category_ward': 'Ward / Locality',
      'summary_units': 'Palliative Units',
      'summary_medicare': 'Medicare Centres',
      'summary_clubs': 'Registered Clubs',
      'summary_wards': 'Wards',

      // Patient Referral & Registration
      'nominate_patient': 'Nominate / Refer Patient in Need',
      'full_name': 'Patient Full Name',
      'age': 'Age',
      'gender': 'Gender',
      'condition': 'Illness / Symptoms / Reason for Referral',
      'address_landmark': 'Address & Nearby Landmark',
      'primary_phone': 'Primary Contact Phone',
      'blood_group': 'Blood Group',
      'submit_referral': 'Submit Patient Referral',

      // Roles
      'role_doctor': 'Palliative Physician',
      'role_nurse': 'Home Care Nurse',
      'role_volunteer': 'Community Volunteer',
      'role_admin': 'Program Coordinator / Admin',
      'role_patient': 'Patient / Family Caregiver',
    },
    'ml': {
      'app_title': 'കെയർലിങ്ക് കേരളം',
      'tagline': 'എഐ അടിസ്ഥാനമാക്കിയ സാന്ത്വന പരിചരണ പ്ലാറ്റ്‌ഫോം',
      'login': 'ലോഗിൻ ചെയ്യുക',
      'register_org': 'സംഘടന രജിസ്റ്റർ ചെയ്യുക',
      'select_org': 'സംഘടന തിരഞ്ഞെടുക്കുക',
      'role': 'പങ്ക് (Role)',
      'switch_role': 'റോൾ മാറ്റുക',
      'dashboard': 'ഡാഷ്‌ബോർഡ്',
      'patients': 'രോഗികൾ',
      'home_visits': 'ഹോം വിസിറ്റ്',
      'appointments': 'അപ്പോയിന്റ്മെന്റുകൾ',
      'volunteers': 'സന്നദ്ധപ്രവർത്തകർ',
      'blood_donors': 'രക്തദാതാക്കൾ',
      'inventory': 'മരുന്ന് & ഉപകരണങ്ങൾ',
      'ambulance': 'ആംബുലൻസ് സർവീസ്',
      'donations': 'സാമ്പത്തികം & സംഭാവനകൾ',
      'crowdfunding': 'ചികിത്സാ ധനസമാഹരണം',
      'ai_assistant': 'എഐ ഹെൽത്ത് അസിസ്റ്റന്റ്',
      'reports': 'റിപ്പോർട്ടുകൾ',
      'settings': 'സെറ്റിംഗ്സ്',
      'language': 'ഭാഷ',
      'english': 'English',
      'malayalam': 'മലയാളം',
      'todays_visits': 'ഇന്നത്തെ സന്ദർശനങ്ങൾ',
      'active_patients': 'നിലവിലുള്ള രോഗികൾ',
      'critical_alerts': 'അടിയന്തര മുന്നറിയിപ്പുകൾ',
      'low_stock': 'മരുന്ന് കുറവ് അലേർട്ട്',
      'emergency_blood': 'അടിയന്തര രക്ത ആവശ്യങ്ങൾ',
      'fund_total': 'സാന്ത്വന നിധി',
      'add_patient': 'പുതിയ രോഗിയെ ചേർക്കുക',
      'search_patients': 'പേര്, ജില്ല അല്ലെങ്കിൽ കാറ്റഗറി തിരയുക...',
      'patient_profile': 'രോഗിയുടെ പ്രൊഫൈൽ',
      'medical_history': 'ചികിത്സാ ചരിത്രം',
      'vitals': 'ജീവൽ ലക്ഷണങ്ങൾ (Vitals)',
      'equipment_issued': 'നൽകിയ ഉപകരണങ്ങൾ',
      'family_contacts': 'കുടുംബം & അടിയന്തര ബന്ധപ്പെടലുകൾ',
      'ai_health_summary': 'എഐ ഹെൽത്ത് സമ്മറി',
      'gps_checkin': 'ജിപിഎസ് ലൊക്കേഷൻ ചെക്ക്-ഇൻ',
      'voice_note': 'ശബ്ദ സന്ദേശമായി കുറിക്കുക',
      'offline_sync': 'ഓഫ്‌ലൈൻ വിവരങ്ങൾ റെക്കോർഡ് ചെയ്തു',
      'eligible': 'രക്തം നൽകാം',
      'not_eligible': 'ഇപ്പോൾ നൽകാൻ കഴിയില്ല',
      'emergency_request': 'അടിയന്തര രക്ത ആവശ്യം',
      'stock_available': 'സ്റ്റോക്കിലുണ്ട്',
      'loaned': 'രോഗിക്ക് നൽകിയത്',
      'speech_to_text': 'വോയ്സ്-ടു-ടെക്സ്റ്റ് അസിസ്റ്റന്റ്',
      'export_report': 'റിപ്പോർട്ട് ഡൗൺലോഡ് ചെയ്യുക',

      // Emergency SOS
      'emergency_sos': 'അടിയന്തര സഹായം (SOS)',
      'rapid_sos_trigger': 'ആംബുലൻസ് & നേഴ്സ് അടിയന്തര സന്ദേശം',
      'tap_3_times': '3 തവണ വേഗത്തിൽ അമർത്തുക അല്ലെങ്കിൽ 3 സെക്കൻഡ് ഹോൾഡ് ചെയ്യുക',
      'voice_sos': 'വോയ്സ് SOS',
      'broadcast_sent': 'അടിയന്തര സന്ദേശം അയച്ചു!',
      'cancel_safety': 'അബദ്ധത്തിൽ അമർത്തിയതാണെങ്കിൽ 5 സെക്കൻഡിനുള്ളിൽ റദ്ദാക്കുക',

      // Kerala Location Selector
      'search_location_hint': 'സ്ഥലം / പഞ്ചായത്ത് / ക്ലിനിക്ക് / ആശുപത്രി / ക്ലബ്ബ് തിരയുക...',
      'district_label': '1. ജില്ല (District)',
      'local_body_label': '2. നഗരസഭ / ഗ്രാമപഞ്ചായത്ത് / കോർപ്പറേഷൻ',
      'palliative_unit_label': '3. പാലിയേറ്റീവ് കെയർ യൂണിറ്റ് / പെയിൻ ക്ലിനിക്ക്',
      'medicare_center_label': '4. ആരോഗ്യ കേന്ദ്രം / ആശുപത്രി / FHC / CHC',
      'registered_club_label': '5. സന്നദ്ധ സംഘടന / കുടുംബശ്രീ / ക്ലബ്ബ് ഡെസ്ക്',
      'ward_label': '6. വാർഡ് / പ്രദേശം (Ward / Locality)',
      'category_lsgd': 'തദ്ദേശ സ്വയംഭരണ സ്ഥാപനം (LSGD)',
      'category_palliative': 'സാന്ത്വന പരിചരണ യൂണിറ്റ്',
      'category_medicare': 'ആശുപത്രി / മെഡികെയർ',
      'category_club': 'സന്നദ്ധ ക്ലബ്ബ് / സംഘടന',
      'category_ward': 'വാർഡ് / പ്രദേശം',
      'summary_units': 'സാന്ത്വന കേന്ദ്രങ്ങൾ',
      'summary_medicare': 'ആശുപത്രികൾ',
      'summary_clubs': 'സന്നദ്ധ ക്ലബ്ബുകൾ',
      'summary_wards': 'വാർഡുകൾ',

      // Patient Referral & Registration
      'nominate_patient': 'പരിചരണം ആവശ്യമുള്ള രോഗിയെ അറിയിക്കുക (റഫറൽ)',
      'full_name': 'രോഗിയുടെ പൂർണ്ണ പേര്',
      'age': 'പ്രായം',
      'gender': 'ലിംഗഭേദം',
      'condition': 'രോഗാവസ്ഥ / രോഗലക്ഷണങ്ങൾ / റഫറലിനുള്ള കാരണം',
      'address_landmark': 'മേൽവിലാസം & അടുത്തുള്ള പ്രധാന ലാൻഡ്മാർക്ക്',
      'primary_phone': 'ഫോൺ നമ്പർ',
      'blood_group': 'രക്തഗ്രൂപ്പ്',
      'submit_referral': 'റഫറൽ സമർപ്പിക്കുക',

      // Roles
      'role_doctor': 'പാലിയേറ്റീവ് ഡോക്ടർ',
      'role_nurse': 'ഹോം കെയർ നേഴ്സ്',
      'role_volunteer': 'കമ്മ്യൂണിറ്റി വോളണ്ടിയർ',
      'role_admin': 'പ്രോഗ്രാം കോർഡിനേറ്റർ / അഡ്മിൻ',
      'role_patient': 'രോഗി / കുടുംബാംഗം',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ml'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
