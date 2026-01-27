import 'package:flutter/material.dart';
import 'package:uems/features/auth/data/auth_service.dart';
import 'package:uems/features/auth/data/user_repository.dart';
import 'package:uems/features/auth/domain/models/user_model.dart';

/// Hardcoded admin credentials (only admin is pre-configured)
class AuthCredentials {
  static const Map<String, Map<String, String>> predefinedAdmins = {
    'fawad@gmail.com': {
      'password': '123456',
      'name': 'Fawad Admin',
      'role': 'admin',
    },
  };

  static bool isAdmin(String email) {
    return predefinedAdmins.containsKey(email.toLowerCase());
  }

  static Map<String, String>? getAdminCredentials(String email) {
    return predefinedAdmins[email.toLowerCase()];
  }
}

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  /// Get current user model
  UserModel? get currentUser => _currentUser;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Check if user is logged in
  bool get isLoggedIn => _authService.isLoggedIn && _currentUser != null;

  /// Get current user role
  String? get userRole => _currentUser?.role;

  /// Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        // Try to get from Firestore first
        try {
          _currentUser = await _userRepository.getUserById(firebaseUser.uid);
        } catch (e) {
          // Firestore might not be available, check if admin
          final admin = AuthCredentials.getAdminCredentials(firebaseUser.email ?? '');
          if (admin != null) {
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: admin['name'] ?? 'Admin',
              role: 'admin',
              createdAt: DateTime.now(),
            );
          } else {
            // Regular student
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? 'Student',
              role: 'student',
              createdAt: DateTime.now(),
            );
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if admin login FIRST (by email)
      final admin = AuthCredentials.getAdminCredentials(email);
      debugPrint('Admin check for $email: ${admin != null}');

      if (admin != null) {
        // This is an admin - always use admin role
        _currentUser = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: admin['name'] ?? 'Admin',
          role: 'admin',
          createdAt: DateTime.now(),
        );
        debugPrint('Logged in as ADMIN: ${_currentUser?.role}');
      } else {
        // Not an admin - try to get from Firestore or create student
        try {
          _currentUser = await _userRepository.getUserById(credential.user!.uid);
          debugPrint('Got user from Firestore: ${_currentUser?.role}');
        } catch (e) {
          // Firestore not available, create student user
          _currentUser = UserModel(
            uid: credential.user!.uid,
            email: email,
            name: credential.user!.displayName ?? 'Student',
            role: 'student',
            createdAt: DateTime.now(),
          );
          debugPrint('Created temp student user');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Parse Firebase error for user-friendly message
      String errorMessage = e.toString().toLowerCase();
      debugPrint('Login error: $e'); // Debug log
      
      if (errorMessage.contains('user-not-found')) {
        _error = 'No account found with this email. Please sign up first.';
      } else if (errorMessage.contains('wrong-password')) {
        _error = 'Incorrect password. Please try again.';
      } else if (errorMessage.contains('invalid-email')) {
        _error = 'Invalid email address format.';
      } else if (errorMessage.contains('user-disabled')) {
        _error = 'This account has been disabled.';
      } else if (errorMessage.contains('too-many-requests')) {
        _error = 'Too many failed attempts. Please try again later.';
      } else if (errorMessage.contains('invalid-credential') || 
                 errorMessage.contains('invalid_login_credentials')) {
        _error = 'Invalid email or password. Please check and try again.';
      } else if (errorMessage.contains('network-request-failed') ||
                 errorMessage.contains('network')) {
        _error = 'Network error. Please check your internet connection.';
      } else {
        _error = 'Login failed: ${e.toString().split(']').last.trim()}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with roll number (for students)
  Future<bool> signInWithRollNumber({
    required String rollNumber,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Look up user by roll number to get email
      final user = await _userRepository.getUserByRollNumber(rollNumber);
      
      if (user == null) {
        _error = 'No account found with this Roll Number.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use the email for Firebase authentication
      final credential = await _authService.signInWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // Get full user data from Firestore
      _currentUser = await _userRepository.getUserById(credential.user!.uid);
      debugPrint('Logged in student via Roll Number: ${_currentUser?.rollNumber}');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMessage = e.toString().toLowerCase();
      debugPrint('Login error: $e');
      
      if (errorMessage.contains('wrong-password')) {
        _error = 'Incorrect password. Please try again.';
      } else if (errorMessage.contains('invalid-credential') || 
                 errorMessage.contains('invalid_login_credentials')) {
        _error = 'Invalid password. Please check and try again.';
      } else if (errorMessage.contains('too-many-requests')) {
        _error = 'Too many failed attempts. Please try again later.';
      } else if (errorMessage.contains('network-request-failed') ||
                 errorMessage.contains('network')) {
        _error = 'Network error. Please check your internet connection.';
      } else {
        _error = 'Login failed: ${e.toString().split(']').last.trim()}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new student (students only)
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String rollNumber,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check if trying to register with admin email
    if (AuthCredentials.isAdmin(email)) {
      _error = 'This email is reserved for admin. Please use login instead.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Check if roll number already exists
    try {
      final rollExists = await _userRepository.rollNumberExists(rollNumber);
      if (rollExists) {
        _error = 'This Roll Number is already registered.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Roll number check failed: $e');
    }

    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create student user model (always student for registration)
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        rollNumber: rollNumber.toUpperCase(),
        role: 'student', // Always student
        createdAt: DateTime.now(),
      );

      // Try to save to Firestore
      try {
        await _userRepository.createUser(user);
      } catch (e) {
        debugPrint('Firestore write failed: $e');
      }

      try {
        await _authService.updateDisplayName(name);
      } catch (e) {
        debugPrint('Update display name failed: $e');
      }

      _currentUser = user;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? studentId,
    String? profileImageBase64,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.updateProfile(
        uid: _currentUser!.uid,
        name: name,
        phone: phone,
        department: department,
        studentId: studentId,
        profileImageBase64: profileImageBase64,
      );

      // Refresh user data
      _currentUser = await _userRepository.getUserById(_currentUser!.uid);
      
      if (name != null) {
        await _authService.updateDisplayName(name);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      _currentUser = await _userRepository.getUserById(_currentUser!.uid);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Watch current user for real-time updates
  Stream<UserModel?> get userStream {
    if (_currentUser == null) {
      return Stream.value(null);
    }
    return _userRepository.watchUser(_currentUser!.uid);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
