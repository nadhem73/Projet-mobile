import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie : Poppins pour les titres, Inter pour le texte courant.
abstract final class AppTypography {
  static String? get headingFamily => GoogleFonts.poppins().fontFamily;
  static String? get bodyFamily => GoogleFonts.inter().fontFamily;

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle heading(double size, FontWeight weight) =>
        GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: primary, height: 1.25);
    TextStyle body(double size, FontWeight weight, Color color) =>
        GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.45);

    return TextTheme(
      displaySmall: heading(32, FontWeight.w700),
      headlineMedium: heading(26, FontWeight.w700),
      headlineSmall: heading(22, FontWeight.w600),
      titleLarge: heading(18, FontWeight.w600),
      titleMedium: body(16, FontWeight.w600, primary),
      titleSmall: body(14, FontWeight.w600, primary),
      bodyLarge: body(16, FontWeight.w400, primary),
      bodyMedium: body(14, FontWeight.w400, primary),
      bodySmall: body(12, FontWeight.w400, secondary),
      labelLarge: body(15, FontWeight.w600, primary),
      labelMedium: body(13, FontWeight.w500, secondary),
      labelSmall: body(11, FontWeight.w500, secondary),
    );
  }
}
