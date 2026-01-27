import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/core/constants/app_constants.dart';
import 'package:uems/features/proposals/domain/models/proposal_model.dart';

/// Repository for managing event proposals
class ProposalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _proposalsRef =>
      _firestore.collection(AppConstants.proposalsCollection);

  CollectionReference<Map<String, dynamic>> get _votesRef =>
      _firestore.collection(AppConstants.votesCollection);

  /// Create a new proposal
  Future<String> createProposal(ProposalModel proposal) async {
    final docRef = await _proposalsRef.add(proposal.toFirestore());
    return docRef.id;
  }

  /// Get all proposals
  Stream<List<ProposalModel>> getProposalsStream() {
    return _proposalsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProposalModel.fromFirestore(doc))
            .toList());
  }

  /// Get proposals by status
  Stream<List<ProposalModel>> getProposalsByStatus(String status) {
    return _proposalsRef
        .where('status', isEqualTo: status)
        .orderBy('voteCount', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProposalModel.fromFirestore(doc))
            .toList());
  }

  /// Get proposal by ID
  Future<ProposalModel?> getProposal(String proposalId) async {
    final doc = await _proposalsRef.doc(proposalId).get();
    if (!doc.exists) return null;
    return ProposalModel.fromFirestore(doc);
  }

  /// Update proposal
  Future<void> updateProposal(String proposalId, Map<String, dynamic> data) async {
    await _proposalsRef.doc(proposalId).update(data);
  }

  /// Vote on a proposal
  Future<void> voteProposal(String proposalId, String userId) async {
    final voteId = VoteModel.generateId(proposalId, userId);
    
    // Check if already voted
    final voteDoc = await _votesRef.doc(voteId).get();
    if (voteDoc.exists) {
      throw Exception('You have already voted on this proposal');
    }

    // Create vote
    final vote = VoteModel(
      id: voteId,
      proposalId: proposalId,
      userId: userId,
      votedAt: DateTime.now(),
    );

    await _votesRef.doc(voteId).set(vote.toFirestore());

    // Increment vote count
    await _proposalsRef.doc(proposalId).update({
      'voteCount': FieldValue.increment(1),
    });
  }

  /// Remove vote
  Future<void> unvoteProposal(String proposalId, String userId) async {
    final voteId = VoteModel.generateId(proposalId, userId);
    
    // Delete vote
    await _votesRef.doc(voteId).delete();

    // Decrement vote count
    await _proposalsRef.doc(proposalId).update({
      'voteCount': FieldValue.increment(-1),
    });
  }

  /// Check if user has voted
  Future<bool> hasUserVoted(String proposalId, String userId) async {
    final voteId = VoteModel.generateId(proposalId, userId);
    final doc = await _votesRef.doc(voteId).get();
    return doc.exists;
  }

  /// Approve proposal and create event from it
  Future<void> approveProposal(String proposalId) async {
    // Just mark as approved - admin will manually create event later
    await _proposalsRef.doc(proposalId).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject proposal
  Future<void> rejectProposal(String proposalId) async {
    await _proposalsRef.doc(proposalId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user's proposals
  Stream<List<ProposalModel>> getUserProposals(String userId) {
    return _proposalsRef
        .where('proposedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProposalModel.fromFirestore(doc))
            .toList());
  }
}

