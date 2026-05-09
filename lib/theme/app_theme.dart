import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF050A0E);
  static const surface = Color(0xFF0A1628);
  static const surfaceVariant = Color(0xFF0D1F3C);
  static const panel = Color(0xFF071220);
  static const border = Color(0xFF1A3A5C);
  static const borderBright = Color(0xFF2A5F9E);

  static const primary = Color(0xFF00D4FF);
  static const primaryDim = Color(0xFF0096B8);
  static const accent = Color(0xFF00FF88);
  static const accentDim = Color(0xFF00B85A);
  static const warning = Color(0xFFFFAA00);
  static const danger = Color(0xFFFF3333);
  static const dangerDim = Color(0xFFCC0000);

  static const textPrimary = Color(0xFFE0F4FF);
  static const textSecondary = Color(0xFF7ABCD8);
  static const textDim = Color(0xFF3A6A8A);
  static const textMuted = Color(0xFF1E4A6A);

  static const radarGreen = Color(0xFF00FF41);
  static const radarGreenDim = Color(0xFF004D18);
  static const radarSweep = Color(0x4400FF41);

  static const gridColor = Color(0x0F00D4FF);
  static const gridColorBright = Color(0x1A00D4FF);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
      ),
      fontFamily: 'monospace',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace'),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace'),
        bodySmall: TextStyle(color: AppColors.textDim, fontFamily: 'monospace'),
        labelLarge: TextStyle(color: AppColors.primary, fontFamily: 'monospace', letterSpacing: 1.5),
        labelMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', letterSpacing: 1.2),
        labelSmall: TextStyle(color: AppColors.textDim, fontFamily: 'monospace', letterSpacing: 1.0),
      ),
      dividerColor: AppColors.border,
      cardColor: AppColors.surface,
    );
  }
}
