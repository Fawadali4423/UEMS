import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uems/features/proposals/data/proposal_repository.dart';
import 'package:uems/features/proposals/domain/models/proposal_model.dart';

/// Provider for managing event proposals and voting
class ProposalProvider with ChangeNotifier {
  final ProposalRepository _repository = ProposalRepository();

  List<ProposalModel> _proposals = [];
  List<ProposalModel> _pendingProposals = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<ProposalModel>>? _proposalsSubscription;
  StreamSubscription<List<ProposalModel>>? _pendingProposalsSubscription;

  @override
  void dispose() {
    _proposalsSubscription?.cancel();
    _pendingProposalsSubscription?.cancel();
    super.dispose();
  }

  List<ProposalModel> get proposals => _proposals;
  List<ProposalModel> get pendingProposals => _pendingProposals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get high-voted proposals (verified demand)
  List<ProposalModel> get highVotedProposals =>
      _proposals.where((p) => p.hasHighVotes && p.isPending).toList();

  /// Load all proposals
  void loadProposals() {
    _isLoading = true;
    notifyListeners();

    _proposalsSubscription?.cancel();
    _proposalsSubscription = _repository.getProposalsStream().listen(
      (proposals) {
        _proposals = proposals;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Load pending proposals
  void loadPendingProposals() {
    _isLoading = true;
    notifyListeners();

    _pendingProposalsSubscription?.cancel();
    _pendingProposalsSubscription = _repository.getProposalsByStatus('pending').listen(
      (proposals) {
        _pendingProposals = proposals;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Create new proposal
  Future<bool> createProposal({
    required String title,
    required String description,
    required String proposedBy,
    required String proposedByName,
    String targetAudience = 'university_wide',
    String? department,
  }) async {
    try {
      final proposal = ProposalModel(
        id: '',
        title: title,
        description: description,
        proposedBy: proposedBy,
        proposedByName: proposedByName,
        targetAudience: targetAudience,
        department: department,
        createdAt: DateTime.now(),
      );

      await _repository.createProposal(proposal);
      _error = null;
      return true;
    } catch (e) {
      print('Error creating proposal: $e'); // Log the actual error
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Vote on proposal
  Future<bool> voteProposal(String proposalId, String userId) async {
    try {
      await _repository.voteProposal(proposalId, userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove vote
  Future<bool> unvoteProposal(String proposalId, String userId) async {
    try {
      await _repository.unvoteProposal(proposalId, userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if user has voted
  Future<bool> hasVoted(String proposalId, String userId) async {
    try {
      return await _repository.hasUserVoted(proposalId, userId);
    } catch (e) {
      return false;
    }
  }

  /// Approve proposal and create event
  Future<bool> approveProposal(String proposalId) async {
    try {
      // This will be handled by the repository which creates an event
      await _repository.approveProposal(proposalId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject proposal
  Future<bool> rejectProposal(String proposalId) async {
    try {
      await _repository.rejectProposal(proposalId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
