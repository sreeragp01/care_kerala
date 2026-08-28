import 'package:flutter/material.dart';

enum MapMarkerType {
  healthCenter,
  patientCategoryA,
  patientCategoryB,
  patientCategoryC,
  ambulanceAvailable,
  ambulanceDispatched,
  oxygenDepot,
  bloodDonor,
}

class MapWaypoint {
  final double latitude;
  final double longitude;
  final String instruction;
  final String roadName;
  final double distanceMeters;

  const MapWaypoint({
    required this.latitude,
    required this.longitude,
    required this.instruction,
    required this.roadName,
    required this.distanceMeters,
  });
}

class MapMarkerModel {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final MapMarkerType type;
  final String categoryTier;
  final String? patientId;
  final String? phone;
  final String? diagnosis;
  final String? urgency;
  final String? vehicleNumber;
  final double distanceKm;
  final int etaMinutes;
  final List<MapWaypoint> routeWaypoints;

  const MapMarkerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.categoryTier = 'Category A',
    this.patientId,
    this.phone,
    this.diagnosis,
    this.urgency,
    this.vehicleNumber,
    required this.distanceKm,
    required this.etaMinutes,
    this.routeWaypoints = const [],
  });

  Color get color {
    switch (type) {
      case MapMarkerType.healthCenter:
        return const Color(0xFF1B5E20); // Deep Forest Green
      case MapMarkerType.patientCategoryA:
        return const Color(0xFFD32F2F); // Red
      case MapMarkerType.patientCategoryB:
        return const Color(0xFFE65100); // Deep Orange
      case MapMarkerType.patientCategoryC:
        return const Color(0xFF0288D1); // Info Blue
      case MapMarkerType.ambulanceAvailable:
        return const Color(0xFF00897B); // Teal
      case MapMarkerType.ambulanceDispatched:
        return const Color(0xFFFF6D00); // Amber Orange
      case MapMarkerType.oxygenDepot:
        return const Color(0xFF7B1FA2); // Purple
      case MapMarkerType.bloodDonor:
        return const Color(0xFFC2185B); // Pink
    }
  }

  IconData get icon {
    switch (type) {
      case MapMarkerType.healthCenter:
        return Icons.local_hospital_rounded;
      case MapMarkerType.patientCategoryA:
        return Icons.personal_injury_rounded;
      case MapMarkerType.patientCategoryB:
        return Icons.elderly_rounded;
      case MapMarkerType.patientCategoryC:
        return Icons.accessible_rounded;
      case MapMarkerType.ambulanceAvailable:
      case MapMarkerType.ambulanceDispatched:
        return Icons.airport_shuttle_rounded;
      case MapMarkerType.oxygenDepot:
        return Icons.air_rounded;
      case MapMarkerType.bloodDonor:
        return Icons.water_drop_rounded;
    }
  }
}
