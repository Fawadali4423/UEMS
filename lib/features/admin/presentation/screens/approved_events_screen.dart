import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/proposals/domain/models/proposal_model.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';

/// Screen showing approved proposals ready to be converted to events
class ApprovedEventsScreen extends StatefulWidget {
  const ApprovedEventsScreen({super.key});

  @override
  State<ApprovedEventsScreen> createState() => _ApprovedEventsScreenState();
}

class _ApprovedEventsScreenState extends State<ApprovedEventsScreen> {
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
              Expanded(child: _buildApprovedList(isDark)),
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
                  'Approved Requests',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Create events from approved proposals',
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

  Widget _buildApprovedList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proposals')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final proposals = snapshot.data?.docs.map((doc) {
          return ProposalModel.fromFirestore(doc);
        }).toList() ?? [];

        if (proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Approved Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Approve student requests to see them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
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
            return _buildProposalCard(proposals[index], isDark, index);
          },
        );
      },
    );
  }

  Widget _buildProposalCard(ProposalModel proposal, bool isDark, int index) {
    return GlassmorphismCard(
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
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_rounded, color: Colors.white),
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
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: const Text(
                  'APPROVED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _createEventFromProposal(proposal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_circle_rounded),
              label: const Text('Create Event from This Request'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
  }

  void _createEventFromProposal(ProposalModel proposal) {
    // Navigate to create event screen with pre-filled data
    Navigator.pushNamed(
      context,
      AppRoutes.createEvent,
      arguments: {
        'proposalId': proposal.id,
        'title': proposal.title,
        'description': proposal.description,
        'organizerId': proposal.proposedBy,
        'organizerName': proposal.proposedByName,
      },
    );
  }
}
