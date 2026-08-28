import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../localization/app_localizations.dart';
import '../services/kerala_location_service.dart';

class KeralaLocationSelector extends StatefulWidget {
  final String? initialDistrict;
  final String? initialLocalBody;
  final String? initialPalliativeUnit;
  final String? initialMedicareCenter;
  final String? initialRegisteredClub;
  final String? initialWard;
  final bool showPalliativeUnit;
  final bool showMedicareCenter;
  final bool showRegisteredClub;
  final bool showWard;
  final Function({
    required String district,
    required String localBody,
    String? palliativeUnit,
    String? medicareCenter,
    String? registeredClub,
    String? ward,
  }) onLocationChanged;

  const KeralaLocationSelector({
    super.key,
    this.initialDistrict,
    this.initialLocalBody,
    this.initialPalliativeUnit,
    this.initialMedicareCenter,
    this.initialRegisteredClub,
    this.initialWard,
    this.showPalliativeUnit = true,
    this.showMedicareCenter = true,
    this.showRegisteredClub = true,
    this.showWard = true,
    required this.onLocationChanged,
  });

  @override
  State<KeralaLocationSelector> createState() => _KeralaLocationSelectorState();
}

class _KeralaLocationSelectorState extends State<KeralaLocationSelector> {
  late String _selectedDistrict;
  String? _selectedLocalBody;
  String? _selectedPalliativeUnit;
  String? _selectedMedicareCenter;
  String? _selectedRegisteredClub;
  String? _selectedWard;

  final TextEditingController _searchController = TextEditingController();
  List<LocationSearchResult> _searchResults = const [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.initialDistrict ?? 'Kozhikode';
    _selectedLocalBody = widget.initialLocalBody;
    _selectedPalliativeUnit = widget.initialPalliativeUnit;
    _selectedMedicareCenter = widget.initialMedicareCenter;
    _selectedRegisteredClub = widget.initialRegisteredClub;
    _selectedWard = widget.initialWard;

    _syncDefaults(notify: false);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _syncDefaults({bool notify = true}) {
    final localBodies = KeralaLocationService.getLocalBodies(_selectedDistrict);
    if (localBodies.isNotEmpty) {
      if (_selectedLocalBody == null || !localBodies.any((b) => b.name == _selectedLocalBody)) {
        _selectedLocalBody = localBodies.first.name;
      }

      if (widget.showPalliativeUnit) {
        final units = KeralaLocationService.getPalliativeUnits(
          district: _selectedDistrict,
          localBodyName: _selectedLocalBody!,
        );
        if (units.isNotEmpty && (_selectedPalliativeUnit == null || !units.contains(_selectedPalliativeUnit))) {
          _selectedPalliativeUnit = units.first;
        }
      }

      if (widget.showMedicareCenter) {
        final medCenters = KeralaLocationService.getMedicareCenters(
          district: _selectedDistrict,
          localBodyName: _selectedLocalBody!,
        );
        if (medCenters.isNotEmpty && (_selectedMedicareCenter == null || !medCenters.contains(_selectedMedicareCenter))) {
          _selectedMedicareCenter = medCenters.first;
        }
      }

      if (widget.showRegisteredClub) {
        final clubs = KeralaLocationService.getRegisteredClubs(
          district: _selectedDistrict,
          localBodyName: _selectedLocalBody!,
        );
        if (clubs.isNotEmpty && (_selectedRegisteredClub == null || !clubs.contains(_selectedRegisteredClub))) {
          _selectedRegisteredClub = clubs.first;
        }
      }

      if (widget.showWard) {
        final wards = KeralaLocationService.getWards(
          district: _selectedDistrict,
          localBodyName: _selectedLocalBody!,
        );
        if (wards.isNotEmpty && (_selectedWard == null || !wards.contains(_selectedWard))) {
          _selectedWard = wards.first;
        }
      }
    }

    if (notify) {
      _notifyChange();
    }
  }

  void _notifyChange() {
    widget.onLocationChanged(
      district: _selectedDistrict,
      localBody: _selectedLocalBody ?? '',
      palliativeUnit: _selectedPalliativeUnit,
      medicareCenter: _selectedMedicareCenter,
      registeredClub: _selectedRegisteredClub,
      ward: _selectedWard,
    );
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = const [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final results = KeralaLocationService.searchLocations(query);
      setState(() {
        _isSearching = true;
        _searchResults = results;
      });
    });
  }

