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

/// Login screen with animated UI - Students use Roll Number, Admin uses Email
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rollNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isAdminLogin = false;

  @override
  void dispose() {
    _rollNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    bool success;
    if (_isAdminLogin) {
      // Admin login with email
      success = await authProvider.signIn(
        email: _rollNumberController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      // Student login with roll number
      success = await authProvider.signInWithRollNumber(
        rollNumber: _rollNumberController.text.trim().toUpperCase(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      final route = AppRoutes.getDashboardRoute(authProvider.userRole ?? '');
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      _showErrorSnackbar(authProvider.error ?? 'Login failed');
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
                SizedBox(height: size.height * 0.05),

                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 45,
                    color: AppTheme.primaryColor,
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut)
                    .fadeIn(),

                const SizedBox(height: 24),

                // Welcome text
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.3, end: 0, delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, delay: 300.ms),

                SizedBox(height: size.height * 0.05),

                // Login Form Card
                GlassmorphismCard(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isAdminLogin ? 'Admin Sign In' : 'Student Sign In',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Admin access note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.warningColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, 
                                color: AppTheme.warningColor, size: 18),
                              const SizedBox(width: 8),
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

                        // Roll Number / Email field
                        CustomTextField(
                          controller: _rollNumberController,
                          label: _isAdminLogin ? 'Email' : 'Roll Number',
                          hint: _isAdminLogin ? 'Enter admin email' : 'e.g., BSCSF23M01',
                          prefixIcon: _isAdminLogin ? Icons.email_outlined : Icons.badge_outlined,
                          keyboardType: _isAdminLogin ? TextInputType.emailAddress : TextInputType.text,
                          validator: _isAdminLogin ? Validators.validateEmail : Validators.validateRollNumber,
                          textInputAction: TextInputAction.next,
                          textCapitalization: _isAdminLogin ? TextCapitalization.none : TextCapitalization.characters,
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
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

                        const SizedBox(height: 12),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login button
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return AnimatedButton(
                              text: 'Sign In',
                              icon: Icons.login_rounded,
                              isLoading: auth.isLoading,
                              onPressed: _handleLogin,
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Toggle Admin/Student login
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isAdminLogin = !_isAdminLogin;
                                _rollNumberController.clear();
                              });
                            },
                            icon: Icon(
                              _isAdminLogin ? Icons.school_rounded : Icons.admin_panel_settings_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _isAdminLogin ? 'Switch to Student Login' : 'Admin Login',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Verify Certificate Link (Public Access)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRoutes.verifyCertificate);
                            },
                            icon: Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                              color: AppTheme.successColor,
                            ),
                            label: Text(
                              'Verify Certificate Authenticity',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(AppRoutes.register);
                              },
                              child: const Text(
                                'Sign Up',
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
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final success = await authProvider.sendPasswordResetEmail(
                  resetEmailController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password reset email sent!'
                            : authProvider.error ?? 'Failed to send email',
                      ),
                      backgroundColor:
                          success ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
