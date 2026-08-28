import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../services/local_database_service.dart';
import 'package:sqflite/sqflite.dart';

class VisitRepository {
  static Future<void> saveCompletedVisitOffline({
    required String visitId,
    required String patientId,
    required String clinicalNotes,
    required String symptomsObserved,
    required String careProvided,
    required String medicationAdministered,
    required String equipmentUsed,
    VitalsReading? vitals,
  }) async {
    final db = await LocalDatabaseService.db;
    final now = DateTime.now().toIso8601String();

    // 1. Save locally to SQLite with PENDING sync status
    await db.insert('visits', {
      'id': visitId,
      'patient_id': patientId,
      'status': 'Completed',
      'clinical_notes': clinicalNotes,
      'symptoms_observed': symptomsObserved,
      'care_provided': careProvided,
      'medication_administered': medicationAdministered,
      'equipment_used': equipmentUsed,
      'sync_status': 'PENDING',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Queue for background sync push
    final payload = jsonEncode({
      'server_id': visitId,
      'patient_id': patientId,
      'clinical_notes': clinicalNotes,
      'symptoms_observed': symptomsObserved,
      'care_provided': careProvided,
      'medication_administered': medicationAdministered,
      'equipment_used': equipmentUsed,
    });

    await LocalDatabaseService.enqueueSyncOperation(
      'visit_complete_${visitId}_$now',
      'visit',
      'COMPLETE_VISIT',
      payload,
    );

    if (vitals != null) {
      final vitalsPayload = jsonEncode({
        'patient_id': patientId,
        'bp': vitals.bp,
        'pulse': vitals.pulse,
        'spo2': vitals.spo2,
        'temperature': vitals.temperature,
        'pain_scale': vitals.painScale,
        'respiratory_rate': vitals.respiratoryRate,
      });

      await LocalDatabaseService.enqueueSyncOperation(
        'vitals_add_${patientId}_$now',
        'vitals',
        'ADD_VITALS',
        vitalsPayload,
      );
    }


    debugPrint('Successfully saved visit $visitId offline and enqueued sync payload.');
  }
}
