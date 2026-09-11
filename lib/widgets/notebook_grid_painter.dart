import 'package:flutter/material.dart';

/// Authentic white squared notebook paper grid custom painter (Kareli Beyaz Defter Izgarası)
/// Reusable across SplashScreen, LoginScreen, and RegisterScreen.
class NotebookGridPainter extends CustomPainter {
  final bool isDark;

  const NotebookGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Crisp clean white notebook paper sheet
    final paperColor =
        isDark ? const Color(0xFF090D18) : const Color(0xFFFFFFFF);
    final paperPaint = Paint()
      ..color = paperColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paperPaint);

    // 2. Square Grid / Graph Paper lines (Kareli defter ızgarası)
    // 24.0 points corresponds to classic ~5mm quad notebook ruling on mobile displays
    const double gridSize = 24.0;

    // Authentic notebook ruling:
    // Light mode: Classic pale cyan-blue / soft technical slate lines (açık mavi kareli defter)
    // Dark mode: Refined blueprint drafting grid
    final gridLineColor = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
        : const Color(0xFF0284C7).withValues(alpha: 0.18);

    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Subtle page edge depth gradient (mimics authentic paper lighting)
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [
          Colors.transparent,
          isDark
              ? Colors.black.withValues(alpha: 0.28)
              : const Color(0xFF64748B).withValues(alpha: 0.05),
        ],
        stops: const [0.70, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant NotebookGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
