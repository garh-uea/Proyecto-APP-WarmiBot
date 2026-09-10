import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Valores base sin significado de interfaz.
/// Los widgets consumen los roles semánticos del tema, no esta clase.
abstract final class WarmiPrimitiveColors {
  static const jungle900 = Color(0xFF083D1C);
  static const jungle800 = Color(0xFF0D5C27);
  static const jungle600 = Color(0xFF1B8A3C);
  static const jungle400 = Color(0xFF52D681);
  static const night950 = Color(0xFF050E1C);
  static const night900 = Color(0xFF0A1628);
  static const night800 = Color(0xFF112040);
  static const night700 = Color(0xFF1A2F4A);
  static const blue200 = Color(0xFFB0C4DE);
  static const blue300 = Color(0xFF91ADD0);
  static const white = Color(0xFFFFFFFF);
  static const amber300 = Color(0xFFFFD166);
  static const coral300 = Color(0xFFFF9B9B);
  static const teal300 = Color(0xFF5DE2E7);
}

abstract final class WarmiPrimitiveType {
  static const display = 28.0;
  static const headline = 22.0;
  static const title = 18.0;
  static const body = 16.0;
  static const bodySmall = 14.0;
  static const label = 12.0;
}

/// Alias temporales para pantallas heredadas todavía no migradas al catálogo.
abstract final class AppColors {
  static const primaryGreen = WarmiPrimitiveColors.jungle600;
  static const primaryGreenDark = WarmiPrimitiveColors.jungle800;
  static const accentGreen = WarmiPrimitiveColors.jungle400;
  static const neonGreen = Color(0xFF00FF88);
  static const bgDark = WarmiPrimitiveColors.night900;
  static const bgCard = WarmiPrimitiveColors.night800;
  static const bgSurface = WarmiPrimitiveColors.night700;
  static const textPrimary = WarmiPrimitiveColors.white;
  static const textSecondary = WarmiPrimitiveColors.blue200;
  static const textMuted = WarmiPrimitiveColors.blue300;
  static const accentTeal = WarmiPrimitiveColors.teal300;
  static const accentAmber = WarmiPrimitiveColors.amber300;
  static const accentCoral = WarmiPrimitiveColors.coral300;
  static const userBubble = WarmiPrimitiveColors.jungle800;
  static const botBubble = WarmiPrimitiveColors.night700;
  static const avatarGradient = [
    WarmiPrimitiveColors.jungle800,
    WarmiPrimitiveColors.jungle600,
    WarmiPrimitiveColors.jungle400,
  ];
  static const bgGradient = [
    WarmiPrimitiveColors.night950,
    WarmiPrimitiveColors.night900,
    Color(0xFF0D2240),
  ];
}

@immutable
class WarmiColorTokens extends ThemeExtension<WarmiColorTokens> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color interactive;
  final Color onInteractive;
  final Color success;
  final Color warning;
  final Color error;
  final Color outline;
  final Color focus;

  const WarmiColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.interactive,
    required this.onInteractive,
    required this.success,
    required this.warning,
    required this.error,
    required this.outline,
    required this.focus,
  });

  @override
  WarmiColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? interactive,
    Color? onInteractive,
    Color? success,
    Color? warning,
    Color? error,
    Color? outline,
    Color? focus,
  }) =>
      WarmiColorTokens(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        interactive: interactive ?? this.interactive,
        onInteractive: onInteractive ?? this.onInteractive,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error: error ?? this.error,
        outline: outline ?? this.outline,
        focus: focus ?? this.focus,
      );

  @override
  WarmiColorTokens lerp(covariant WarmiColorTokens? other, double t) {
    if (other == null) return this;
    return WarmiColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      interactive: Color.lerp(interactive, other.interactive, t)!,
      onInteractive: Color.lerp(onInteractive, other.onInteractive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
    );
  }
}

