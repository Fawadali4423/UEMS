import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as import_cloud_firestore;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/proposals/presentation/providers/proposal_provider.dart';
import 'package:uems/features/proposals/domain/models/proposal_model.dart';

/// Screen showing all student event requests (pending proposals)
class RequestedEventsScreen extends StatefulWidget {
  const RequestedEventsScreen({super.key});

  @override
  State<RequestedEventsScreen> createState() => _RequestedEventsScreenState();
}

class _RequestedEventsScreenState extends State<RequestedEventsScreen> {
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
              _buildHeader(isDark),
              Expanded(child: _buildProposalsList(isDark)),
            ],
          ),
        ),
      ),
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
                  'Student Requests',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Event proposals from students',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildProposalsList(bool isDark) {
    return Consumer<ProposalProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final proposals = provider.pendingProposals;
        if (proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 80,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Requests Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            return _buildProposalCard(proposals[index], isDark, provider, index);
          },
        );
      },
    );
  }

  Widget _buildProposalCard(
    ProposalModel proposal,
    bool isDark,
    ProposalProvider provider,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _showSuggestions(context, proposal, isDark),
      child: GlassmorphismCard(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      Text(
                        'By ${proposal.proposedByName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${proposal.voteCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              proposal.description,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : (Colors.grey[300] ?? Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.comment_outlined, 
                    size: 16, 
                    color: isDark ? Colors.grey[400] : Colors.grey[600]
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to view student suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await provider.rejectProposal(proposal.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Rejected' : 'Failed'),
                            backgroundColor: success ? AppTheme.warningColor : AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await provider.approveProposal(proposal.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? '✅ Moved to Approved Events' : 'Failed'),
                            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
  }

  void _showSuggestions(BuildContext context, ProposalModel proposal, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lightbulb, color: AppTheme.accentColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggestions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          Text(
                            'For "${proposal.title}"',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<import_cloud_firestore.QuerySnapshot>(
                  stream: import_cloud_firestore.FirebaseFirestore.instance
                      .collection('proposals')
                      .doc(proposal.id)
                      .collection('suggestions')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, 
                              size: 64, 
                              color: isDark ? Colors.grey[700] : Colors.grey[300]
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No suggestions yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final suggestion = data['suggestion'] as String? ?? '';
                        final timestamp = data['createdAt'] as import_cloud_firestore.Timestamp?;
                        
                        // Format date manually to avoid intl dependency if not imported, 
                        // but let's assume simple display for now
                        final dateStr = timestamp != null 
                            ? '${timestamp.toDate().day}/${timestamp.toDate().month} ${timestamp.toDate().hour}:${timestamp.toDate().minute}'
                            : 'Just now';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D2D44) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : (Colors.grey[200] ?? Colors.grey),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, 
                                    size: 12, 
                                    color: isDark ? Colors.grey[500] : Colors.grey[500]
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (data['isAnonymous'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Anonymous',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