  void _selectSearchResult(LocationSearchResult result) {
    _debounceTimer?.cancel();
    setState(() {
      _selectedDistrict = result.district;
      _selectedLocalBody = result.localBody;
      if (result.palliativeUnit != null) {
        _selectedPalliativeUnit = result.palliativeUnit;
      }
      if (result.medicareCenter != null) {
        _selectedMedicareCenter = result.medicareCenter;
      }
      if (result.registeredClub != null) {
        _selectedRegisteredClub = result.registeredClub;
      }
      if (result.ward != null) {
        _selectedWard = result.ward;
      }
      _isSearching = false;
      _searchController.clear();
      _syncDefaults(notify: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isMalayalam = Localizations.localeOf(context).languageCode == 'ml';

    final localBodies = KeralaLocationService.getLocalBodies(_selectedDistrict);

    final currentBody = localBodies.firstWhere(
      (b) => b.name == _selectedLocalBody,
      orElse: () => localBodies.isNotEmpty ? localBodies.first : const LocalBodyInfo(name: '', type: LocalBodyType.gramaPanchayat, district: '', palliativeUnits: [], wards: []),
    );

    final palliativeUnits = currentBody.palliativeUnits;
    final medicareCenters = currentBody.medicareCenters;
    final registeredClubs = currentBody.registeredClubsAndSocieties;
    final wards = currentBody.wards;

    final safeLocalBody = localBodies.any((b) => b.name == _selectedLocalBody)
        ? _selectedLocalBody
        : (localBodies.isNotEmpty ? localBodies.first.name : null);

    final safePalliativeUnit = palliativeUnits.contains(_selectedPalliativeUnit)
        ? _selectedPalliativeUnit
        : (palliativeUnits.isNotEmpty ? palliativeUnits.first : null);

    final safeMedicareCenter = medicareCenters.contains(_selectedMedicareCenter)
        ? _selectedMedicareCenter
        : (medicareCenters.isNotEmpty ? medicareCenters.first : null);

    final safeRegisteredClub = registeredClubs.contains(_selectedRegisteredClub)
        ? _selectedRegisteredClub
        : (registeredClubs.isNotEmpty ? registeredClubs.first : null);

    final safeWard = wards.contains(_selectedWard)
        ? _selectedWard
        : (wards.isNotEmpty ? wards.first : null);

    final districtDisplayName = AppLocalizations.getDistrictName(_selectedDistrict, isMalayalam: isMalayalam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Instant Location Search & Auto-Suggest Bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: l10n.translate('search_location_hint'),
            hintText: 'e.g., Chevayur, Mavoor, Edappally, Pallium, Medical College...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResults = const [];
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        // Auto-Suggest Dropdown Results Card
        if (_isSearching && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2620) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = _searchResults[idx];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: item.category.contains('Hospital') || item.category.contains('Medicare')
                        ? Colors.blue.withValues(alpha: 0.15)
                        : (item.category.contains('Club')
                            ? Colors.purple.withValues(alpha: 0.15)
                            : AppColors.lightGreenSurface),
                    child: Icon(
                      item.category.contains('Hospital') || item.category.contains('Medicare')
                          ? Icons.local_hospital_rounded
                          : (item.category.contains('Club')
                              ? Icons.groups_rounded
                              : Icons.location_on_rounded),
                      size: 14,
                      color: item.category.contains('Hospital') || item.category.contains('Medicare')
                          ? Colors.blue
                          : (item.category.contains('Club') ? Colors.purple : AppColors.primaryGreen),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                  onTap: () => _selectSearchResult(item),
                );
              },
            ),
          ),
        ],

        // 2. Interactive District & Local Body Live Header Summary Card
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_city_rounded, color: AppColors.primaryGreen, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isMalayalam
                          ? '$districtDisplayName ജില്ല: ${currentBody.name}'
                          : '$_selectedDistrict District: ${currentBody.name}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentBody.type.displayName.split(' ').first,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• ${palliativeUnits.length} ${l10n.translate('summary_units')}  • ${medicareCenters.length} ${l10n.translate('summary_medicare')}  • ${registeredClubs.length} ${l10n.translate('summary_clubs')}  • ${wards.length} ${l10n.translate('summary_wards')}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Quick Local Body Selector Chips for Selected District
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: localBodies.map((body) {
              final isSelected = body.name == _selectedLocalBody;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  label: Text(
                    body.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen,
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() {
                      _selectedLocalBody = body.name;
                      _selectedPalliativeUnit = null;
                      _selectedMedicareCenter = null;
                      _selectedRegisteredClub = null;
                      _selectedWard = null;
                      _syncDefaults(notify: true);
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Cascading District Dropdown
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.translate('district_label'),
            prefixIcon: const Icon(Icons.map_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedDistrict,
              items: KeralaLocationService.districts.map((district) {
                final dName = AppLocalizations.getDistrictName(district, isMalayalam: isMalayalam);
                return DropdownMenuItem<String>(
                  value: district,
                  child: Text(
                    isMalayalam ? '$dName ($district)' : district,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newDistrict) {
                if (newDistrict != null && newDistrict != _selectedDistrict) {
                  setState(() {
                    _selectedDistrict = newDistrict;
                    _selectedLocalBody = null;
                    _selectedPalliativeUnit = null;
                    _selectedMedicareCenter = null;
                    _selectedRegisteredClub = null;
                    _selectedWard = null;
                    _syncDefaults(notify: true);
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 4. Cascading Municipality / Grama Panchayat / Corporation Dropdown
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.translate('local_body_label'),
            prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: safeLocalBody,
              items: localBodies.map((body) {
                return DropdownMenuItem<String>(
                  value: body.name,
                  child: Text('${body.name} (${body.type.displayName.split(' ').first})', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (newBody) {
                if (newBody != null && newBody != _selectedLocalBody) {
                  setState(() {
                    _selectedLocalBody = newBody;
                    _selectedPalliativeUnit = null;
                    _selectedMedicareCenter = null;
                    _selectedRegisteredClub = null;
                    _selectedWard = null;
                    _syncDefaults(notify: true);
                  });
                }
              },
            ),
          ),
        ),

        // 5. Associated Palliative Care Units Dropdown
        if (widget.showPalliativeUnit && palliativeUnits.isNotEmpty) ...[
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.translate('palliative_unit_label'),
              prefixIcon: const Icon(Icons.volunteer_activism_rounded, size: 20, color: AppColors.primaryGreen),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safePalliativeUnit,
                items: palliativeUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newUnit) {
                  if (newUnit != null && newUnit != _selectedPalliativeUnit) {
                    setState(() {
                      _selectedPalliativeUnit = newUnit;
                      _notifyChange();
                    });
                  }
                },
              ),
            ),
          ),
        ],

        // 6. Associated Medicare / Hospitals / FHCs Dropdown
        if (widget.showMedicareCenter && medicareCenters.isNotEmpty) ...[
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.translate('medicare_center_label'),
              prefixIcon: const Icon(Icons.local_hospital_rounded, size: 20, color: Colors.blue),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safeMedicareCenter,
                items: medicareCenters.map((med) {
                  return DropdownMenuItem<String>(
                    value: med,
                    child: Text(med, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newMed) {
                  if (newMed != null && newMed != _selectedMedicareCenter) {
                    setState(() {
                      _selectedMedicareCenter = newMed;
                      _notifyChange();
                    });
                  }
                },
              ),
            ),
          ),
        ],

        // 7. Associated Registered Clubs & Volunteer Wings Dropdown
        if (widget.showRegisteredClub && registeredClubs.isNotEmpty) ...[
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.translate('registered_club_label'),
              prefixIcon: const Icon(Icons.groups_rounded, size: 20, color: Colors.purple),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safeRegisteredClub,
                items: registeredClubs.map((club) {
                  return DropdownMenuItem<String>(
                    value: club,
                    child: Text(club, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newClub) {
                  if (newClub != null && newClub != _selectedRegisteredClub) {
                    setState(() {
                      _selectedRegisteredClub = newClub;
                      _notifyChange();
                    });
                  }
                },
              ),
            ),
          ),
        ],

        // 8. Associated Wards Dropdown
        if (widget.showWard && wards.isNotEmpty) ...[
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.translate('ward_label'),
              prefixIcon: const Icon(Icons.home_work_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safeWard,
                items: wards.map((ward) {
                  return DropdownMenuItem<String>(
                    value: ward,
                    child: Text(ward, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newWard) {
                  if (newWard != null && newWard != _selectedWard) {
                    setState(() {
                      _selectedWard = newWard;
                      _notifyChange();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
