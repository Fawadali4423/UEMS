import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/utils/date_utils.dart' as date_utils;
import 'package:uems/core/widgets/custom_text_field.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/registration/data/registration_repository.dart';
import 'package:uems/features/registration/domain/models/registration_model.dart';

/// Admin screen to view all registrations for an event
class EventRegistrationsScreen extends StatefulWidget {
  final EventModel event;

  const EventRegistrationsScreen({super.key, required this.event});

  @override
  State<EventRegistrationsScreen> createState() => _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends State<EventRegistrationsScreen> {
  final RegistrationRepository _registrationRepository = RegistrationRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<RegistrationModel> _registrations = [];
  List<RegistrationModel> _filteredRegistrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    setState(() => _isLoading = true);
    
    try {
      final registrations = await _registrationRepository.getEventRegistrations(widget.event.id);
      setState(() {
        _registrations = registrations;
        _filteredRegistrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading registrations: $e')),
        );
      }
    }
  }

  void _filterRegistrations(String query) {
    if (query.isEmpty) {
      setState(() => _filteredRegistrations = _registrations);
      return;
    }

    final queryLower = query.toLowerCase();
    setState(() {
      _filteredRegistrations = _registrations.where((reg) {
        final nameMatch = reg.studentName?.toLowerCase().contains(queryLower) ?? false;
        final rollMatch = reg.rollNumber?.toLowerCase().contains(queryLower) ?? false;
        final emailMatch = reg.studentEmail?.toLowerCase().contains(queryLower) ?? false;
        final regIdMatch = reg.registrationId.toLowerCase().contains(queryLower);
        return nameMatch || rollMatch || emailMatch || regIdMatch;
      }).toList();
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
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
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
                            'Event Registrations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          Text(
                            widget.event.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      onPressed: _loadRegistrations,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassmorphismCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total',
                        '${_registrations.length}',
                        Icons.people_rounded,
                        AppTheme.primaryColor,
                        isDark,
                      ),
                      if (widget.event.isPaid) ...[
                        _buildStatItem(
                          'Paid',
                          '${_registrations.where((r) => r.isPaymentCompleted).length}',
                          Icons.payment_rounded,
                          AppTheme.successColor,
                          isDark,
                        ),
                        _buildStatItem(
                          'Pending',
                          '${_registrations.where((r) => r.isPaymentRequired).length}',
                          Icons.pending_rounded,
                          AppTheme.warningColor,
                          isDark,
                        ),
                      ],
                      _buildStatItem(
                        'Entry Fee',
                        widget.event.isPaid 
                            ? 'PKR ${widget.event.entryFee?.toStringAsFixed(0) ?? '0'}'
                            : 'Free',
                        Icons.confirmation_number_rounded,
                        widget.event.isPaid ? AppTheme.accentColor : AppTheme.successColor,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Search',
                  hint: 'Search by name, roll number, or email',
                  prefixIcon: Icons.search_rounded,
                  onChanged: _filterRegistrations,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // Registrations List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredRegistrations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_rounded,
                                  size: 64,
                                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No registrations yet'
                                      : 'No matching registrations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRegistrations,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredRegistrations.length,
                              itemBuilder: (context, index) {
                                final reg = _filteredRegistrations[index];
                                return _buildRegistrationCard(reg, isDark, index);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationCard(RegistrationModel reg, bool isDark, int index) {
    return GlassmorphismCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              radius: 20,
              child: Text(
                (reg.studentName ?? 'S').isNotEmpty ? (reg.studentName ?? 'S')[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reg.studentName ?? 'Unknown Student',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          reg.rollNumber ?? 'N/A',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reg.studentEmail ?? 'N/A',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        date_utils.DateTimeUtils.formatDateTime(reg.registeredAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions Column
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.event.isPaid)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reg.isPaymentCompleted
                          ? AppTheme.successColor.withValues(alpha: 0.15)
                          : AppTheme.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reg.isPaymentCompleted ? 'Paid' : 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: reg.isPaymentCompleted
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                    ),
                  ),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Payment Proof Button
                    if (widget.event.isPaid && reg.paymentProofUrl != null)
                      InkWell(
                        onTap: () => _showPaymentProof(context, reg.paymentProofUrl!),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    if (widget.event.isPaid && reg.paymentProofUrl != null)
                      const SizedBox(width: 8),

                    // ID
                    Text(
                      '#${reg.registrationId.length > 6 ? reg.registrationId.substring(0, 6) : reg.registrationId}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05, end: 0);
  }

  void _showPaymentProof(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Failed to load image"),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
