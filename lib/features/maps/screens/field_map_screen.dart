import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../models/map_marker_model.dart';
import '../widgets/interactive_map_canvas.dart';

class FieldMapScreen extends StatefulWidget {
  final AppStateProvider state;
  final String? initialTargetPatientName;
  final VisitModel? initialVisit;

  const FieldMapScreen({
    super.key,
    required this.state,
    this.initialTargetPatientName,
    this.initialVisit,
  });

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  late List<MapMarkerModel> _allMarkers;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  MapMarkerModel? _selectedMarker;
  MapMarkerModel? _activeNavigationTarget;

  bool _isNavigating = false;
  double _navigationProgress = 0.0;
  Timer? _navigationTimer;
  int _currentStepIndex = 0;
  bool _isVoiceMuted = false;

  bool _isSatelliteMode = false;
  bool _isNightMode = false;

  final List<MapWaypoint> _sampleWaypoints = [
    const MapWaypoint(
      latitude: 11.2588,
      longitude: 75.7804,
      instruction: 'Start from Kozhikode Palliative Health Hub',
      roadName: 'Beach - Medical College Link Road',
      distanceMeters: 200,
    ),
    const MapWaypoint(
      latitude: 11.2610,
      longitude: 75.7830,
      instruction: 'In 350m, Turn Left onto Mavoor Main Highway',
      roadName: 'Mavoor Road (SH 34)',
      distanceMeters: 850,
    ),
    const MapWaypoint(
      latitude: 11.2635,
      longitude: 75.7865,
      instruction: 'Continue straight through Kuttikkattoor Junction',
      roadName: 'Mavoor - Medical College Byepass',
      distanceMeters: 1200,
    ),
    const MapWaypoint(
      latitude: 11.2660,
      longitude: 75.7890,
      instruction: 'In 400m, Turn Right at Temple Junction into Ward 12 lane',
      roadName: 'Ward Community Road',
      distanceMeters: 600,
    ),
    const MapWaypoint(
      latitude: 11.2680,
      longitude: 75.7910,
      instruction: 'Arriving at Patient Residence on the Left',
      roadName: 'Karthyayani Amma Residence (House #42)',
      distanceMeters: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeMarkers();

    if (widget.initialTargetPatientName != null || widget.initialVisit != null) {
      final targetName = widget.initialTargetPatientName ?? widget.initialVisit!.patientName;
      final found = _allMarkers.firstWhere(
        (m) => m.title.toLowerCase().contains(targetName.toLowerCase()),
        orElse: () => _allMarkers.first,
      );
      _selectedMarker = found;
      _activeNavigationTarget = found;
    } else if (_allMarkers.isNotEmpty) {
      _selectedMarker = _allMarkers.first;
      _activeNavigationTarget = _allMarkers.first;
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _initializeMarkers() {
    _allMarkers = [
      // Health Center Base
      const MapMarkerModel(
        id: 'BASE-01',
        title: 'Kozhikode Palliative Hub',
        subtitle: 'Main Community Nursing Center & Dispatch Base',
        latitude: 11.2588,
        longitude: 75.7804,
        type: MapMarkerType.healthCenter,
        distanceKm: 0.0,
        etaMinutes: 0,
      ),

      // Patients
      MapMarkerModel(
        id: 'PAT-01',
        title: 'Karthyayani Amma',
        subtitle: 'Ward 12, Mavoor, Kozhikode',
        latitude: 11.2680,
        longitude: 75.7910,
        type: MapMarkerType.patientCategoryA,
        categoryTier: 'Category A',
        phone: '+91 98470 12345',
        diagnosis: 'Post-CVA Bedridden with Grade 3 Sacral Pressure Ulcer',
        urgency: 'High Urgency (Daily Dressing)',
        distanceKm: 2.8,
        etaMinutes: 9,
        routeWaypoints: _sampleWaypoints,
      ),
      const MapMarkerModel(
        id: 'PAT-02',
        title: 'Aboobacker Haji',
        subtitle: 'Ward 8, Feroke, Kozhikode',
        latitude: 11.2480,
        longitude: 75.7760,
        type: MapMarkerType.patientCategoryA,
        categoryTier: 'Category A',
        phone: '+91 94471 67890',
        diagnosis: 'Advanced Bronchogenic Carcinoma (Severe Dyspnea & Pain)',
        urgency: 'Pain Escalation Protocol',
        distanceKm: 4.2,
        etaMinutes: 14,
      ),
      const MapMarkerModel(
        id: 'PAT-03',
        title: 'Sukumaran Nair',
        subtitle: 'Ward 3, Medical College, Kozhikode',
        latitude: 11.2740,
        longitude: 75.7980,
        type: MapMarkerType.patientCategoryB,
        categoryTier: 'Category B',
        phone: '+91 97455 22334',
        diagnosis: 'Parkinsonism with Severe Mobility Limitation',
        urgency: 'Physiotherapy & Nutrition',
        distanceKm: 3.5,
        etaMinutes: 11,
      ),
      const MapMarkerModel(
        id: 'PAT-04',
        title: 'Mariyamma Thomas',
        subtitle: 'Ward 5, Beypore, Kozhikode',
        latitude: 11.2420,
        longitude: 75.7680,
        type: MapMarkerType.patientCategoryC,
        categoryTier: 'Category C',
        phone: '+91 98950 44556',
        diagnosis: 'Diabetic Peripheral Neuropathy & Foot Ulcer',
        urgency: 'Bi-weekly Follow-up',
        distanceKm: 5.1,
        etaMinutes: 16,
      ),

      // Ambulances
      const MapMarkerModel(
        id: 'AMB-01',
        title: 'Ambulance KL-11-AV-9012',
        subtitle: 'Driver: Rajesh Kumar • Kozhikode Civil Station',
        latitude: 11.2640,
        longitude: 75.7880,
        type: MapMarkerType.ambulanceAvailable,
        vehicleNumber: 'KL-11-AV-9012',
        phone: '+91 94470 11223',
        distanceKm: 1.4,
        etaMinutes: 4,
      ),
      const MapMarkerModel(
        id: 'AMB-02',
        title: 'Ambulance KL-11-EM-1108',
        subtitle: 'Driver: Faisal K. • Dispatched to Calicut Med College',
        latitude: 11.2710,
        longitude: 75.7940,
        type: MapMarkerType.ambulanceDispatched,
        vehicleNumber: 'KL-11-EM-1108',
        phone: '+91 98471 99887',
        distanceKm: 3.1,
        etaMinutes: 8,
      ),

      // Oxygen Depot
      const MapMarkerModel(
        id: 'DEPOT-01',
        title: 'Kozhikode Community Oxygen Depot',
        subtitle: '12 Oxygen Concentrators & 8 Water Beds in Reserve',
        latitude: 11.2560,
        longitude: 75.7820,
        type: MapMarkerType.oxygenDepot,
        phone: '+91 495 2720000',
        distanceKm: 0.6,
        etaMinutes: 2,
      ),

      // Emergency Blood Donor
      const MapMarkerModel(
        id: 'DONOR-01',
        title: 'Donor: Shaji Mathew (O+)',
        subtitle: 'Eligible Blood Donor • Kozhikode City',
        latitude: 11.2600,
        longitude: 75.7790,
        type: MapMarkerType.bloodDonor,
        phone: '+91 98470 55443',
        distanceKm: 0.9,
        etaMinutes: 3,
      ),
    ];
  }

  void _startNavigationSimulation() {
    setState(() {
      _isNavigating = true;
      _navigationProgress = 0.0;
      _currentStepIndex = 0;
    });

    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _navigationProgress += 0.025;
        if (_navigationProgress >= 1.0) {
          _navigationProgress = 1.0;
          _isNavigating = false;
          timer.cancel();
          _showArrivalDialog();
        } else {
          final step = (_navigationProgress * (_sampleWaypoints.length - 1)).floor();
          _currentStepIndex = step.clamp(0, _sampleWaypoints.length - 1);
        }
      });
    });
  }

  void _stopNavigationSimulation() {
    _navigationTimer?.cancel();
    setState(() {
      _isNavigating = false;
      _navigationProgress = 0.0;
    });
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text('Arrived at Patient Home!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          'You have reached ${_activeNavigationTarget?.title ?? "Patient Residence"}.\n\nWould you like to log the verified GPS Check-In on the clinical record now?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _handleGpsCheckIn();
            },
            icon: const Icon(Icons.gps_fixed_rounded, size: 16),
            label: const Text('Log GPS Check-In'),
          ),
        ],
      ),
    );
  }

  void _handleGpsCheckIn() {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')} AM';
    final locationName = '${_activeNavigationTarget?.title} Residence (11.2680° N, 75.7910° E)';

    if (widget.initialVisit != null) {
      widget.initialVisit!.gpsCheckInTime = timeStr;
      widget.initialVisit!.gpsLocationName = locationName;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Verified GPS Check-In logged at $timeStr: $locationName'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showOptimalTourPlanner(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2620) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alt_route_rounded, color: AppColors.primaryGreen, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Multi-Stop Route Optimizer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI Sequenced 4 Patient Visits: Saves 3.4 km & ~28 mins travel time for rural nurse team today.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Optimized Visit Sequence (Kozhikode Ward Loop):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTourStepTile('Start Base', 'Kozhikode Palliative Health Hub', '0.0 km', Icons.local_hospital_rounded, Colors.teal),
              _buildTourStepTile('Stop 1', 'Karthyayani Amma (Category A • Daily Ulcer Dressing)', '2.8 km', Icons.personal_injury_rounded, AppColors.danger),
              _buildTourStepTile('Stop 2', 'Sukumaran Nair (Category B • Parkinson Mobility)', '5.2 km', Icons.elderly_rounded, AppColors.warning),
              _buildTourStepTile('Stop 3', 'Aboobacker Haji (Category A • Pain Protocol Refill)', '8.4 km', Icons.personal_injury_rounded, AppColors.danger),
              _buildTourStepTile('Stop 4', 'Mariyamma Thomas (Category C • Diabetic Foot Dressing)', '11.8 km', Icons.accessible_rounded, AppColors.info),
              _buildTourStepTile('End Base', 'Return to Kozhikode Palliative Hub', '14.2 km Total', Icons.flag_rounded, Colors.teal),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startNavigationSimulation();
                  },
                  icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                  label: const Text('Start Optimized Field Tour', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTourStepTile(String step, String label, String dist, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(step, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(dist, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  List<MapMarkerModel> get _filteredMarkers {
    return _allMarkers.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.diagnosis?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Category A') return m.type == MapMarkerType.patientCategoryA;
      if (_selectedFilter == 'Patients') {
        return m.type == MapMarkerType.patientCategoryA ||
            m.type == MapMarkerType.patientCategoryB ||
            m.type == MapMarkerType.patientCategoryC;
      }
      if (_selectedFilter == 'Ambulances') {
        return m.type == MapMarkerType.ambulanceAvailable ||
            m.type == MapMarkerType.ambulanceDispatched;
      }
      if (_selectedFilter == 'Depots & Donors') {
        return m.type == MapMarkerType.oxygenDepot ||
            m.type == MapMarkerType.bloodDonor;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || _isNightMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Field Map & GPS Navigation'),
        actions: [
          IconButton(
            tooltip: 'AI Multi-Stop Tour Optimizer',
            icon: const Icon(Icons.alt_route_rounded, color: AppColors.accentGold),
            onPressed: () => _showOptimalTourPlanner(context, isDark),
          ),
          IconButton(
            tooltip: _isSatelliteMode ? 'Switch to Standard Map' : 'Switch to Satellite Map',
            icon: Icon(
              _isSatelliteMode ? Icons.map_rounded : Icons.satellite_alt_rounded,
              color: _isSatelliteMode ? AppColors.accentGold : null,
            ),
            onPressed: () => setState(() => _isSatelliteMode = !_isSatelliteMode),
          ),
          IconButton(
            tooltip: _isNightMode ? 'Switch to Day Mode' : 'Switch to Night Mode Navigation',
            icon: Icon(
              _isNightMode ? Icons.light_mode_rounded : Icons.nightlight_round,
              color: _isNightMode ? AppColors.accentGold : null,
            ),
            onPressed: () => setState(() => _isNightMode = !_isNightMode),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full Canvas Interactive Vector Map
          Positioned.fill(
            child: InteractiveMapCanvas(
              markers: _filteredMarkers,
              selectedMarker: _selectedMarker,
              activeNavigationTarget: _activeNavigationTarget,
              isNavigating: _isNavigating,
              navigationProgress: _navigationProgress,
              isSatelliteMode: _isSatelliteMode,
              isNightMode: _isNightMode,
              onMarkerSelected: (marker) {
                setState(() {
                  _selectedMarker = marker;
                  _activeNavigationTarget = marker;
                });
              },
            ),
          ),

          // 2. Top Navigation Turn-by-Turn HUD (Visible during Live Navigation)
          if (_isNavigating)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildTurnByTurnHud(isDark),
            ),

          // 3. Top Search & Category Filter Chips Bar (Visible when not actively navigating)
          if (!_isNavigating)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(isDark),
                  const SizedBox(height: 8),
                  _buildCategoryFilterBar(isDark),
                ],
              ),
            ),

          // 4. Offline Map Tiles Cache Status Pill
          Positioned(
            left: 16,
            bottom: _selectedMarker != null ? 200 : 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2620) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Offline GIS Vector Cached (Kerala PHC)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Interactive Patient / Marker Information Sheet Card
          if (_selectedMarker != null)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildMarkerDetailCard(_selectedMarker!, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? const Color(0xFF1E2620) : Colors.white,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search patient, ward, ambulance, or depot...',
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTurnByTurnHud(bool isDark) {
    final currentStep = _sampleWaypoints[_currentStepIndex];
    final remainingKm = ((1.0 - _navigationProgress) * (_activeNavigationTarget?.distanceKm ?? 2.8)).toStringAsFixed(1);
    final remainingMin = ((1.0 - _navigationProgress) * (_activeNavigationTarget?.etaMinutes ?? 9)).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B261D) : const Color(0xFF0F381E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(color: const Color(0xFF00E676), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.turn_slight_left_rounded, color: Colors.black87, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep.instruction,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentStep.roadName,
                      style: const TextStyle(color: Color(0xFFB9F6CA), fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isVoiceMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _isVoiceMuted = !_isVoiceMuted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isVoiceMuted ? 'Voice Guidance Muted' : 'Voice Guidance Enabled'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Toggle Voice Guidance',
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: _stopNavigationSimulation,
                tooltip: 'Stop Navigation',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$remainingKm km • $remainingMin mins left',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Speed: 38 km/h', style: TextStyle(color: Color(0xFFB9F6CA), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleGpsCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Check-In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _navigationProgress,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          'All',
          'Category A',
          'Patients',
          'Ambulances',
          'Depots & Donors',
        ].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
              backgroundColor: isDark ? const Color(0xFF1E2620) : Colors.white,
              elevation: 3,
              checkmarkColor: Colors.white,
              onSelected: (_) => setState(() => _selectedFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarkerDetailCard(MapMarkerModel marker, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: marker.color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: marker.color.withValues(alpha: 0.15),
                  child: Icon(marker.icon, color: marker.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        marker.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: marker.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${marker.distanceKm} km • ${marker.etaMinutes}m',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: marker.color),
                  ),
                ),
              ],
            ),
            if (marker.diagnosis != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Diagnosis: ${marker.diagnosis!}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (marker.phone != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${marker.title} at ${marker.phone}...')),
                        );
                      },
                      icon: const Icon(Icons.call_rounded, size: 14),
                      label: const Text('Call', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isNavigating ? _stopNavigationSimulation : _startNavigationSimulation,
                    icon: Icon(_isNavigating ? Icons.stop_circle_outlined : Icons.navigation_rounded, size: 14),
                    label: Text(
                      _isNavigating ? 'Stop Navigation' : 'Start GPS Navigation',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating ? AppColors.danger : (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
