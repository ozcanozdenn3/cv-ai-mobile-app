import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import 'login_screen.dart';
import '../widgets/dynamic_ambient_canvas.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const SplashScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.1, 0.7, curve: Curves.easeIn)),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.65, 1.0, curve: Curves.easeInOut)),
    );

    _animController.forward();
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    // 1. Initialize services in parallel
    await Future.wait([
      AuthService.init(),
      CvStorageService.loadActiveCv(),
      LocalizationService.init(),
      Future.delayed(
          const Duration(milliseconds: 2200)), // Allow splash to animate
    ]);

    if (!mounted) return;

    final currentUser = AuthService.currentUser;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          if (currentUser != null) {
            return MainNavigationWrapper(
              onToggleTheme: widget.onToggleTheme,
              isDark: isDark,
            );
          } else {
            return LoginScreen(
              onToggleTheme: widget.onToggleTheme,
            );
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtitleColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(
                child: DynamicAmbientCanvas(
                  theme: AmbientTheme.cosmicBlue,
                  particleDensity: 1.0,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                  const Spacer(flex: 2),

                  // Animated Glowing Brand Logo
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value * _pulseAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 165,
                      height: 165,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(38),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFF38BDF8),
                            Color(0xFF1D4ED8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8)
                                .withValues(alpha: isDark ? 0.6 : 0.45),
                            blurRadius: 38,
                            spreadRadius: 4,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 155,
                          height: 155,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1E293B),
                            child: const Icon(
                              Icons.description_rounded,
                              size: 70,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Animated Title & Subtitle
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CV AI',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF4F46E5)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'STUDIO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocalizationService.tr('splash_subtitle'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Modern Loading Spinner & Version Info
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131B2E)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                LocalizationService.tr('splash_version_badge'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        );
      },
    );
  }
}
