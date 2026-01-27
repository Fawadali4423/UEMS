import 'package:flutter/foundation.dart';
import 'package:uems/core/services/local_storage_service.dart';
import 'package:uems/core/services/connectivity_service.dart';
import 'package:uems/core/models/offline_attendance_item.dart';
import 'package:uems/features/attendance/data/attendance_repository.dart';

/// Provider for managing offline data synchronization
class SyncProvider with ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  String? _lastSyncError;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncProvider() {
    _init();
  }

  Future<void> _init() async {
    // Initialize connectivity monitoring
    _connectivityService.connectionStatus.listen((isConnected) {
      _isOnline = isConnected;
      notifyListeners();
      
      // Auto-sync when connection is restored
      if (isConnected && _pendingSyncCount > 0) {
        syncAll();
      }
    });

    // Check initial connection status
    _isOnline = await _connectivityService.checkConnection();
    
    // Update pending sync count
    await updatePendingSyncCount();
    
    // Get last sync time
    _lastSyncTime = _storageService.getLastSync();
    
    notifyListeners();
  }

  /// Update the count of pending items to sync
  Future<void> updatePendingSyncCount() async {
    try {
      final attendanceQueue = _storageService.getAttendanceQueue();
      _pendingSyncCount = attendanceQueue.where((item) => !item.synced).length;
      notifyListeners();
    } catch (e) {
      print('Error updating pending sync count: $e');
    }
  }

  /// Sync all pending data
  Future<bool> syncAll() async {
    if (_isSyncing) return false;
    if (!_isOnline) {
      _lastSyncError = 'No internet connection';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // Sync attendance queue
      final success = await _syncAttendanceQueue();
      
      if (success) {
        // Update last sync time
        _lastSyncTime = DateTime.now();
        await _storageService.updateLastSync();
        
        // Clear pending count
        await updatePendingSyncCount();
      }
      
      _isSyncing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _lastSyncError = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Sync attendance queue to Firestore
  Future<bool> _syncAttendanceQueue() async {
    try {
      final queue = _storageService.getAttendanceQueue();
      final pendingItems = queue.where((item) => !item.synced).toList();
      
      if (pendingItems.isEmpty) return true;

      int successCount = 0;
      final List<String> failedIds = [];

      for (final item in pendingItems) {
        try {
          // Mark attendance in Firestore
          await _attendanceRepository.markAttendance(
            item.eventId,
            item.studentId,
          );

          // Remove from queue
          await _storageService.removeFromAttendanceQueue(item.id);
          successCount++;
        } catch (e) {
          print('Failed to sync attendance item ${item.id}: $e');
          failedIds.add(item.id);
        }
      }

      // If all items synced successfully
      if (failedIds.isEmpty) {
        await _storageService.clearAttendanceQueue();
        return true;
      }

      // Partial success
      _lastSyncError = 'Failed to sync ${failedIds.length} items';
      return successCount > 0;
    } catch (e) {
      _lastSyncError = 'Attendance sync failed: $e';
      return false;
    }
  }

  /// Manually trigger sync
  Future<void> manualSync() async {
    await syncAll();
  }

  /// Clear sync error
  void clearError() {
    _lastSyncError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
