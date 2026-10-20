import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/features/shell/presentation/screens/chat_screen.dart';
import 'package:medilink/features/shell/presentation/screens/onboarding_screen.dart';
import 'package:medilink/features/shell/presentation/screens/patient_panel_screen.dart';
import 'package:medilink/features/shell/presentation/screens/splash_screen.dart';

/// Socle commun : démarrage, présentation, panel patient, messagerie.
/// Responsable : Membre 1 (module User), car c'est la base de l'application.
abstract final class ShellRoutes {
  static const chat = '/chat';
}

class ShellModule extends FeatureModule {
  const ShellModule();

  @override
  String get name => 'Shell';

  @override
  List<RouteBase> get routes => [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: AppRoutes.patientHome, builder: (_, _) => const PatientPanelScreen()),
        GoRoute(path: ShellRoutes.chat, builder: (_, _) => const MLChatScreen()),
      ];
}
