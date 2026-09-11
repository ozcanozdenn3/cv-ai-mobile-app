import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import '../widgets/notebook_grid_painter.dart';
import 'login_screen.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;

  late AnimationController _tickerController;

  @override
  void initState() {
    super.initState();

    // 1. Initial fade-in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // 2. Cardiac heartbeat pulsing animation for the center logo
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    _heartbeatAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
    ]).animate(_heartbeatController);

    // 3. Mini tool badges marquee ticker animation (smooth, infinite)
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _fadeController.forward();
    _heartbeatController.repeat();
    _tickerController.repeat();

    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    // Initialize services in parallel while splash animates
    await Future.wait([
      AuthService.init(),
      CvStorageService.loadActiveCv(),
      LocalizationService.init(),
      Future.delayed(const Duration(milliseconds: 3200)),
    ]);

    if (!mounted) return;

    final currentUser = AuthService.currentUser;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
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
    _fadeController.dispose();
    _heartbeatController.dispose();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final edgeFadeColor =
        isDark ? const Color(0xFF090D18) : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D18) : Colors.white,
      body: CustomPaint(
        painter: NotebookGridPainter(isDark: isDark),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // 1. Subtle Executive Ambient Glow (Soft diffuse, no starry particles)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.28,
                left: MediaQuery.of(context).size.width * 0.15,
                right: MediaQuery.of(context).size.width * 0.15,
                height: MediaQuery.of(context).size.width * 0.70,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.16)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        blurRadius: 90,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. TOP STREAM: Mini logos flowing smoothly to the RIGHT (Sağa akış)
              Positioned(
                top: topPadding + 28,
                left: 0,
                right: 0,
                child: _MiniToolTicker(
                  controller: _tickerController,
                  direction: _TickerDirection.toRight,
                  isDark: isDark,
                  fadeColor: edgeFadeColor,
                  items: _topTools,
                ),
              ),

              // 3. CENTER: Authentic Brand Logo with Cardiac Heartbeat + CV AI STUDIO branding
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _heartbeatAnimation,
                      builder: (context, child) {
                        final scale = _heartbeatAnimation.value;
                        final pulseRatio =
                            ((scale - 1.0) / 0.16).clamp(0.0, 1.0);

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 142,
                            height: 142,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(34),
                              color: isDark
                                  ? const Color(0xFF131826)
                                  : Colors.white,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2A344C)
                                    : const Color(0xFFE2E8F0),
                                width: 1.6,
                              ),
                              boxShadow: [
                                // Deep natural physical elevation shadow
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.45 : 0.10,
                                  ),
                                  blurRadius: 26 + 10 * pulseRatio,
                                  offset: const Offset(0, 10),
                                ),
                                // Subtle executive royal blue warmth
                                BoxShadow(
                                  color: const Color(0xFF1E40AF).withValues(
                                    alpha: (isDark ? 0.18 : 0.08) +
                                        0.08 * pulseRatio,
                                  ),
                                  blurRadius: 16 + 6 * pulseRatio,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 134,
                                height: 134,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.description_rounded,
                                    size: 64,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // EXACT BRAND TITLE FROM HOMESCREEN: "CV AI [STUDIO]"
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            LocalizationService.tr('app_title'),
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1D4ED8),
                                  Color(0xFF2563EB),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'STUDIO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      LocalizationService.tr('app_subtitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. BOTTOM STREAM: Mini logos flowing smoothly to the LEFT (Sola akış)
              Positioned(
                bottom: bottomPadding + 34,
                left: 0,
                right: 0,
                child: _MiniToolTicker(
                  controller: _tickerController,
                  direction: _TickerDirection.toLeft,
                  isDark: isDark,
                  fadeColor: edgeFadeColor,
                  items: _bottomTools,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TickerDirection {
  toRight,
  toLeft,
}

class _MiniToolItem {
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color darkCardBg;
  final Color lightCardBg;

  const _MiniToolItem({
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.darkCardBg,
    required this.lightCardBg,
  });
}

// Top tools: PDF, Word (DOCX), CV, CamScanner, Excel (XLSX), PPTX
const List<_MiniToolItem> _topTools = [
  _MiniToolItem(
    label: 'PDF',
    icon: Icons.picture_as_pdf_rounded,
    primaryColor: Color(0xFFDC2626), // Adobe Crimson
    darkCardBg: Color(0xFF1E1214),
    lightCardBg: Color(0xFFFEF2F2),
  ),
  _MiniToolItem(
    label: 'Word',
    icon: Icons.article_rounded,
    primaryColor: Color(0xFF2563EB), // Word Blue
    darkCardBg: Color(0xFF10192D),
    lightCardBg: Color(0xFFEFF6FF),
  ),
  _MiniToolItem(
    label: 'CV',
    icon: Icons.badge_rounded,
    primaryColor: Color(0xFF1E40AF), // Executive Navy
    darkCardBg: Color(0xFF0F172A),
    lightCardBg: Color(0xFFF1F5F9),
  ),
  _MiniToolItem(
    label: 'CamScanner',
    icon: Icons.document_scanner_rounded,
    primaryColor: Color(0xFF0D9488), // Scanner Teal
    darkCardBg: Color(0xFF0C1F1D),
    lightCardBg: Color(0xFFF0FDFA),
  ),
  _MiniToolItem(
    label: 'Excel',
    icon: Icons.table_chart_rounded,
    primaryColor: Color(0xFF16A34A), // Excel Green
    darkCardBg: Color(0xFF0E2218),
    lightCardBg: Color(0xFFF0FDF4),
  ),
  _MiniToolItem(
    label: 'PPTX',
    icon: Icons.slideshow_rounded,
    primaryColor: Color(0xFFEA580C), // PowerPoint Orange
    darkCardBg: Color(0xFF24150D),
    lightCardBg: Color(0xFFFFF7ED),
  ),
];

// Bottom tools: Complementary order (PPTX, Excel, CamScanner, CV, Word, PDF)
const List<_MiniToolItem> _bottomTools = [
  _MiniToolItem(
    label: 'PPTX',
    icon: Icons.slideshow_rounded,
    primaryColor: Color(0xFFEA580C),
    darkCardBg: Color(0xFF24150D),
    lightCardBg: Color(0xFFFFF7ED),
  ),
  _MiniToolItem(
    label: 'Excel',
    icon: Icons.table_chart_rounded,
    primaryColor: Color(0xFF16A34A),
    darkCardBg: Color(0xFF0E2218),
    lightCardBg: Color(0xFFF0FDF4),
  ),
  _MiniToolItem(
    label: 'CamScanner',
    icon: Icons.document_scanner_rounded,
    primaryColor: Color(0xFF0D9488),
    darkCardBg: Color(0xFF0C1F1D),
    lightCardBg: Color(0xFFF0FDFA),
  ),
  _MiniToolItem(
    label: 'CV',
    icon: Icons.badge_rounded,
    primaryColor: Color(0xFF1E40AF),
    darkCardBg: Color(0xFF0F172A),
    lightCardBg: Color(0xFFF1F5F9),
  ),
  _MiniToolItem(
    label: 'Word',
    icon: Icons.article_rounded,
    primaryColor: Color(0xFF2563EB),
    darkCardBg: Color(0xFF10192D),
    lightCardBg: Color(0xFFEFF6FF),
  ),
  _MiniToolItem(
    label: 'PDF',
    icon: Icons.picture_as_pdf_rounded,
    primaryColor: Color(0xFFDC2626),
    darkCardBg: Color(0xFF1E1214),
    lightCardBg: Color(0xFFFEF2F2),
  ),
];

class _MiniToolTicker extends StatelessWidget {
  final AnimationController controller;
  final _TickerDirection direction;
  final bool isDark;
  final Color fadeColor;
  final List<_MiniToolItem> items;

  const _MiniToolTicker({
    required this.controller,
    required this.direction,
    required this.isDark,
    required this.fadeColor,
    required this.items,
  });

  static const double _itemWidth = 172.0;
  static const double _itemGap = 14.0;
  static const double _step = _itemWidth + _itemGap; // 186.0

  @override
  Widget build(BuildContext context) {
    final cycleWidth = items.length * _step; // 6 * 186 = 1116.0
    // Repeat items 5 times to provide plenty of width across any screen
    final repeatedItems = [
      ...items,
      ...items,
      ...items,
      ...items,
      ...items,
    ];

    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          // Flowing track
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final double t = controller.value;
              final double offset;
              if (direction == _TickerDirection.toRight) {
                // Moving right: offset increases from -cycleWidth to 0
                offset = (t * cycleWidth) - cycleWidth;
              } else {
                // Moving left: offset decreases from 0 to -cycleWidth
                offset = -(t * cycleWidth);
              }

              return ClipRect(
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: double.infinity,
                  minHeight: 0,
                  maxHeight: 60,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: repeatedItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: _itemGap),
                          child: _buildMiniToolBadge(item),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),

          // Left edge soft dissolve
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 56,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fadeColor,
                      fadeColor.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // Right edge soft dissolve
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 56,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fadeColor.withValues(alpha: 0.0),
                      fadeColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniToolBadge(_MiniToolItem item) {
    final cardBg = isDark ? item.darkCardBg : item.lightCardBg;
    final borderColor = isDark
        ? item.primaryColor.withValues(alpha: 0.35)
        : item.primaryColor.withValues(alpha: 0.25);
    final labelColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      width: _itemWidth,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini tool colored squircle icon (Enlarged and bolder)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: item.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 11),
          // Tool label (Bigger and clear)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w900,
                  color: labelColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


