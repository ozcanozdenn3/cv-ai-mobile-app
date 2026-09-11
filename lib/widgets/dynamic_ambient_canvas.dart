import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AmbientTheme {
  goldVip,
  cosmicBlue,
  auroraPurple,
  darkMinimal,
}

class DynamicAmbientCanvas extends StatefulWidget {
  final Widget? child;
  final AmbientTheme theme;
  final bool showParticles;
  final double particleDensity;

  const DynamicAmbientCanvas({
    super.key,
    this.child,
    this.theme = AmbientTheme.goldVip,
    this.showParticles = true,
    this.particleDensity = 1.0,
  });

  @override
  State<DynamicAmbientCanvas> createState() => _DynamicAmbientCanvasState();
}

class _DynamicAmbientCanvasState extends State<DynamicAmbientCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    final count = (35 * widget.particleDensity).round();
    _particles.clear();
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: _random.nextDouble() * 2.2 + 0.8,
          speed: _random.nextDouble() * 0.15 + 0.05,
          opacity: _random.nextDouble() * 0.5 + 0.2,
          driftAngle: _random.nextDouble() * math.pi * 2,
          pulseSpeed: _random.nextDouble() * 2.0 + 1.0,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant DynamicAmbientCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleDensity != widget.particleDensity) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AmbientPainter(
            progress: _controller.value,
            theme: widget.theme,
            particles: widget.showParticles ? _particles : const [],
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;
  final double driftAngle;
  final double pulseSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.driftAngle,
    required this.pulseSpeed,
  });
}

class _AmbientPainter extends CustomPainter {
  final double progress;
  final AmbientTheme theme;
  final List<_Particle> particles;
  final bool isDark;

  _AmbientPainter({
    required this.progress,
    required this.theme,
    required this.particles,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final time = progress * math.pi * 2;

    // 1. Theme Color Palettes
    Color baseBg;
    Color orbColor1;
    Color orbColor2;
    Color orbColor3;
    Color particleColor;

    switch (theme) {
      case AmbientTheme.goldVip:
        baseBg = isDark ? const Color(0xFF090A10) : const Color(0xFFFAF8F5);
        orbColor1 = const Color(0xFFF59E0B); // Amber Gold
        orbColor2 = const Color(0xFFD97706); // Warm Amber
        orbColor3 = const Color(0xFF8B5CF6); // Royal Violet contrast
        particleColor = isDark ? const Color(0xFFFDE047) : const Color(0xFFD97706); // Golden in dark, rich warm amber in light
        break;
      case AmbientTheme.cosmicBlue:
        baseBg = isDark ? const Color(0xFF070B14) : const Color(0xFFF1F5F9);
        orbColor1 = isDark ? const Color(0xFF2563EB) : const Color(0xFF3B82F6); // Royal Blue
        orbColor2 = isDark ? const Color(0xFF6366F1) : const Color(0xFF6366F1); // Indigo
        orbColor3 = isDark ? const Color(0xFF06B6D4) : const Color(0xFF0284C7); // Cyan
        particleColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB); // Soft cyan in dark, vibrant royal blue in light
        break;
      case AmbientTheme.auroraPurple:
        baseBg = isDark ? const Color(0xFF0C0714) : const Color(0xFFFAF5FF);
        orbColor1 = const Color(0xFF9333EA); // Purple
        orbColor2 = const Color(0xFFEC4899); // Pink
        orbColor3 = const Color(0xFF3B82F6); // Blue
        particleColor = isDark ? const Color(0xFFF472B6) : const Color(0xFF9333EA);
        break;
      case AmbientTheme.darkMinimal:
        baseBg = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
        orbColor1 = const Color(0xFF334155);
        orbColor2 = const Color(0xFF1E293B);
        orbColor3 = const Color(0xFF475569);
        particleColor = isDark ? Colors.white : const Color(0xFF475569);
        break;
    }

    // 2. Base Background Fill
    canvas.drawRect(rect, Paint()..color = baseBg);

    // 3. Dynamic Moving Luminous Orbs (Smooth Sinusoidal Orbits)
    final double orb1X = size.width * (0.25 + 0.20 * math.sin(time));
    final double orb1Y = size.height * (0.20 + 0.15 * math.cos(time * 0.8));
    final double orb1Radius = size.width * 0.70;

    final double orb2X = size.width * (0.80 - 0.25 * math.cos(time * 0.7));
    final double orb2Y = size.height * (0.65 + 0.20 * math.sin(time * 0.9));
    final double orb2Radius = size.width * 0.65;

    final double orb3X = size.width * (0.45 + 0.25 * math.sin(time * 1.2 + 1));
    final double orb3Y = size.height * (0.85 - 0.15 * math.cos(time * 0.6));
    final double orb3Radius = size.width * 0.55;

    final double alphaMultiplier = isDark ? 1.0 : 0.85;

    // Orb 1
    final paintOrb1 = Paint()
      ..shader = RadialGradient(
        colors: [
          orbColor1.withValues(alpha: (isDark ? 0.28 : 0.20) * alphaMultiplier),
          orbColor1.withValues(alpha: (isDark ? 0.08 : 0.05) * alphaMultiplier),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: orb1Radius));
    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, paintOrb1);

