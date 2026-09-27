import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';

/// Medical 3D Animated Theme System
/// 
/// Features:
/// - Material 3 with medical color palette
/// - 3D card elevations and shadows
/// - Glassmorphism/frosted glass effects
/// - Custom page transitions with 3D effects
/// - Animated gradients and shimmer effects
/// - Micro-interaction animations
/// - Breathing/pulse animations for medical feel

class MedicalThemeData {
  MedicalThemeData._();

  // ==================== ANIMATION DURATIONS ====================
  static const Duration microDuration = Duration(milliseconds: 150);
  static const Duration shortDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 500);
  static const Duration longDuration = Duration(milliseconds: 800);
  static const Duration pageTransitionDuration = Duration(milliseconds: 600);
  static const Duration breathingDuration = Duration(milliseconds: 2000);
  static const Duration pulseDuration = Duration(milliseconds: 1500);

  // ==================== ANIMATION CURVES ====================
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve deceleratedCurve = Curves.decelerate;
  static const Curve acceleratedCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve medicalCurve = Cubic(0.4, 0.0, 0.2, 1.0); // Material 3 standard
  static const Curve breathingCurve = Curves.easeInOutSine;
  static const Curve pulseCurve = Curves.easeInOutQuad;

  // ==================== 3D ELEVATIONS ====================
  static const double elevationLevel0 = 0.0;
  static const double elevationLevel1 = 2.0;
  static const double elevationLevel2 = 4.0;
  static const double elevationLevel3 = 8.0;
  static const double elevationLevel4 = 12.0;
  static const double elevationLevel5 = 16.0;
  static const double elevationFloating = 24.0;

  // ==================== 3D SHADOWS ====================
  static List<BoxShadow> get cardShadowLight => [
    BoxShadow(
      color: shadowLight,
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowMedium,
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: shadowMedium,
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowHeavy,
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadowHeavy => [
    BoxShadow(
      color: shadowHeavy,
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColoredTeal,
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get floatingShadowLight => [
    BoxShadow(
      color: shadowLight,
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: shadowMedium,
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: shadowColoredTeal,
      offset: Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> get floatingShadowDark => [
    BoxShadow(
      color: shadowDark,
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: shadowDark,
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: shadowDarkColored,
      offset: Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  // Glassmorphism shadows
  static List<BoxShadow> get glassShadowLight => [
    BoxShadow(
      color: shadowLight,
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColoredTeal,
      offset: Offset(0, 8),
      blurRadius: 30,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get glassShadowDark => [
    BoxShadow(
      color: shadowDark,
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowDarkColored,
      offset: Offset(0, 8),
      blurRadius: 30,
      spreadRadius: -4,
    ),
  ];

  // ==================== GLASSMORPHISM EFFECTS ====================
  static BoxDecoration glassmorphismLight({
    double borderRadius = 20,
    double opacity = 0.8,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: glassLightGradient,
      border: withBorder
          ? Border.all(
              color: medicalWhite.withValues(alpha: 0.3),
              width: 1.5,
            )
          : null,
      boxShadow: glassShadowLight,
      backgroundBlendMode: BlendMode.srcOver,
    );
  }

  static BoxDecoration glassmorphismDark({
    double borderRadius = 20,
    double opacity = 0.8,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: glassDarkGradient,
      border: withBorder
          ? Border.all(
              color: medicalDarkElevated.withValues(alpha: 0.3),
              width: 1.5,
            )
          : null,
      boxShadow: glassShadowDark,
      backgroundBlendMode: BlendMode.srcOver,
    );
  }

  // ==================== 3D CARD DECORATIONS ====================
  static BoxDecoration card3DLight({
    double borderRadius = 20,
    double elevation = 1,
    Color? color,
    LinearGradient? gradient,
  }) {
    final shadows = switch (elevation.toInt()) {
      0 => <BoxShadow>[],
      1 => cardShadowLight,
      2 => cardShadowMedium,
      _ => cardShadowHeavy,
    };

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color ?? medicalWhite,
      gradient: gradient,
      boxShadow: shadows,
    );
  }

  static BoxDecoration card3DDark({
    double borderRadius = 20,
    double elevation = 1,
    Color? color,
    LinearGradient? gradient,
  }) {
    final shadows = switch (elevation.toInt()) {
      0 => <BoxShadow>[],
      1 => cardShadowLight,
      2 => cardShadowMedium,
      _ => cardShadowHeavy,
    };

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color ?? medicalDarkCard,
      gradient: gradient,
      boxShadow: shadows,
    );
  }

  // ==================== ANIMATED GRADIENTS ====================
  static BoxDecoration animatedGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double borderRadius = 20,
    Duration duration = const Duration(seconds: 3),
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ),
    );
  }

  // ==================== SHIMMER DECORATION ====================
  static BoxDecoration shimmerLight({
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: shimmerLightGradient,
    );
  }

  static BoxDecoration shimmerDark({
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: shimmerDarkGradient,
    );
  }

  // ==================== BREATHING ANIMATION DECORATION ====================
  static BoxDecoration breathingLight({
    double borderRadius = 20,
    required Animation<double> animation,
  }) {
    final color = Color.lerp(
      breathingColors[0],
      breathingColors[1],
      animation.value,
    )!;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color,
      boxShadow: [
        BoxShadow(
          color: shadowColoredTeal.withValues(alpha: animation.value * 0.3),
          offset: Offset(0, 4 * animation.value),
          blurRadius: 12 * animation.value,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration breathingDark({
    double borderRadius = 20,
    required Animation<double> animation,
  }) {
    final color = Color.lerp(
      breathingDarkColors[0],
      breathingDarkColors[1],
      animation.value,
    )!;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color,
      boxShadow: [
        BoxShadow(
          color: shadowDarkColored.withValues(alpha: animation.value * 0.4),
          offset: Offset(0, 4 * animation.value),
          blurRadius: 12 * animation.value,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // ==================== PULSE ANIMATION DECORATION ====================
  static BoxDecoration pulseLight({
    double borderRadius = 20,
    required Animation<double> animation,
    Color baseColor = medicalTealPrimary,
  }) {
    final color = Color.lerp(
      baseColor,
      baseColor.lighten(0.2),
      animation.value,
    )!;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color,
      boxShadow: [
        BoxShadow(
          color: shadowColoredTeal.withValues(alpha: 0.5 * animation.value),
          offset: Offset(0, 4 * animation.value),
          blurRadius: 20 * animation.value,
          spreadRadius: 2 * animation.value,
        ),
      ],
    );
  }

  static BoxDecoration pulseDark({
    double borderRadius = 20,
    required Animation<double> animation,
    Color baseColor = medicalTealDarkPrimary,
  }) {
    final color = Color.lerp(
      baseColor,
      baseColor.lighten(0.2),
      animation.value,
    )!;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color,
      boxShadow: [
        BoxShadow(
          color: shadowDarkColored.withValues(alpha: 0.5 * animation.value),
          offset: Offset(0, 4 * animation.value),
          blurRadius: 20 * animation.value,
          spreadRadius: 2 * animation.value,
        ),
      ],
    );
  }
}