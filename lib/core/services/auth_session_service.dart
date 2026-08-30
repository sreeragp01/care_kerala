import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import 'local_database_service.dart';

class AuthSession {
  final String token;
  final String? refreshToken;
  final UserModel user;
  final bool isLoggedIn;
  final DateTime lastActive;

  AuthSession({
    required this.token,
    this.refreshToken,
    required this.user,
    required this.isLoggedIn,
    required this.lastActive,
  });

  Map<String, dynamic> toMap() => {
    'id': 'active_session',
    'token': token,
    'refresh_token': refreshToken ?? '',
    'user_json': jsonEncode(user.toJson()),
    'is_logged_in': isLoggedIn ? 1 : 0,
    'last_active': lastActive.toIso8601String(),
  };

  factory AuthSession.fromMap(Map<String, dynamic> map) {
    UserModel user;
    try {
      final userJson = jsonDecode(map['user_json']);
      user = UserModel.fromJson(userJson);
    } catch (_) {
      user = UserModel(
        id: 'USR-SAVED',
        name: 'CareLink User',
        email: 'user@carelink.kerala.gov.in',
        phone: '+91 98470 00000',
        role: UserRole.nurse,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      );
    }

    return AuthSession(
      token: map['token'] ?? '',
      refreshToken: map['refresh_token']?.toString().isNotEmpty == true ? map['refresh_token'] : null,
      user: user,
      isLoggedIn: map['is_logged_in'] == 1,
      lastActive: map['last_active'] != null ? DateTime.tryParse(map['last_active']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class AuthSessionService {
  // In-memory cache for ultra-fast access & test safety
  static AuthSession? _cachedSession;

  static const String _tableName = 'auth_session';

  /// Save persistent session with JWT token and user profile
  static Future<void> saveSession({
    required String token,
    String? refreshToken,
    required UserModel user,
  }) async {
    final session = AuthSession(
      token: token,
      refreshToken: refreshToken,
      user: user,
      isLoggedIn: true,
      lastActive: DateTime.now(),
    );

    _cachedSession = session;

    try {
      final db = await LocalDatabaseService.db;
      // Ensure table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          token TEXT,
          refresh_token TEXT,
          user_json TEXT,
          is_logged_in INTEGER DEFAULT 1,
          last_active TEXT
        )
      ''');

      await db.insert(
        _tableName,
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('AuthSessionService: Persisted JWT session for ${user.name} (${user.role.displayName})');
    } catch (e) {
      if (!e.toString().contains('databaseFactory not initialized')) {
        debugPrint('AuthSessionService (SQLite fallback to memory): $e');
      }
    }
  }

  /// Retrieve the active saved session, if any
  static Future<AuthSession?> getSession() async {
    if (_cachedSession != null && _cachedSession!.isLoggedIn) {
      return _cachedSession;
    }

    try {
      final db = await LocalDatabaseService.db;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          token TEXT,
          refresh_token TEXT,
          user_json TEXT,
          is_logged_in INTEGER DEFAULT 1,
          last_active TEXT
        )
      ''');

      final results = await db.query(
        _tableName,
        where: 'id = ? AND is_logged_in = 1',
        whereArgs: ['active_session'],
        limit: 1,
      );

      if (results.isNotEmpty) {
        _cachedSession = AuthSession.fromMap(results.first);
        return _cachedSession;
      }
    } catch (e) {
      if (!e.toString().contains('databaseFactory not initialized')) {
        debugPrint('AuthSessionService getSession error: $e');
      }
    }

    return _cachedSession;
  }

  /// Explicitly clear session on Logout
  static Future<void> clearSession() async {
    _cachedSession = null;

    try {
      final db = await LocalDatabaseService.db;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: ['active_session'],
      );
      debugPrint('AuthSessionService: Cleared persistent JWT session.');
    } catch (e) {
      if (!e.toString().contains('databaseFactory not initialized')) {
        debugPrint('AuthSessionService clearSession error: $e');
      }
    }
  }


  /// Check if user has a valid active session
  static Future<bool> hasActiveSession() async {
    final session = await getSession();
    return session != null && session.isLoggedIn && session.token.isNotEmpty;
  }

  /// Reset cache for test cases
  @visibleForTesting
  static void resetCacheForTesting([AuthSession? session]) {
    _cachedSession = session;
  }
}
