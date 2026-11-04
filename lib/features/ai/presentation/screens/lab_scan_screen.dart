import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/ai_module.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_scan_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/shooting_tips.dart';

/// « Scanner un bilan » : photo (caméra / galerie) → recadrage → analyse.
class BilanScanScreen extends StatefulWidget {
  const BilanScanScreen({super.key});

  @override
  State<BilanScanScreen> createState() => _BilanScanScreenState();
}

class _BilanScanScreenState extends State<BilanScanScreen> {
  final _controller = getIt<BilanScanController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  /// Analyse terminée → ouverture de la revue du bilan.
  void _onChange() {
    final id = _controller.bilanId;
    if (_controller.step != ScanStep.done || id == null || !mounted) return;
    if (_controller.analysedOffline) {
      context.showInfo('Analysé sur le téléphone : vérifiez les valeurs avant de valider.');
    }
    _controller.reset();
    context.pushReplacement(AiRoutes.bilan(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un bilan'),
        actions: [
          IconButton(
            tooltip: 'Mes bilans',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AiRoutes.bilans),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder:
                (context, _) => PopupMenuButton<void>(
                  tooltip: 'Paramètres',
                  itemBuilder:
                      (_) => [
                        CheckedPopupMenuItem(
                          checked: _controller.offlineForced,
                          onTap: () => _controller.setOfflineForced(!_controller.offlineForced),
                          child: const Text('OCR hors-ligne uniquement'),
                        ),
                      ],
                ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (c.step.isBusy) return _ProgressView(step: c.step, progress: c.progress);
          if (c.step == ScanStep.error) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState.error(c.error ?? 'Erreur inconnue', onRetry: c.canRetry ? c.retry : null),
                MediButton.text(
                  label: 'Choisir une autre photo',
                  icon: Icons.photo_library_rounded,
                  onPressed: () => c.pick(ImageSource.gallery),
                ),
              ],
            );
          }
          return _IdleView(controller: c);
        },
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.controller});

  final BilanScanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = controller.offlineForced || !controller.serverConfigured;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MediCard(
          color: AppColors.accentSurface,
          borderColor: AppColors.accent.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.document_scanner_rounded, size: 44, color: AppColors.accentDark),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Bilan de laboratoire', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Prenez votre bilan en photo : les valeurs sont extraites et comparées aux normes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: MediButton(
                      label: 'Caméra',
                      icon: Icons.photo_camera_rounded,
                      onPressed: () => controller.pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: MediButton.outlined(
                      label: 'Galerie',
                      icon: Icons.photo_library_rounded,
                      onPressed: () => controller.pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const ShootingTips(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Icon(local ? Icons.phone_android_rounded : Icons.cloud_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                local
                    ? 'Analyse sur le téléphone (Tesseract, hors-ligne).'
                    : 'Analyse par le serveur MediLink ; sur le téléphone si le réseau est indisponible.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.step, required this.progress});

  final ScanStep step;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = progress == null ? null : ' ${(progress! * 100).round()} %';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.document_scanner_rounded, size: 56, color: AppColors.accent),
            const SizedBox(height: AppSpacing.xl),
            Text('${step.label}${percent ?? ''}', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              step == ScanStep.uploading
                  ? 'L\'analyse par le serveur peut prendre jusqu\'à 90 secondes.'
                  : 'Quelques secondes…',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
