import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the system
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin', 'organizer', 'student'
  final String? rollNumber; // Unique student identifier (e.g., BSCSF23M01)
  final String? profileImageBase64;
  final String? phone;
  final String? department;
  final String? studentId;
  final List<String> permissions; // New: For granular organizer roles
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.rollNumber,
    this.profileImageBase64,
    this.phone,
    this.department,
    this.studentId,
    this.permissions = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      rollNumber: data['rollNumber'],
      profileImageBase64: data['profileImageBase64'],
      phone: data['phone'],
      department: data['department'],
      studentId: data['studentId'],
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'rollNumber': rollNumber,
      'profileImageBase64': profileImageBase64,
      'phone': phone,
      'department': department,
      'studentId': studentId,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? rollNumber,
    String? profileImageBase64,
    String? phone,
    String? department,
    String? studentId,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      rollNumber: rollNumber ?? this.rollNumber,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is organizer
  bool get isOrganizer => role == 'organizer';

  /// Check if user is a student
  bool get isStudent => role == 'student';

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Check if user has any of the given permissions
  bool hasAnyPermission(List<String> perms) {
    return perms.any((p) => permissions.contains(p));
  }

  /// Check if user has all of the given permissions
  bool hasAllPermissions(List<String> perms) {
    return perms.every((p) => permissions.contains(p));
  }

  /// Get count of assigned permissions
  int get permissionCount => permissions.length;

  /// Check if organizer has only one permission
  bool get hasSinglePermission => isOrganizer && permissions.length == 1;

  /// Get the single permission (if only one exists)
  String? get singlePermission => hasSinglePermission ? permissions.first : null;

  // Specific permission getters
  bool get canCreateEvents => hasPermission('create_event');
  bool get canScanQR => hasPermission('scan_qr');
  bool get canManageFinance => hasPermission('manage_finance');
  bool get canApproveEvents => hasPermission('approve_event');
  bool get canManageCertificates => hasPermission('manage_certificates');

  bool get hasScannerPermission => isAdmin || permissions.contains('scan_qr');
  bool get hasFinancePermission => isAdmin || permissions.contains('manage_finance');
  bool get hasEventPermission => isAdmin || permissions.contains('create_event');

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, role: $role)';
  }
}
