import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/legal_constants.dart';
import '../constants/theme_constants.dart';
import '../models/subscription_model.dart';
import '../services/auth_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/localization_service.dart';
import '../widgets/dynamic_ambient_canvas.dart';

class VipPaywallSheet extends StatefulWidget {
  const VipPaywallSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VipPaywallSheet(),
    );
  }

  @override
  State<VipPaywallSheet> createState() => _VipPaywallSheetState();
}

class _VipPaywallSheetState extends State<VipPaywallSheet>
    with TickerProviderStateMixin {
  SubscriptionTier _selectedTier = SubscriptionTier.yearly;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  bool _isLoading = false;
  Timer? _purchaseWatchdog;

  @override
  void initState() {
    super.initState();
    InAppPurchaseService.loadProducts();
    InAppPurchaseService.purchaseStatusMessageNotifier
        .addListener(_onPurchaseStatusChanged);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _purchaseWatchdog?.cancel();
    InAppPurchaseService.purchaseStatusMessageNotifier
        .removeListener(_onPurchaseStatusChanged);
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPurchaseStatusChanged() {
    if (!mounted) return;
    final status = InAppPurchaseService.purchaseStatusMessageNotifier.value;
    if (status == null) return;

    if (status == 'purchase_success' || status == 'restore_success') {
      setState(() => _isLoading = false);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.accentEmerald,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('profile_pro_active'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 13.5),
                    ),
                    Text(
                      LocalizationService.tr('paywall_guarantee'),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (status == 'canceled') {
      setState(() => _isLoading = false);
    } else if (status.startsWith('error') ||
        status.startsWith('purchase_failed')) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.accentRose,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            status
                .replaceFirst('error: ', '')
                .replaceFirst('purchase_failed: ', ''),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    // Reset to null so an identical repeat status (e.g. the same error
    // twice in a row) still notifies listeners next time, and stop the
    // stuck-loading watchdog now that a real update has arrived.
    _purchaseWatchdog?.cancel();
    InAppPurchaseService.purchaseStatusMessageNotifier.value = null;
  }

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final started = await InAppPurchaseService.buySubscription(_selectedTier);
      if (started && mounted) {
        _purchaseWatchdog?.cancel();
        _purchaseWatchdog = Timer(const Duration(seconds: 45), () {
          if (!mounted || !_isLoading) return;
          setState(() => _isLoading = false);
          InAppPurchaseService.isProcessingNotifier.value = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.accentAmber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              content: const Text(
                'Mağazadan yanıt alınamadı. Lütfen tekrar deneyin.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        });
      }
      if (!started && mounted) {
        setState(() => _isLoading = false);
        final status = InAppPurchaseService.purchaseStatusMessageNotifier.value;
        if (status == 'product_not_found') {
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: AppColors.accentRose,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              content: const Text(
                'Ürün bilgisi henüz yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accentRose,
            content: Text('Hata: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await InAppPurchaseService.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 1200));
      final isValid = await AuthService.checkSubscriptionExpiry();

      if (mounted) {
        setState(() => _isLoading = false);
        if (isValid && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        messenger.showSnackBar(
          SnackBar(
            backgroundColor:
                isValid ? AppColors.accentEmerald : AppColors.accentAmber,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              isValid
                  ? LocalizationService.tr('profile_pro_active')
                  : LocalizationService.tr('paywall_no_active_sub'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accentRose,
            content: Text('Geri yükleme hatası: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? const Color(0xFF272A3D) : const Color(0xFFE2E8F0);
    final pricing = LocalizationService.currentPricing;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.94,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07090F) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF2A3048) : const Color(0xFFE2E8F0),
                width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 48,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: Stack(
              children: [
                // 1. DYNAMIC AMBIENT LIVING PARTICLES CANVAS
                const Positioned.fill(
                  child: DynamicAmbientCanvas(
                    theme: AmbientTheme.goldVip,
                    particleDensity: 1.1,
                  ),
                ),

                // 2. SCROLLABLE CONTENT
                ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B415C)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 3D Metallic Crown Badge with Pulsing Aura Ring
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Glowing Aura Ring
                              Container(
                                width: 76 + (pulse * 8),
                                height: 76 + (pulse * 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(
                                        alpha: 0.35 - (pulse * 0.2)),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              // Core Golden Orb
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFDF00),
                                      Color(0xFFF59E0B),
                                      Color(0xFFD97706)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.55),
                                      blurRadius: 22,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Color(0xFF1E1B18),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title & PRO VIP Tag
                    Center(
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'CV AI',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFF59E0B)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'PRO VIP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LocalizationService.tr('paywall_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: subColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Feature Checklist (Core 3 Benefits)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF111422).withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem(Icons.auto_awesome_rounded,
                              LocalizationService.tr('paywall_feat_1'), isDark),
                          _buildFeatureItem(Icons.document_scanner_rounded,
                              LocalizationService.tr('paywall_feat_3'), isDark),
                          _buildFeatureItem(
                              Icons.transform_rounded,
                              LocalizationService.tr('paywall_feat_office'),
                              isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SUBSCRIPTION TIERS (Dinamik StoreKit / Google Play Fiyatları)
                    ValueListenableBuilder(
                      valueListenable: InAppPurchaseService.productsNotifier,
                      builder: (context, products, _) {
                        // Direct pricing from localization service (USD fixed prices)
                        final weeklyPrice = pricing.weeklyPrice;
                        final monthlyPrice = pricing.monthlyPrice;
                        final yearlyPrice = pricing.yearlyPrice;

                        return Column(
                          children: [
                            // 1. HAFTALIK PLAN
                            _buildTierCard(
                              tier: SubscriptionTier.weekly,
                              title:
                                  LocalizationService.tr('paywall_plan_weekly'),
                              badge: pricing.currencySymbol,
                              price: '$weeklyPrice / ${pricing.weeklyPeriod}',
                              subPrice: LocalizationService.tr(
                                  'paywall_weekly_flexible'),
                              isDark: isDark,
                            ),

                            const SizedBox(height: 8),

                            // 2. AYLIK PLAN
                            _buildTierCard(
                              tier: SubscriptionTier.monthly,
                              title: LocalizationService.tr(
                                  'paywall_plan_monthly'),
                              badge: pricing.currencySymbol,
                              price: '$monthlyPrice / ${pricing.monthlyPeriod}',
                              subPrice: LocalizationService.tr(
                                  'paywall_monthly_renewal'),
                              isDark: isDark,
                            ),

                            const SizedBox(height: 8),

                            // 3. YILLIK PLAN (EN POPÜLER)
                            _buildTierCard(
                              tier: SubscriptionTier.yearly,
                              title:
                                  LocalizationService.tr('paywall_plan_yearly'),
                              badge:
                                  "${LocalizationService.tr('paywall_yearly_badge')} (${pricing.saveBadge})",
                              price: "$yearlyPrice / ${pricing.yearlyPeriod}",
                              subPrice:
                                  "${LocalizationService.tr('paywall_yearly_saving')} ${pricing.yearlyMonthlyEquivalent}",
                              isHighlighted: true,
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // CTA BUTTON WITH ANIMATED SHIMMER LIGHT BEAM
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return GestureDetector(
                          onTap: _isLoading ? null : _handlePurchase,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFE066),
                                  Color(0xFFF59E0B),
                                  Color(0xFFD97706),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Shimmer Light Reflection Sweep
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: CustomPaint(
                                      painter: _ShimmerSweepPainter(
                                          progress: _shimmerController.value),
                                    ),
                                  ),
                                ),
                                // Button Label & Spinner
                                Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.flash_on_rounded,
                                                color: Colors.black, size: 22),
                                            const SizedBox(width: 8),
                                            Flexible(
                                                child: Text(
                                              LocalizationService.tr(
                                                  'paywall_cta'),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                                letterSpacing: 0.5,
                                              ),
                                            )),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Trust & Guarantee Badges (Wrap to prevent overflow)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_repeat_rounded,
                                size: 13, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(
                              LocalizationService.tr('paywall_cancel_anytime'),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: subColor),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(
                              LocalizationService.tr('paywall_money_back'),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: subColor),
                            )),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Footer Interactive Links (Restore, Terms, Privacy)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        GestureDetector(
                          onTap: _handleRestorePurchases,
                          child: Text(
                            LocalizationService.tr('paywall_restore'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF2563EB),
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text('•',
                            style: TextStyle(fontSize: 11, color: subColor)),
                        GestureDetector(
                          onTap: () async {
                            final opened =
                                await LegalConstants.openTermsOfUse();
                            if (!opened && context.mounted) {
                              _showLegalModal(
                                context,
                                title: LocalizationService.tr('paywall_terms'),
                                content: LocalizationService.tr(
                                    'paywall_terms_detail'),
                              );
                            }
                          },
                          child: Text(
                            LocalizationService.tr('paywall_terms'),
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text('•',
                            style: TextStyle(fontSize: 11, color: subColor)),
                        GestureDetector(
                          onTap: () async {
                            final opened =
                                await LegalConstants.openPrivacyPolicy();
                            if (!opened && context.mounted) {
                              _showLegalModal(
                                context,
                                title: LocalizationService.tr(
                                    'paywall_privacy_title'),
                                content: LocalizationService.tr(
                                    'paywall_privacy_detail'),
                              );
                            }
                          },
                          child: Text(
                            LocalizationService.tr('paywall_privacy_title'),
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 3. TOP RIGHT CLOSE BUTTON
                Positioned(
                  top: 14,
                  right: 14,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C2134)
                              : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: textColor,
                          ),
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

  void _showLegalModal(BuildContext context,
      {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child:
              Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocalizationService.tr('cancel'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFFF59E0B), size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required SubscriptionTier tier,
    required String title,
    required String badge,
    required String price,
    required String subPrice,
    bool isHighlighted = false,
    required bool isDark,
  }) {
    final isSelected = _selectedTier == tier;
    final cardBg = isDark
        ? (isSelected
            ? const Color(0xFF1B2035)
            : const Color(0xFF101320).withValues(alpha: 0.9))
        : (isSelected ? const Color(0xFFEFF6FF) : Colors.white);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? (isHighlighted
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF3B82F6))
                : (isDark ? const Color(0xFF242940) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isHighlighted
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6))
                        .withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (isHighlighted
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3B82F6))
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFCBD5E1)),
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 13, color: Colors.black))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isHighlighted
                              ? const Color(0xFFF59E0B)
                              : textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isHighlighted
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF3B82F6))
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: isHighlighted
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subPrice,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerSweepPainter extends CustomPainter {
  final double progress;

  _ShimmerSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final shimmerWidth = width * 0.45;
    final currentX = -shimmerWidth + (width + shimmerWidth * 2) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.40),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(currentX, 0, shimmerWidth, height));

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) => true;
}
