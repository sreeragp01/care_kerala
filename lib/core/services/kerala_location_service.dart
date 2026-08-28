enum LocalBodyType {
  corporation,
  municipality,
  gramaPanchayat,
}

extension LocalBodyTypeExt on LocalBodyType {
  String get displayName {
    switch (this) {
      case LocalBodyType.corporation:
        return 'Corporation (കോർപ്പറേഷൻ)';
      case LocalBodyType.municipality:
        return 'Municipality (മുനിസിപ്പാലിറ്റി)';
      case LocalBodyType.gramaPanchayat:
        return 'Grama Panchayat (ഗ്രാമപഞ്ചായത്ത്)';
    }
  }
}

class LocalBodyInfo {
  final String name;
  final LocalBodyType type;
  final String district;
  final List<String> palliativeUnits;
  final List<String> medicareCenters;
  final List<String> registeredClubsAndSocieties;
  final List<String> wards;

  const LocalBodyInfo({
    required this.name,
    required this.type,
    required this.district,
    required this.palliativeUnits,
    this.medicareCenters = const [],
    this.registeredClubsAndSocieties = const [],
    required this.wards,
  });
}

class LocationSearchResult {
  final String title;
  final String subtitle;
  final String district;
  final String localBody;
  final String? palliativeUnit;
  final String? medicareCenter;
  final String? registeredClub;
  final String? ward;
  final String category;

  const LocationSearchResult({
    required this.title,
    required this.subtitle,
    required this.district,
    required this.localBody,
    this.palliativeUnit,
    this.medicareCenter,
    this.registeredClub,
    this.ward,
    this.category = 'Palliative Unit',
  });
}

