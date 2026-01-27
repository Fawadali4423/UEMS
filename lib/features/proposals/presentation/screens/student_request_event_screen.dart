import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/proposals/presentation/providers/proposal_provider.dart';

/// Screen for students to request new events
class StudentRequestEventScreen extends StatefulWidget {
  const StudentRequestEventScreen({super.key});

  @override
  State<StudentRequestEventScreen> createState() => _StudentRequestEventScreenState();
}

class _StudentRequestEventScreenState extends State<StudentRequestEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _targetAudience = 'university_wide';
  String _eventType = 'free';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

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

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info card
                        _buildInfoCard(isDark),
                        
                        const SizedBox(height: 24),

                        // Title
                        _buildTextField(
                          controller: _titleController,
                          label: 'Event Title',
                          hint: 'e.g., Tech Workshop 2024',
                          icon: Icons.event_rounded,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter event title';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Description
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Describe your event idea...',
                          icon: Icons.description_rounded,
                          isDark: isDark,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter description';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Date & Time
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(isDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimePicker(isDark),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Venue
                        _buildTextField(
                          controller: _venueController,
                          label: 'Suggested Venue',
                          hint: 'e.g., Main Auditorium',
                          icon: Icons.location_on_rounded,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter venue';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Target Audience
                        _buildTargetAudience(isDark),

                        const SizedBox(height: 16),

                        // Event Type
                        _buildEventType(isDark),

                        const SizedBox(height: 32),

                        // Submit Button
                        _buildSubmitButton(user),
                      ],
                    ),
                  ),
                ),
              ),
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
                  'Request Event',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Submit your event idea',
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

  Widget _buildInfoCard(bool isDark) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Voting',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Other students will vote on your proposal',
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
    ).animate().fadeIn(delay: 100.ms).scale();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return GlassmorphismCard(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return GlassmorphismCard(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.grey[900],
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

  Widget _buildTimePicker(bool isDark) {
    return GlassmorphismCard(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 10, minute: 0),
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedTime != null ? FontWeight.w600 : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.grey[900],
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

  Widget _buildTargetAudience(bool isDark) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Target Audience',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  'University Wide',
                  'university_wide',
                  _targetAudience == 'university_wide',
                  (value) => setState(() => _targetAudience = value!),
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRadioOption(
                  'My Department',
                  'department',
                  _targetAudience == 'department',
                  (value) => setState(() => _targetAudience = value!),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventType(bool isDark) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Event Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  'Free Entry',
                  'free',
                  _eventType == 'free',
                  (value) => setState(() => _eventType = value!),
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRadioOption(
                  'Paid Event',
                  'paid',
                  _eventType == 'paid',
                  (value) => setState(() => _eventType = value!),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    bool isSelected,
    void Function(String?) onChanged,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(user) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : () => _submitProposal(user),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Submit Proposal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Future<void> _submitProposal(user) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null) {
      _showError('Please select event date');
      return;
    }
    
    if (_selectedTime == null) {
      _showError('Please select event time');
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<ProposalProvider>(context, listen: false);
    
    final success = await provider.createProposal(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      proposedBy: user?.uid ?? '',
      proposedByName: user?.name ?? '',
      targetAudience: _targetAudience,
      department: _targetAudience == 'department' ? user?.department : null,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proposal submitted! Others can now vote on it.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        _showError('Failed to submit proposal. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
