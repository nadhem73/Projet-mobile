import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_agenda_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_consultation_detail_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_consultation_list_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_lab_results_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_patient_list_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_patient_medical_record_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_prescription_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/prescription_screen.dart';

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
  static const newPrescription = '/doctor/prescription/new';
  static const prescriptionTemplate = '/doctor/prescription/template';

  /// Côté patient : historique de ses ordonnances.
  static const patientPrescriptions = '/prescriptions';
}

class DoctorModule extends FeatureModule {
  const DoctorModule();

  @override
  String get name => 'Médecin';

  @override
  void registerDependencies(GetIt getIt) {
    // TODO(doctor): enregistrer ConsultationRepository, PrescriptionRepository...
  }

  @override
  List<RouteBase> get routes => [
        GoRoute(path: DoctorRoutes.dashboard, builder: (_, _) => const MLDoctorDashboardScreen()),
        GoRoute(path: DoctorRoutes.agenda, builder: (_, _) => const MLDoctorAgendaScreen()),
        GoRoute(path: DoctorRoutes.consultations, builder: (_, _) => const MLDoctorConsultationListScreen()),
        GoRoute(
          path: '/doctor/consultation/:id',
          builder: (_, state) => MLDoctorConsultationDetailScreen(consultationId: state.pathParameters['id']),
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
          path: DoctorRoutes.newPrescription,
          builder: (_, state) => MLDoctorPrescriptionScreen(
            consultationId: state.uri.queryParameters['consultationId'],
            patientId: state.uri.queryParameters['patientId'],
          ),
        ),
        GoRoute(
          path: DoctorRoutes.prescriptionTemplate,
          builder: (_, state) => MLDoctorPrescriptionScreen(
            isTemplate: true,
            patientId: state.uri.queryParameters['patientId'],
          ),
        ),
        GoRoute(path: DoctorRoutes.patientPrescriptions, builder: (_, _) => const MLPrescriptionScreen()),
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
