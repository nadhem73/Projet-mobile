import 'package:get_it/get_it.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/modules/module_registry.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Conteneur d'injection de dépendances global.
final GetIt getIt = GetIt.instance;

/// Enregistre les services partagés puis les dépendances de chaque module.
///
/// [database] permet aux tests d'injecter une base en mémoire.
Future<void> configureDependencies(List<FeatureModule> modules, {AppDatabase? database}) async {
  // ---- Services partagés (core) ----
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<SessionService>(SessionService(prefs)..restore());
  getIt.registerSingleton<AppDatabase>(database ?? await AppDatabase.open());
  getIt.registerLazySingleton<PasswordHasher>(() => const PasswordHasher());
  getIt.registerLazySingleton<AppStore>(() => AppStore());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService(getIt()));
  getIt.registerSingleton<ModuleRegistry>(ModuleRegistry(modules));

  // ---- Modules ----
  for (final module in modules) {
    module.registerDependencies(getIt);
  }
}
