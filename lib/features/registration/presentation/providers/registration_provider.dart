import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uems/features/events/data/event_repository.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/registration/data/registration_repository.dart';
import 'package:uems/features/registration/domain/models/registration_model.dart';
import 'package:uems/core/services/local_storage_service.dart';
import 'package:uems/core/services/connectivity_service.dart';
import 'package:uems/core/models/cached_qr_pass.dart';

/// Provider for managing registrations
class RegistrationProvider extends ChangeNotifier {
  final RegistrationRepository _registrationRepository = RegistrationRepository();
  final EventRepository _eventRepository = EventRepository();
  final LocalStorageService _storageService = LocalStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<RegistrationModel> _registrations = [];
  List<EventModel> _registeredEvents = [];
  final Set<String> _registeredEventIds = {};
  PassModel? _currentPass;
  bool _isLoading = false;
  bool _isLoadedFromCache = false;
  String? _error;

  // Getters
  List<RegistrationModel> get registrations => _registrations;
  List<EventModel> get registeredEvents => _registeredEvents;
  PassModel? get currentPass => _currentPass;
  bool get isLoading => _isLoading;
  bool get isLoadedFromCache => _isLoadedFromCache;
  String? get error => _error;

  /// Check if registered for event
  bool isRegisteredForEvent(String eventId) {
    return _registeredEventIds.contains(eventId);
  }



  /// Check if registered
  Future<void> checkRegistration(String eventId, String studentId) async {
    try {
      final isRegistered = await _registrationRepository.isRegistered(eventId, studentId);
      if (isRegistered) {
        _registeredEventIds.add(eventId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Register for event
  Future<String?> registerForEvent({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required String studentId,
    required String rollNumber,
    required String studentName,
    required String studentEmail,
    bool isPaidEvent = false,
    double? entryFee,
    String? paymentId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final registrationId = await _registrationRepository.registerForEvent(
        eventId: eventId,
        eventName: eventName,
        eventDate: eventDate,
        studentId: studentId,
        rollNumber: rollNumber,
        studentName: studentName,
        studentEmail: studentEmail,
        isPaidEvent: isPaidEvent,
        entryFee: entryFee,
        paymentId: paymentId,
      );
      _registeredEventIds.add(eventId);
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return registrationId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load pass for display (with offline support)
  Future<void> loadPass(String eventId, String studentId) async {
    _isLoading = true;
    _isLoadedFromCache = false;
    notifyListeners();

    try {
      // Try to load from cache first
      final passId = PassModel.generateId(eventId, studentId);
      final cachedPass = _storageService.getQrPass(passId);
      
      // Check if online
      final isOnline = await _connectivityService.checkConnection();
      
      if (isOnline) {
        // Load from Firestore
        try {
          _currentPass = await _registrationRepository.getPass(eventId, studentId);
          
          // Cache the pass
          if (_currentPass != null) {
            await _cachePass(_currentPass!);
          }
          
          _isLoadedFromCache = false;
        } catch (e) {
          // If Firestore fails but we have cache, use it
          if (cachedPass != null) {
            _currentPass = _passFromCached(cachedPass);
            _isLoadedFromCache = true;
          } else {
            throw e;
          }
        }
      } else {
        // Offline: use cached data
        if (cachedPass != null) {
          _currentPass = _passFromCached(cachedPass);
          _isLoadedFromCache = true;
        } else {
          throw Exception('No internet connection and no cached data available');
        }
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cache a pass to local storage
  Future<void> _cachePass(PassModel pass) async {
    try {
      final cachedPass = CachedQrPass(
        id: pass.id,
        registrationId: pass.registrationId,
        eventId: pass.eventId,
        eventName: pass.eventName,
        eventDate: pass.eventDate,
        studentId: pass.studentId,
        rollNumber: pass.rollNumber,
        studentName: pass.studentName,
        studentEmail: pass.studentEmail,
        qrData: pass.qrData,
        isUsed: pass.isUsed,
        cachedAt: DateTime.now(),
      );
      
      await _storageService.saveQrPass(cachedPass);
    } catch (e) {
      print('Error caching pass: $e');
    }
  }

  /// Convert cached pass to PassModel
  PassModel _passFromCached(CachedQrPass cached) {
    return PassModel(
      id: cached.id,
      registrationId: cached.registrationId,
      eventId: cached.eventId,
      eventName: cached.eventName,
      eventDate: cached.eventDate,
      studentId: cached.studentId,
      rollNumber: cached.rollNumber,
      studentName: cached.studentName,
      studentEmail: cached.studentEmail,
      qrData: cached.qrData,
      isUsed: cached.isUsed,
      createdAt: cached.cachedAt,
    );
  }

  /// Validate QR code
  Future<PassModel?> validateQrCode(String qrData) async {
    try {
      return await _registrationRepository.validateQrData(qrData);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  /// Mark pass as used (attendance)
  Future<bool> markAttendance(String eventId, String studentId) async {
    try {
      await _registrationRepository.markPassAsUsed(eventId, studentId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear current pass
  void clearPass() {
    _currentPass = null;
    notifyListeners();
  }

  // Student passes list
  List<PassModel> _studentPasses = [];
  List<PassModel> get studentPasses => _studentPasses;

  /// Get active passes (not expired / event not past)
  List<PassModel> get activePasses => _studentPasses.where((p) => !p.isExpired).toList();

  /// Get expired passes
  List<PassModel> get expiredPasses => _studentPasses.where((p) => p.isExpired).toList();

  StreamSubscription<List<RegistrationModel>>? _registrationsSubscription;
  StreamSubscription<List<PassModel>>? _passesSubscription;

  @override
  void dispose() {
    _registrationsSubscription?.cancel();
    _passesSubscription?.cancel();
    super.dispose();
  }

  /// Start real-time registrations listener
  void startRealtimeRegistrations(String studentId) {
    _isLoading = true;
    notifyListeners();

    _registrationsSubscription?.cancel();
    _registrationsSubscription = _registrationRepository
        .getStudentRegistrationsStream(studentId)
        .listen((registrations) async {
      _registrations = registrations;
      
      // Update registered events list
      _registeredEvents = [];
      _registeredEventIds.clear();
      
      for (final reg in registrations) {
        // Optimisation: Fetch event only if not in _registeredEvents?
        // For simplicity, we fetch fresh to ensure event data is up to date too
        // But doing this in loop inside stream listener might be heavy if many events.
        // Better: Listen to events stream separately.
        // However, here we just need event details.
        
        final event = await _eventRepository.getEventById(reg.eventId);
        if (event != null) {
          _registeredEvents.add(event);
          _registeredEventIds.add(event.id);
        }
      }

      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Start real-time passes listener
  void startRealtimePasses(String studentId) {
    _isLoading = true;
    notifyListeners(); // Optional: don't show loading if silent update preferred

    _passesSubscription?.cancel();
    _passesSubscription = _registrationRepository
        .getStudentPassesStream(studentId)
        .listen((passes) {
      _studentPasses = passes;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Load student registrations (legacy -> calls realtime)
  Future<void> loadStudentRegistrations(String studentId) async {
    startRealtimeRegistrations(studentId);
  }

  /// Load all passes for a student (legacy -> calls realtime)
  Future<void> loadStudentPasses(String studentId) async {
    startRealtimePasses(studentId);
  }
}
