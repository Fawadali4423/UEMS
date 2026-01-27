import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uems/core/models/cached_qr_pass.dart';
import 'package:uems/core/models/cached_certificate.dart';
import 'package:uems/core/models/user_preferences.dart';
import 'package:uems/core/models/offline_attendance_item.dart';

/// Centralized service for managing local storage operations
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;

  // Storage keys
  static const String _qrPassPrefix = 'qr_pass_';
  static const String _certificatePrefix = 'certificate_';
  static const String _userPrefsKey = 'user_preferences';
  static const String _cachedEventsKey = 'cached_events';
  static const String _attendanceQueueKey = 'attendance_queue';
  static const String _userProfileKey = 'user_profile';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== QR Pass Operations ====================

  /// Save QR pass data
  Future<bool> saveQrPass(CachedQrPass pass) async {
    try {
      final key = _qrPassPrefix + pass.id;
      final jsonString = jsonEncode(pass.toJson());
      return await prefs.setString(key, jsonString);
    } catch (e) {
      print('Error saving QR pass: $e');
      return false;
    }
  }

  /// Get QR pass by ID
  CachedQrPass? getQrPass(String passId) {
    try {
      final key = _qrPassPrefix + passId;
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CachedQrPass.fromJson(json);
    } catch (e) {
      print('Error getting QR pass: $e');
      return null;
    }
  }

  /// Get all cached QR passes
  List<CachedQrPass> getAllQrPasses() {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_qrPassPrefix));
      final passes = <CachedQrPass>[];
      
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            passes.add(CachedQrPass.fromJson(json));
          } catch (e) {
            print('Error parsing QR pass from key $key: $e');
          }
        }
      }
      
      // Sort by cached date (most recent first)
      passes.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
      return passes;
    } catch (e) {
      print('Error getting all QR passes: $e');
      return [];
    }
  }

  /// Delete a QR pass
  Future<bool> deleteQrPass(String passId) async {
    try {
      final key = _qrPassPrefix + passId;
      return await prefs.remove(key);
    } catch (e) {
      print('Error deleting QR pass: $e');
      return false;
    }
  }

  // ==================== Certificate Operations ====================

  /// Save certificate
  Future<bool> saveCertificate(CachedCertificate certificate) async {
    try {
      final key = _certificatePrefix + certificate.id;
      final jsonString = jsonEncode(certificate.toJson());
      return await prefs.setString(key, jsonString);
    } catch (e) {
      print('Error saving certificate: $e');
      return false;
    }
  }

  /// Get certificate by ID
  CachedCertificate? getCertificate(String certificateId) {
    try {
      final key = _certificatePrefix + certificateId;
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CachedCertificate.fromJson(json);
    } catch (e) {
      print('Error getting certificate: $e');
      return null;
    }
  }

  /// Get all cached certificates
  List<CachedCertificate> getAllCertificates() {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_certificatePrefix));
      final certificates = <CachedCertificate>[];
      
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            certificates.add(CachedCertificate.fromJson(json));
          } catch (e) {
            print('Error parsing certificate from key $key: $e');
          }
        }
      }
      
      // Sort by generated date (most recent first)
      certificates.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return certificates;
    } catch (e) {
      print('Error getting all certificates: $e');
      return [];
    }
  }

  /// Delete a certificate
  Future<bool> deleteCertificate(String certificateId) async {
    try {
      final key = _certificatePrefix + certificateId;
      return await prefs.remove(key);
    } catch (e) {
      print('Error deleting certificate: $e');
      return false;
    }
  }

  // ==================== User Preferences ====================

  /// Save user preferences
  Future<bool> saveUserPreferences(UserPreferences preferences) async {
    try {
      final jsonString = jsonEncode(preferences.toJson());
      return await prefs.setString(_userPrefsKey, jsonString);
    } catch (e) {
      print('Error saving user preferences: $e');
      return false;
    }
  }

  /// Get user preferences
  UserPreferences getUserPreferences() {
    try {
      final jsonString = prefs.getString(_userPrefsKey);
      if (jsonString == null) return UserPreferences();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserPreferences.fromJson(json);
    } catch (e) {
      print('Error getting user preferences: $e');
      return UserPreferences();
    }
  }

  // ==================== Event Caching ====================

  /// Cache events data (stored as JSON array)
  Future<bool> cacheEvents(List<Map<String, dynamic>> events) async {
    try {
      // Limit to 50 most recent events
      final limitedEvents = events.take(50).toList();
      final jsonString = jsonEncode(limitedEvents);
      return await prefs.setString(_cachedEventsKey, jsonString);
    } catch (e) {
      print('Error caching events: $e');
      return false;
    }
  }

  /// Get cached events
  List<Map<String, dynamic>> getCachedEvents() {
    try {
      final jsonString = prefs.getString(_cachedEventsKey);
      if (jsonString == null) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting cached events: $e');
      return [];
    }
  }

  // ==================== Offline Attendance Queue ====================

  /// Queue offline attendance scan
  Future<bool> queueOfflineAttendance(OfflineAttendanceItem item) async {
    try {
      final queue = getAttendanceQueue();
      queue.add(item);
      
      // Limit queue to 500 items
      final limitedQueue = queue.take(500).toList();
      final jsonString = jsonEncode(limitedQueue.map((e) => e.toJson()).toList());
      return await prefs.setString(_attendanceQueueKey, jsonString);
    } catch (e) {
      print('Error queuing attendance: $e');
      return false;
    }
  }

  /// Get attendance queue
  List<OfflineAttendanceItem> getAttendanceQueue() {
    try {
      final jsonString = prefs.getString(_attendanceQueueKey);
      if (jsonString == null) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => OfflineAttendanceItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting attendance queue: $e');
      return [];
    }
  }

  /// Clear attendance queue
  Future<bool> clearAttendanceQueue() async {
    try {
      return await prefs.remove(_attendanceQueueKey);
    } catch (e) {
      print('Error clearing attendance queue: $e');
      return false;
    }
  }

  /// Remove specific item from attendance queue
  Future<bool> removeFromAttendanceQueue(String itemId) async {
    try {
      final queue = getAttendanceQueue();
      queue.removeWhere((item) => item.id == itemId);
      final jsonString = jsonEncode(queue.map((e) => e.toJson()).toList());
      return await prefs.setString(_attendanceQueueKey, jsonString);
    } catch (e) {
      print('Error removing from attendance queue: $e');
      return false;
    }
  }

  // ==================== User Profile Caching ====================

  /// Save user profile
  Future<bool> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final jsonString = jsonEncode(profile);
      return await prefs.setString(_userProfileKey, jsonString);
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  /// Get user profile
  Map<String, dynamic>? getUserProfile() {
    try {
      final jsonString = prefs.getString(_userProfileKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Clear user profile
  Future<bool> clearUserProfile() async {
    try {
      return await prefs.remove(_userProfileKey);
    } catch (e) {
      print('Error clearing user profile: $e');
      return false;
    }
  }

  // ==================== Sync Management ====================

  /// Update last sync timestamp
  Future<bool> updateLastSync() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return await prefs.setInt(_lastSyncKey, timestamp);
    } catch (e) {
      print('Error updating last sync: $e');
      return false;
    }
  }

  /// Get last sync timestamp
  DateTime? getLastSync() {
    try {
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting last sync: $e');
      return null;
    }
  }

  // ==================== Cache Management ====================

  /// Clear expired cache (older than 30 days)
  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiryDate = now.subtract(const Duration(days: 30));

      // Clear old QR passes
      final qrPasses = getAllQrPasses();
      for (final pass in qrPasses) {
        if (pass.cachedAt.isBefore(expiryDate)) {
          await deleteQrPass(pass.id);
        }
      }

      // Clear old certificates
      final certificates = getAllCertificates();
      for (final cert in certificates) {
        if (cert.generatedAt.isBefore(expiryDate)) {
          await deleteCertificate(cert.id);
        }
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  /// Clear all cache
  Future<bool> clearAllCache() async {
    try {
      final keys = prefs.getKeys();
      
      // Remove all cache-related keys except user preferences
      for (final key in keys) {
        if (key.startsWith(_qrPassPrefix) ||
            key.startsWith(_certificatePrefix) ||
            key == _cachedEventsKey ||
            key == _attendanceQueueKey ||
            key == _userProfileKey) {
          await prefs.remove(key);
        }
      }
      
      return true;
    } catch (e) {
      print('Error clearing all cache: $e');
      return false;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    try {
      final qrPassCount = getAllQrPasses().length;
      final certificateCount = getAllCertificates().length;
      final eventCount = getCachedEvents().length;
      final attendanceQueueCount = getAttendanceQueue().length;
      final lastSync = getLastSync();
      
      return {
        'qrPasses': qrPassCount,
        'certificates': certificateCount,
        'events': eventCount,
        'pendingAttendance': attendanceQueueCount,
        'lastSync': lastSync?.toIso8601String(),
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {};
    }
  }
}
