import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'carelink_kerala_offline.db');

    debugPrint('Initializing local SQLite database at: $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Patients Table
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            organization_id TEXT,
            name TEXT,
            age INTEGER,
            gender TEXT,
            blood_group TEXT,
            district TEXT,
            ward TEXT,
            address TEXT,
            phone TEXT,
            lifecycle_status TEXT,
            category_tier TEXT,
            diagnosis TEXT,
            risk_level TEXT,
            ai_summary TEXT,
            emergency_contact_name TEXT,
            emergency_contact_phone TEXT,
            registered_date TEXT,
            sync_status TEXT DEFAULT 'SYNCED'
          )
        ''');

        // Visits Table
        await db.execute('''
          CREATE TABLE visits (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            patient_name TEXT,
            patient_address TEXT,
            assigned_nurse_name TEXT,
            scheduled_date TEXT,
            scheduled_time TEXT,
            status TEXT,
            gps_check_in_time TEXT,
            gps_location_name TEXT,
            symptoms_observed TEXT,
            assessment_notes TEXT,
            care_provided TEXT,
            medication_administered TEXT,
            equipment_used TEXT,
            follow_up_instructions TEXT,
            clinical_notes TEXT,
            doctor_review_notes TEXT,
            doctor_signed_off INTEGER DEFAULT 0,
            doctor_signoff_timestamp TEXT,
            sync_status TEXT DEFAULT 'PENDING'
          )
        ''');

        // Vitals Table
        await db.execute('''
          CREATE TABLE vitals (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            bp TEXT,
            pulse INTEGER,
            spo2 INTEGER,
            temperature REAL,
            pain_scale INTEGER,
            respiratory_rate INTEGER,
            recorded_by TEXT,
            recorded_at TEXT,
            sync_status TEXT DEFAULT 'PENDING'
          )
        ''');

        // Alerts Table
        await db.execute('''
          CREATE TABLE alerts (
            id TEXT PRIMARY KEY,
            patient_name TEXT,
            alert_type TEXT,
            severity TEXT,
            title TEXT,
            message TEXT,
            status TEXT,
            created_at TEXT,
            acknowledged_by TEXT,
            acknowledged_at TEXT
          )
        ''');

        // Sync Queue Table
        await db.execute('''
          CREATE TABLE sync_queue (
            local_id TEXT PRIMARY KEY,
            entity_type TEXT,
            operation TEXT,
            payload_json TEXT,
            sync_status TEXT DEFAULT 'PENDING',
            retry_count INTEGER DEFAULT 0,
            last_error TEXT,
            created_at TEXT
          )
        ''');

        // Auth Session Table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS auth_session (
            id TEXT PRIMARY KEY,
            token TEXT,
            refresh_token TEXT,
            user_json TEXT,
            is_logged_in INTEGER DEFAULT 1,
            last_active TEXT
          )
        ''');
      },
    );

  }


  // Queue Operations Helper
  static Future<void> enqueueSyncOperation(String localId, String entityType, String operation, String payloadJson) async {
    final database = await db;
    await database.insert('sync_queue', {
      'local_id': localId,
      'entity_type': entityType,
      'operation': operation,
      'payload_json': payloadJson,
      'sync_status': 'PENDING',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final database = await db;
    return await database.query('sync_queue', where: 'sync_status = ?', whereArgs: ['PENDING']);
  }

  static Future<void> markQueueItemSynced(String localId) async {
    final database = await db;
    await database.update('sync_queue', {'sync_status': 'SYNCED'}, where: 'local_id = ?', whereArgs: [localId]);
  }

  static Future<int> getPendingSyncCount() async {
    final database = await db;
    final res = await database.rawQuery("SELECT COUNT(*) as cnt FROM sync_queue WHERE sync_status = 'PENDING'");
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
