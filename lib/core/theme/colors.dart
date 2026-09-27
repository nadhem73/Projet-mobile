import 'package:flutter/material.dart';

/// Medilink Design System - Palette « Bleu Canard + Cyan Médical »
///
/// Bleu canard (duck blue) : confiance, professionnalisme, sérieux médical.
/// Cyan                   : technologie, vitalité, accents & gradients.
/// Vert émeraude          : santé, validation, croissance.
/// Corail                 : chaleur, attention bienveillante.
/// Neutres froids (slate) : propreté clinique, lisibilité maximale.

// ==================== PALETTE PRINCIPALE ====================

// Bleu canard - base de la marque
const Color duckBlueDeep = Color(0xFF0A2E5C);
const Color duckBluePrimary = Color(0xFF0D47A1);
const Color duckBlueMedium = Color(0xFF1565C0);
const Color duckBlueLight = Color(0xFF1E88E5);
const Color duckBlueSurface = Color(0xFFE8F1FB);

// Cyan - accents & gradients signature
const Color cyanAccent = Color(0xFF22D3EE);
const Color cyanAccentDark = Color(0xFF06B6D4);
const Color cyanAccentLight = Color(0xFFA5F3FC);
const Color cyanSurface = Color(0xFFE6FBFF);

// Couleurs d'accent secondaires de la marque (tokens legacy « teal »)
const Color medicalTealPrimary = duckBluePrimary;
const Color medicalTealLight = duckBlueLight;
const Color medicalTealDark = duckBlueDeep;
const Color medicalTealUltraLight = duckBlueSurface;

// Vitality Green - santé & vitalité
const Color vitalityGreenPrimary = Color(0xFF10B981);
const Color vitalityGreenLight = Color(0xFF34D399);
const Color vitalityGreenDark = Color(0xFF059669);
const Color vitalityGreenUltraLight = Color(0xFFD1FAE5);

// Care Coral - chaleur & attention
const Color careCoralPrimary = Color(0xFFFF6B57);
const Color careCoralLight = Color(0xFFFF8A73);
const Color careCoralDark = Color(0xFFE5482F);
const Color careCoralUltraLight = Color(0xFFFFEDE9);

// Medical Blue - précision clinique (gradient bleu -> cyan)
const Color medicalBluePrimary = duckBluePrimary;
const Color medicalBlueLight = cyanAccent;
const Color medicalBlueDark = duckBlueDeep;
const Color medicalBlueUltraLight = duckBlueSurface;

// ==================== DARK THEME COLORS ====================

const Color medicalTealDarkPrimary = Color(0xFF64B5F6);
const Color medicalTealDarkLight = Color(0xFF90CAF9);
const Color medicalTealDarkDark = Color(0xFF42A5F5);

const Color vitalityGreenDarkPrimary = Color(0xFF34D399);
const Color vitalityGreenDarkLight = Color(0xFF6EE7B7);
const Color vitalityGreenDarkDark = Color(0xFF10B981);

const Color careCoralDarkPrimary = Color(0xFFFF8A73);
const Color careCoralDarkLight = Color(0xFFFFAB91);
const Color careCoralDarkDark = Color(0xFFFF6B57);

const Color medicalBlueDarkPrimary = Color(0xFF64B5F6);
const Color medicalBlueDarkLight = Color(0xFF90CAF9);
const Color medicalBlueDarkDark = Color(0xFF1E88E5);

// ==================== NEUTRAL COLORS ====================

// Light neutrals (slate froid)
const Color medicalWhite = Color(0xFFFFFFFF);
const Color medicalOffWhite = Color(0xFFF4F7FB);
const Color medicalAppBackground = Color(0xFFF4F7FB);
const Color medicalLightGray = Color(0xFFF1F5F9);
const Color medicalMediumGray = Color(0xFFE2E8F0);
const Color medicalDarkGray = Color(0xFF64748B);
const Color medicalCharcoal = Color(0xFF334155);
const Color medicalBlack = Color(0xFF0B1B2B);

// Dark neutrals (bleu nuit)
const Color medicalDarkSurface = Color(0xFF0B1220);
const Color medicalDarkCard = Color(0xFF131C2E);
const Color medicalDarkElevated = Color(0xFF1B2639);
const Color medicalDarkBorder = Color(0xFF27344A);

// ==================== SEMANTIC COLORS ====================

// Success/Santé
const Color healthSuccess = Color(0xFF10B981);
const Color healthSuccessLight = Color(0xFFD1FAE5);
const Color healthSuccessDark = Color(0xFF047857);

// Warning/Vigilance
const Color healthWarning = Color(0xFFF59E0B);
const Color healthWarningLight = Color(0xFFFEF3C7);
const Color healthWarningDark = Color(0xFFB45309);

// Error/Critique
const Color healthError = Color(0xFFEF4444);
const Color healthErrorLight = Color(0xFFFEE2E2);
const Color healthErrorDark = Color(0xFFB91C1C);

// Info
const Color healthInfo = duckBluePrimary;
const Color healthInfoLight = duckBlueSurface;
const Color healthInfoDark = duckBlueDeep;

// ==================== 3D/GRADIENT COLORS ====================

// Gradient principal de la marque : bleu canard -> cyan
const LinearGradient medicalBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [duckBluePrimary, cyanAccentDark],
);

