import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ai/data/ocr/bilan_parser.dart';
import 'package:medilink/features/ai/data/ocr/image_preprocessor.dart';
import 'package:medilink/features/ai/data/ocr/ocr_engine.dart';
import 'package:medilink/features/ai/data/repositories/bilan_api.dart';
import 'package:medilink/features/ai/data/repositories/bilan_image_store.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';
import 'package:medilink/features/ai/data/repositories/doctor_directory.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_evolution_controller.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_history_controller.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_review_controller.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_scan_controller.dart';
import 'package:medilink/features/ai/presentation/controllers/doctor_bilans_controller.dart';
import 'package:medilink/features/ai/presentation/controllers/patient_record_bilans_controller.dart';
import 'package:medilink/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:medilink/features/ai/presentation/screens/bilan_evolution_screen.dart';
import 'package:medilink/features/ai/presentation/screens/bilan_history_screen.dart';
import 'package:medilink/features/ai/presentation/screens/bilan_review_screen.dart';
import 'package:medilink/features/ai/presentation/screens/bot_screen.dart';
import 'package:medilink/features/ai/presentation/screens/doctor_bilan_screen.dart';
import 'package:medilink/features/ai/presentation/screens/doctor_bilans_screen.dart';
import 'package:medilink/features/ai/presentation/screens/lab_scan_screen.dart';
import 'package:medilink/features/ai/presentation/screens/patient_record_bilans.dart';

/// Module IA — partagé / à attribuer.
/// Analyse des bilans (OCR serveur ou Tesseract hors-ligne) + assistant LLM/RAG.
abstract final class AiRoutes {
  static const assistant = '/ai-assistant';
  static const bot = '/bot';

  /// Scanner un bilan.
  static const labScan = '/lab-scan';

  /// Historique « Mes bilans ».
  static const bilans = '/bilans';

  /// Revue / détail d'un bilan.
  static String bilan(Object id) => '/bilans/$id';

  /// Courbe d'un test sur les bilans confirmés.
  static const evolution = '/bilans/evolution';

  /// Côté médecin (préfixe /doctor/ : réservé au rôle médecin par le routeur).
  static const doctorBilans = '/doctor/bilans';
  static String doctorBilan(Object id) => '/doctor/bilans/$id';

  /// Bilan validé d'un patient, ouvert depuis son dossier médical (onglet Documents).
  static String patientRecordBilan(Object patientId, Object bilanId) => '/doctor/dossier/$patientId/bilans/$bilanId';
}

class AiModule extends FeatureModule {
  const AiModule();

  @override
  String get name => 'IA';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      // OCR / données
      ..registerLazySingleton<BilanParser>(() => BilanParser())
      ..registerLazySingleton<OcrEngine>(() => const OcrEngine())
      ..registerLazySingleton<ImagePreprocessor>(() => const ImagePreprocessor())
      ..registerLazySingleton<BilanImageStore>(() => const BilanImageStore())
      ..registerLazySingleton<BilanApi>(() => BilanApi(http.Client()))
      ..registerLazySingleton<BilanRepository>(() => BilanRepository(getIt(), getIt(), getIt()))
      ..registerLazySingleton<DoctorDirectory>(() => DoctorDirectory(getIt()))
      // Controllers (une instance par écran)
      ..registerFactory<BilanScanController>(
        () => BilanScanController(getIt(), getIt(), getIt(), getIt(), getIt(), getIt(), getIt(), getIt()),
      )
      ..registerFactory<BilanReviewController>(() => BilanReviewController(getIt(), getIt(), getIt()))
      ..registerFactory<BilanHistoryController>(() => BilanHistoryController(getIt(), getIt(), getIt(), getIt()))
      ..registerFactory<BilanEvolutionController>(() => BilanEvolutionController(getIt(), getIt()))
      ..registerFactory<DoctorBilansController>(() => DoctorBilansController(getIt(), getIt()))
      ..registerFactory<DoctorBilanController>(() => DoctorBilanController(getIt(), getIt()))
      ..registerFactory<PatientRecordBilansController>(() => PatientRecordBilansController(getIt(), getIt(), getIt()));
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(path: AiRoutes.assistant, builder: (_, _) => const MLAiAssistantScreen()),
    GoRoute(path: AiRoutes.bot, builder: (_, _) => const MLBotScreen()),
    GoRoute(path: AiRoutes.labScan, builder: (_, _) => const BilanScanScreen()),
    GoRoute(
      path: AiRoutes.bilans,
      builder: (_, _) => const BilanHistoryScreen(),
      routes: [
        // Avant ':id' pour ne pas être capturé comme identifiant.
        GoRoute(
          path: 'evolution',
          builder: (_, state) => BilanEvolutionScreen(initialTest: state.uri.queryParameters['test']),
        ),
        GoRoute(path: ':id', builder: (_, state) => BilanReviewScreen(bilanId: state.pathParameters['id']!)),
      ],
    ),
    GoRoute(
      path: AiRoutes.doctorBilans,
      builder: (_, _) => const DoctorBilansScreen(),
      routes: [GoRoute(path: ':id', builder: (_, state) => DoctorBilanScreen(bilanId: state.pathParameters['id']!))],
    ),
    GoRoute(
      path: '/doctor/dossier/:patientId/bilans/:bilanId',
      builder:
          (_, state) => PatientRecordBilanScreen(
            patientId: int.parse(state.pathParameters['patientId']!),
            bilanId: state.pathParameters['bilanId']!,
          ),
    ),
  ];

  @override
  List<ModuleShortcut> get doctorShortcuts => const [
    ModuleShortcut(
      label: 'Bilans reçus',
      icon: Icons.science_rounded,
      route: AiRoutes.doctorBilans,
      color: AppColors.moduleAi,
      order: 20,
    ),
  ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(
      label: 'Scanner un bilan',
      icon: Icons.document_scanner_rounded,
      route: AiRoutes.labScan,
      color: AppColors.moduleAi,
      order: 60,
    ),
    ModuleShortcut(
      label: 'Mes bilans',
      icon: Icons.science_rounded,
      route: AiRoutes.bilans,
      color: AppColors.moduleAi,
      order: 61,
    ),
    ModuleShortcut(
      label: 'Assistant IA',
      icon: Icons.auto_awesome_rounded,
      route: AiRoutes.assistant,
      color: AppColors.moduleAi,
      order: 62,
    ),
  ];
}
