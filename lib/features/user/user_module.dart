import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';
import 'package:medilink/features/user/presentation/controllers/auth_controller.dart';
import 'package:medilink/features/user/presentation/controllers/medical_record_controller.dart';
import 'package:medilink/features/user/presentation/controllers/profile_controller.dart';
import 'package:medilink/features/user/presentation/screens/add_dependent_screen.dart';
import 'package:medilink/features/user/presentation/screens/auth/forgot_password_screen.dart';
import 'package:medilink/features/user/presentation/screens/auth/login_screen.dart';
import 'package:medilink/features/user/presentation/screens/auth/register_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record/edit_medical_record_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record/medical_record_screen.dart';
import 'package:medilink/features/user/presentation/screens/profile/edit_profile_screen.dart';
import 'package:medilink/features/user/presentation/screens/profile/profile_screen.dart';

/// Module USER — Membre 1.
/// Authentification multi-rôles (patient, médecin, pharmacien, assureur),
/// profils et dossier médical.
abstract final class UserRoutes {
  static const login = AppRoutes.login;
  static const register = AppRoutes.register;
  static const forgotPassword = AppRoutes.forgotPassword;
  static const profile = AppRoutes.profile;
  static const editProfile = '/profile/edit';
  static const medicalRecord = '/medical-record';
  static const editMedicalRecord = '/medical-record/edit';
  static const addDependent = '/add-dependent';
}

class UserModule extends FeatureModule {
  const UserModule();

  @override
  String get name => 'User';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<AuthRepository>(() => AuthRepository(getIt(), getIt()))
      ..registerLazySingleton<ProfileRepository>(() => ProfileRepository(getIt(), getIt()))
      ..registerLazySingleton<MedicalRecordRepository>(() => MedicalRecordRepository(getIt()))
      ..registerFactory<AuthController>(() => AuthController(getIt(), getIt()))
      ..registerFactory<ProfileController>(() => ProfileController(getIt(), getIt(), getIt()))
      ..registerFactoryParam<MedicalRecordController, int, void>(
        (patientId, _) => MedicalRecordController(getIt(), patientId),
      );
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(path: UserRoutes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: UserRoutes.register, builder: (_, _) => const RegisterScreen()),
    GoRoute(path: UserRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
    GoRoute(path: UserRoutes.profile, builder: (_, _) => const ProfileScreen()),
    GoRoute(path: UserRoutes.editProfile, builder: (_, _) => const EditProfileScreen()),
    GoRoute(path: UserRoutes.medicalRecord, builder: (_, _) => const MedicalRecordScreen()),
    GoRoute(path: UserRoutes.editMedicalRecord, builder: (_, _) => const EditMedicalRecordScreen()),
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