@immutable
class WarmiSpacingTokens extends ThemeExtension<WarmiSpacingTokens> {
  final double xxs, xs, sm, md, lg, xl, xxl;
  const WarmiSpacingTokens({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  @override
  WarmiSpacingTokens copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) =>
      WarmiSpacingTokens(
        xxs: xxs ?? this.xxs,
        xs: xs ?? this.xs,
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
        xxl: xxl ?? this.xxl,
      );

  @override
  WarmiSpacingTokens lerp(covariant WarmiSpacingTokens? other, double t) {
    if (other == null) return this;
    return WarmiSpacingTokens(
      xxs: _lerp(xxs, other.xxs, t),
      xs: _lerp(xs, other.xs, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      xxl: _lerp(xxl, other.xxl, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

@immutable
class WarmiRadiusTokens extends ThemeExtension<WarmiRadiusTokens> {
  final double small, medium, large, pill;
  const WarmiRadiusTokens({
    this.small = 8,
    this.medium = 12,
    this.large = 16,
    this.pill = 999,
  });

  @override
  WarmiRadiusTokens copyWith({
    double? small,
    double? medium,
    double? large,
    double? pill,
  }) =>
      WarmiRadiusTokens(
        small: small ?? this.small,
        medium: medium ?? this.medium,
        large: large ?? this.large,
        pill: pill ?? this.pill,
      );

  @override
  WarmiRadiusTokens lerp(covariant WarmiRadiusTokens? other, double t) {
    if (other == null) return this;
    return WarmiRadiusTokens(
      small: WarmiSpacingTokens._lerp(small, other.small, t),
      medium: WarmiSpacingTokens._lerp(medium, other.medium, t),
      large: WarmiSpacingTokens._lerp(large, other.large, t),
      pill: WarmiSpacingTokens._lerp(pill, other.pill, t),
    );
  }
}

@immutable
class WarmiSizeTokens extends ThemeExtension<WarmiSizeTokens> {
  final double minTouchTarget, iconSmall, iconMedium, stateIcon, avatarSmall;
  const WarmiSizeTokens({
    this.minTouchTarget = 48,
    this.iconSmall = 20,
    this.iconMedium = 24,
    this.stateIcon = 48,
    this.avatarSmall = 32,
  });

  @override
  WarmiSizeTokens copyWith({
    double? minTouchTarget,
    double? iconSmall,
    double? iconMedium,
    double? stateIcon,
    double? avatarSmall,
  }) =>
      WarmiSizeTokens(
        minTouchTarget: minTouchTarget ?? this.minTouchTarget,
        iconSmall: iconSmall ?? this.iconSmall,
        iconMedium: iconMedium ?? this.iconMedium,
        stateIcon: stateIcon ?? this.stateIcon,
        avatarSmall: avatarSmall ?? this.avatarSmall,
      );

  @override
  WarmiSizeTokens lerp(covariant WarmiSizeTokens? other, double t) {
    if (other == null) return this;
    return WarmiSizeTokens(
      minTouchTarget:
          WarmiSpacingTokens._lerp(minTouchTarget, other.minTouchTarget, t),
      iconSmall: WarmiSpacingTokens._lerp(iconSmall, other.iconSmall, t),
      iconMedium: WarmiSpacingTokens._lerp(iconMedium, other.iconMedium, t),
      stateIcon: WarmiSpacingTokens._lerp(stateIcon, other.stateIcon, t),
      avatarSmall: WarmiSpacingTokens._lerp(avatarSmall, other.avatarSmall, t),
    );
  }
}

extension WarmiThemeContext on BuildContext {
  WarmiColorTokens get warmiColors =>
      Theme.of(this).extension<WarmiColorTokens>()!;
  WarmiSpacingTokens get warmiSpacing =>
      Theme.of(this).extension<WarmiSpacingTokens>()!;
  WarmiRadiusTokens get warmiRadii =>
      Theme.of(this).extension<WarmiRadiusTokens>()!;
  WarmiSizeTokens get warmiSizes =>
      Theme.of(this).extension<WarmiSizeTokens>()!;
}

abstract final class AppTheme {
  static const _colors = WarmiColorTokens(
    background: WarmiPrimitiveColors.night900,
    surface: WarmiPrimitiveColors.night800,
    surfaceElevated: WarmiPrimitiveColors.night700,
    textPrimary: WarmiPrimitiveColors.white,
    textSecondary: WarmiPrimitiveColors.blue200,
    textMuted: WarmiPrimitiveColors.blue300,
    interactive: WarmiPrimitiveColors.jungle800,
    onInteractive: WarmiPrimitiveColors.white,
    success: WarmiPrimitiveColors.jungle400,
    warning: WarmiPrimitiveColors.amber300,
    error: WarmiPrimitiveColors.coral300,
    outline: Color(0xFF557797),
    focus: WarmiPrimitiveColors.teal300,
  );

  static ThemeData get darkTheme {
    const spacing = WarmiSpacingTokens();
    const radii = WarmiRadiusTokens();
    const sizes = WarmiSizeTokens();
    final textTheme =
        GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: WarmiPrimitiveType.display,
        fontWeight: FontWeight.w700,
        color: _colors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: WarmiPrimitiveType.headline,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: WarmiPrimitiveType.title,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      ),
      bodyLarge: GoogleFonts.lato(
        fontSize: WarmiPrimitiveType.body,
        color: _colors.textPrimary,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: WarmiPrimitiveType.bodySmall,
        color: _colors.textSecondary,
      ),
      labelLarge: GoogleFonts.lato(
        fontSize: WarmiPrimitiveType.bodySmall,
        fontWeight: FontWeight.w700,
        color: _colors.textPrimary,
      ),
      labelSmall: GoogleFonts.lato(
        fontSize: WarmiPrimitiveType.label,
        color: _colors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _colors.interactive,
        onPrimary: _colors.onInteractive,
        secondary: _colors.success,
        onSecondary: WarmiPrimitiveColors.night950,
        surface: _colors.surface,
        onSurface: _colors.textPrimary,
        error: _colors.error,
        onError: WarmiPrimitiveColors.night950,
      ),
      extensions: const [_colors, spacing, radii, sizes],
      scaffoldBackgroundColor: _colors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: _colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: _colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.large),
          side: BorderSide(color: _colors.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _colors.interactive,
          foregroundColor: _colors.onInteractive,
          minimumSize: Size(sizes.minTouchTarget, sizes.minTouchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.medium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(sizes.minTouchTarget, sizes.minTouchTarget),
          foregroundColor: _colors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.pill),
          borderSide: BorderSide(color: _colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.pill),
          borderSide: BorderSide(color: _colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.pill),
          borderSide: BorderSide(color: _colors.focus, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _colors.textMuted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _colors.surface,
        selectedItemColor: _colors.success,
        unselectedItemColor: _colors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: _colors.outline,
      iconTheme: IconThemeData(color: _colors.textSecondary),
    );
  }
}
