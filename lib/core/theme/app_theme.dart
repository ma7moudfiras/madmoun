import 'package:flutter/material.dart';

/// Olive & Amber design system. The ONLY file allowed to contain color hex
/// values; everything else reads colors through [Theme] / [AppColors].
abstract final class AppTheme {
  static const Color primary = Color(0xFF42552F);
  static const Color primaryDark = Color(0xFF26301B);
  static const Color accent = Color(0xFFE8A33D);
  static const Color container = Color(0xFFF5E9CF);
  static const Color surface = Color(0xFFFBFAF6);
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF5F6B54);
  static const Color _outline = Color(0xFFD8DCCF);
  static const Color _primaryTint = Color(0x1A42552F);
  static const Color _accentTint = Color(0x33E8A33D);
  static const Color _successTint = Color(0x1A2E7D32);
  static const Color _errorTint = Color(0x14B3261E);
  static const Color _shimmerBase = Color(0xFFEDEBE3);
  static const Color _shimmerHighlight = Color(0xFFF8F6F0);
  static const Color _neutralChip = Color(0xFFEDEFE8);

  static const String fontFamily = 'IBMPlexSansArabic';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: _white,
      primaryContainer: container,
      onPrimaryContainer: primaryDark,
      secondary: accent,
      onSecondary: primaryDark,
      secondaryContainer: _accentTint,
      onSecondaryContainer: primaryDark,
      tertiary: success,
      onTertiary: _white,
      error: error,
      onError: _white,
      errorContainer: _errorTint,
      onErrorContainer: error,
      surface: surface,
      onSurface: primaryDark,
      surfaceContainerHighest: _neutralChip,
      onSurfaceVariant: _textMuted,
      outline: _outline,
      outlineVariant: _primaryTint,
      shadow: primaryDark,
      scrim: primaryDark,
      inverseSurface: primaryDark,
      onInverseSurface: surface,
      inversePrimary: container,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: primaryDark,
        displayColor: primaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _primaryTint),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _neutralChip,
        selectedColor: container,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: primaryDark,
        ),
      ),
      dividerTheme: const DividerThemeData(color: _primaryTint, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        contentTextStyle:
            const TextStyle(fontFamily: fontFamily, color: _white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _white,
        indicatorColor: container,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryDark,
          ),
        ),
      ),
      extensions: const [AppColors.light],
    );
  }
}

/// Semantic colors that Material's scheme has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.dangerTint,
    required this.primaryTint,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color dangerTint;
  final Color primaryTint;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const AppColors light = AppColors(
    success: AppTheme.success,
    successTint: AppTheme._successTint,
    warning: AppTheme.accent,
    warningTint: AppTheme._accentTint,
    dangerTint: AppTheme._errorTint,
    primaryTint: AppTheme._primaryTint,
    shimmerBase: AppTheme._shimmerBase,
    shimmerHighlight: AppTheme._shimmerHighlight,
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? successTint,
    Color? warning,
    Color? warningTint,
    Color? dangerTint,
    Color? primaryTint,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColors(
      success: success ?? this.success,
      successTint: successTint ?? this.successTint,
      warning: warning ?? this.warning,
      warningTint: warningTint ?? this.warningTint,
      dangerTint: dangerTint ?? this.dangerTint,
      primaryTint: primaryTint ?? this.primaryTint,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      successTint: Color.lerp(successTint, other.successTint, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
      dangerTint: Color.lerp(dangerTint, other.dangerTint, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
