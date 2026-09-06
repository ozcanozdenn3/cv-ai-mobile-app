import 'package:flutter/material.dart';
 
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/legal_constants.dart';
import '../constants/theme_constants.dart';
import '../models/subscription_model.dart';
import 'vip_paywall_sheet.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final bool isProUser;

  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.isProUser = true,
  });

  static void show(BuildContext context,
      {required bool isDark,
      required VoidCallback onToggleTheme,
      bool isPro = true}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          isDark: isDark,
          onToggleTheme: onToggleTheme,
          isProUser: isPro,
        ),
      ),
    );
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded,
                color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocalizationService.tr('profile_logout'),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
          ],
        ),
        content: Text(
          LocalizationService.tr('profile_logout_confirm'),
          style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('cancel'),
                style: TextStyle(color: subColor, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
              await AuthService.logout();
            },
            child: Text(LocalizationService.tr('profile_logout')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.accentRose, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocalizationService.tr('profile_delete_acc'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentRose),
              ),
            ),
          ],
        ),
        content: Text(
          LocalizationService.tr('profile_delete_confirm'),
          style: TextStyle(fontSize: 12.5, color: subColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('cancel'),
                style: TextStyle(color: subColor, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
              await AuthService.deleteAccount();
            },
            child: Text(LocalizationService.tr('profile_delete_acc')),
          ),
        ],
      ),
    );
  }

  late bool _isPro;
  String _userName = 'Canberk Yılmaz';
  String _userEmail = 'canberk.yilmaz@email.com';
  int _avatarColorIndex = 0;

  final List<LinearGradient> _avatarGradients = const [
    LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
    LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
    LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
    LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
    LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
    LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
  ];

  @override
  void initState() {
    super.initState();
    _isPro = AuthService.currentUser?.isPro ?? widget.isProUser;
    final user = AuthService.currentUser;
    if (user != null) {
      _userName = user.fullName;
      _userEmail = user.email;
    }
    AuthService.currentUserNotifier.addListener(_syncUserData);
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_syncUserData);
    super.dispose();
  }

  void _syncUserData() {
    final user = AuthService.currentUser;
    if (mounted) {
      setState(() {
        _isPro = user?.isPro ?? false;
        if (user != null) {
          _userName = user.fullName;
          _userEmail = user.email;
        }
      });
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LocalizationService.tr('edit'),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                labelText: LocalizationService.tr('cv_field_fullname'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                labelText: LocalizationService.tr('cv_field_email'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();
              if (newName.isNotEmpty) _userName = newName;
              if (newEmail.isNotEmpty) _userEmail = newEmail;
              await AuthService.updateProfile(
                  fullName: _userName, email: _userEmail);
              setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(LocalizationService.tr('save'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131726) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF262E48) : const Color(0xFFE2E8F0);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.blueGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService.tr('profile_language'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textColor),
                          ),
                          Text(
                            LocalizationService.tr('profile_language_sub'),
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: LocalizationService.supportedLanguages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final item = LocalizationService.supportedLanguages[idx];
                      final isSelected =
                          LocalizationService.currentLocale == item.code;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await LocalizationService.setLanguage(item.code);
                            setState(() {});
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                      .withValues(alpha: isDark ? 0.2 : 0.1)
                                  : (isDark
                                      ? const Color(0xFF1B2032)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : borderColor,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.w900
                                                    : FontWeight.w700,
                                                color: isSelected
                                                    ? AppColors.primaryLight
                                                    : textColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: (isSelected
                                                      ? AppColors.primary
                                                      : Colors.grey)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.currencySymbol,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? AppColors.primaryLight
                                                    : subColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.nativeName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? AppColors.primaryLight
                                                  .withValues(alpha: 0.8)
                                              : subColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpSupportModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131726) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF262E48) : const Color(0xFFE2E8F0);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    const supportEmail = 'ozden9865@gmail.com';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Color(0xFFF59E0B), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('support_modal_title'),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textColor),
                      ),
                      Text(
                        LocalizationService.tr('support_modal_sub'),
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: subColor),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),

            // Email Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1B2032) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationService.tr('support_email_label'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          supportEmail,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: LocalizationService.tr('copy'),
                        icon: const Icon(Icons.copy_rounded,
                            size: 18, color: AppColors.primary),
                        onPressed: () {
                          Clipboard.setData(
                              const ClipboardData(text: supportEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '📋 $supportEmail ${LocalizationService.tr('copied')}'),
                              backgroundColor: AppColors.accentEmerald,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Feature Highlights
            Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  LocalizationService.tr('support_response_time'),
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: subColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.verified_rounded,
                    size: 16, color: AppColors.accentEmerald),
                const SizedBox(width: 6),
                Text(
                  LocalizationService.tr('support_coverage'),
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: subColor),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Send Mail Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: supportEmail,
                    queryParameters: {
                      'subject': 'CV AI Support & Feedback',
                      'body':
                          'Hello,\n\nI need support regarding the CV AI application.\n\nDetails:',
                    },
                  );

                  try {
                    final canLaunch = await canLaunchUrl(emailLaunchUri);
                    if (canLaunch) {
                      await launchUrl(emailLaunchUri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(emailLaunchUri);
                    }
                  } catch (e) {
                    await Clipboard.setData(
                        const ClipboardData(text: supportEmail));
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  LocalizationService.tr('support_btn_send'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecurityModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_rounded,
                  color: AppColors.accentEmerald, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              LocalizationService.tr('profile_privacy'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.tr('profile_privacy_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Privacy Policy External Link
            OutlinedButton.icon(
              onPressed: () => LegalConstants.openPrivacyPolicy(),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                LocalizationService.tr('paywall_privacy_title'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                foregroundColor: AppColors.accentEmerald,
                side: const BorderSide(color: AppColors.accentEmerald),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            // Terms of Use / EULA External Link
            OutlinedButton.icon(
              onPressed: () => LegalConstants.openTermsOfUse(),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: Text(
                LocalizationService.tr('paywall_terms'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                foregroundColor: textColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(LocalizationService.tr('ok'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, currentLocale, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
        final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final textColor =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subColor =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final borderColor =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;

        final initials = _userName.isNotEmpty
            ? _userName
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join('')
                .toUpperCase()
            : 'CY';

        final activeLanguage = LocalizationService.currentLanguageOption;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2032)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: textColor),
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              LocalizationService.tr('profile_title'),
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.primaryLight),
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
            children: [
              // USER PROFILE HEADER CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _avatarColorIndex =
                              (_avatarColorIndex + 1) % _avatarGradients.length;
                        });
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _avatarGradients[_avatarColorIndex],
                              border: Border.all(
                                color: _isPro
                                    ? const Color(0xFFFFD54F)
                                    : (isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1)),
                                width: _isPro ? 2.5 : 2.0,
                              ),
                              boxShadow: _isPro
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 18,
                                        offset: const Offset(0, 5),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFFFD54F)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (_isPro)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  gradient: AppColors.radiantGoldGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF161824)
                                        : Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFA000)
                                          .withValues(alpha: 0.7),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 16,
                                    color: Color(0xFF451A03)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PRO MEMBERSHIP BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: _isPro
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFFEF3C7),
                                  Color(0xFFFDE68A),
                                  Color(0xFFFCD34D)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isPro
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPro
                                ? Icons.verified_rounded
                                : Icons.star_border_rounded,
                            size: 15,
                            color: _isPro
                                ? const Color(0xFF78350F)
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPro
                                ? LocalizationService.tr('profile_pro_active')
                                : LocalizationService.tr('profile_free_plan'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: _isPro
                                  ? const Color(0xFF78350F)
                                  : Colors.grey.shade800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // PRO MEMBERSHIP CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E243A), Color(0xFF151928)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                        : const Color(0xFF93C5FD),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.diamond_rounded,
                          color: Color(0xFF451A03), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService.tr('profile_vip_status'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocalizationService.tr('profile_vip_desc'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_isPro) {
                          _showSubscriptionManagementSheet(context);
                        } else {
                          VipPaywallSheet.show(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF451A03),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: Text(
                        _isPro
                            ? LocalizationService.tr('profile_btn_manage')
                            : LocalizationService.tr('profile_btn_upgrade'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // USAGE STATS
              Text(
                LocalizationService.tr('profile_stats_title'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                        '3',
                        LocalizationService.tr('profile_stat_cvs'),
                        Icons.description_rounded,
                        const Color(0xFF3B82F6),
                        cardBg,
                        borderColor,
                        textColor,
                        subColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                        '14',
                        LocalizationService.tr('profile_stat_scans'),
                        Icons.document_scanner_rounded,
                        const Color(0xFF10B981),
                        cardBg,
                        borderColor,
                        textColor,
                        subColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                        '9',
                        LocalizationService.tr('profile_stat_converts'),
                        Icons.swap_horiz_rounded,
                        const Color(0xFF8B5CF6),
                        cardBg,
                        borderColor,
                        textColor,
                        subColor),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // PREFERENCES & SETTINGS
              Text(
                LocalizationService.tr('profile_settings_title'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      iconColor:
                          isDark ? AppColors.accentAmber : AppColors.primary,
                      title: LocalizationService.tr('profile_theme'),
                      subtitle: isDark
                          ? LocalizationService.tr('profile_theme_dark')
                          : LocalizationService.tr('profile_theme_light'),
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeThumbColor: AppColors.accentAmber,
                        onChanged: (val) => widget.onToggleTheme(),
                      ),
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildSettingTile(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: LocalizationService.tr('profile_language'),
                      subtitle: '${activeLanguage.flag} ${activeLanguage.name}',
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: subColor),
                      onTap: _showLanguagePicker,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildSettingTile(
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: LocalizationService.tr('profile_privacy'),
                      subtitle: LocalizationService.tr('profile_privacy_sub'),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: subColor),
                      onTap: _showSecurityModal,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildSettingTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: LocalizationService.tr('profile_help'),
                      subtitle: LocalizationService.tr('profile_help_sub'),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: subColor),
                      onTap: _showHelpSupportModal,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ACCOUNT MANAGEMENT ACTIONS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Logout Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout_rounded,
                                color: Color(0xFFF59E0B), size: 17),
                            label: Text(
                              LocalizationService.tr('profile_logout'),
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                  color: Color(0xFFF59E0B), width: 1.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Delete Account Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showDeleteAccountDialog,
                            icon: const Icon(Icons.delete_forever_rounded,
                                color: Colors.white, size: 17),
                            label: Text(
                              LocalizationService.tr('profile_delete_acc'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRose,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w600, color: subColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required Color textColor,
    required Color subColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 10.5, color: subColor),
        ),
        trailing: trailing,
      ),
    );
  }

  void _showSubscriptionManagementSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131726) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF262E48) : const Color(0xFFE2E8F0);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final sub = AuthService.activeSubscription;

    final tierName =
        sub?.tierDisplayName ?? LocalizationService.tr('sub_yearly');
    final startDateStr = sub != null
        ? '${sub.startDate.day.toString().padLeft(2, '0')}.${sub.startDate.month.toString().padLeft(2, '0')}.${sub.startDate.year}'
        : '-';
    final expiryDateStr = sub?.tier == SubscriptionTier.unlimited
        ? LocalizationService.tr('lifetime_unlimited')
        : (sub?.expiresAt != null
            ? '${sub!.expiresAt!.day.toString().padLeft(2, '0')}.${sub.expiresAt!.month.toString().padLeft(2, '0')}.${sub.expiresAt!.year}'
            : '-');
    final remainingDays = sub?.remainingDays ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentAmber.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFF451A03), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.tr('sub_management'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocalizationService.tr('sub_vip_details'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // PLAN SUMMARY CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF181D30)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            LocalizationService.tr('sub_current_plan'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: subColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF451A03),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildSubDetailRow(LocalizationService.tr('sub_status'),
                        LocalizationService.tr('sub_status_active'), textColor,
                        isBold: true),
                    const SizedBox(height: 10),
                    _buildSubDetailRow(LocalizationService.tr('sub_start_date'),
                        startDateStr, textColor),
                    const SizedBox(height: 10),
                    _buildSubDetailRow(LocalizationService.tr('sub_end_date'),
                        expiryDateStr, textColor),
                    if (sub?.tier != SubscriptionTier.unlimited) ...[
                      const SizedBox(height: 10),
                      _buildSubDetailRow(
                          LocalizationService.tr('sub_remaining'),
                          '$remainingDays ${LocalizationService.tr('sub_days')}',
                          textColor,
                          valueColor: AppColors.accentEmerald),
                    ],
                    const SizedBox(height: 10),
                    _buildSubDetailRow(
                        LocalizationService.tr('sub_auto_renew'),
                        sub?.autoRenew == true
                            ? LocalizationService.tr('sub_open')
                            : LocalizationService.tr('sub_closed'),
                        textColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubDetailRow(String label, String value, Color textColor,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? textColor,
            ),
          ),
        ),
      ],
    );
  }
}
