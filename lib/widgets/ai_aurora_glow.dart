import 'dart:async';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// Wraps any widget with a mesmerizing, futuristic Apple Intelligence / Gemini style
/// glowing gradient border (Aurora glow) and a localized AI badge.
class AiAuroraGlowCard extends StatefulWidget {
  final Widget child;
  final bool isGlowing;
  final VoidCallback? onDismissGlow;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool showBadge;

  const AiAuroraGlowCard({
    super.key,
    required this.child,
    this.isGlowing = true,
    this.onDismissGlow,
    this.borderRadius,
    this.padding,
    this.showBadge = true,
  });

  @override
  State<AiAuroraGlowCard> createState() => _AiAuroraGlowCardState();
}

class _AiAuroraGlowCardState extends State<AiAuroraGlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glowAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutSine,
    );

    if (widget.isGlowing) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AiAuroraGlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlowing && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isGlowing && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isGlowing) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.borderRadius ?? BorderRadius.circular(16);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final t = _glowAnimation.value;
        final glowColor1 = const Color(0xFF6366F1).withValues(alpha: 0.5 + 0.4 * t);
        final glowColor2 = const Color(0xFF06B6D4).withValues(alpha: 0.4 + 0.4 * (1 - t));
        final glowColor3 = const Color(0xFFD946EF).withValues(alpha: 0.35 + 0.3 * t);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Glowing Ambient Aura
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: r,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 * t : 0.22 * t),
                      blurRadius: 16 + 10 * t,
                      spreadRadius: 1 + 2 * t,
                    ),
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.3 * (1 - t) : 0.18 * (1 - t)),
                      blurRadius: 20 + 8 * (1 - t),
                      spreadRadius: 1 + 1.5 * (1 - t),
                    ),
                  ],
                ),
              ),
            ),

            // Animated Gradient Border Container
            Container(
              padding: const EdgeInsets.all(1.8),
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: SweepGradient(
                  center: Alignment.center,
                  startAngle: 0,
                  endAngle: 3.14159 * 2,
                  transform: GradientRotation(_animController.value * 3.14159 * 2),
                  colors: [
                    glowColor1,
                    glowColor2,
                    glowColor3,
                    glowColor1,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular((r.topLeft.x - 1.8).clamp(0, 100)),
                child: widget.child,
              ),
            ),

            // Localized Floating AI Badge
            if (widget.showBadge)
              Positioned(
                top: -8,
                right: 14,
                child: GestureDetector(
                  onTap: widget.onDismissGlow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          LocalizationService.tr('cv_ai_badge_generated'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Helper for typewriter streaming animations
class TypewriterHelper {
  /// Streams text smoothly word-by-word into a TextEditingController
  static Future<void> streamToController(
    TextEditingController controller,
    String fullText, {
    Duration wordDelay = const Duration(milliseconds: 32),
    VoidCallback? onTick,
    VoidCallback? onComplete,
  }) async {
    final words = fullText.split(' ');
    controller.clear();
    final buffer = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i < words.length - 1) buffer.write(' ');
      controller.text = buffer.toString();
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      onTick?.call();
      await Future.delayed(wordDelay);
    }
    onComplete?.call();
  }
}
