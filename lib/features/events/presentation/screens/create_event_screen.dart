import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/utils/validators.dart';
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/custom_text_field.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/core/services/certificate_api_service.dart';



/// Screen for creating a new event (Admin only)
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiService = CertificateApiService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isLoading = false;
  String? _imageBase64;
  File? _imageFile;
  String _eventType = 'free'; // 'free' or 'paid'
  EventModel? _editingEvent;
  bool _isEditMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get route arguments for edit mode
    if (!_isEditMode) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['event'] != null) {
        _editingEvent = args['event'] as EventModel;
        _isEditMode = args['isEdit'] == true;
        
        if (_isEditMode && _editingEvent != null) {
          _prefillEventData();
        }
      }
    }
  }

  void _prefillEventData() {
    if (_editingEvent == null) return;
    
    setState(() {
      _titleController.text = _editingEvent!.title;
      _descriptionController.text = _editingEvent!.description;
      _venueController.text = _editingEvent!.venue;
      _selectedDate = _editingEvent!.date;
      _eventType = _editingEvent!.isFree ? 'free' : 'paid';
      
      if (!_editingEvent!.isFree) {
        _entryFeeController.text = _editingEvent!.entryFee.toString();
      }
      
      // Parse time strings (format: "09:00 AM")
      final startParts = _editingEvent!.startTime.split(' ');
      final startTimeParts = startParts[0].split(':');
      int startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      
      if (startParts.length > 1 && startParts[1] == 'PM' && startHour != 12) {
        startHour += 12;
      } else if (startParts.length > 1 && startParts[1] == 'AM' && startHour == 12) {
        startHour = 0;
      }
      
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      
      final endParts = _editingEvent!.endTime.split(' ');
      final endTimeParts = endParts[0].split(':');
      int endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);
      
      if (endParts.length > 1 && endParts[1] == 'PM' && endHour != 12) {
        endHour += 12;
      } else if (endParts.length > 1 && endParts[1] == 'AM' && endHour == 12) {
        endHour = 0;
      }
      
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
      
      // Set existing banner image
      if (_editingEvent!.posterBase64 != null && _editingEvent!.posterBase64!.isNotEmpty) {
        _imageBase64 = _editingEvent!.posterBase64;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _entryFeeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageBase64 = base64Encode(bytes);
      });
    }
  }


  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<bool> _checkAvailability({bool silent = false}) async {
    if (_venueController.text.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a venue first')),
        );
      }
      return false;
    }

    if (!silent) setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkEventConflicts(
        eventId: '',
        date: _selectedDate,
        startTime: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        venue: _venueController.text.trim(),
      );

      if (!silent) setState(() => _isLoading = false);

      if (!mounted) return false;

      if (result.hasConflict) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conflict Detected', style: TextStyle(color: AppTheme.errorColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The venue "${_venueController.text}" is already booked:'),
                const SizedBox(height: 12),
                ...result.conflictingEvents.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '• ${e.name}\n  (${e.startTime} - ${e.endTime})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
                const SizedBox(height: 12),
                const Text('Please choose a different time or venue.', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return false;
      } else {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Venue is available!'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      }
    } catch (e) {
      if (!silent) setState(() => _isLoading = false);
      if (mounted && !silent) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Failed'),
            content: Text('Could not verify availability: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
      return false;
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    // Enforce Conflict Check
    setState(() => _isLoading = true);
    final isAvailable = await _checkAvailability(silent: true);
    if (!isAvailable) {
      setState(() => _isLoading = false);
      // If check failed silently (due to conflict), run it loudly to show dialog
      if (mounted) _checkAvailability(); 
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    // Parse entry fee if paid event
    double? entryFee;
    if (_eventType == 'paid' && _entryFeeController.text.isNotEmpty) {
      entryFee = double.tryParse(_entryFeeController.text.trim());
    }

    // Admin events are always approved
    final event = EventModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      startTime: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      endTime: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      venue: _venueController.text.trim(),
      organizerId: authProvider.currentUser?.uid ?? '',
      organizerName: authProvider.currentUser?.name ?? 'Admin',
      status: 'approved', // Admin events are auto-approved
      eventType: _eventType,
      entryFee: entryFee,
      createdAt: DateTime.now(),
    );

    final eventId = await eventProvider.createEvent(event);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (eventId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event created and notifications sent to students!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventProvider.error ?? 'Failed to create event'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

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
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                      child: Text(
                        _isEditMode ? 'Edit Event' : 'Create Event',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Event Image Card
                        GlassmorphismCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Banner',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: double.infinity,
                                  height: isSmallScreen ? 150 : 180,
                                  decoration: BoxDecoration(
                                    color: isDark 
                                      ? const Color(0xFF2D2D44) 
                                      : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                    image: _imageFile != null
                                      ? DecorationImage(
                                          image: FileImage(_imageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  ),
                                  child: _imageFile == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: isSmallScreen ? 40 : 50,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Tap to add event banner',
                                            style: TextStyle(
                                              color: isDark 
                                                ? Colors.grey[400] 
                                                : Colors.grey[600],
                                              fontSize: isSmallScreen ? 13 : 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Stack(
                                        children: [
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.edit_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),

                        SizedBox(height: isSmallScreen ? 12 : 20),

                        // Event Details Card
                        GlassmorphismCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Details',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 14 : 20),

                              // Title
                              CustomTextField(
                                controller: _titleController,
                                label: 'Event Title',
                                hint: 'Enter event title',
                                prefixIcon: Icons.title_rounded,
                                validator: Validators.validateTitle,
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),

                              // Description
                              CustomTextField(
                                controller: _descriptionController,
                                label: 'Description',
                                hint: 'Enter event description',
                                prefixIcon: Icons.description_rounded,
                                maxLines: 3,
                                validator: Validators.validateDescription,
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),

                              // Venue
                              CustomTextField(
                                controller: _venueController,
                                label: 'Venue',
                                hint: 'Enter event venue',
                                prefixIcon: Icons.location_on_rounded,
                                validator: Validators.validateVenue,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                        SizedBox(height: isSmallScreen ? 12 : 20),

                        // Date & Time Card
                        GlassmorphismCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 14 : 20),

                              // Date picker
                              InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                      ? const Color(0xFF2D2D44) 
                                      : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark 
                                        ? Colors.grey[700]! 
                                        : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: AppTheme.primaryColor,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      SizedBox(width: isSmallScreen ? 10 : 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 11 : 12,
                                                color: isDark 
                                                  ? Colors.grey[400] 
                                                  : Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              DateFormat('EEE, MMM d, y').format(_selectedDate),
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 14 : 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark 
                                                  ? Colors.white 
                                                  : Colors.grey[900],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: isDark 
                                          ? Colors.grey[400] 
                                          : Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 12 : 16),

                              // Time pickers - Stack vertically on small screens
                              isSmallScreen
                                ? Column(
                                    children: [
                                      _buildTimePicker(
                                        label: 'Start Time',
                                        time: _startTime,
                                        onTap: () => _selectTime(true),
                                        isDark: isDark,
                                        isSmall: true,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTimePicker(
                                        label: 'End Time',
                                        time: _endTime,
                                        onTap: () => _selectTime(false),
                                        isDark: isDark,
                                        isSmall: true,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _buildTimePicker(
                                          label: 'Start Time',
                                          time: _startTime,
                                          onTap: () => _selectTime(true),
                                          isDark: isDark,
                                          isSmall: false,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTimePicker(
                                          label: 'End Time',
                                          time: _endTime,
                                          onTap: () => _selectTime(false),
                                          isDark: isDark,
                                          isSmall: false,
                                        ),
                                      ),
                                    ],
                                  ),
                              
                              SizedBox(height: isSmallScreen ? 12 : 20),
                              
                              // Check Availability Button
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _checkAvailability,
                                icon: _isLoading 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                  : Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryColor),
                                label: Text(
                                  _isLoading ? 'Checking...' : 'Check Venue Availability',
                                  style: TextStyle(color: AppTheme.primaryColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.primaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                        SizedBox(height: isSmallScreen ? 12 : 20),

                        // Event Type Card (Free/Paid)
                        GlassmorphismCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entry Type',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 14),

                              // Free/Paid selection
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _eventType = 'free'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _eventType == 'free'
                                              ? AppTheme.successColor.withValues(alpha: 0.15)
                                              : (isDark ? const Color(0xFF2D2D44) : Colors.grey[100]),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _eventType == 'free'
                                                ? AppTheme.successColor
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.celebration_rounded,
                                              color: _eventType == 'free'
                                                  ? AppTheme.successColor
                                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                              size: 28,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Free Entry',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _eventType == 'free'
                                                    ? AppTheme.successColor
                                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _eventType = 'paid'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _eventType == 'paid'
                                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                              : (isDark ? const Color(0xFF2D2D44) : Colors.grey[100]),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _eventType == 'paid'
                                                ? AppTheme.primaryColor
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.payments_rounded,
                                              color: _eventType == 'paid'
                                                  ? AppTheme.primaryColor
                                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                              size: 28,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Paid Entry',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _eventType == 'paid'
                                                    ? AppTheme.primaryColor
                                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Entry fee input (visible only for paid events)
                              if (_eventType == 'paid') ...[
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _entryFeeController,
                                  label: 'Entry Fee (PKR)',
                                  hint: 'Enter amount in PKR',
                                  prefixIcon: Icons.attach_money_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: (value) =>
                                      _eventType == 'paid' ? Validators.validateEntryFee(value) : null,
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

                        SizedBox(height: isSmallScreen ? 20 : 30),

                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'All students will be notified when this event is created',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Submit button
                        AnimatedButton(
                          text: _isEditMode ? 'Update Event' : 'Create & Publish Event',
                          icon: _isEditMode ? Icons.save_rounded : Icons.publish_rounded,
                          isLoading: _isLoading,
                          onPressed: _handleCreate,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                        SizedBox(height: isSmallScreen ? 16 : 20),
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

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
    required bool isSmall,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D44) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: isSmall ? 18 : 20,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: isSmall ? 8 : 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