    // Orb 2
    final paintOrb2 = Paint()
      ..shader = RadialGradient(
        colors: [
          orbColor2.withValues(alpha: (isDark ? 0.22 : 0.16) * alphaMultiplier),
          orbColor2.withValues(alpha: (isDark ? 0.06 : 0.04) * alphaMultiplier),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: orb2Radius));
    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, paintOrb2);

    // Orb 3
    final paintOrb3 = Paint()
      ..shader = RadialGradient(
        colors: [
          orbColor3.withValues(alpha: (isDark ? 0.16 : 0.12) * alphaMultiplier),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb3X, orb3Y), radius: orb3Radius));
    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, paintOrb3);

    // 4. Floating Luminous Micro-Particles (Ethereal Stardust / Ember Drift)
    for (final p in particles) {
      // Advance position
      final currentY = (p.y - progress * p.speed) % 1.0;
      final currentX = (p.x + 0.04 * math.sin(time * p.pulseSpeed + p.driftAngle)) % 1.0;

      final px = currentX * size.width;
      final py = currentY * size.height;

      // Pulsing opacity and scale
      final pulse = 0.6 + 0.4 * math.sin(time * p.pulseSpeed * 2.0);
      final currentOpacity = (p.opacity * pulse * (isDark ? 0.9 : 0.85)).clamp(0.0, 1.0);
      final currentRadius = p.radius * (isDark ? 1.0 : 1.25) * (0.8 + 0.3 * pulse);

      // Core particle dot
      final particlePaint = Paint()
        ..color = particleColor.withValues(alpha: currentOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), currentRadius, particlePaint);

      // Soft glow around prominent particles
      if (p.radius > 1.8) {
        final glowPaint = Paint()
          ..color = particleColor.withValues(alpha: currentOpacity * (isDark ? 0.35 : 0.45))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(Offset(px, py), currentRadius * 2.2, glowPaint);
      }
    }

    // 5. Cinematic Shooting Stars (Kayan Yıldızlar)
    _drawShootingStars(canvas, size, particleColor, isDark);
  }

  void _drawShootingStars(
    Canvas canvas,
    Size size,
    Color starColor,
    bool isDark,
  ) {
    // 3 distinct shooting star trajectories during the 12s progress cycle
    final shootingStars = [
      (
        startP: 0.08,
        endP: 0.17,
        from: Offset(size.width * 0.92, size.height * 0.06),
        to: Offset(size.width * 0.15, size.height * 0.38),
      ),
      (
        startP: 0.42,
        endP: 0.51,
        from: Offset(size.width * 0.85, size.height * 0.28),
        to: Offset(size.width * 0.08, size.height * 0.62),
      ),
      (
        startP: 0.73,
        endP: 0.82,
        from: Offset(size.width * 0.70, size.height * 0.02),
        to: Offset(size.width * 0.02, size.height * 0.32),
      ),
    ];

    for (final star in shootingStars) {
      if (progress >= star.startP && progress <= star.endP) {
        final localT = (progress - star.startP) / (star.endP - star.startP);
        final head = Offset.lerp(star.from, star.to, localT)!;
        final delta = star.to - star.from;
        final length = delta.distance;
        if (length == 0) continue;
        final norm = delta / length;
        final tailLen = math.min(100.0, length * 0.3);
        final tail = head - norm * tailLen;

        // Smooth fade-in, peak, fade-out
        final fade = math.sin(localT * math.pi);

        // Meteor Trail Gradient
        final trailPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              starColor.withValues(alpha: (isDark ? 0.65 : 0.45) * fade),
              Colors.white.withValues(alpha: 0.95 * fade),
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawLine(tail, head, trailPaint);

        // Bright Glowing Star Head
        final headGlow = Paint()
          ..color = starColor.withValues(alpha: (isDark ? 0.6 : 0.4) * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(head, 4.0, headGlow);

        final headCore = Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * fade)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(head, 2.0, headCore);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => true;
}
