import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';

/// Splash screen with animated logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for animations
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      final route = AppRoutes.getDashboardRoute(authProvider.userRole ?? '');
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              // App Name
              Text(
                'UEMS',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'University Event Management',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 500.ms),

              const SizedBox(height: 80),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 500.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    delay: 1000.ms,
                    duration: 500.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
