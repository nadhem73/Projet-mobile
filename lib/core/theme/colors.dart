import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';

export 'package:medilink/core/theme/app_colors.dart';

// =============================================================================
// ALIAS HÉRITÉS DU TEMPLATE
// -----------------------------------------------------------------------------
// Les écrans repris du template utilisent encore ces noms. Ils pointent tous
// vers la palette MediLink (AppColors) : changer AppColors suffit à re-thémer
// toute l'application.
//
// ⚠️ Nouveau code : utiliser AppColors.xxx, PAS ces alias. Ils disparaîtront au
// fur et à mesure que chaque module réécrit ses écrans.
// =============================================================================

// ---- Marque ----
const Color mlPrimaryColor = AppColors.primary;
const Color mlColorBlue = AppColors.primary;
const Color mlColorDarkBlue = AppColors.primaryDark;
const Color mlColorCyan = AppColors.primaryLight;
const Color mlColorRed = AppColors.error;
const Color mlColorLightGrey = AppColors.border;
const Color mlColorLightGrey100 = AppColors.surfaceMuted;
const Color mlColorGreyShade = AppColors.surfaceMuted;

const Color medicalTealPrimary = AppColors.primary;
const Color medicalTealLight = AppColors.primaryLight;
const Color medicalTealDark = AppColors.primaryDark;
const Color medicalTealUltraLight = AppColors.primarySurface;
const Color medicalBluePrimary = AppColors.primary;
const Color medicalBlueDark = AppColors.primaryDeep;
const Color medicalBlueUltraLight = AppColors.primarySurface;
const Color duckBlueMedium = AppColors.primary;
const Color duckBlueSurface = AppColors.primarySurface;
const Color cyanAccent = AppColors.primaryLight;
const Color cyanAccentDark = AppColors.primaryLight;
const Color cyanSurface = AppColors.primarySurface;

const Color vitalityGreenPrimary = AppColors.success;
const Color careCoralPrimary = AppColors.accent;
const Color careCoralLight = Color(0xFFFB923C);

// ---- Mode sombre ----
const Color medicalTealDarkPrimary = AppColors.darkPrimary;
const Color medicalTealDarkLight = AppColors.primarySoft;
const Color vitalityGreenDarkPrimary = Color(0xFF4ADE80);
const Color careCoralDarkPrimary = Color(0xFFFB923C);

// ---- Neutres ----
const Color medicalWhite = AppColors.surface;
const Color medicalAppBackground = AppColors.background;
const Color medicalMediumGray = AppColors.border;
const Color medicalDarkGray = AppColors.textMuted;
const Color medicalCharcoal = AppColors.textSecondary;
const Color medicalBlack = AppColors.textPrimary;
const Color medicalDarkSurface = AppColors.darkBackground;
const Color medicalDarkCard = AppColors.darkSurface;
const Color medicalDarkElevated = AppColors.darkSurfaceElevated;
const Color medicalDarkBorder = AppColors.darkBorder;

// ---- Sémantique ----
const Color healthSuccess = AppColors.success;
const Color healthSuccessLight = AppColors.successSurface;
const Color healthSuccessDark = Color(0xFF15803D);
const Color healthWarning = AppColors.warning;
const Color healthWarningLight = AppColors.warningSurface;
const Color healthWarningDark = Color(0xFFB45309);
const Color healthError = AppColors.error;
const Color healthErrorLight = AppColors.errorSurface;

// ---- Dégradés ----
const LinearGradient medicalPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryLight],
);
const LinearGradient medicalPrimaryDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primaryDark, AppColors.darkPrimary],
);
const LinearGradient glassLightGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.surface, AppColors.background],
);
const LinearGradient glassDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.darkSurface, AppColors.darkBackground],
);
const LinearGradient shimmerLightGradient = LinearGradient(
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  colors: [AppColors.border, AppColors.surfaceMuted, AppColors.border],
  stops: [0.0, 0.5, 1.0],
);
const LinearGradient shimmerDarkGradient = LinearGradient(
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  colors: [AppColors.darkSurfaceElevated, AppColors.darkBorder, AppColors.darkSurfaceElevated],
  stops: [0.0, 0.5, 1.0],
);

// ---- Ombres ----
const Color shadowLight = Color(0x140F1F1C);
const Color shadowMedium = Color(0x220F1F1C);
const Color shadowHeavy = Color(0x330F1F1C);
const Color shadowColoredTeal = Color(0x330F766E);
const Color shadowDark = Color(0x4D000000);
const Color shadowDarkColored = Color(0x4D0F766E);

// ---- Animations ----
const List<Color> breathingColors = [AppColors.primarySurface, AppColors.surface, AppColors.primarySurface];
const List<Color> breathingDarkColors = [
  AppColors.darkBackground,
  AppColors.darkSurfaceElevated,
  AppColors.darkBackground,
];

// ---- Globals nb_utils (utilisés par AppStore) ----
const Color appColorPrimary = AppColors.primary;
const Color appColorPrimaryLight = AppColors.primarySurface;
const Color iconColorPrimary = Color(0xFFFFFFFF);
const Color iconColorSecondary = Color(0xFF9FB7B1);
const Color iconColorPrimaryDark = Color(0xFFFFFFFF);
const Color iconColorSecondaryDark = Color(0xFF9FB7B1);
const Color appSecondaryBackgroundColor = AppColors.darkBackground;
const Color appTextColorPrimary = AppColors.textPrimary;
const Color appTextColorSecondary = AppColors.textSecondary;
const Color appShadowColor = Color(0x1F0F766E);
const Color appBackgroundColorDark = AppColors.darkBackground;
const Color cardBackgroundBlackDark = AppColors.darkSurface;
const Color appShadowColorDark = Color(0x1A2DD4BF);

extension MedicalColorExtensions on Color {
  /// Version plus claire de la couleur.
  Color lighten([double amount = 0.1]) => Color.lerp(this, Colors.white, amount)!;

  /// Version plus sombre de la couleur.
  Color darken([double amount = 0.1]) => Color.lerp(this, Colors.black, amount)!;

  Color withOpacityValue(double opacity) => withValues(alpha: opacity);
}
