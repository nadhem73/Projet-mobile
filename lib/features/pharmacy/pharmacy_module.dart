import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_finder_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/stock_repository.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/medicine_catalog_controller.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/pharmacy_dashboard_controller.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/pharmacy_finder_controller.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/pharmacy_profile_controller.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/stock_management_controller.dart';
import 'package:medilink/features/pharmacy/presentation/screens/medicine_catalog_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/online_pharmacy_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_dashboard_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_detail_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_finder_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_profile_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/stock_management_screen.dart';

/// Module PHARMACIE — Membre 4.
/// Gestion des officines, recherche de médicaments avec stock en temps réel,
/// prix personnalisés par pharmacie et inventaire.
abstract final class PharmacyRoutes {
  /// Panel du pharmacien (espace réservé au rôle PHARMACIST).
  static const dashboard = AppRoutes.pharmacistHome;

  static const home = '/pharmacy';
  static const finder = '/pharmacy/finder';
  static const catalog = '/pharmacy/catalog';
  static const detail = '/pharmacy/detail';
  static const profile = '/pharmacy/profile';
  static const stockManagement = '/pharmacy/stock-management';
}

class PharmacyModule extends FeatureModule {
  const PharmacyModule();

  @override
  String get name => 'Pharmacie';

  @override
  void registerDependencies(GetIt getIt) {
    // Repositories
    getIt.registerLazySingleton<MedicineRepository>(() => MedicineRepository(getIt<AppDatabase>()));
    getIt.registerLazySingleton<PharmacyRepository>(() => PharmacyRepository(getIt<AppDatabase>()));
    getIt.registerLazySingleton<StockRepository>(() => StockRepository(getIt<AppDatabase>()));
    getIt.registerLazySingleton<PharmacyFinderRepository>(() => PharmacyFinderRepository(
      getIt<PharmacyRepository>(),
      getIt<MedicineRepository>(),
      getIt<StockRepository>(),
    ));

    // Controllers
    getIt.registerFactory<MedicineCatalogController>(() => MedicineCatalogController(
      getIt<SessionService>(),
      getIt<PharmacyRepository>(),
      getIt<MedicineRepository>(),
      getIt<StockRepository>(),
    ));
    getIt.registerFactory<PharmacyDashboardController>(() => PharmacyDashboardController(
      getIt<SessionService>(),
      getIt<PharmacyRepository>(),
      getIt<StockRepository>(),
      getIt<MedicineRepository>(),
    ));
    getIt.registerFactory<PharmacyFinderController>(() => PharmacyFinderController(
      getIt<PharmacyFinderRepository>(),
    ));
    getIt.registerFactory<PharmacyProfileController>(() => PharmacyProfileController(
      getIt<SessionService>(),
      getIt<PharmacyRepository>(),
    ));
    getIt.registerFactory<StockManagementController>(() => StockManagementController(
      getIt<SessionService>(),
      getIt<PharmacyRepository>(),
      getIt<MedicineRepository>(),
      getIt<StockRepository>(),
    ));
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: PharmacyRoutes.dashboard,
      builder: (_, _) => const PharmacyDashboardScreen(),
    ),
    GoRoute(
      path: PharmacyRoutes.home,
      builder: (_, _) => const MLOnlinePharmacyScreen(),
    ),
    GoRoute(
      path: PharmacyRoutes.finder,
      builder: (context, state) {
        final initial = state.uri.queryParameters['initial'] ?? (state.extra as String?);
        return PharmacyFinderScreen(initialMedicine: initial);
      },
    ),
    GoRoute(
      path: PharmacyRoutes.catalog,
      builder: (context, state) {
        final filter = state.uri.queryParameters['filter'] ?? (state.extra as String?);
        return MedicineCatalogScreen(initialFilter: filter);
      },
    ),
    GoRoute(
      path: PharmacyRoutes.detail,
      builder: (context, state) {
        final pharmacy = state.extra as Pharmacy;
        return PharmacyDetailScreen(pharmacy: pharmacy);
      },
    ),
    GoRoute(
      path: PharmacyRoutes.profile,
      builder: (_, _) => const PharmacyProfileScreen(),
    ),
    GoRoute(
      path: PharmacyRoutes.stockManagement,
      builder: (context, state) {
        final medicineId = (state.extra as int?) ?? 1;
        return StockManagementScreen(medicineId: medicineId);
      },
    ),
  ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(
      label: 'Pharmacie',
      icon: Icons.local_pharmacy_rounded,
      route: PharmacyRoutes.home,
      color: AppColors.modulePharmacy,
      order: 50,
    ),
  ];
}
