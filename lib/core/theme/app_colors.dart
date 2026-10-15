import 'package:flutter/material.dart';

/// Palette officielle MediLink Tunisia — « Vert santé + Menthe ».
///
/// Toujours utiliser ces tokens (ou `Theme.of(context).colorScheme`) dans le
/// nouveau code. Ne jamais écrire de `Color(0xFF...)` en dur dans un écran.
abstract final class AppColors {
  // ---------- Marque ----------
  static const Color primary = Color(0xFF0F766E); // vert émeraude profond
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryDeep = Color(0xFF0B3D3A);
  static const Color primaryLight = Color(0xFF14B8A6); // menthe
  static const Color primarySoft = Color(0xFF5EEAD4);
  static const Color primarySurface = Color(0xFFE6F4F1);

  static const Color accent = Color(0xFFF97316); // orange chaud (CTA secondaires, badges)
  static const Color accentDark = Color(0xFFEA580C);
  static const Color accentSurface = Color(0xFFFFF1E7);

  // ---------- Neutres (mode clair) ----------
  static const Color background = Color(0xFFF6FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF4F2);
  static const Color border = Color(0xFFDCE7E4);
  static const Color textPrimary = Color(0xFF0F1F1C);
  static const Color textSecondary = Color(0xFF4B5F5A);
  static const Color textMuted = Color(0xFF8A9A96);

  // ---------- Neutres (mode sombre) ----------
  static const Color darkBackground = Color(0xFF0B1514);
  static const Color darkSurface = Color(0xFF12201E);
  static const Color darkSurfaceElevated = Color(0xFF1A2B28);
  static const Color darkBorder = Color(0xFF24403B);
  static const Color darkPrimary = Color(0xFF2DD4BF);
  static const Color darkTextPrimary = Color(0xFFE6F2EF);
  static const Color darkTextSecondary = Color(0xFF9FB7B1);

  // ---------- Sémantique ----------
  static const Color success = Color(0xFF16A34A);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSurface = Color(0xFFE0F2FE);

  // ---------- Couleur par module (icônes, badges, en-têtes) ----------
  static const Color moduleUser = primary;
  static const Color moduleAppointment = Color(0xFF0EA5E9);
  static const Color moduleInsurance = Color(0xFF7C3AED);
  static const Color modulePharmacy = Color(0xFF16A34A);
  static const Color moduleDoctor = Color(0xFF0F766E);
  static const Color moduleAi = accent;

  // ---------- Dégradés ----------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary, primaryLight],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primarySurface, background],
  );
}