class KeralaLocationService {
  static const List<String> districts = [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  static final Map<String, List<LocalBodyInfo>> _keralaDirectory = {
    // =========================================================================
    // 1. KOZHIKODE DISTRICT (കോഴിക്കോട്)
    // =========================================================================
    'Kozhikode': [
      const LocalBodyInfo(
        name: 'Kozhikode Corporation',
        type: LocalBodyType.corporation,
        district: 'Kozhikode',
        palliativeUnits: [
          'Calicut Medical College Pain & Palliative Clinic',
          'Chevayur Pain & Palliative Care Society (PPCS HQ)',
          'Beach Hospital Palliative Homecare Wing',
          'Kallai Sanmanassu Community Palliative Unit',
          'Meenchanda Urban Health Palliative Wing',
          'Nadakkavu Karunya Palliative Helpdesk',
          'Beypore Coastal Area Palliative Unit',
          'Elathur Janaseva Palliative Care Wing',
        ],
        medicareCenters: [
          'Government Medical College Hospital, Calicut',
          'Government General Hospital (Beach Hospital)',
          'Institute of Maternal & Child Health (IMCH)',
          'Government Homeo Hospital Nadakkavu',
          'Government Ayurveda Research Hospital Meenchanda',
          'Urban Primary Health Centre (UPHC) Kallai',
        ],
        registeredClubsAndSocieties: [
          'Pain & Palliative Care Society (PPCS) Calicut',
          'Rotary Club of Calicut Palliative Care Foundation',
          'Lions Club Kozhikode Medical Aid Desk',
          'Kudumbashree CDS Palliative Task Force Ward 14',
          'Yuvadhara Youth & Arts Club Palliative Wing',
          'Chalappuram Cultural & Health Forum',
        ],
        wards: [
          'Ward 1 - Elathur',
          'Ward 14 - Chevayur',
          'Ward 22 - Nadakkavu',
          'Ward 35 - Medical College',
          'Ward 48 - Chalappuram',
          'Ward 60 - Beypore Port',
          'Ward 68 - Meenchanda',
          'Ward 74 - Kallai',
        ],
      ),
      const LocalBodyInfo(
        name: 'Feroke Municipality',
        type: LocalBodyType.municipality,
        district: 'Kozhikode',
        palliativeUnits: [
          'Feroke Community Palliative Clinic',
          'Chungam Palliative Homecare Center',
          'Karuvanthiruthy CHC Palliative Desk',
          'Feroke College Area Care Wing',
        ],
        medicareCenters: [
          'Community Health Centre (CHC) Chungam, Feroke',
          'Taluk Hospital Feroke',
          'Government Ayurveda Dispensary Petta',
        ],
        registeredClubsAndSocieties: [
          'Feroke Janamaithri Community Palliative Forum',
          'Petta Youth Arts & Sports Club Medical Desk',
          'Feroke Merchants Relief Samithi',
          'Kudumbashree Santhwanam Feroke Unit',
        ],
        wards: [
          'Ward 1 - Petta',
          'Ward 8 - Feroke College',
          'Ward 15 - Chungam',
          'Ward 24 - Karuvanthiruthy',
          'Ward 29 - Kadalundi Road',
        ],
      ),
      const LocalBodyInfo(
        name: 'Vadakara Municipality',
        type: LocalBodyType.municipality,
        district: 'Kozhikode',
        palliativeUnits: [
          'Vadakara Ashraya Pain & Palliative Clinic',
          'Vadakara District Hospital Palliative Center',
          'Chorode Coastal Palliative Outreach',
          'Nut Street Community Care Cell',
        ],
        medicareCenters: [
          'District Hospital Vadakara',
          'Government Ayurveda Hospital Vadakara',
          'Co-operative Hospital Oncology Palliative Wing',
        ],
        registeredClubsAndSocieties: [
          'Kadathanad Arts & Sports Club Palliative Forum',
          'Vadakara Rotary Midtown Medical Wing',
          'Lions Club of Vadakara Care Trust',
        ],
        wards: [
          'Ward 6 - Nut Street',
          'Ward 15 - Lokanarkavu',
          'Ward 28 - Vadakara Beach',
          'Ward 34 - Memunda',
        ],
      ),
      const LocalBodyInfo(
        name: 'Koyilandy Municipality',
        type: LocalBodyType.municipality,
        district: 'Kozhikode',
        palliativeUnits: [
          'Koyilandy Taluk Palliative Support Center',
          'Kollam-Koyilandy Coastal Palliative Unit',
          'Koyilandy Harbour Health Care Desk',
        ],
        medicareCenters: ['Taluk Hospital Koyilandy', 'FHC Koyilandy Urban', 'Govt Homeo Clinic'],
        registeredClubsAndSocieties: ['Koyilandy Coastal Fishermen Care Forum', 'Koyilandy Lions Club'],
        wards: ['Ward 5 - Beach North', 'Ward 14 - Koyilandy Town', 'Ward 26 - Kollam Parambil'],
      ),
      const LocalBodyInfo(
        name: 'Koduvally Municipality',
        type: LocalBodyType.municipality,
        district: 'Kozhikode',
        palliativeUnits: [
          'Koduvally Palliative Care Society',
          'Koduvally Taluk Hospital Palliative Wing',
          'Vennakkad Community Care Desk',
        ],
        medicareCenters: ['Taluk Hospital Koduvally', 'Koduvally CHC', 'Govt Ayurveda Dispensary'],
        registeredClubsAndSocieties: ['Koduvally Care & Relief Trust', 'Koduvally Youth Federation'],
        wards: ['Ward 5 - Koduvally South', 'Ward 11 - Vennakkad', 'Ward 20 - Koduvally Town'],
      ),
      const LocalBodyInfo(
        name: 'Mavoor Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Kozhikode',
        palliativeUnits: [
          'Mavoor Pain & Palliative Care Trust',
          'Mavoor FHC Palliative Outreach Wing',
          'Cheruppa Leprosy & Chronic Palliative Wing',
        ],
        medicareCenters: ['Family Health Centre (FHC) Mavoor', 'Cheruppa Government Hospital'],
        registeredClubsAndSocieties: ['Mavoor Gwalior Rayons Workers Relief Club', 'Mavoor Youth Forum'],
        wards: ['Ward 3 - Cheruppa', 'Ward 7 - Mavoor Town', 'Ward 12 - Valillappuzha', 'Ward 16 - Kattachira'],
      ),
      const LocalBodyInfo(
        name: 'Kunnamangalam Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Kozhikode',
        palliativeUnits: [
          'Kunnamangalam Community Palliative Society',
          'Kuttikkattoor Palliative Care Unit',
          'IIM / REC Palliative Aid Center',
        ],
        medicareCenters: ['Community Health Centre Kunnamangalam', 'FHC Kuttikkattoor'],
        registeredClubsAndSocieties: ['NIT & IIM Social Service Volunteers', 'Kunnamangalam Youth Club'],
        wards: ['Ward 4 - Kuttikkattoor', 'Ward 9 - Kunnamangalam Town', 'Ward 18 - Pilassery'],
      ),
      const LocalBodyInfo(
        name: 'Thamarassery Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Kozhikode',
        palliativeUnits: ['Thamarassery Ghats Palliative Unit', 'Chungam Thamarassery Care Desk'],
        medicareCenters: ['Taluk Hospital Thamarassery', 'FHC Korangad'],
        registeredClubsAndSocieties: ['Ghat Road Travellers & Palliative Volunteers', 'Thamarassery Rotary'],
        wards: ['Ward 2 - Korangad', 'Ward 8 - Thamarassery Town', 'Ward 15 - Kaithapoyil'],
      ),
    ],

    // =========================================================================
    // 2. MALAPPURAM DISTRICT (മലപ്പുറം)
    // =========================================================================
    'Malappuram': [
      const LocalBodyInfo(
        name: 'Malappuram Municipality',
        type: LocalBodyType.municipality,
        district: 'Malappuram',
        palliativeUnits: [
          'Malappuram Pain and Palliative Care Clinic',
          'Taluk Hospital Malappuram Palliative Cell',
          'Down Hill Community Care Desk',
          'Melmuri Community Palliative Outreach',
        ],
        medicareCenters: [
          'Government Taluk Hospital Malappuram',
          'FHC Melmuri',
          'District Ayurveda Hospital Malappuram',
          'Government Homeo Hospital Up Hill',
        ],
        registeredClubsAndSocieties: [
          'Malappuram District Palliative Initiative',
          'Down Hill Sports & Care Club',
          'Kudumbashree Malappuram CDS 1 Palliative Wing',
          'Janamaithri Health Support Group',
        ],
        wards: [
          'Ward 4 - Munduparamba',
          'Ward 12 - Down Hill',
          'Ward 24 - Up Hill',
          'Ward 30 - Valiyangadi',
          'Ward 36 - Melmuri',
        ],
      ),
      const LocalBodyInfo(
        name: 'Manjeri Municipality',
        type: LocalBodyType.municipality,
        district: 'Malappuram',
        palliativeUnits: [
          'Manjeri Medical College Palliative Department',
          'Karunya Palliative Care Society Manjeri',
          'Kacherippadi Social Care Unit',
          'Vettekkode Rural Palliative Clinic',
        ],
        medicareCenters: [
          'Government Medical College Hospital Manjeri',
          'Urban Primary Health Centre Manjeri',
          'Ayurveda Dispensary Vettekkode',
        ],
        registeredClubsAndSocieties: [
          'Manjeri Rotary Social Care Foundation',
          'Manjeri Youth Forum & Medical Relief Cell',
          'Janaseva Palliative Trust Manjeri',
        ],
        wards: ['Ward 7 - Kacherippadi', 'Ward 16 - Vettekkode', 'Ward 30 - Medical College Ward', 'Ward 42 - Thrikkalangode Road'],
      ),
      const LocalBodyInfo(
        name: 'Tirur Municipality',
        type: LocalBodyType.municipality,
        district: 'Malappuram',
        palliativeUnits: [
          'Tirur Palliative Care Consortium',
          'Thunchan Memorial Palliative Wing',
          'BP Angadi Coastal Care Cell',
        ],
        medicareCenters: ['District Hospital Tirur', 'FHC BP Angadi', 'Taluk Ayurveda Hospital'],
        registeredClubsAndSocieties: ['Thunchan Memorial Care Forum', 'Tirur Merchants Relief Wing', 'Yuvadhara Tirur'],
        wards: ['Ward 5 - Thunchan Parambu', 'Ward 14 - Tirur Town', 'Ward 28 - Chembra', 'Ward 35 - Alathiyur'],
      ),
      const LocalBodyInfo(
        name: 'Perinthalmanna Municipality',
        type: LocalBodyType.municipality,
        district: 'Malappuram',
        palliativeUnits: [
          'Perinthalmanna Palliative Consortium',
          'EMS Memorial Palliative Clinic',
          'Angadippuram Railway Area Care Desk',
        ],
        medicareCenters: ['District Hospital Perinthalmanna', 'Al Shifa Healthcare Outreach', 'FHC Angadippuram'],
        registeredClubsAndSocieties: ['Perinthalmanna Janamaithri Trust', 'Angadippuram Rotary Club'],
        wards: ['Ward 5 - Angadippuram Gate', 'Ward 14 - Town Hall Ward', 'Ward 22 - Jubilee Ward'],
      ),
      const LocalBodyInfo(
        name: 'Nilambur Municipality',
        type: LocalBodyType.municipality,
        district: 'Malappuram',
        palliativeUnits: [
          'Nilambur Forest Tribal Palliative Unit',
          'Chaliyar River Palliative Wing',
          'Manimooly Border Area Care Cell',
        ],
        medicareCenters: ['District Taluk Hospital Nilambur', 'Tribal Mobile Clinic Unit', 'FHC Chandakkunnu'],
        registeredClubsAndSocieties: ['Nilambur Teak City Care Club', 'Janamaithri Tribal Outreach'],
        wards: ['Ward 3 - Chandakkunnu', 'Ward 10 - Nilambur Town', 'Ward 21 - Manimooly'],
      ),
      const LocalBodyInfo(
        name: 'Edappal Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Malappuram',
        palliativeUnits: ['Edappal Palliative Care Trust', 'Kuttippala Community Care Desk'],
        medicareCenters: ['Community Health Centre Edappal', 'Edappal Hospital Rural Wing'],
        registeredClubsAndSocieties: ['Edappal Rotary Midtown', 'Edappal Youth Club'],
        wards: ['Ward 3 - Edappal Town', 'Ward 9 - Kuttippala', 'Ward 14 - Ayankalam'],
      ),
    ],

    // =========================================================================
    // 3. ERNAKULAM DISTRICT (എറണാകുളം)
    // =========================================================================
    'Ernakulam': [
      const LocalBodyInfo(
        name: 'Kochi Corporation',
        type: LocalBodyType.corporation,
        district: 'Ernakulam',
        palliativeUnits: [
          'Ernakulam General Hospital Palliative Department',
          'Edappally Karunya Palliative Care Center',
          'Fort Kochi Palliative Homecare Wing',
          'Palarivattom Urban Health Palliative Cell',
          'Mattancherry Heritage Palliative Desk',
          'Vyttila Mobility Hub Palliative Helpdesk',
          'Kaloor Community Cancer Support Wing',
        ],
        medicareCenters: [
          'Government General Hospital Ernakulam',
          'Fort Kochi Taluk Hospital',
          'Maharaja Government Hospital Karuvelippady',
          'Cochin Port Trust Hospital',
          'Government Homeopathic Medical Hospital',
          'Government Ayurveda Dispensary Kaloor',
        ],
        registeredClubsAndSocieties: [
          'Rotary Club of Cochin Palliative Foundation',
          'Lions Club International Ernakulam Greater',
          'YMCA Kochi Social Medical Desk',
          'Kudumbashree Urban Palliative CDS 1',
          'Edappally Social Service Guild',
          'Mattancherry Brotherhood Medical Samithi',
        ],
        wards: [
          'Ward 1 - Fort Kochi',
          'Ward 12 - Mattancherry',
          'Ward 18 - Edappally',
          'Ward 34 - Kaloor',
          'Ward 52 - Ernakulam South',
          'Ward 68 - Vyttila',
          'Ward 72 - Ravipuram',
          'Ward 76 - Thevara',
        ],
      ),
      const LocalBodyInfo(
        name: 'Aluva Municipality',
        type: LocalBodyType.municipality,
        district: 'Ernakulam',
        palliativeUnits: [
          'Aluva Palliative Care Society',
          'Aluva District Hospital Palliative Wing',
          'Periyar Shore Palliative Support Wing',
          'Bank Junction Urban Care Unit',
        ],
        medicareCenters: ['District Hospital Aluva', 'FHC Bank Junction', 'Govt Ayurveda Hospital Aluva'],
        registeredClubsAndSocieties: ['YMCA Aluva Medical Cell', 'Periyar Care Volunteers', 'Aluva Rotary Club'],
        wards: ['Ward 3 - Bank Junction', 'Ward 9 - Periyar Nagar', 'Ward 17 - Thottakkattukara', 'Ward 24 - UC College Ward'],
      ),
      const LocalBodyInfo(
        name: 'Kalamassery Municipality',
        type: LocalBodyType.municipality,
        district: 'Ernakulam',
        palliativeUnits: [
          'Cochin Medical College Palliative Clinic',
          'Kalamassery Community Care Unit',
          'HMT Colony Palliative Outreach Desk',
        ],
        medicareCenters: ['Government Medical College Hospital Kalamassery', 'FHC HMT Colony'],
        registeredClubsAndSocieties: ['CUSAT NSS Palliative Cell', 'Kalamassery Youth Care Forum'],
        wards: ['Ward 8 - Premier Junction', 'Ward 14 - HMT Colony', 'Ward 22 - Medical College Road'],
      ),
      const LocalBodyInfo(
        name: 'Tripunithura Municipality',
        type: LocalBodyType.municipality,
        district: 'Ernakulam',
        palliativeUnits: [
          'Hill Palace Palliative Society',
          'Tripunithura Taluk Palliative Desk',
          'Statue Junction Palliative Cell',
        ],
        medicareCenters: ['Taluk Hospital Tripunithura', 'Ayurveda College Hospital Tripunithura'],
        registeredClubsAndSocieties: ['Poornathrayeesa Seva Samithi', 'Statue Junction Youth Club'],
        wards: ['Ward 4 - Hill Palace', 'Ward 15 - Statue Junction', 'Ward 28 - Kizhakkekotta'],
      ),
      const LocalBodyInfo(
        name: 'Angamaly Municipality',
        type: LocalBodyType.municipality,
        district: 'Ernakulam',
        palliativeUnits: ['Angamaly Taluk Palliative Center', 'Little Flower Palliative Outreach'],
        medicareCenters: ['Taluk Hospital Angamaly', 'Little Flower Hospital Oncology Cell'],
        registeredClubsAndSocieties: ['St. George Palliative Society', 'Angamaly Merchants Association'],
        wards: ['Ward 2 - TB Junction', 'Ward 11 - Champannoor', 'Ward 25 - Nayathode'],
      ),
      const LocalBodyInfo(
        name: 'Kumbalangi Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Ernakulam',
        palliativeUnits: ['Kumbalangi Backwater Palliative Unit', 'Model Village Coastal Care Desk'],
        medicareCenters: ['Family Health Centre Kumbalangi', 'Primary Health Dispensary'],
        registeredClubsAndSocieties: ['Kumbalangi Kayal Club', 'Integrated Village Development Society'],
        wards: ['Ward 2 - North Kumbalangi', 'Ward 8 - Illikkal', 'Ward 14 - Kallanchery'],
      ),
    ],

    // =========================================================================
    // 4. THIRUVANANTHAPURAM DISTRICT (തിരുവനന്തപുരം)
    // =========================================================================
    'Thiruvananthapuram': [
      const LocalBodyInfo(
        name: 'Thiruvananthapuram Corporation',
        type: LocalBodyType.corporation,
        district: 'Thiruvananthapuram',
        palliativeUnits: [
          'Pallium India Palliative Care Center (Trivandrum HQ)',
          'Regional Cancer Centre (RCC) Palliative Oncology Wing',
          'Government Medical College Trivandrum Palliative Clinic',
          'Peroorkada District Hospital Palliative Cell',
          'Sree Chitra Tirunal Medical Palliative Outreach',
          'Kazhakoottam Technopark Care Desk',
          'Vizhinjam Coastal Palliative Center',
        ],
        medicareCenters: [
          'Government Medical College Hospital, Thiruvananthapuram',
          'Regional Cancer Centre (RCC)',
          'General Hospital (W&C) Thycaud',
          'Sree Chitra Tirunal Institute for Medical Sciences (SCTIMST)',
          'Government Ayurveda College Hospital Thiruvananthapuram',
          'Peroorkada Mental Health Centre & General Hospital',
        ],
        registeredClubsAndSocieties: [
          'Pallium India Foundation',
          'Trivandrum Cosmopolitan Lions Club',
          'Technopark Prathidhwani Palliative Taskforce',
          'Karyavattom University NSS Care Cell',
          'Rotary Club of Trivandrum South',
          'Kowdiar Citizens Welfare Forum',
        ],
        wards: [
          'Ward 1 - Kazhakoottam',
          'Ward 15 - Medical College',
          'Ward 32 - Peroorkada',
          'Ward 48 - Kowdiar',
          'Ward 65 - Palayam',
          'Ward 88 - Nemom',
          'Ward 96 - Vizhinjam Port',
        ],
      ),
      const LocalBodyInfo(
        name: 'Attingal Municipality',
        type: LocalBodyType.municipality,
        district: 'Thiruvananthapuram',
        palliativeUnits: ['Attingal Taluk Palliative Center', 'Valiyakunnu Palliative Outreach'],
        medicareCenters: ['Valiyakunnu Taluk Hospital', 'FHC Attingal Town', 'Govt Ayurveda Dispensary'],
        registeredClubsAndSocieties: ['Mamom Youth Forum', 'Attingal Citizens Relief Forum'],
        wards: ['Ward 4 - Valiyakunnu', 'Ward 12 - Kacheri Ward', 'Ward 21 - Mamom'],
      ),
      const LocalBodyInfo(
        name: 'Neyyattinkara Municipality',
        type: LocalBodyType.municipality,
        district: 'Thiruvananthapuram',
        palliativeUnits: ['Neyyattinkara General Hospital Palliative Wing', 'Amaravila Palliative Support Group'],
        medicareCenters: ['General Hospital Neyyattinkara', 'FHC Amaravila'],
        registeredClubsAndSocieties: ['Amaravila Handloom Care Club', 'CSI Mission Health Outreach'],
        wards: ['Ward 6 - Amaravila', 'Ward 14 - Town Ward', 'Ward 28 - Vazhimukku'],
      ),
      const LocalBodyInfo(
        name: 'Varkala Municipality',
        type: LocalBodyType.municipality,
        district: 'Thiruvananthapuram',
        palliativeUnits: ['Varkala Sivagiri Sree Narayana Palliative Society', 'Varkala Taluk Palliative Cell'],
        medicareCenters: ['Taluk Hospital Varkala', 'Sivagiri Sree Narayana Medical Mission'],
        registeredClubsAndSocieties: ['Varkala Cliff Tourism & Care Club', 'Sivagiri Seva Samithi'],
        wards: ['Ward 5 - Papanasam Beach', 'Ward 12 - Sivagiri', 'Ward 24 - Maithanam'],
      ),
    ],

    // =========================================================================
    // 5. THRISSUR DISTRICT (തൃശ്ശൂർ)
    // =========================================================================
    'Thrissur': [
      const LocalBodyInfo(
        name: 'Thrissur Corporation',
        type: LocalBodyType.corporation,
        district: 'Thrissur',
        palliativeUnits: [
          'Thrissur Pain and Palliative Care Society (PPCS)',
          'Alpha Palliative Care Thrissur HQ',
          'Government Medical College Thrissur Palliative Clinic',
          'Jubilee Mission Palliative Care Unit',
          'Amala Institute of Medical Sciences Oncology Palliative Wing',
          'Ollur Community Care Center',
          'Mannuthy Agricultural Belt Care Desk',
        ],
        medicareCenters: [
          'Government Medical College Hospital Thrissur',
          'General Hospital Thrissur',
          'Jubilee Mission Medical College Hospital',
          'Amala Cancer Hospital & Research Centre',
          'District Ayurveda Hospital Thrissur',
          'Government Homeo Dispensary Ayyanthole',
        ],
        registeredClubsAndSocieties: [
          'Alpha Palliative Trust',
          'Thrissur Round Rotary Club',
          'Pain and Palliative Care Society Thrissur',
          'Kerala Sastra Sahitya Parishad Care Wing',
          'Ollur Citizens Welfare Association',
        ],
        wards: [
          'Ward 5 - Round South',
          'Ward 18 - Ayyanthole',
          'Ward 32 - Ollur',
          'Ward 46 - Mannuthy',
          'Ward 54 - Ramavarmapuram',
        ],
      ),
      const LocalBodyInfo(
        name: 'Guruvayur Municipality',
        type: LocalBodyType.municipality,
        district: 'Thrissur',
        palliativeUnits: ['Guruvayur Palliative Care Wing', 'Chavakkad Taluk Palliative Desk'],
        medicareCenters: ['Chavakkad Taluk Hospital', 'Deo Medical Dispensary'],
        registeredClubsAndSocieties: ['Guruvayur Temple Seva Trust', 'Chavakkad Coastal Forum'],
        wards: ['Ward 3 - East Nada', 'Ward 11 - Mammiyoor', 'Ward 20 - Kottappadi'],
      ),
      const LocalBodyInfo(
        name: 'Chalakudy Municipality',
        type: LocalBodyType.municipality,
        district: 'Thrissur',
        palliativeUnits: ['Taluk Hospital Chalakudy Palliative Wing', 'St. James Palliative Care Wing'],
        medicareCenters: ['Taluk Hospital Chalakudy', 'St. James Hospital'],
        registeredClubsAndSocieties: ['Chalakudy Rotary Club', 'Athirappilly Forest Welfare Desk'],
        wards: ['Ward 4 - South Chalakudy', 'Ward 14 - Kanjirappilly', 'Ward 28 - Potta'],
      ),
    ],

    // =========================================================================
    // 6. WAYANAD DISTRICT (വയനാട്)
    // =========================================================================
    'Wayanad': [
      const LocalBodyInfo(
        name: 'Mananthavady Municipality',
        type: LocalBodyType.municipality,
        district: 'Wayanad',
        palliativeUnits: [
          'Wayanad Tribal Mobile Palliative Care Unit',
          'Mananthavady Medical College Palliative Wing',
          'Valliyoorkavu Community Care Unit',
          'Wayanad Social Service Society (WSSS) Health Wing',
        ],
        medicareCenters: [
          'Government Medical College Hospital Mananthavady',
          'Valliyoorkavu Community Health Centre',
          'District Tribal Specialty Mobile Clinic',
        ],
        registeredClubsAndSocieties: [
          'WSSS Tribal Health Mission',
          'Mananthavady Rotary Club',
          'Janamaithri Tribal Care Network',
        ],
        wards: ['Ward 3 - Valliyoorkavu', 'Ward 8 - Mananthavady Town', 'Ward 19 - Payyampally', 'Ward 28 - Cherukattoor'],
      ),
      const LocalBodyInfo(
        name: 'Sultan Bathery Municipality',
        type: LocalBodyType.municipality,
        district: 'Wayanad',
        palliativeUnits: ['Sultan Bathery Taluk Palliative Center', 'Kuppadi Community Palliative Society'],
        medicareCenters: ['Taluk Hospital Sultan Bathery', 'Assumption Hospital Palliative Cell'],
        registeredClubsAndSocieties: ['Bathery Rotary Midtown', 'Cheeral Farmers Care Society'],
        wards: ['Ward 5 - Kuppadi', 'Ward 12 - Bathery Town', 'Ward 21 - Cheeral Road'],
      ),
      const LocalBodyInfo(
        name: 'Kalpetta Municipality',
        type: LocalBodyType.municipality,
        district: 'Wayanad',
        palliativeUnits: ['Kalpetta Swami Vivekananda Palliative Unit', 'General Hospital Kalpetta Palliative Wing'],
        medicareCenters: ['General Hospital Kalpetta', 'Swami Vivekananda Medical Mission Kainatty'],
        registeredClubsAndSocieties: ['Swami Vivekananda Medical Trust', 'Kalpetta Lions Club'],
        wards: ['Ward 4 - Kainatty', 'Ward 10 - Kalpetta Main', 'Ward 16 - Munderi'],
      ),
      const LocalBodyInfo(
        name: 'Vythiri Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Wayanad',
        palliativeUnits: ['Vythiri Tribal Palliative Outreach Desk', 'Vythiri PHC Palliative Center'],
        medicareCenters: ['Primary Health Centre Vythiri', 'Lakkidi Forest Dispensary'],
        registeredClubsAndSocieties: ['Tea Plantation Workers Relief Union', 'Lakkidi Valley Youth Club'],
        wards: ['Ward 2 - Lakkidi Pass', 'Ward 6 - Vythiri Town', 'Ward 11 - Old Vythiri'],
      ),
    ],

    // =========================================================================
    // 7. KANNUR DISTRICT (കണ്ണൂർ)
    // =========================================================================
    'Kannur': [
      const LocalBodyInfo(
        name: 'Kannur Corporation',
        type: LocalBodyType.corporation,
        district: 'Kannur',
        palliativeUnits: [
          'Kannur District Pain & Palliative Care Society',
          'Pariyaram Medical College Palliative Clinic',
          'Thottada Community Health Palliative Cell',
          'AKG Memorial Hospital Palliative Department',
        ],
        medicareCenters: [
          'Government District Hospital Kannur',
          'Government Medical College Hospital Pariyaram',
          'AKG Memorial Hospital Talap',
        ],
        registeredClubsAndSocieties: [
          'Kannur Pain and Palliative Care Society',
          'Rotary Club of Cannanore Medical Taskforce',
          'Red Star Arts & Sports Club Care Desk',
        ],
        wards: ['Ward 4 - Thavakkara', 'Ward 14 - Pallikkunnu', 'Ward 28 - Thottada', 'Ward 42 - Edakkad'],
      ),
      const LocalBodyInfo(
        name: 'Thalassery Municipality',
        type: LocalBodyType.municipality,
        district: 'Kannur',
        palliativeUnits: [
          'Thalassery General Hospital Palliative Wing',
          'Malabar Cancer Centre (MCC) Palliative Unit',
        ],
        medicareCenters: ['General Hospital Thalassery', 'Malabar Cancer Centre (MCC) Kodiyeri'],
        registeredClubsAndSocieties: ['MCC Cancer Patient Relief Samithi', 'Thalassery Fort Lions Club'],
        wards: ['Ward 6 - Fort Ward', 'Ward 18 - Temple Gate', 'Ward 31 - Moozhikkara'],
      ),
      const LocalBodyInfo(
        name: 'Payyannur Municipality',
        type: LocalBodyType.municipality,
        district: 'Kannur',
        palliativeUnits: ['Payyannur Taluk Palliative Society', 'Gandhi Smrithi Care Desk'],
        medicareCenters: ['Taluk Hospital Payyannur', 'FHC Payyannur Town'],
        registeredClubsAndSocieties: ['Gandhi Smrithi Seva Trust', 'Payyannur Youth Forum'],
        wards: ['Ward 5 - Perumba', 'Ward 15 - Annur', 'Ward 26 - Keloth'],
      ),
    ],

    // =========================================================================
    // 8. PALAKKAD DISTRICT (പാലക്കാട്)
    // =========================================================================
    'Palakkad': [
      const LocalBodyInfo(
        name: 'Palakkad Municipality',
        type: LocalBodyType.municipality,
        district: 'Palakkad',
        palliativeUnits: [
          'Palakkad Pain & Palliative Care Society',
          'District Hospital Palakkad Palliative Wing',
          'Fort Maidan Community Care Cell',
        ],
        medicareCenters: ['Government District Hospital Palakkad', 'Women and Child Hospital Palakkad'],
        registeredClubsAndSocieties: ['Palakkad Pain & Palliative Trust', 'Rotary Club of Palakkad Midtown'],
        wards: ['Ward 7 - Sultanpet', 'Ward 19 - Fort Maidan', 'Ward 33 - Olavakkode', 'Ward 42 - Kalpathy'],
      ),
      const LocalBodyInfo(
        name: 'Ottapalam Municipality',
        type: LocalBodyType.municipality,
        district: 'Palakkad',
        palliativeUnits: ['Ottapalam Taluk Palliative Care Center', 'Varode Palliative Homecare Wing'],
        medicareCenters: ['Taluk Hospital Ottapalam', 'NSS Medical Mission Wing'],
        registeredClubsAndSocieties: ['Ottapalam Lions Club', 'Nila Cultural & Health Forum'],
        wards: ['Ward 4 - Kanniyampuram', 'Ward 12 - Main Road', 'Ward 26 - Varode'],
      ),
      const LocalBodyInfo(
        name: 'Mannarkkad Municipality',
        type: LocalBodyType.municipality,
        district: 'Palakkad',
        palliativeUnits: ['Mannarkkad Taluk Palliative Unit', 'Attappadi Buffer Zone Care Desk'],
        medicareCenters: ['Taluk Hospital Mannarkkad', 'Agali Tribal Speciality Hospital Outreach'],
        registeredClubsAndSocieties: ['Silent Valley Welfare Forum', 'MES College NSS Care Desk'],
        wards: ['Ward 5 - Kunnumpuram', 'Ward 14 - Nellippuzha', 'Ward 24 - Arappetta'],
      ),
    ],

    // =========================================================================
    // 9. KOLLAM DISTRICT (കൊല്ലം)
    // =========================================================================
    'Kollam': [
      const LocalBodyInfo(
        name: 'Kollam Corporation',
        type: LocalBodyType.corporation,
        district: 'Kollam',
        palliativeUnits: [
          'Kollam District Palliative Care Society',
          'Victoria Hospital Palliative Clinic',
          'Cashew Workers Social Palliative Wing',
        ],
        medicareCenters: [
          'Government District Hospital Kollam',
          'Government Medical College Hospital Parippally',
          'Victoria Hospital for Women and Children',
        ],
        registeredClubsAndSocieties: ['Quilon Lions Club Medical Taskforce', 'Cashew Workers Relief Society'],
        wards: ['Ward 3 - Chinnakkada', 'Ward 16 - Asramam', 'Ward 35 - Tangasseri', 'Ward 45 - Eravipuram'],
      ),
      const LocalBodyInfo(
        name: 'Karunagappally Municipality',
        type: LocalBodyType.municipality,
        district: 'Kollam',
        palliativeUnits: ['Karunagappally Taluk Palliative Center', 'Thazhava Care Clinic'],
        medicareCenters: ['Taluk Hospital Karunagappally', 'Coastal PHC Alappad'],
        registeredClubsAndSocieties: ['Karunagappally Social Service Society', 'Thazhava Youth Forum'],
        wards: ['Ward 4 - Kozhikode Ward (Kollam)', 'Ward 15 - Town Ward', 'Ward 27 - Maruthoorkulangara'],
      ),
    ],

    // =========================================================================
    // 10. ALAPPUZHA DISTRICT (ആലപ്പുഴ)
    // =========================================================================
    'Alappuzha': [
      const LocalBodyInfo(
        name: 'Alappuzha Municipality',
        type: LocalBodyType.municipality,
        district: 'Alappuzha',
        palliativeUnits: [
          'T.D. Medical College Palliative Clinic',
          'Alappuzha Karunya Palliative Wing',
          'Kuttanad Water Boat Ambulance Palliative Unit',
        ],
        medicareCenters: [
          'Government T.D. Medical College Hospital Vandanam',
          'General Hospital Alappuzha',
        ],
        registeredClubsAndSocieties: ['Rotary Club of Alleppey', 'Coir Workers Palliative Samithi'],
        wards: ['Ward 5 - Beach Ward', 'Ward 18 - Mullakkal', 'Ward 30 - Kalarcode', 'Ward 40 - Sanathanapuram'],
      ),
      const LocalBodyInfo(
        name: 'Cherthala Municipality',
        type: LocalBodyType.municipality,
        district: 'Alappuzha',
        palliativeUnits: ['Cherthala Taluk Palliative Center', 'KVM Palliative Outreach'],
        medicareCenters: ['Taluk Hospital Cherthala', 'KVM Super Speciality Outreach'],
        registeredClubsAndSocieties: ['St. Michael Care Desk', 'Cherthala Lions Club'],
        wards: ['Ward 4 - Town North', 'Ward 12 - Railway Station Ward', 'Ward 22 - Kadakkarappally Road'],
      ),
    ],

    // =========================================================================
    // 11. KOTTAYAM DISTRICT (കോട്ടയം)
    // =========================================================================
    'Kottayam': [
      const LocalBodyInfo(
        name: 'Kottayam Municipality',
        type: LocalBodyType.municipality,
        district: 'Kottayam',
        palliativeUnits: [
          'Kottayam Medical College Palliative Department',
          'Karunya Palliative Care Society Kottayam',
          'Caritas Palliative Oncology Center',
        ],
        medicareCenters: [
          'Government Medical College Hospital Gandhinagar',
          'District Hospital Kottayam',
          'Caritas Cancer Institute',
        ],
        registeredClubsAndSocieties: ['CMS College NSS Care Cell', 'Rotary Club of Kottayam Greater'],
        wards: ['Ward 4 - Thirunakkara', 'Ward 15 - Nagampadam', 'Ward 28 - Kanjikuzhy', 'Ward 36 - Gandhinagar'],
      ),
      const LocalBodyInfo(
        name: 'Changanassery Municipality',
        type: LocalBodyType.municipality,
        district: 'Kottayam',
        palliativeUnits: ['General Hospital Changanassery Palliative Desk', 'NSS Headquarters Social Care Cell'],
        medicareCenters: ['General Hospital Changanassery', 'FHC Perunna'],
        registeredClubsAndSocieties: ['Nair Service Society (NSS) Medical Wing', 'SB College NSS Palliative Unit'],
        wards: ['Ward 6 - Perunna', 'Ward 14 - Market Ward', 'Ward 25 - Vazhoor Road'],
      ),
    ],

    // =========================================================================
    // 12. PATHANAMTHITTA DISTRICT (പത്തനംതിട്ട)
    // =========================================================================
    'Pathanamthitta': [
      const LocalBodyInfo(
        name: 'Pathanamthitta Municipality',
        type: LocalBodyType.municipality,
        district: 'Pathanamthitta',
        palliativeUnits: [
          'General Hospital Pathanamthitta Palliative Wing',
          'Ashraya Palliative Clinic',
        ],
        medicareCenters: ['General Hospital Pathanamthitta', 'FHC Kumbazha'],
        registeredClubsAndSocieties: ['Catholicate College NSS Care Desk', 'Pathanamthitta Rotary Club'],
        wards: ['Ward 3 - Ring Road', 'Ward 11 - College Ward', 'Ward 22 - Kumbazha'],
      ),
      const LocalBodyInfo(
        name: 'Thiruvalla Municipality',
        type: LocalBodyType.municipality,
        district: 'Pathanamthitta',
        palliativeUnits: ['Pushpagiri Medical College Palliative Dept', 'Believers Church Palliative Wing'],
        medicareCenters: ['Taluk Hospital Thiruvalla', 'Pushpagiri Medical College Hospital'],
        registeredClubsAndSocieties: ['Mar Thoma Medical Care Network', 'Thiruvalla Lions Club'],
        wards: ['Ward 5 - Cross Junction', 'Ward 14 - SCS Junction', 'Ward 28 - Manjadi'],
      ),
    ],

    // =========================================================================
    // 13. IDUKKI DISTRICT (ഇടുക്കി)
    // =========================================================================
    'Idukki': [
      const LocalBodyInfo(
        name: 'Thodupuzha Municipality',
        type: LocalBodyType.municipality,
        district: 'Idukki',
        palliativeUnits: [
          'Thodupuzha District Hospital Palliative Care Center',
          'High Range Palliative Society',
          'Al-Azhar Medical College Palliative Wing',
        ],
        medicareCenters: ['District Hospital Thodupuzha', 'Al-Azhar Medical College Hospital'],
        registeredClubsAndSocieties: ['Newman College NSS Palliative Wing', 'Thodupuzha Lions Club'],
        wards: ['Ward 2 - Mangattukavala', 'Ward 14 - Gandhi Square', 'Ward 26 - Vengalloor'],
      ),
      const LocalBodyInfo(
        name: 'Munnar Grama Panchayat',
        type: LocalBodyType.gramaPanchayat,
        district: 'Idukki',
        palliativeUnits: ['KDHP Tea Plantation Workers Palliative Unit', 'Munnar High Altitude Clinic'],
        medicareCenters: ['General Hospital Munnar', 'Tata Tea General Hospital'],
        registeredClubsAndSocieties: ['KDHP Plantation Workers Welfare Club', 'Munnar Rotary Club'],
        wards: ['Ward 2 - Old Munnar', 'Ward 7 - Colony Ward', 'Ward 14 - Mattupetty'],
      ),
    ],

    // =========================================================================
    // 14. KASARAGOD DISTRICT (കാസർഗോഡ്)
    // =========================================================================
    'Kasaragod': [
      const LocalBodyInfo(
        name: 'Kasaragod Municipality',
        type: LocalBodyType.municipality,
        district: 'Kasaragod',
        palliativeUnits: [
          'General Hospital Kasaragod Palliative Care Center',
          'Endosulfan Victims Special Palliative Care Wing',
          'Malik Dinar Palliative Clinic',
        ],
        medicareCenters: [
          'General Hospital Kasaragod',
          'Government Medical College Kasaragod (Ukkinadka)',
        ],
        registeredClubsAndSocieties: [
          'Endosulfan Relief and Remediation Cell',
          'Rotary Club of Kasaragod Midtown',
          'Malik Dinar Charitable Trust',
        ],
        wards: ['Ward 5 - Nullippady', 'Ward 14 - Karanthakkad', 'Ward 27 - Thalangara', 'Ward 36 - Vidyanagar'],
      ),
      const LocalBodyInfo(
        name: 'Kanhangad Municipality',
        type: LocalBodyType.municipality,
        district: 'Kasaragod',
        palliativeUnits: ['District Hospital Kanhangad Palliative Wing', 'Anandashram Palliative Unit'],
        medicareCenters: ['District Hospital Kanhangad', 'Nithyananda Medical Dispensary'],
        registeredClubsAndSocieties: ['Anandashram Social Care Wing', 'Nehru Arts College NSS Palliative Unit'],
        wards: ['Ward 4 - Hosdurg', 'Ward 15 - Kotikulam', 'Ward 28 - Bellikoth'],
      ),
    ],
  };

  /// Returns all local bodies for a district
  static List<LocalBodyInfo> getLocalBodies(String district) {
    return _keralaDirectory[district] ?? [];
  }

  /// Returns all palliative care units in a local body
  static List<String> getPalliativeUnits({required String district, required String localBodyName}) {
    final bodies = getLocalBodies(district);
    final match = bodies.firstWhere(
      (b) => b.name.toLowerCase() == localBodyName.toLowerCase(),
      orElse: () => bodies.isNotEmpty ? bodies.first : const LocalBodyInfo(name: '', type: LocalBodyType.gramaPanchayat, district: '', palliativeUnits: [], wards: []),
    );
    return match.palliativeUnits;
  }

  /// Returns all medicare centers in a local body
  static List<String> getMedicareCenters({required String district, required String localBodyName}) {
    final bodies = getLocalBodies(district);
    final match = bodies.firstWhere(
      (b) => b.name.toLowerCase() == localBodyName.toLowerCase(),
      orElse: () => bodies.isNotEmpty ? bodies.first : const LocalBodyInfo(name: '', type: LocalBodyType.gramaPanchayat, district: '', palliativeUnits: [], wards: []),
    );
    return match.medicareCenters;
  }

  /// Returns all registered clubs and palliative societies in a local body
  static List<String> getRegisteredClubs({required String district, required String localBodyName}) {
    final bodies = getLocalBodies(district);
    final match = bodies.firstWhere(
      (b) => b.name.toLowerCase() == localBodyName.toLowerCase(),
      orElse: () => bodies.isNotEmpty ? bodies.first : const LocalBodyInfo(name: '', type: LocalBodyType.gramaPanchayat, district: '', palliativeUnits: [], wards: []),
    );
    return match.registeredClubsAndSocieties;
  }

  /// Returns all wards for a local body
  static List<String> getWards({required String district, required String localBodyName}) {
    final bodies = getLocalBodies(district);
    final match = bodies.firstWhere(
      (b) => b.name.toLowerCase() == localBodyName.toLowerCase(),
      orElse: () => bodies.isNotEmpty ? bodies.first : const LocalBodyInfo(name: '', type: LocalBodyType.gramaPanchayat, district: '', palliativeUnits: [], wards: []),
    );
    return match.wards;
  }

  static List<LocationSearchResult>? _preIndexedCache;

  static List<LocationSearchResult> _getIndex() {
    if (_preIndexedCache != null) return _preIndexedCache!;

    final list = <LocationSearchResult>[];
    for (final entry in _keralaDirectory.entries) {
      final district = entry.key;
      for (final body in entry.value) {
        // 1. Local Body
        list.add(
          LocationSearchResult(
            title: body.name,
            subtitle: '$district District • ${body.type.displayName}',
            district: district,
            localBody: body.name,
            category: 'Local Self Government (LSGD)',
            palliativeUnit: body.palliativeUnits.isNotEmpty ? body.palliativeUnits.first : null,
          ),
        );

        // 2. Dedicated Palliative Care Units
        for (final unit in body.palliativeUnits) {
          list.add(
            LocationSearchResult(
              title: unit,
              subtitle: '${body.name}, $district (Palliative Care Unit)',
              district: district,
              localBody: body.name,
              palliativeUnit: unit,
              category: 'Palliative Unit',
            ),
          );
        }

        // 3. Medicare Centers (Hospitals / FHCs / CHCs)
        for (final med in body.medicareCenters) {
          list.add(
            LocationSearchResult(
              title: med,
              subtitle: '${body.name}, $district (Government & Hospital Centre)',
              district: district,
              localBody: body.name,
              medicareCenter: med,
              category: 'Medicare & Hospital',
              palliativeUnit: body.palliativeUnits.isNotEmpty ? body.palliativeUnits.first : null,
            ),
          );
        }

        // 4. Registered Clubs, Kudumbashree & Volunteer Societies
        for (final club in body.registeredClubsAndSocieties) {
          list.add(
            LocationSearchResult(
              title: club,
              subtitle: '${body.name}, $district (Registered Club & Social Forum)',
              district: district,
              localBody: body.name,
              registeredClub: club,
              category: 'Registered Club & Society',
              palliativeUnit: body.palliativeUnits.isNotEmpty ? body.palliativeUnits.first : null,
            ),
          );
        }

        // 5. Wards & Localities
        for (final ward in body.wards) {
          list.add(
            LocationSearchResult(
              title: ward,
              subtitle: '${body.name}, $district (Ward / Locality)',
              district: district,
              localBody: body.name,
              ward: ward,
              category: 'Ward / Locality',
              palliativeUnit: body.palliativeUnits.isNotEmpty ? body.palliativeUnits.first : null,
            ),
          );
        }
      }
    }
    _preIndexedCache = list;
    return list;
  }

  /// Instant Ultra-Fast Search from In-Memory Pre-Indexed Directory
  static List<LocationSearchResult> searchLocations(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase().trim();
    final index = _getIndex();

    final results = <LocationSearchResult>[];
    for (int i = 0; i < index.length; i++) {
      final item = index[i];
      if (item.title.toLowerCase().contains(q) ||
          item.district.toLowerCase().contains(q) ||
          item.localBody.toLowerCase().contains(q) ||
          (item.medicareCenter?.toLowerCase().contains(q) ?? false) ||
          (item.registeredClub?.toLowerCase().contains(q) ?? false)) {
        results.add(item);
        if (results.length >= 15) break; // Return top 15 matches instantly
      }
    }
    return results;
  }
}
