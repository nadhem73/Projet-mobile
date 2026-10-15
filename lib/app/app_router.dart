import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/navigation/route_logger.dart';
import 'package:medilink/core/session/session_service.dart';

/// Construit le routeur à partir des routes déclarées par chaque module.
///
/// Garde d'accès (cahier des charges §13.1 « accès contrôlés selon le rôle ») :
/// - non connecté → seules les routes publiques sont accessibles ;
/// - connecté → login / inscription redirigent vers l'accueil du rôle ;
/// - l'espace `/doctor/...` est réservé aux médecins.
GoRouter buildAppRouter({required List<FeatureModule> modules, required SessionService session}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    observers: [RouteLogger()],
    routes: [for (final module in modules) ...module.routes],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final user = session.currentUser;
      final isPublic = AppRoutes.public.contains(location);

      if (location == AppRoutes.splash) return null;
      if (user == null) return isPublic ? null : AppRoutes.login;

      final home = user.isDoctor ? AppRoutes.doctorHome : AppRoutes.patientHome;
      if (isPublic) return home;
      if (location.startsWith(AppRoutes.doctorAreaPrefix) && !user.isDoctor) return home;
      return null;
    },
  );
}
