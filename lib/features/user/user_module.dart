import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/user/presentation/screens/add_dependent_screen.dart';
import 'package:medilink/features/user/presentation/screens/forget_password_screen.dart';
import 'package:medilink/features/user/presentation/screens/login_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record_screen.dart';
import 'package:medilink/features/user/presentation/screens/profile_screen.dart';
import 'package:medilink/features/user/presentation/screens/registration_screen.dart';

/// Module USER — Membre 1.
/// Inscription, connexion, profils patient/médecin, dossier médical.
abstract final class UserRoutes {
  static const login = AppRoutes.login;
  static const register = AppRoutes.register;
  static const forgotPassword = AppRoutes.forgotPassword;
  static const profile = '/profile';
  static const medicalRecord = '/medical-record';
  static const addDependent = '/add-dependent';
}

class UserModule extends FeatureModule {
  const UserModule();

  @override
  String get name => 'User';

  @override
  void registerDependencies(GetIt getIt) {
    // TODO(user): enregistrer AuthRepository, ProfileRepository, MedicalRecordRepository...
  }

  @override
  List<RouteBase> get routes => [
        GoRoute(path: UserRoutes.login, builder: (_, _) => const MLLoginScreen()),
        GoRoute(path: UserRoutes.register, builder: (_, _) => const MLRegistrationScreen()),
        GoRoute(path: UserRoutes.forgotPassword, builder: (_, _) => const MLForgetPasswordScreen()),
        GoRoute(path: UserRoutes.profile, builder: (_, _) => const MLUpdateProfileScreen()),
        GoRoute(path: UserRoutes.medicalRecord, builder: (_, _) => const MLMedicalRecordScreen()),
        GoRoute(path: UserRoutes.addDependent, builder: (_, _) => const MLAddDependentScreen()),
      ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
        ModuleShortcut(
          label: 'Dossier médical',
          icon: Icons.folder_shared_rounded,
          route: UserRoutes.medicalRecord,
          color: AppColors.moduleUser,
          order: 20,
        ),
      ];
}