// Gradient héros : bleu profond -> bleu canard (headers, écrans d'accueil)
const LinearGradient medicalHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [duckBlueDeep, duckBluePrimary],
);

const LinearGradient medicalPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [medicalTealPrimary, medicalTealLight],
);

const LinearGradient medicalVitalityGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [vitalityGreenPrimary, vitalityGreenLight],
);

const LinearGradient medicalCareGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [careCoralPrimary, careCoralLight],
);

const LinearGradient medicalBlueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [medicalBluePrimary, medicalBlueLight],
);

// Dark gradients
const LinearGradient medicalPrimaryDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [medicalTealDarkPrimary, medicalTealDarkLight],
);

const LinearGradient medicalVitalityDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [vitalityGreenDarkPrimary, vitalityGreenDarkLight],
);

const LinearGradient medicalCareDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [careCoralDarkPrimary, careCoralDarkLight],
);

// Glassmorphism gradients
const LinearGradient glassLightGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FB)],
);

const LinearGradient glassDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF131C2E), Color(0xFF0B1220)],
);

// Shimmer gradients for loading
const LinearGradient shimmerLightGradient = LinearGradient(
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  colors: [
    Color(0xFFE2E8F0),
    Color(0xFFF1F5F9),
    Color(0xFFE2E8F0),
  ],
  stops: [0.0, 0.5, 1.0],
);

const LinearGradient shimmerDarkGradient = LinearGradient(
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  colors: [
    Color(0xFF1B2639),
    Color(0xFF27344A),
    Color(0xFF1B2639),
  ],
  stops: [0.0, 0.5, 1.0],
);

// ==================== SHADOW COLORS ====================

const Color shadowLight = Color(0x140B1B2B);
const Color shadowMedium = Color(0x290B1B2B);
const Color shadowHeavy = Color(0x330B1B2B);
const Color shadowColoredTeal = Color(0x330D47A1);
const Color shadowColoredGreen = Color(0x3310B981);
const Color shadowColoredCoral = Color(0x33FF6B57);

const Color shadowDark = Color(0x4D000000);
const Color shadowDarkColored = Color(0x4D0D47A1);

// ==================== ANIMATION COLORS ====================

// Pulse animation colors
const List<Color> pulseColors = [
  medicalTealPrimary,
  medicalTealLight,
  medicalTealPrimary,
];

const List<Color> pulseDarkColors = [
  medicalTealDarkPrimary,
  medicalTealDarkLight,
  medicalTealDarkPrimary,
];

// Breathing animation colors
const List<Color> breathingColors = [
  medicalTealUltraLight,
  medicalWhite,
  medicalTealUltraLight,
];

const List<Color> breathingDarkColors = [
  medicalDarkSurface,
  medicalDarkElevated,
  medicalDarkSurface,
];

// ==================== LEGACY PALETTE (renamed to medical palette) ====================
// Kept for compatibility with existing screens; values follow the duck blue brand.

const Color mlPrimaryColor = medicalTealPrimary;
const Color mlColorBlue = medicalTealPrimary;
const Color mlColorDarkBlue = medicalTealDark;
const Color mlColorRed = healthError;
const Color mlColorCyan = cyanAccentDark;
const Color mlColorLightGrey = medicalMediumGray;
const Color mlColorLightGrey100 = medicalLightGray;
const Color mlColorGreyShade = medicalLightGray;

// ==================== APP GLOBALS (nb_utils theme colors) ====================

const Color appColorPrimary = medicalTealPrimary;
const Color iconColorPrimary = Color(0xFFFFFFFF);
const Color iconColorSecondary = Color(0xFF94A3B8);
const Color appSecondaryBackgroundColor = Color(0xFF0B1220);
const Color appTextColorPrimary = Color(0xFF0B1B2B);
const Color appTextColorSecondary = Color(0xFF475569);
const Color appShadowColor = Color(0x95D7E3F2);
const Color appColorPrimaryLight = medicalTealUltraLight;

// Dark Theme Colors
const Color appBackgroundColorDark = Color(0xFF0B1220);
const Color cardBackgroundBlackDark = Color(0xFF131C2E);
const Color colorPrimaryBlack = Color(0xFF0B1220);
const Color iconColorPrimaryDark = Color(0xFFFFFFFF);
const Color iconColorSecondaryDark = Color(0xFF94A3B8);
const Color appShadowColorDark = Color(0x1A0D47A1);

// ==================== HELPER EXTENSIONS ====================

extension MedicalColorExtensions on Color {
  /// Create a lighter version of this color
  Color lighten([double amount = 0.1]) {
    final red255 = (r * 255).round();
    final green255 = (g * 255).round();
    final blue255 = (b * 255).round();
    return Color.fromARGB(
      (a * 255).round(),
      (red255 + (255 - red255) * amount).round(),
      (green255 + (255 - green255) * amount).round(),
      (blue255 + (255 - blue255) * amount).round(),
    );
  }

  /// Create a darker version of this color
  Color darken([double amount = 0.1]) {
    final red255 = (r * 255).round();
    final green255 = (g * 255).round();
    final blue255 = (b * 255).round();
    return Color.fromARGB(
      (a * 255).round(),
      (red255 * (1 - amount)).round(),
      (green255 * (1 - amount)).round(),
      (blue255 * (1 - amount)).round(),
    );
  }

  /// Get color with opacity
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }
}
