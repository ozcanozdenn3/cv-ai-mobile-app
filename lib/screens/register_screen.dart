import 'package:flutter/material.dart';
 
import '../constants/legal_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/localization_service.dart';
import '../widgets/dynamic_ambient_canvas.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({super.key, this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = true;
  bool _isLoading = false;

  bool _isSocialSigningIn = false;
  bool _hasNavigated = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // E-posta doğrulama linki tıklandığında otomatik algıla
    AuthService.currentUserNotifier.addListener(_onAuthUserChanged);
  }

  void _onAuthUserChanged() {
    if (_isSocialSigningIn || _hasNavigated) return;
    if (AuthService.isLoggedIn && mounted) {
      _hasNavigated = true;
      debugPrint('🎉 E-posta doğrulaması deep link ile tamamlandı, ana ekrana yönlendiriliyor.');
      _showToast('🎉 ${LocalizationService.tr('auth_email_confirmed_welcome')}');
      _navigateOnSuccess();
    }
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_onAuthUserChanged);
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateOnSuccess() {
    if (widget.onRegisterSuccess != null) {
      widget.onRegisterSuccess!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainNavigationWrapper(
            onToggleTheme: () {},
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (!_acceptedTerms) {
      _showToast(LocalizationService.tr('auth_accept_terms'), isError: true);
      return;
    }

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showToast(LocalizationService.tr('auth_err_fill_all'), isError: true);
      return;
    }

    if (pass.length < 6) {
      _showToast(LocalizationService.tr('auth_password_length'), isError: true);
      return;
    }

    if (pass != confirmPass) {
      _showToast(LocalizationService.tr('auth_err_password_mismatch'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    bool emailConfirmationNeeded = false;
    try {
      final success = await AuthService.registerWithEmail(
        fullName: name,
        email: email,
        password: pass,
        acceptedTerms: _acceptedTerms,
        onConfirmationRequired: (needed) {
          emailConfirmationNeeded = needed;
        },
      );

      if (emailConfirmationNeeded && mounted) {
        _showEmailConfirmationModal(email);
      } else if (success && mounted) {
        _showToast('🎉 ${LocalizationService.tr('success')}');
        _navigateOnSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showToast(AuthService.localizeAuthError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// E-posta Onay Modalı (Doğrulama Linki Bilgilendirmesi)
  void _showEmailConfirmationModal(String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst çekme çubuğu
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // İkon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      const Color(0xFF60A5FA).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Color(0xFF3B82F6),
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              Text(
                LocalizationService.tr('auth_modal_title'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Açıklama
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: '$email\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    TextSpan(
                      text: '${LocalizationService.tr('auth_modal_desc_prefix')} ',
                    ),
                    TextSpan(
                      text: LocalizationService.tr('auth_modal_desc_suffix'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bilgi Kutusu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LocalizationService.tr('auth_modal_spam_hint'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Buton 1: Tekrar Gönder
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final errorMsg =
                      await SupabaseService.resendVerificationEmail(email);
                  if (ctx.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(errorMsg == null
                            ? '✉️ ${LocalizationService.tr('auth_modal_resent_success')}'
                            : '⚠️ $errorMsg'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(LocalizationService.tr('auth_modal_resend_btn')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Buton 2: Giriş Ekranına Dön
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Login ekranına döner
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(LocalizationService.tr('auth_modal_back_to_login')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignUp() async {
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

  Future<void> _handleAppleSignUp() async {
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

  void _showTermsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131A2B) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded,
                color: Color(0xFF2563EB), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocalizationService.tr('profile_privacy'),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CV AI Studio\n\n${LocalizationService.tr('auth_terms_body')}',
                style: TextStyle(fontSize: 13, height: 1.5, color: subColor),
              ),
              const SizedBox(height: 16),
              // Privacy Policy External Link
              OutlinedButton.icon(
                onPressed: () => LegalConstants.openPrivacyPolicy(),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Flexible(
                  child: Text(
                    LocalizationService.tr('paywall_privacy_title'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              // Terms of Use / EULA External Link
              OutlinedButton.icon(
                onPressed: () => LegalConstants.openTermsOfUse(),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: Flexible(
                  child: Text(
                    LocalizationService.tr('paywall_terms'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(LocalizationService.tr('ok'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111728) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor, size: 15),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              LocalizationService.tr('auth_btn_register'),
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: textColor),
            ),
            centerTitle: true,
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // 1. LIVE AMBIENT CANVAS
                const Positioned.fill(
                  child: DynamicAmbientCanvas(
                    theme: AmbientTheme.cosmicBlue,
                    particleDensity: 0.85,
                  ),
                ),

              // 2. MAIN SCROLLABLE FORM
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 8),
                      child: Column(
                        children: [
                          // Brand Logo Hero
                          Hero(
                            tag: 'app_brand_logo',
                            child: Container(
                              width: 118,
                              height: 118,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D4ED8)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            LocalizationService.tr('auth_create_account'),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocalizationService.tr('auth_register_subtitle'),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: subColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // REGISTER FORM CARD
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg.withValues(
                                  alpha: isDark ? 0.92 : 0.96),
                              borderRadius: BorderRadius.circular(26),
                              border:
                                  Border.all(color: borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.45 : 0.07),
                                  blurRadius: 26,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name
                                _buildInputLabel(
                                    LocalizationService.tr('auth_name'),
                                    subColor),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: textColor,
                                      fontWeight: FontWeight.w600),
                                  decoration: _buildInputDecoration(
                                    hint: LocalizationService.tr(
                                        'auth_name_hint'),
                                    icon: Icons.person_outline_rounded,
                                    isDark: isDark,
                                    inputBg: inputBg,
                                    borderColor: borderColor,
                                    subColor: subColor,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Email
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
                                const SizedBox(height: 12),

                                // Password
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
                                    hint:
                                        '•••••••• (${LocalizationService.tr('auth_password_hint')})',
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
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Confirm Password
                                _buildInputLabel(
                                    LocalizationService.tr(
                                        'auth_confirm_password'),
                                    subColor),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: textColor,
                                      fontWeight: FontWeight.w600),
                                  decoration: _buildInputDecoration(
                                    hint: '••••••••',
                                    icon: Icons.lock_reset_rounded,
                                    isDark: isDark,
                                    inputBg: inputBg,
                                    borderColor: borderColor,
                                    subColor: subColor,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: subColor,
                                        size: 19,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // TERMS CHECKBOX
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF090D18)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _acceptedTerms,
                                          activeColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          onChanged: (val) => setState(() =>
                                              _acceptedTerms = val ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() =>
                                              _acceptedTerms = !_acceptedTerms),
                                          child: Wrap(
                                            children: [
                                              Text(
                                                LocalizationService.tr(
                                                    'auth_terms_prefix'),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: subColor),
                                              ),
                                              GestureDetector(
                                                onTap: _showTermsDialog,
                                                child: Text(
                                                  LocalizationService.tr(
                                                      'auth_terms_link'),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF2563EB),
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                LocalizationService.tr(
                                                    'auth_terms_suffix'),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: subColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Register Action Button (Disabled until terms checkbox is checked)
                                Builder(builder: (context) {
                                  final bool isRegisterActive =
                                      !_isLoading && _acceptedTerms;
                                  return Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: isRegisterActive
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF2563EB),
                                                Color(0xFF4F46E5)
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            )
                                          : LinearGradient(
                                              colors: [
                                                isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFCBD5E1),
                                                isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFF94A3B8),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isRegisterActive
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF2563EB)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isRegisterActive
                                          ? _handleRegister
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        disabledForegroundColor: isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8),
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
                                                Text(
                                                  LocalizationService.tr(
                                                      'auth_btn_register'),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: isRegisterActive
                                                          ? Colors.white
                                                          : (isDark
                                                              ? Colors.white38
                                                              : const Color(
                                                                  0xFF64748B))),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                  color: isRegisterActive
                                                      ? Colors.white
                                                      : (isDark
                                                          ? Colors.white38
                                                          : const Color(
                                                              0xFF64748B)),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // DIVIDER
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: borderColor, thickness: 1)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  LocalizationService.tr(
                                      'register_or_continue'),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: subColor,
                                      letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: borderColor, thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // GOOGLE REGISTER
                          _buildSocialButton(
                            title: LocalizationService.tr('auth_google'),
                            iconWidget: _buildGoogleBadge(),
                            onTap: _handleGoogleSignUp,
                            isDark: isDark,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 10),

                          // APPLE REGISTER (Sadece iOS / macOS üzerinde gösterilir)
                          if (Theme.of(context).platform == TargetPlatform.iOS ||
                              Theme.of(context).platform == TargetPlatform.macOS) ...[
                            _buildSocialButton(
                              title: LocalizationService.tr('auth_apple'),
                              iconWidget: Icon(
                                Icons.apple_rounded,
                                color: isDark ? Colors.white : Colors.black,
                                size: 22,
                              ),
                              onTap: _handleAppleSignUp,
                              isDark: isDark,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 18),

                          // FOOTER LOGIN LINK
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    LocalizationService.tr('auth_have_account'),
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: subColor),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text(
                                    LocalizationService.tr('auth_btn_login'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
