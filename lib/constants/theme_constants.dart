import 'package:flutter/material.dart';

class AppColors {
  // Brand Gradients & Vibrant Appetite Accents
  static const Color primary = Color(0xFF3B82F6);        // Electric Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentEmerald = Color(0xFF10B981);   // Mint Emerald
  static const Color accentAmber = Color(0xFFF59E0B);     // Sunset Gold
  static const Color accentGold = Color(0xFFFBBF24);      // Gold alias
  static const Color accentRose = Color(0xFFF43F5E);      // Vibrant Coral Rose
  static const Color accentPurple = Color(0xFF8B5CF6);    // Electric Purple
  static const Color accentCyan = Color(0xFF06B6D4);      // Neon Cyan

  // Light Mode Tokens (Ultra-Crisp Premium Platinum & Porcelain Canvas)
  static const Color lightBg = Color(0xFFF8FAFC);         // Ultra-Clean High-End Slate Platinum
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure Solid Brilliant White Card
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9); // Light Slate 100 Input Fill / Accent Container
  static const Color lightBorder = Color(0xFFE2E8F0);     // Crisp Visible Slate Border
  static const Color lightBorderStrong = Color(0xFFCBD5E1); // High-Contrast Input Field Border
  static const Color lightTextPrimary = Color(0xFF0F172A); // Deep Obsidian Slate
  static const Color lightTextSecondary = Color(0xFF334155); // Rich Slate 700
  static const Color lightTextMuted = Color(0xFF64748B);   // Slate 500

  // Dark Mode Tokens (Deep Obsidian with Brilliant High-Contrast Text & Crisp Slate Borders)
  static const Color darkBg = Color(0xFF090A0F);          // Deep Pitch Obsidian Black
  static const Color darkSurface = Color(0xFF141724);     // Deep Obsidian Slate Card
  static const Color darkSurfaceAlt = Color(0xFF1D2235);  // Elevated Dark Slate Input Fill
  static const Color darkBorder = Color(0xFF2B3248);      // Crisp Visible High-End Border
  static const Color darkBorderStrong = Color(0xFF3E4866); // High-Contrast Dark Input Border
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure Solid Brilliant White
  static const Color darkTextSecondary = Color(0xFFE2E8F0); // Bright Modern Silver-Zinc (Highly Legible)
  static const Color darkTextMuted = Color(0xFF94A3B8);   // Crisp Muted Silver

  // General Compatibility Aliases
  static const Color background = darkBg;
  static const Color surface = darkSurface;
  static const Color surfaceLight = darkSurfaceAlt;
  static const Color cardBorder = darkBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;

  // Ultra-Luminous Radiant 3D Gold VIP Gradient
  static const LinearGradient radiantGoldGradient = LinearGradient(
    colors: [
      Color(0xFFFFF59D), // Shimmer Bright Gold
      Color(0xFFFFD54F), // Radiant Yellow Gold
      Color(0xFFFFA000), // Rich Amber Gold
      Color(0xFFFF8F00), // Deep Burnished Gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Clean Platinum Canvas Light Background Gradient
  static const LinearGradient lightCanvasGradient = LinearGradient(
    colors: [
      Color(0xFFF8FAFC), // Platinum Crisp White
      Color(0xFFFFFFFF), // Pure White
      Color(0xFFF1F5F9), // Subtle Cool Porcelain
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Rich Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricPillGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient wordDocGradient = LinearGradient(
    colors: [Color(0xFF2B579A), Color(0xFF183B70)], // Microsoft Word Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient excelGradient = LinearGradient(
    colors: [Color(0xFF217346), Color(0xFF104A2A)], // Microsoft Excel Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pptGradient = LinearGradient(
    colors: [Color(0xFFD24726), Color(0xFF9B2C13)], // PowerPoint Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pdfGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Adobe PDF Red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentEmerald,
        surface: AppColors.lightSurface,
        error: AppColors.accentRose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      fontFamily: 'System',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentEmerald,
        surface: AppColors.darkSurface,
        error: AppColors.accentRose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      fontFamily: 'System',
    );
  }
}
