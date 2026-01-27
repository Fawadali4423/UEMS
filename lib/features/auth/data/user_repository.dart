import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/core/constants/app_constants.dart';
import 'package:uems/features/auth/domain/models/user_model.dart';

/// Repository for user data operations in Firestore
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Create a new user in Firestore
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toFirestore());
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Get user stream by ID (real-time updates)
  Stream<UserModel?> getUserStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Watch user for real-time updates (alias for getUserStream)
  Stream<UserModel?> watchUser(String uid) => getUserStream(uid);

  /// Update user data
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _usersRef.doc(uid).update(updates);
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? department,
    String? studentId,
    String? rollNumber,
    String? profileImageBase64,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (department != null) updates['department'] = department;
    if (studentId != null) updates['studentId'] = studentId;
    if (rollNumber != null) updates['rollNumber'] = rollNumber;
    if (profileImageBase64 != null) {
      updates['profileImageBase64'] = profileImageBase64;
    }

    await _usersRef.doc(uid).update(updates);
  }

  /// Get user role
  Future<String?> getUserRole(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  /// Get all users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    final snapshot = await _usersRef
        .where('role', isEqualTo: role)
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Stream all users
  Stream<List<UserModel>> getUsersStream() {
    return _usersRef.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
    );
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final snapshot = await _usersRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Check if roll number exists
  Future<bool> rollNumberExists(String rollNumber) async {
    final snapshot = await _usersRef
        .where('rollNumber', isEqualTo: rollNumber.toUpperCase())
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Get user by roll number
  Future<UserModel?> getUserByRollNumber(String rollNumber) async {
    final snapshot = await _usersRef
        .where('rollNumber', isEqualTo: rollNumber.toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromFirestore(snapshot.docs.first);
  }

  /// Get user count by role
  Future<int> getUserCountByRole(String role) async {
    final snapshot = await _usersRef.where('role', isEqualTo: role).count().get();
    return snapshot.count ?? 0;
  }

  /// Search users by name or roll number
  Future<List<UserModel>> searchUsers(String query) async {
    final queryUpper = query.toUpperCase();
    
    // First try to search by roll number (exact partial match)
    final rollSnapshot = await _usersRef
        .where('rollNumber', isGreaterThanOrEqualTo: queryUpper)
        .where('rollNumber', isLessThanOrEqualTo: '$queryUpper\uf8ff')
        .limit(20)
        .get();
    
    if (rollSnapshot.docs.isNotEmpty) {
      return rollSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    }
    
    // Fallback to name search
    final queryLower = query.toLowerCase();
    final snapshot = await _usersRef
        .orderBy('name')
        .startAt([queryLower])
        .endAt(['$queryLower\uf8ff'])
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}
