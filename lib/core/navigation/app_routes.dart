import 'package:medilink/core/session/user_role.dart';

/// Routes globales utilisées par le routeur (redirections, garde d'accès).
///
/// Les routes propres à chaque module sont déclarées dans
/// `features/<module>/<module>_module.dart`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  /// Profil de l'utilisateur connecté (tous les rôles).
  static const profile = '/profile';

  // ---- Panels (accueil de chaque rôle) ----
  static const patientHome = '/dashboard';
  static const doctorHome = '/doctor/dashboard';
  static const pharmacistHome = '/pharmacist/dashboard';
  static const insurerHome = '/insurer/dashboard';

  static String homeFor(UserRole role) => switch (role) {
    UserRole.patient => patientHome,
    UserRole.doctor => doctorHome,
    UserRole.pharmacist => pharmacistHome,
    UserRole.insurer => insurerHome,
  };

  /// Espaces réservés : toute route commençant par ce préfixe n'est
  /// accessible qu'au rôle correspondant.
  static const Map<UserRole, String> areaPrefixes = {
    UserRole.doctor: '/doctor/',
    UserRole.pharmacist: '/pharmacist/',
    UserRole.insurer: '/insurer/',
  };

  /// Routes réservées aux patients (hors préfixe).
  static const Set<String> patientOnly = {patientHome};

  /// Routes accessibles sans être connecté.
  static const Set<String> public = {splash, onboarding, login, register, forgotPassword};
}
