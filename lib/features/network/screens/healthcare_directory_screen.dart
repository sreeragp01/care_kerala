import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/carelink_brand_logo.dart';
import 'hospital_detail_screen.dart';
import 'doctor_detail_screen.dart';
import 'join_carelink_screen.dart';
import 'hospital_management_dashboard.dart';
import 'platform_network_admin_screen.dart';

class HealthcareDirectoryScreen extends StatefulWidget {
  final AppStateProvider state;

  const HealthcareDirectoryScreen({super.key, required this.state});

  @override
  State<HealthcareDirectoryScreen> createState() => _HealthcareDirectoryScreenState();
}

class _HealthcareDirectoryScreenState extends State<HealthcareDirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _keralaDistricts = const [
    'All Districts',
    'Kozhikode',
    'Ernakulam',
    'Thiruvananthapuram',
    'Wayanad',
    'Thrissur',
    'Malappuram',
    'Kannur',
    'Palakkad',
    'Kottayam',
    'Alappuzha',
    'Idukki',
    'Pathanamthitta',
    'Kollam',
    'Kasaragod',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final isDark = state.isDarkMode;
        final user = state.currentUser;
        final isSuperAdmin = user.role.name == 'superAdmin';
        final isHospitalStaff = user.role.name == 'orgAdmin' || user.role.name == 'doctor' || user.role.name == 'nurse';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CareLinkBrandLogo(size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'CareLink Network',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        '2.0',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandTeal),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Verified Healthcare Directory across Kerala',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              if (isSuperAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandHealthGreen),
                  tooltip: 'Platform Network Admin',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlatformNetworkAdminScreen(state: widget.state)),
                  ),
                )
              else if (isHospitalStaff)
                IconButton(
                  icon: const Icon(Icons.business_rounded, color: AppColors.brandTeal),
                  tooltip: 'Hospital Workspace',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HospitalManagementDashboard(state: widget.state)),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.app_registration_rounded),
                tooltip: 'Join CareLink Network',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JoinCareLinkScreen(state: widget.state)),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.brandTeal,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.brandTeal,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.local_hospital_rounded, size: 18), text: 'Hospitals & Units'),
                Tab(icon: Icon(Icons.medical_services_rounded, size: 18), text: 'Verified Doctors'),
                Tab(icon: Icon(Icons.emergency_rounded, size: 18), text: '24x7 Emergency Care'),
                Tab(icon: Icon(Icons.volunteer_activism_rounded, size: 18), text: 'Palliative Centers'),
              ],
            ),
          ),
          body: GlassScaffoldBackground(
            child: Column(
              children: [
                _buildFilterHeader(state, isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHospitalsList(state, isDark, filterType: null),
                      _buildDoctorsList(state, isDark),
                      _buildEmergencyList(state, isDark),
                      _buildHospitalsList(state, isDark, filterType: 'Palliative Care Center'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JoinCareLinkScreen(state: widget.state)),
            ),
            backgroundColor: AppColors.brandNavy,
            icon: const Icon(Icons.add_business_rounded, color: Colors.white),
            label: const Text('Join CareLink', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildFilterHeader(AppStateProvider state, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => state.setNetworkSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search hospital, doctor, specialty...',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              state.setNetworkSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.networkDistrictFilter != 'All Districts'
                        ? AppColors.brandTeal
                        : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.networkDistrictFilter,
                    icon: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.brandTeal),
                    dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    items: _keralaDistricts.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) state.setNetworkDistrictFilter(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSpecialtyChip(
                  label: 'All Specialties',
                  isSelected: state.networkSpecialtyFilter == null,
                  onTap: () => state.setNetworkSpecialtyFilter(null),
                  isDark: isDark,
                ),
                ...state.specialties.map((s) {
                  final isSelected = state.networkSpecialtyFilter == s.name;
                  return _buildSpecialtyChip(
                    label: s.name,
                    isSelected: isSelected,
                    onTap: () => state.setNetworkSpecialtyFilter(isSelected ? null : s.name),
                    isDark: isDark,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.brandTeal.withValues(alpha: 0.2),
        checkmarkColor: AppColors.brandTeal,
        labelStyle: TextStyle(
          color: isSelected
              ? AppColors.brandTeal
              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.brandTeal : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalsList(AppStateProvider state, bool isDark, {String? filterType}) {
    var list = state.filteredHealthcareProfiles;
    if (filterType != null) {
      list = list.where((h) => h.organizationType.toLowerCase().contains(filterType.toLowerCase())).toList();
    }

    if (list.isEmpty) {
      return _buildEmptyState(isDark, 'No healthcare centers found matching your filters.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hospital = list[index];
        return _buildHospitalCard(hospital, isDark);
      },
    );
  }

  Widget _buildHospitalCard(HealthcareProfileModel hospital, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hospital, state: widget.state)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${hospital.district} • ${hospital.organizationType}',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hospital.isCareLinkVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandHealthGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.brandHealthGreen.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 14, color: AppColors.brandHealthGreen),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hospital.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hospital.is24x7Emergency)
                  _buildMiniBadge(Icons.emergency_rounded, '24x7 Emergency', Colors.redAccent),
                if (hospital.ambulanceAvailable)
                  _buildMiniBadge(Icons.airport_shuttle_rounded, 'Ambulance', AppColors.brandNavy),
                if (hospital.totalBeds > 0)
                  _buildMiniBadge(Icons.bed_rounded, '${hospital.totalBeds} Beds', Colors.blueGrey),
                if (hospital.doctors.isNotEmpty)
                  _buildMiniBadge(Icons.medical_services_rounded, '${hospital.doctors.length} Doctors', AppColors.brandTeal),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Updated: ${hospital.lastVerifiedDate}',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
                ),
                Row(
                  children: [
                    const Text(
                      'View Profile',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandTeal),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandTeal),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(AppStateProvider state, bool isDark) {
    var docs = state.doctors;
    if (state.networkDistrictFilter != 'All Districts') {
      docs = docs.where((d) => d.district.toLowerCase() == state.networkDistrictFilter.toLowerCase()).toList();
    }
    if (state.networkSpecialtyFilter != null) {
      docs = docs.where((d) => d.specialty.toLowerCase().contains(state.networkSpecialtyFilter!.toLowerCase())).toList();
    }
    if (state.networkSearchQuery.isNotEmpty) {
      final q = state.networkSearchQuery.toLowerCase();
      docs = docs.where((d) => d.name.toLowerCase().contains(q) || d.specialty.toLowerCase().contains(q) || d.organizationName.toLowerCase().contains(q)).toList();
    }

    if (docs.isEmpty) {
      return _buildEmptyState(isDark, 'No verified doctors found matching your criteria.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doctor = docs[index];
        return _buildDoctorCard(doctor, isDark);
      },
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor, state: widget.state)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
                  child: Text(
                    doctor.name.split(' ').length > 1 ? doctor.name.split(' ')[1][0] : 'D',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.brandTeal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.brandHealthGreen),
                        ],
                      ),
                      Text(
                        '${doctor.specialty} • ${doctor.experienceYears}y exp',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandTeal),
                      ),
                      Text(
                        doctor.organizationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              doctor.qualification,
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (doctor.schedules.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.brandHealthGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${doctor.schedules.first.dayOfWeek}: ${doctor.schedules.first.startTime} - ${doctor.schedules.first.endTime} (${doctor.schedules.first.locationRoom})',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doctor.consultationFee > 0 ? 'Fee: ₹${doctor.consultationFee.toInt()}' : 'Free / Trust Consultation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: doctor.consultationFee == 0 ? AppColors.brandHealthGreen : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor, state: widget.state)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(80, 32),
                  ),
                  child: const Text('Consult', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyList(AppStateProvider state, bool isDark) {
    final list = state.filteredHealthcareProfiles.where((h) => h.is24x7Emergency).toList();
    if (list.isEmpty) {
      return _buildEmptyState(isDark, 'No 24x7 Emergency Units found in the selected district.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hospital = list[index];
        return _buildHospitalCard(hospital, isDark);
      },
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 54, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
