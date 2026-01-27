import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/utils/validators.dart';
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/custom_text_field.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';

/// Registration screen - STUDENTS ONLY
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      rollNumber: _rollNumberController.text.trim().toUpperCase(),
      role: 'student', // Always student
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard);
    } else {
      _showErrorSnackbar(authProvider.error ?? 'Registration failed');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.02),

                // Back button and title
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Student Registration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                SizedBox(height: size.height * 0.03),

                // Registration Form Card
                GlassmorphismCard(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Create your student account',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Info about admin access
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Admin access is restricted to authorized personnel only.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Name field
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: Icons.person_outline,
                          validator: Validators.validateName,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // Roll Number field
                        CustomTextField(
                          controller: _rollNumberController,
                          label: 'Roll Number',
                          hint: 'e.g., BSCSF23M01',
                          prefixIcon: Icons.badge_outlined,
                          validator: Validators.validateRollNumber,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                        ),

                        const SizedBox(height: 16),

                        // Email field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create a password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm password field
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleRegister(),
                          validator: (value) => Validators.validateConfirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Register button
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return AnimatedButton(
                              text: 'Create Student Account',
                              icon: Icons.school_rounded,
                              isLoading: auth.isLoading,
                              onPressed: _handleRegister,
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
