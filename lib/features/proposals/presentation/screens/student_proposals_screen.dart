import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/proposals/presentation/providers/proposal_provider.dart';
import 'package:uems/features/proposals/domain/models/proposal_model.dart';
import 'package:uems/features/proposals/presentation/screens/student_request_event_screen.dart';
import 'package:uems/core/widgets/proposal_suggestion_dialog.dart';

/// Screen for students to browse and vote on event proposals
class StudentProposalsScreen extends StatefulWidget {
  const StudentProposalsScreen({super.key});

  @override
  State<StudentProposalsScreen> createState() => _StudentProposalsScreenState();
}

class _StudentProposalsScreenState extends State<StudentProposalsScreen> {
  String _sortBy = 'recent'; // recent, most_voted
  String _filterBy = 'all'; // all, department, university

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProposalProvider>(context, listen: false).loadPendingProposals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.grey[100],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),

              // Sort & Filter
              _buildControls(isDark),

              const SizedBox(height: 16),

              // Proposals List
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

                    return RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                        provider.loadPendingProposals();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: proposals.length,
                        itemBuilder: (context, index) {
                          return _buildProposalCard(proposals[index], isDark, index);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Proposals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Vote for events you want to see',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Sort
          Expanded(
            child: _buildDropdown(
              value: _sortBy,
              items: const [
                {'value': 'recent', 'label': 'Recent'},
                {'value': 'most_voted', 'label': 'Most Voted'},
              ],
              onChanged: (value) => setState(() => _sortBy = value!),
              icon: Icons.sort_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          // Filter
          Expanded(
            child: _buildDropdown(
              value: _filterBy,
              items: const [
                {'value': 'all', 'label': 'All Events'},
                {'value': 'university', 'label': 'University'},
                {'value': 'department', 'label': 'My Dept'},
              ],
              onChanged: (value) => setState(() => _filterBy = value!),
              icon: Icons.filter_list_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                dropdownColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item['value'],
                    child: Text(item['label']!),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(ProposalModel proposal, bool isDark, int index) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'High Demand',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
              height: 1.5,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      proposal.proposedByName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Suggestion button
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProposalSuggestionDialog(
                      proposalId: proposal.id,
                      proposalTitle: proposal.title,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 14,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Suggest',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Vote button
              FutureBuilder<bool>(
                future: Provider.of<ProposalProvider>(context, listen: false)
                    .hasVoted(proposal.id, userId),
                builder: (context, snapshot) {
                  final hasVoted = snapshot.data ?? false;
                  
                  return GestureDetector(
                    onTap: () => _toggleVote(proposal.id, hasVoted, userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: hasVoted ? AppTheme.primaryGradient : null,
                        color: hasVoted ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasVoted ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: hasVoted
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasVoted ? Icons.how_to_vote : Icons.how_to_vote_outlined,
                            size: 18,
                            color: hasVoted ? Colors.white : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${proposal.voteCount}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: hasVoted ? Colors.white : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient.scale(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.how_to_vote_rounded,
              size: 60,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[400],
            ),
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'No Proposals Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to request an event!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentRequestEventScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Request Event',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 300.ms);
  }

  List<ProposalModel> _getFilteredProposals(ProposalProvider provider) {
    var proposals = provider.pendingProposals;

    // Filter by target audience
    if (_filterBy == 'university') {
      proposals = proposals.where((p) => p.targetAudience == 'university_wide').toList();
    } else if (_filterBy == 'department') {
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.department;
      proposals = proposals.where((p) => p.department == userId).toList();
    }

    // Sort
    if (_sortBy == 'most_voted') {
      proposals.sort((a, b) => b.voteCount.compareTo(a.voteCount));
    } else {
      proposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return proposals;
  }

  Future<void> _toggleVote(String proposalId, bool hasVoted, String userId) async {
    final provider = Provider.of<ProposalProvider>(context, listen: false);
    
    final success = hasVoted
        ? await provider.unvoteProposal(proposalId, userId)
        : await provider.voteProposal(proposalId, userId);

    if (mounted && success) {
      setState(() {}); // Refresh to update vote button state
    }
  }
}
