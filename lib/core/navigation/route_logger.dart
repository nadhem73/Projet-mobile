import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Affiche dans la console la route ouverte (aide au debug en équipe).
class RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _log('→', route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _log('←', previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _log('⇄', newRoute);
  }

  void _log(String arrow, Route<dynamic> route) {
    if (!kDebugMode) return;
    final name = route.settings.name ?? route.runtimeType.toString();
    debugPrint('[nav] $arrow $name');
  }
}
