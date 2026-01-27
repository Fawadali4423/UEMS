import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for event proposals submitted by students
class ProposalModel {
  final String id;
  final String title;
  final String description;
  final String proposedBy; // Student ID
  final String proposedByName;
  final String targetAudience; // 'university_wide' or 'department'
  final String? department;
  final int voteCount;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;

  ProposalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.proposedBy,
    required this.proposedByName,
    this.targetAudience = 'university_wide',
    this.department,
    this.voteCount = 0,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  /// Create from Firestore
  factory ProposalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProposalModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      proposedBy: data['proposedBy'] ?? '',
      proposedByName: data['proposedByName'] ?? '',
      targetAudience: data['targetAudience'] ?? 'university_wide',
      department: data['department'],
      voteCount: data['voteCount'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'proposedBy': proposedBy,
      'proposedByName': proposedByName,
      'targetAudience': targetAudience,
      'department': department,
      'voteCount': voteCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  /// Copy with
  ProposalModel copyWith({
    int? voteCount,
    String? status,
    DateTime? updatedAt,
    String? rejectionReason,
  }) {
    return ProposalModel(
      id: id,
      title: title,
      description: description,
      proposedBy: proposedBy,
      proposedByName: proposedByName,
      targetAudience: targetAudience,
      department: department,
      voteCount: voteCount ?? this.voteCount,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Check if pending
  bool get isPending => status == 'pending';

  /// Check if approved
  bool get isApproved => status == 'approved';

  /// Check if rejected
  bool get isRejected => status == 'rejected';

  /// Check if has high votes (verified demand)
  bool get hasHighVotes => voteCount >= 10;
}

/// Vote record model
class VoteModel {
  final String id;
  final String proposalId;
  final String userId;
  final DateTime votedAt;

  VoteModel({
    required this.id,
    required this.proposalId,
    required this.userId,
    required this.votedAt,
  });

  /// Create from Firestore
  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoteModel(
      id: doc.id,
      proposalId: data['proposalId'] ?? '',
      userId: data['userId'] ?? '',
      votedAt: (data['votedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'proposalId': proposalId,
      'userId': userId,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }

  /// Generate document ID
  static String generateId(String proposalId, String userId) {
    return '${proposalId}_$userId';
  }
}
