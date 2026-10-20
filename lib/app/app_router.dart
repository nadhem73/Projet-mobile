import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/navigation/route_logger.dart';
import 'package:medilink/core/session/session_service.dart';

/// Construit le routeur à partir des routes déclarées par chaque module.
///
/// Garde d'accès (cahier des charges §13.1 « accès contrôlés selon le rôle ») :
/// - non connecté → seules les routes publiques sont accessibles ;
/// - connecté → login / inscription redirigent vers le panel du rôle ;
/// - `/doctor/...`, `/pharmacist/...`, `/insurer/...` sont réservés au rôle concerné ;
/// - le panel patient est réservé aux patients.
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

      final home = AppRoutes.homeFor(user.role);
      if (isPublic) return home;
      for (final MapEntry(key: role, value: prefix) in AppRoutes.areaPrefixes.entries) {
        if (location.startsWith(prefix) && user.role != role) return home;
      }
      if (AppRoutes.patientOnly.contains(location) && !user.isPatient) return home;
      return null;
    },
  );
}
