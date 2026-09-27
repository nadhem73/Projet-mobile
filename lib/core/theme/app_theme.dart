import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medilab_prokit/core/widgets/medical_3d_components.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/theme/medical_theme.dart';

class AppThemeData {
  //
  AppThemeData._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: medicalAppBackground,
    primaryColor: medicalTealPrimary,
    hoverColor: medicalTealUltraLight,
    dividerColor: medicalMediumGray,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: medicalWhite,
      elevation: 0,
      scrolledUnderElevation: MedicalThemeData.elevationLevel1,
      iconTheme: const IconThemeData(color: medicalBlack),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: medicalBlack,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: medicalTealPrimary,
      selectionColor: medicalTealLight,
      selectionHandleColor: medicalTealPrimary,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: medicalTealPrimary,
      brightness: Brightness.light,
      primary: medicalTealPrimary,
      secondary: careCoralPrimary,
      tertiary: vitalityGreenPrimary,
      error: healthError,
      surface: medicalWhite,
    ),
    cardTheme: CardThemeData(
      color: medicalWhite,
      elevation: MedicalThemeData.elevationLevel2,
      shadowColor: shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardColor: medicalWhite,
    iconTheme: const IconThemeData(color: medicalBlack),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: medicalWhite,
      elevation: MedicalThemeData.elevationLevel5,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: medicalTealPrimary,
        foregroundColor: medicalWhite,
        elevation: MedicalThemeData.elevationLevel2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: medicalTealPrimary,
        foregroundColor: medicalWhite,
        elevation: MedicalThemeData.elevationLevel2,
        shadowColor: shadowColoredTeal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: medicalTealPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: medicalTealUltraLight,
      selectedColor: medicalTealPrimary,
      labelStyle: GoogleFonts.plusJakartaSans(color: medicalTealDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: medicalMediumGray),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: medicalTealPrimary,
      foregroundColor: medicalWhite,
      elevation: MedicalThemeData.elevationLevel3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: medicalWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.plusJakartaSans(color: medicalDarkGray),
      labelStyle: GoogleFonts.plusJakartaSans(color: medicalDarkGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: medicalMediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: medicalMediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: medicalTealPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: healthError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: healthError, width: 2),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: medicalTealPrimary,
      unselectedLabelColor: medicalDarkGray,
      indicatorColor: medicalTealPrimary,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: medicalCharcoal,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: medicalWhite),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: TextTheme(
      labelLarge: GoogleFonts.plusJakartaSans(
        color: medicalTealPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: medicalBlack,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: medicalBlack,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: medicalBlack,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(color: medicalCharcoal),
      bodyMedium: GoogleFonts.plusJakartaSans(color: medicalCharcoal),
      bodySmall: GoogleFonts.plusJakartaSans(color: medicalDarkGray),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  ).copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: Medical3DPageTransitionBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: Medical3DPageTransitionBuilder(),
        TargetPlatform.macOS: Medical3DPageTransitionBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: medicalDarkSurface,
    highlightColor: medicalDarkSurface,
    hoverColor: medicalTealDarkPrimary.withValues(alpha: 0.2),
    dividerColor: medicalDarkBorder,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: medicalDarkSurface,
      elevation: 0,
      scrolledUnderElevation: MedicalThemeData.elevationLevel1,
      iconTheme: IconThemeData(color: medicalWhite),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: medicalTealDarkPrimary,
      selectionColor: medicalTealDarkLight,
      selectionHandleColor: medicalTealDarkPrimary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: medicalDarkCard,
      elevation: MedicalThemeData.elevationLevel5,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    cardTheme: CardThemeData(
      color: medicalDarkCard,
      elevation: MedicalThemeData.elevationLevel2,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardColor: medicalDarkCard,
    iconTheme: const IconThemeData(color: medicalWhite),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: medicalTealDarkPrimary,
        foregroundColor: medicalWhite,
        elevation: MedicalThemeData.elevationLevel2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: medicalTealDarkPrimary,
        foregroundColor: medicalWhite,
        elevation: MedicalThemeData.elevationLevel2,
        shadowColor: shadowDarkColored,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: medicalTealDarkPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: medicalDarkElevated,
      selectedColor: medicalTealDarkPrimary,
      labelStyle: GoogleFonts.plusJakartaSans(color: medicalWhite),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: medicalDarkBorder),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: medicalTealDarkPrimary,
      foregroundColor: medicalWhite,
      elevation: MedicalThemeData.elevationLevel3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: medicalDarkElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.plusJakartaSans(color: medicalDarkGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: medicalTealDarkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: healthError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: healthError, width: 2),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: medicalTealDarkPrimary,
      unselectedLabelColor: medicalDarkGray,
      indicatorColor: medicalTealDarkPrimary,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: medicalDarkElevated,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: medicalWhite),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: TextTheme(
      labelLarge: GoogleFonts.plusJakartaSans(
        color: medicalTealDarkPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: medicalWhite,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: medicalWhite,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: medicalWhite,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1)),
      bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1)),
      bodySmall: GoogleFonts.plusJakartaSans(color: medicalDarkGray),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      seedColor: medicalTealDarkPrimary,
      brightness: Brightness.dark,
      primary: medicalTealDarkPrimary,
      secondary: careCoralDarkPrimary,
      tertiary: vitalityGreenDarkPrimary,
      error: healthError,
      surface: medicalDarkSurface,
    ),
  ).copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: Medical3DPageTransitionBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: Medical3DPageTransitionBuilder(),
        TargetPlatform.macOS: Medical3DPageTransitionBuilder(),
      },
    ),
  );
}
