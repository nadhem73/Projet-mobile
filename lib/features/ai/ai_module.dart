import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:medilink/features/ai/presentation/screens/bot_screen.dart';
import 'package:medilink/features/ai/presentation/screens/lab_scan_screen.dart';

/// Module IA — partagé / à attribuer.
/// OCR des bilans (Tesseract) + assistant d'orientation LLM/RAG.
abstract final class AiRoutes {
  static const assistant = '/ai-assistant';
  static const labScan = '/lab-scan';
  static const bot = '/bot';
}

class AiModule extends FeatureModule {
  const AiModule();

  @override
  String get name => 'IA';

  @override
  List<RouteBase> get routes => [
        GoRoute(path: AiRoutes.assistant, builder: (_, _) => const MLAiAssistantScreen()),
        GoRoute(path: AiRoutes.labScan, builder: (_, _) => const MLLabScanScreen()),
        GoRoute(path: AiRoutes.bot, builder: (_, _) => const MLBotScreen()),
      ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
        ModuleShortcut(
          label: 'Analyser un bilan',
          icon: Icons.document_scanner_rounded,
          route: AiRoutes.labScan,
          color: AppColors.moduleAi,
          order: 60,
        ),
        ModuleShortcut(
          label: 'Assistant IA',
          icon: Icons.auto_awesome_rounded,
          route: AiRoutes.assistant,
          color: AppColors.moduleAi,
          order: 61,
        ),
      ];
}
