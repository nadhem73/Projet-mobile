import 'package:get_it/get_it.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Conteneur d'injection de dépendances global.
final GetIt getIt = GetIt.instance;

/// Enregistre les services partagés puis les dépendances de chaque module.
Future<void> configureDependencies(List<FeatureModule> modules) async {
  // ---- Services partagés (core) ----
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<SessionService>(SessionService(prefs)..restore());
  getIt.registerSingleton<AppDatabase>(await AppDatabase.open());
  getIt.registerLazySingleton<PasswordHasher>(() => const PasswordHasher());
  getIt.registerLazySingleton<AppStore>(() => AppStore());

  // ---- Modules ----
  for (final module in modules) {
    module.registerDependencies(getIt);
  }
}
