import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../widgets/notebook_grid_painter.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onToggleTheme;

  const LoginScreen({super.key, this.onLoginSuccess, this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isSocialSigningIn = false;
  bool _hasNavigated = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // E-posta onay linki tıklandığında otomatik algıla ve yönlendir
    AuthService.currentUserNotifier.addListener(_onAuthUserChanged);
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_login_email');
      final remember = prefs.getBool('saved_remember_me') ?? true;
      if (mounted) {
        setState(() {
          _rememberMe = remember;
          if (remember && savedEmail != null && savedEmail.isNotEmpty) {
            _emailController.text = savedEmail;
          }
        });
      }
    } catch (_) {}
  }

  void _onAuthUserChanged() {
    if (_isSocialSigningIn || _hasNavigated) return;
    if (AuthService.isLoggedIn && mounted) {
      _hasNavigated = true;
      debugPrint(
          '🎉 E-posta doğrulaması deep link ile tamamlandı, ana ekrana yönlendiriliyor.');
      _showToast(
          '🎉 ${LocalizationService.tr('auth_email_confirmed_welcome')}');
      _navigateOnSuccess();
    }
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_onAuthUserChanged);
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateOnSuccess() {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainNavigationWrapper(
            onToggleTheme: widget.onToggleTheme ?? () {},
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showToast(LocalizationService.tr('auth_err_empty_credentials'),
          isError: true);
      return;
    }

    _isSocialSigningIn = true;
    setState(() => _isLoading = true);
    try {
      await AuthService.loginWithEmail(emailOrUsername: email, password: pass);
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('saved_login_email', email);
          await prefs.setBool('saved_remember_me', true);
        } else {
          await prefs.remove('saved_login_email');
          await prefs.setBool('saved_remember_me', false);
        }
      } catch (_) {}
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        _showToast('🎉 ${LocalizationService.tr('success')}');
        _navigateOnSuccess();
      }
    } catch (e) {
      _isSocialSigningIn = false;
      if (mounted) {
        _showToast(AuthService.localizeAuthError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _isSocialSigningIn = true;
    setState(() => _isLoading = true);
    try {
      final success = await AuthService.signInWithGoogle();
      if (success && mounted && !_hasNavigated) {
        _hasNavigated = true;
        _showToast(
            '✨ ${LocalizationService.tr('auth_google')} ${LocalizationService.tr('success')}');
        _navigateOnSuccess();
      }
    } catch (e) {
      _isSocialSigningIn = false;
      if (mounted) {
        _showToast(LocalizationService.tr('auth_google_error'), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    _isSocialSigningIn = true;
    setState(() => _isLoading = true);
    try {
      final success = await AuthService.signInWithApple();
      if (success && mounted && !_hasNavigated) {
        _hasNavigated = true;
        _showToast(
            '🍏 ${LocalizationService.tr('auth_apple')} ${LocalizationService.tr('success')}');
        _navigateOnSuccess();
      }
    } catch (e) {
      _isSocialSigningIn = false;
      if (mounted) {
        _showToast(LocalizationService.tr('auth_apple_error'), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? AppColors.accentRose : AppColors.accentEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF111728) : Colors.white;
        final textColor =
            isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
        final subColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor =
            isDark ? const Color(0xFF222B42) : const Color(0xFFE2E8F0);
        final inputBg =
            isDark ? const Color(0xFF090D18) : const Color(0xFFF8FAFC);

        return CustomPaint(
          painter: NotebookGridPainter(isDark: isDark),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // HERO BRAND SECTION
                            Hero(
                              tag: 'app_brand_logo',
                              child: Container(
                                width: 135,
                                height: 135,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2B354C)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.45 : 0.10,
                                      ),
                                      blurRadius: 26,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Brand Name & Tagline
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    LocalizationService.tr('app_title'),
                                    style: TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3.5),
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
                                          color: const Color(0xFF4F46E5)
                                              .withValues(alpha: 0.4),
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
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              LocalizationService.tr('app_subtitle'),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: subColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // AUTH CARD
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: cardBg.withValues(
                                    alpha: isDark ? 0.90 : 0.95),
                                borderRadius: BorderRadius.circular(26),
                                border:
                                    Border.all(color: borderColor, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.45 : 0.07),
                                    blurRadius: 26,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocalizationService.tr('auth_btn_login'),
                                    style: TextStyle(
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.w900,
                                        color: textColor),
                                  ),
                                  const SizedBox(height: 16),

                                  // Email Input
                                  _buildInputLabel(
                                      LocalizationService.tr('auth_email'),
                                      subColor),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textCapitalization: TextCapitalization.none,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        color: textColor,
                                        fontWeight: FontWeight.w600),
                                    decoration: _buildInputDecoration(
                                      hint: LocalizationService.tr(
                                          'auth_email_hint'),
                                      icon: Icons.alternate_email_rounded,
                                      isDark: isDark,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      subColor: subColor,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Password Input
                                  _buildInputLabel(
                                      LocalizationService.tr('auth_password'),
                                      subColor),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        color: textColor,
                                        fontWeight: FontWeight.w600),
                                    decoration: _buildInputDecoration(
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      isDark: isDark,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      subColor: subColor,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: subColor,
                                          size: 19,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Remember Me Row (Forgot Password Removed)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          onChanged: (val) => setState(
                                              () => _rememberMe = val ?? true),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                          child: Text(
                                        LocalizationService.tr(
                                            'auth_remember_me'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: subColor),
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // Primary Login Button
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF4F46E5)
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                    child: Text(
                                                  LocalizationService.tr(
                                                      'auth_btn_login'),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.white),
                                                )),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 18),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // SOCIAL / GUEST DIVIDER
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: borderColor, thickness: 1)),
                                Flexible(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    child: Text(
                                      LocalizationService.tr(
                                          'login_or_continue'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: subColor,
                                          letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: borderColor, thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // GOOGLE SIGN IN
                            _buildSocialButton(
                              title: LocalizationService.tr('auth_google'),
                              iconWidget: _buildGoogleBadge(),
                              onTap: _handleGoogleSignIn,
                              isDark: isDark,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            // APPLE SIGN IN (Sadece iOS / macOS üzerinde gösterilir)
                            if (Theme.of(context).platform ==
                                    TargetPlatform.iOS ||
                                Theme.of(context).platform ==
                                    TargetPlatform.macOS) ...[
                              const SizedBox(height: 10),
                              _buildSocialButton(
                                title: LocalizationService.tr('auth_apple'),
                                iconWidget: Icon(
                                  Icons.apple_rounded,
                                  color: isDark ? Colors.white : Colors.black,
                                  size: 24,
                                ),
                                onTap: _handleAppleSignIn,
                                isDark: isDark,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                            ],
                            const SizedBox(height: 2),

                            Text(
                              LocalizationService.tr('auth_no_account'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildSocialButton(
                              title:
                                  LocalizationService.tr('auth_btn_register'),
                              iconWidget: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Color(0xFF2563EB),
                                size: 21,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(
                                      onRegisterSuccess: widget.onLoginSuccess,
                                    ),
                                  ),
                                );
                              },
                              isDark: isDark,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color inputBg,
    required Color borderColor,
    required Color subColor,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: subColor.withValues(alpha: 0.5), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }

  Widget _buildSocialButton({
    required String title,
    required Widget iconWidget,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A2B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleBadge() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
