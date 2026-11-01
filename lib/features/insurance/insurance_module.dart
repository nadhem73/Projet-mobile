import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_home_screen.dart';
import 'package:medilink/features/insurance/presentation/screens/insurer_dashboard_screen.dart';

/// Module ASSURANCE — Membre 3.
/// Contrats d'assurance / mutuelle (CNAM...), remboursements, prise en charge.
abstract final class InsuranceRoutes {
  /// Panel de l'assureur (espace réservé au rôle INSURER).
  static const dashboard = AppRoutes.insurerHome;

  static const home = '/insurance';
}

class InsuranceModule extends FeatureModule {
  const InsuranceModule();

  @override
  String get name => 'Assurance';

  @override
  void registerDependencies(GetIt getIt) {
    // TODO(insurance): enregistrer InsuranceRepository...
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(path: InsuranceRoutes.dashboard, builder: (_, _) => const InsurerDashboardScreen()),
    GoRoute(path: InsuranceRoutes.home, builder: (_, _) => const InsuranceHomeScreen()),
  ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(
      label: 'Assurance',
      icon: Icons.health_and_safety_rounded,
      route: InsuranceRoutes.home,
      color: AppColors.moduleInsurance,
      order: 40,
    ),
  ];
}
