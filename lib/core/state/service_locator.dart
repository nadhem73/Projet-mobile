import 'package:get_it/get_it.dart';
import 'package:medilab_prokit/core/state/app_store.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Global state
  getIt.registerLazySingleton<AppStore>(() => AppStore());
  
  // TODO: Register feature-specific dependencies
  // getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  // getIt.registerLazySingleton<PatientRepository>(() => PatientRepositoryImpl());
}