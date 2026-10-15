/// Routes globales utilisées par le routeur (redirections, garde d'accès).
///
/// Les routes propres à chaque module sont déclarées dans
/// `features/<module>/<module>_routes.dart`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  /// Accueil patient (barre de navigation du bas).
  static const patientHome = '/dashboard';

  /// Accueil médecin.
  static const doctorHome = '/doctor/dashboard';

  /// Préfixe de l'espace médecin : réservé au rôle DOCTOR.
  static const doctorAreaPrefix = '/doctor/';

  /// Routes accessibles sans être connecté.
  static const Set<String> public = {splash, onboarding, login, register, forgotPassword};
}
