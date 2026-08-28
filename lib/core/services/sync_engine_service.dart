import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'local_database_service.dart';

class SyncEngineService {
  static bool _isSyncing = false;

  static Future<int> getPendingCount() async {
    return await LocalDatabaseService.getPendingSyncCount();
  }

  static Future<bool> syncPendingQueue() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      final pendingItems = await LocalDatabaseService.getPendingSyncQueue();
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return true;
      }

      debugPrint('SyncEngine: Pushing ${pendingItems.length} queued operations to Django REST API...');

      final operationsPayload = pendingItems.map((item) {
        return {
          'operation': item['operation'],
          'local_id': item['local_id'],
          'data': jsonDecode(item['payload_json'] as String),
        };
      }).toList();

      final body = jsonEncode({
        'device_id': 'flutter_device_${DateTime.now().millisecondsSinceEpoch}',
        'operations': operationsPayload,
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/sync/push/'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.authToken != null) 'Authorization': 'Bearer ${ApiService.authToken}',
          if (ApiService.activeTenantId != null) 'X-Tenant-ID': ApiService.activeTenantId!,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final accepted = resData['accepted'] as List? ?? [];
        for (final item in accepted) {
          final localId = item['local_id'];
          if (localId != null) {
            await LocalDatabaseService.markQueueItemSynced(localId.toString());
          }
        }
        debugPrint('SyncEngine: Batch sync succeeded. ${accepted.length} operations marked SYNCED.');
        _isSyncing = false;
        return true;
      }
    } catch (e) {
      debugPrint('SyncEngine: Error during sync push: $e');
    }

    _isSyncing = false;
    return false;
  }
}
