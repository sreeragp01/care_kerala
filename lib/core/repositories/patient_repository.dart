import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import 'package:sqflite/sqflite.dart';

class PatientRepository {
  static Future<List<PatientModel>> getPatients({String? district, String? tier}) async {
    // 1. Try reading from Local SQLite Database first (Instant Offline Rendering)
    try {
      final db = await LocalDatabaseService.db;
      final maps = await db.query('patients');
      if (maps.isNotEmpty) {
        debugPrint('Loaded ${maps.length} patients from local SQLite database.');
        return maps.map((map) => PatientModel(
          id: map['id'] as String,
          name: map['name'] as String? ?? 'Patient',
          age: map['age'] as int? ?? 65,
          gender: map['gender'] as String? ?? 'Unknown',
          bloodGroup: map['blood_group'] as String? ?? 'O+',
          district: map['district'] as String? ?? 'Kozhikode',
          ward: map['ward'] as String? ?? 'Ward 1',
          address: map['address'] as String? ?? '',
          phone: map['phone'] as String? ?? '',
          lifecycleStatus: map['lifecycle_status'] as String? ?? 'Active Care',
          categoryTier: map['category_tier'] as String? ?? 'Category A (Bedridden)',
          diagnosis: map['diagnosis'] as String? ?? '',
          riskLevel: map['risk_level'] as String? ?? 'Moderate Risk',
          aiSummary: map['ai_summary'] as String? ?? '',
          emergencyContactName: map['emergency_contact_name'] as String? ?? '',
          emergencyContactPhone: map['emergency_contact_phone'] as String? ?? '',
          vitalsHistory: [],
          equipmentIssued: [],
          familyMembers: [],
          medicalHistory: [(map['diagnosis'] as String? ?? '')],
          registeredDate: map['registered_date'] as String? ?? '2026-08-01',
        )).toList();
      }
    } catch (e) {
      debugPrint('Local SQLite query error: $e');
    }

    // 2. Fetch from Django REST API if available and cache locally
    final remotePatients = await ApiService.getPatients(district: district, tier: tier);
    if (remotePatients.isNotEmpty) {
      _cachePatientsLocally(remotePatients);
    }
    return remotePatients;
  }

  static Future<void> _cachePatientsLocally(List<PatientModel> patients) async {
    try {
      final db = await LocalDatabaseService.db;
      for (final p in patients) {
        await db.insert('patients', {
          'id': p.id,
          'name': p.name,
          'age': p.age,
          'gender': p.gender,
          'blood_group': p.bloodGroup,
          'district': p.district,
          'ward': p.ward,
          'address': p.address,
          'phone': p.phone,
          'lifecycle_status': p.lifecycleStatus,
          'category_tier': p.categoryTier,
          'diagnosis': p.diagnosis,
          'risk_level': p.riskLevel,
          'ai_summary': p.aiSummary,
          'emergency_contact_name': p.emergencyContactName,
          'emergency_contact_phone': p.emergencyContactPhone,
          'registered_date': p.registeredDate,
          'sync_status': 'SYNCED',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Failed to cache patients locally: $e');
    }
  }
}
