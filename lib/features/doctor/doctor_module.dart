import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/medicament_api.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/doctor/presentation/controllers/consultation_controller.dart';
import 'package:medilink/features/doctor/presentation/controllers/consultations_controller.dart';
import 'package:medilink/features/doctor/presentation/controllers/prescription_editor_controller.dart';
import 'package:medilink/features/doctor/presentation/controllers/prescriptions_controller.dart';
import 'package:medilink/features/doctor/presentation/screens/consultation_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/consultations_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_agenda_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_lab_results_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_patient_list_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_patient_medical_record_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/prescription_detail_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/prescription_editor_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/prescriptions_screen.dart';

/// Module MÉDECIN — Membre 5.
/// Espace médecin : agenda, consultations, dossiers patients, ordonnances.
/// Côté patient : consultation de ses ordonnances.
abstract final class DoctorRoutes {
  static const dashboard = AppRoutes.doctorHome;
  static const agenda = '/doctor/agenda';
  static const consultations = '/doctor/consultations';
  static String consultation(Object id) => '/doctor/consultation/$id';
  static const patients = '/doctor/patients';
  static String patientRecord(Object patientId) => '/doctor/patient/$patientId/record';
  static String patientLabs(Object patientId) => '/doctor/patient/$patientId/labs';

  /// Rédaction d'une ordonnance pendant la consultation [consultationId].
  static String prescriptionFor(Object consultationId) => '/doctor/consultation/$consultationId/prescription';

  /// Ordonnances de l'utilisateur connecté (reçues par le patient, rédigées par le médecin).
  static const patientPrescriptions = '/prescriptions';

  /// Détail d'une ordonnance (patient, médecin, pharmacien, assureur).
  static String prescription(Object id) => '/prescriptions/$id';
}

class DoctorModule extends FeatureModule {
  const DoctorModule();

  @override
  String get name => 'Médecin';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      // Repositories
      ..registerLazySingleton<ConsultationRepository>(() => ConsultationRepository(getIt(), getIt(), getIt()))
      ..registerLazySingleton<PrescriptionRepository>(() => PrescriptionRepository(getIt(), getIt(), getIt()))
      ..registerLazySingleton<MedicamentApi>(() => MedicamentApi(http.Client()))
      // Controllers (une instance par écran)
      ..registerFactory<ConsultationsController>(() => ConsultationsController(getIt(), getIt()))
      ..registerFactory<ConsultationController>(() => ConsultationController(getIt(), getIt(), getIt(), getIt()))
      ..registerFactory<PrescriptionEditorController>(
        () => PrescriptionEditorController(getIt(), getIt(), getIt(), getIt()),
      )
      ..registerFactory<PrescriptionsController>(() => PrescriptionsController(getIt(), getIt()));
  }

  static int _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

  @override
  List<RouteBase> get routes => [
    GoRoute(path: DoctorRoutes.dashboard, builder: (_, _) => const MLDoctorDashboardScreen()),
    GoRoute(path: DoctorRoutes.agenda, builder: (_, _) => const MLDoctorAgendaScreen()),
    GoRoute(path: DoctorRoutes.consultations, builder: (_, _) => const DoctorConsultationsScreen()),
    GoRoute(
      path: '/doctor/consultation/:id',
      builder: (_, state) => ConsultationScreen(consultationId: _id(state)),
      routes: [
        GoRoute(path: 'prescription', builder: (_, state) => PrescriptionEditorScreen(consultationId: _id(state))),
      ],
    ),
    GoRoute(path: DoctorRoutes.patients, builder: (_, _) => const MLDoctorPatientListScreen()),
    GoRoute(
      path: '/doctor/patient/:id/record',
      builder: (_, state) => MLDoctorPatientMedicalRecordScreen(patientId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/doctor/patient/:id/labs',
      builder: (_, state) => MLDoctorLabResultsScreen(patientId: state.pathParameters['id']),
    ),
    GoRoute(
      path: DoctorRoutes.patientPrescriptions,
      builder: (_, _) => const PrescriptionsScreen(),
      routes: [GoRoute(path: ':id', builder: (_, state) => PrescriptionDetailScreen(prescriptionId: _id(state)))],
    ),
  ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(
      label: 'Ordonnances',
      icon: Icons.receipt_long_rounded,
      route: DoctorRoutes.patientPrescriptions,
      color: AppColors.moduleDoctor,
      order: 30,
    ),
  ];
}
