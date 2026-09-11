import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/theme_constants.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'screens/home_screen.dart';
import 'screens/cv_builder_screen.dart';
import 'screens/cam_scanner_screen.dart';
import 'screens/pdf_converter_screen.dart';
import 'screens/documents_library_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';

import 'services/in_app_purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Beklenmeyen derin bağlantı veya asenkron SDK hatalarında uygulamanın kapanmasını önle
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('⚠️ Global yakalanan asenkron durum: $error');
    return true; // Uygulamanın çökmesini engeller
  };

  await SupabaseService.init();
  await LocalizationService.init();
  await AuthService.init();
  runApp(const CvAiApp());

  // Google Play may not have an account or a reachable billing service during
  // startup. It must never prevent the app from rendering.
  unawaited(InAppPurchaseService.init());
}

class CvAiApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const CvAiApp({super.key});

  @override
  State<CvAiApp> createState() => _CvAiAppState();
}

class _CvAiAppState extends State<CvAiApp> with WidgetsBindingObserver {
  static const String _prefThemeKey = 'app_user_selected_theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefThemeKey);
      if (saved != null && mounted) {
        setState(() {
          _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved theme: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AuthService.checkSubscriptionExpiry();
    }
  }

  Future<void> _toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {
      _themeMode = newMode;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefThemeKey, newMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          navigatorKey: CvAiApp.navigatorKey,
          title: LocalizationService.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          home: SplashScreen(
            onToggleTheme: _toggleTheme,
          ),
          onGenerateRoute: (settings) {
            // E-posta doğrulama linki (/?code=...) veya deep link geldiğinde hatasız karşılar
            return MaterialPageRoute(
              builder: (context) => SplashScreen(
                onToggleTheme: _toggleTheme,
              ),
              settings: settings,
            );
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => SplashScreen(
                onToggleTheme: _toggleTheme,
              ),
              settings: settings,
            );
          },
        );
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const MainNavigationWrapper({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  List<NavItem> _getNavItems() {
    return [
      NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: LocalizationService.tr('nav_home'),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        glowColor: const Color(0xFF3B82F6),
      ),
      NavItem(
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge_rounded,
        label: LocalizationService.tr('nav_cv'),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        glowColor: const Color(0xFF6366F1),
      ),
      NavItem(
        icon: Icons.document_scanner_outlined,
        selectedIcon: Icons.document_scanner_rounded,
        label: LocalizationService.tr('nav_scan'),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        glowColor: const Color(0xFF10B981),
      ),
      NavItem(
        icon: Icons.sync_alt_rounded,
        selectedIcon: Icons.sync_alt_rounded,
        label: LocalizationService.tr('nav_convert'),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        glowColor: const Color(0xFF2563EB),
      ),
      NavItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_shared_rounded,
        label: LocalizationService.tr('nav_archive'),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        glowColor: const Color(0xFFF59E0B),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final navItems = _getNavItems();
        return ValueListenableBuilder<UserModel?>(
          valueListenable: AuthService.currentUserNotifier,
          builder: (context, user, _) {
            if (user == null) {
              return LoginScreen(
                onToggleTheme: widget.onToggleTheme,
                onLoginSuccess: () {
                  setState(() {});
                },
              );
            }

            final isDark = widget.isDark;

            final List<Widget> screens = [
              HomeScreen(
                onToggleTheme: widget.onToggleTheme,
                isDark: widget.isDark,
                onNavigateTab: (index) => setState(() => _currentIndex = index),
              ),
              CvBuilderScreen(
                  onReturnHome: () => setState(() => _currentIndex = 0)),
              CamScannerScreen(
                  onReturnHome: () => setState(() => _currentIndex = 0)),
              PdfConverterScreen(
                  onReturnHome: () => setState(() => _currentIndex = 0)),
              DocumentsLibraryScreen(
                  onReturnHome: () => setState(() => _currentIndex = 0)),
            ];

            final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

            return PopScope(
              canPop: _currentIndex == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (_currentIndex != 0) {
                  setState(() => _currentIndex = 0);
                }
              },
              child: Scaffold(
                extendBody: true,
                resizeToAvoidBottomInset: false,
                backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                body: IndexedStack(
                  key: ValueKey(
                      'main_tabs_${LocalizationService.currentLocale}'),
                  index: _currentIndex,
                  children: screens,
                ),
                bottomNavigationBar: isKeyboardOpen
                    ? null
                    : Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 22),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 9.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A0F1D)
                                  .withValues(alpha: 0.45),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: navItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isSelected = _currentIndex == index;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _currentIndex = index),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSelected ? 14 : 9,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? item.selectedIcon
                                          : item.icon,
                                      color: isSelected
                                          ? const Color(0xFF0F172A)
                                          : Colors.white
                                              .withValues(alpha: 0.65),
                                      size: isSelected ? 20.5 : 22,
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item.label,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final LinearGradient gradient;
  final Color glowColor;

  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.gradient,
    required this.glowColor,
  });
}
