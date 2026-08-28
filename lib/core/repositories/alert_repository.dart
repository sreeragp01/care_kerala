import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';

class AlertRepository {
  static Future<List<ClinicalAlertModel>> getAlerts({String? severity, String? status}) async {
    // 1. Check local SQLite cache first
    try {
      final db = await LocalDatabaseService.db;
      final maps = await db.query('alerts');
      if (maps.isNotEmpty) {
        return maps.map((m) => ClinicalAlertModel(
          id: m['id'] as String,
          patientName: m['patient_name'] as String? ?? '',
          alertType: m['alert_type'] as String? ?? '',
          severity: m['severity'] as String? ?? 'MEDIUM',
          title: m['title'] as String? ?? '',
          message: m['message'] as String? ?? '',
          status: m['status'] as String? ?? 'OPEN',
          createdAt: m['created_at'] as String? ?? '',
          acknowledgedBy: m['acknowledged_by'] as String? ?? '',
          acknowledgedAt: m['acknowledged_at'] as String?,
        )).toList();
      }
    } catch (e) {
      debugPrint('Error querying local SQLite alerts table: $e');
    }

    // 2. Fetch from Django REST API
    try {
      var query = '';
      if (severity != null) query += 'severity=$severity&';
      if (status != null) query += 'status=$status';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/alerts/?$query'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.authToken != null) 'Authorization': 'Bearer ${ApiService.authToken}',
          if (ApiService.activeTenantId != null) 'X-Tenant-ID': ApiService.activeTenantId!,
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final alerts = data.map((json) => ClinicalAlertModel.fromJson(json)).toList();
        _cacheAlertsLocally(alerts);
        return alerts;
      }
    } catch (e) {
      debugPrint('Error fetching alerts from API: $e');
    }

    return [];
  }

  static Future<bool> acknowledgeAlert(String alertId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/alerts/$alertId/acknowledge/'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.authToken != null) 'Authorization': 'Bearer ${ApiService.authToken}',
          if (ApiService.activeTenantId != null) 'X-Tenant-ID': ApiService.activeTenantId!,
        },
      );

      if (response.statusCode == 200) {
        final db = await LocalDatabaseService.db;
        await db.update('alerts', {'status': 'ACKNOWLEDGED'}, where: 'id = ?', whereArgs: [alertId]);
        return true;
      }
    } catch (e) {
      debugPrint('Error acknowledging alert $alertId: $e');
    }
    return false;
  }

  static Future<void> _cacheAlertsLocally(List<ClinicalAlertModel> alerts) async {
    try {
      final db = await LocalDatabaseService.db;
      for (final a in alerts) {
        await db.insert('alerts', {
          'id': a.id,
          'patient_name': a.patientName,
          'alert_type': a.alertType,
          'severity': a.severity,
          'title': a.title,
          'message': a.message,
          'status': a.status,
          'created_at': a.createdAt,
          'acknowledged_by': a.acknowledgedBy,
          'acknowledged_at': a.acknowledgedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Failed to cache alerts locally: $e');
    }
  }
}
