import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/custom_text_field.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';

/// Profile screen for viewing and editing user profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _newProfileImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512, // Resize to save storage
        maxHeight: 512,
        imageQuality: 70, // Compress quality
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newProfileImageBase64 = base64Encode(bytes);
        });
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showImagePicker() {
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
                ),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.secondaryColor),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
                ),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      profileImageBase64: _newProfileImageBase64,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isEditing = false;
        // Don't clear new image here as it's now current
        _newProfileImageBase64 = null; 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Profile updated successfully!' : 'Failed to update profile',
          ),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
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
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                    if (!_isEditing)
                      IconButton(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: Icon(
                          Icons.edit_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final user = authProvider.currentUser;
                      if (user == null) {
                        return const Center(child: Text('User not found'));
                      }

                      // Determine image source
                      ImageProvider? bgImage;
                      if (_newProfileImageBase64 != null) {
                        bgImage = MemoryImage(base64Decode(_newProfileImageBase64!));
                      } else if (user.profileImageBase64 != null) {
                        bgImage = MemoryImage(base64Decode(user.profileImageBase64!));
                      }

                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Profile Avatar
                            GestureDetector(
                              onTap: _showImagePicker,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: bgImage == null ? AppTheme.primaryGradient : null,
                                      image: bgImage != null 
                                          ? DecorationImage(image: bgImage, fit: BoxFit.cover) 
                                          : null,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: bgImage == null
                                        ? Center(
                                            child: Text(
                                              user.name.isNotEmpty 
                                                  ? user.name[0].toUpperCase() 
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      right: -5,
                                      bottom: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ).animate().scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 400.ms,
                                curve: Curves.elasticOut,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Profile Info
                            GlassmorphismCard(
                              child: Column(
                                children: [
                                  if (_isEditing)
                                    CustomTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      hint: 'Enter your name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                    )
                                  else
                                    _buildInfoRow(
                                      icon: Icons.person_outline,
                                      label: 'Name',
                                      value: user.name,
                                      isDark: isDark,
                                    ),
                                  const Divider(),
                                  _buildInfoRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: user.email,
                                    isDark: isDark,
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Member Since',
                                    value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 30),

                            // Save Button (when editing)
                            if (_isEditing) ...[
                              AnimatedButton(
                                text: 'Save Changes',
                                icon: Icons.save_rounded,
                                isLoading: _isLoading,
                                onPressed: _saveProfile,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  _nameController.text = user.name;
                                  setState(() => _isEditing = false);
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ],
                        ),
                      );
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.errorColor;
      case 'organizer':
        return AppTheme.primaryColor;
      default:
        return AppTheme.successColor;
    }
  }
}
