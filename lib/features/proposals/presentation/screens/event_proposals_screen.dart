import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/proposals/presentation/providers/proposal_provider.dart';
import 'package:uems/features/proposals/domain/models/proposal_model.dart';

/// Screen for viewing and managing event proposals
class EventProposalsScreen extends StatefulWidget {
  const EventProposalsScreen({super.key});

  @override
  State<EventProposalsScreen> createState() => _EventProposalsScreenState();
}

class _EventProposalsScreenState extends State<EventProposalsScreen> {
  String _filter = 'all'; // all, high_votes, pending

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Filter tabs
        _buildFilterTabs(isDark),
        
        const SizedBox(height: 16),

        // Proposals list
        Expanded(
          child: Consumer<ProposalProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final proposals = _getFilteredProposals(provider);

              if (proposals.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  return _buildProposalCard(proposals[index], isDark);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<ProposalModel> _getFilteredProposals(ProposalProvider provider) {
    switch (_filter) {
      case 'high_votes':
        return provider.pendingProposals.where((p) => p.hasHighVotes).toList();
      case 'pending':
        return provider.pendingProposals;
      default:
        return provider.pendingProposals;
    }
  }

  Widget _buildFilterTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('High Votes', 'high_votes', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filter == value;
    
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildProposalCard(ProposalModel proposal, bool isDark) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and verified badge
          Row(
            children: [
              Expanded(
                child: Text(
                  proposal.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ),
              if (proposal.hasHighVotes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'High Demand',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            proposal.description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              // Proposer
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                proposal.proposedByName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
              const Spacer(),

              // Vote count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.how_to_vote_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${proposal.voteCount} votes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveProposal(proposal),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectProposal(proposal),
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.how_to_vote_rounded,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No proposals yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Student proposals will appear here',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveProposal(ProposalModel proposal) async {
    final provider = Provider.of<ProposalProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Proposal'),
        content: Text('Convert "${proposal.title}" to an event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.approveProposal(proposal.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Proposal approved! Create event from proposal.'
                : 'Failed to approve proposal'),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectProposal(ProposalModel proposal) async {
    final provider = Provider.of<ProposalProvider>(context, listen: false);
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Proposal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject "${proposal.title}"?'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Why is this proposal rejected?',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      final success = await provider.rejectProposal(proposal.id, reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Proposal rejected' : 'Failed to reject proposal'),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
