import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/user/data/repositories/admin_repository.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/dependent_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';
import 'package:medilink/features/user/presentation/controllers/admin_controller.dart';
import 'package:medilink/features/user/presentation/controllers/auth_controller.dart';
import 'package:medilink/features/user/presentation/controllers/dependents_controller.dart';
import 'package:medilink/features/user/presentation/controllers/medical_record_controller.dart';
import 'package:medilink/features/user/presentation/controllers/profile_controller.dart';
import 'package:medilink/features/user/presentation/controllers/user_avatar_store.dart';
import 'package:medilink/features/user/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:medilink/features/user/presentation/screens/admin/admin_users_screen.dart';
import 'package:medilink/features/user/presentation/screens/auth/forgot_password_screen.dart';
import 'package:medilink/features/user/presentation/screens/auth/login_screen.dart';
import 'package:medilink/features/user/presentation/screens/auth/register_screen.dart';
import 'package:medilink/features/user/presentation/screens/dependents/dependents_screen.dart';
import 'package:medilink/features/user/presentation/screens/doctor/doctor_patients_records_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record/edit_medical_record_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record/emergency_card_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record/medical_record_screen.dart';
import 'package:medilink/features/user/presentation/screens/profile/edit_profile_screen.dart';
import 'package:medilink/features/user/presentation/screens/profile/profile_screen.dart';

/// Module USER — Membre 1.
/// Comptes et sécurité (5 rôles, validation des professionnels par un
/// administrateur), profils, proches, dossier médical et accès des médecins.
abstract final class UserRoutes {
  // Authentification
  static const login = AppRoutes.login;
  static const register = AppRoutes.register;
  static const forgotPassword = AppRoutes.forgotPassword;

  // Profil (tous les rôles)
  static const profile = AppRoutes.profile;
  static const editProfile = '/profile/edit';

  // Patient
  static const medicalRecord = '/medical-record';
  static const editMedicalRecord = '/medical-record/edit';
  static const emergencyCard = '/medical-record/emergency-card';
  static const dependents = '/dependents';

  // Médecin (préfixe /doctor/ : réservé aux médecins)
  static const doctorRecords = '/doctor/medical-records';
  static String doctorPatientRecord(int patientId) => '/doctor/medical-records/$patientId';

  // Administrateur (préfixe /admin/ : réservé aux administrateurs)
  static const adminDashboard = AppRoutes.adminHome;
  static const adminUsers = '/admin/users';
}

class UserModule extends FeatureModule {
  const UserModule();

  @override
  String get name => 'User';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      // Repositories
      ..registerLazySingleton<AuthRepository>(() => AuthRepository(getIt(), getIt(), getIt()))
      ..registerLazySingleton<ProfileRepository>(() => ProfileRepository(getIt(), getIt()))
      ..registerLazySingleton<MedicalRecordRepository>(() => MedicalRecordRepository(getIt()))
      ..registerLazySingleton<MedicalAccessRepository>(() => MedicalAccessRepository(getIt(), getIt(), getIt()))
      ..registerLazySingleton<DependentRepository>(() => DependentRepository(getIt()))
      ..registerLazySingleton<AdminRepository>(() => AdminRepository(getIt(), getIt()))
      ..registerLazySingleton<UserAvatarStore>(() => UserAvatarStore(getIt()))
      // Controllers (une instance par écran)
      ..registerFactory<AuthController>(() => AuthController(getIt(), getIt()))
      ..registerFactory<ProfileController>(
        () => ProfileController(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()),
      )
      ..registerFactory<AdminController>(() => AdminController(getIt(), getIt()))
      ..registerFactoryParam<MedicalRecordController, int, void>(
        (patientId, _) => MedicalRecordController(getIt(), getIt(), patientId),
      )
      ..registerFactoryParam<DependentsController, int, void>(
        (patientId, _) => DependentsController(getIt(), patientId),
      );

    // Les photos en cache ne survivent pas à la déconnexion.
    final session = getIt<SessionService>();
    session.addListener(() {
      if (!session.isAuthenticated && getIt.isRegistered<UserAvatarStore>()) getIt<UserAvatarStore>().clear();
    });
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
    GoRoute(path: UserRoutes.emergencyCard, builder: (_, _) => const EmergencyCardScreen()),
    GoRoute(path: UserRoutes.dependents, builder: (_, _) => const DependentsScreen()),
    GoRoute(path: UserRoutes.doctorRecords, builder: (_, _) => const DoctorPatientsRecordsScreen()),
    GoRoute(
      path: '/doctor/medical-records/:patientId',
      builder: (_, state) => DoctorPatientRecordScreen(patientId: int.parse(state.pathParameters['patientId']!)),
    ),
    GoRoute(path: UserRoutes.adminDashboard, builder: (_, _) => const AdminDashboardScreen()),
    GoRoute(
      path: UserRoutes.adminUsers,
      builder: (_, state) => AdminUsersScreen(initialRole: state.extra as UserRole?),
    ),
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
    ModuleShortcut(
      label: 'Carte d\'urgence',
      icon: Icons.qr_code_2_rounded,
      route: UserRoutes.emergencyCard,
      color: AppColors.error,
      order: 21,
    ),
    ModuleShortcut(
      label: 'Mes proches',
      icon: Icons.family_restroom_rounded,
      route: UserRoutes.dependents,
      color: AppColors.moduleAppointment,
      order: 22,
    ),
  ];

  @override
  List<ModuleShortcut> get doctorShortcuts => const [
    ModuleShortcut(
      label: 'Dossiers médicaux',
      icon: Icons.folder_shared_rounded,
      route: UserRoutes.doctorRecords,
      color: AppColors.moduleUser,
      order: 10,
    ),
  ];
}
