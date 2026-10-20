import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/presentation/controllers/medical_record_controller.dart';
import 'package:medilink/features/user/presentation/widgets/medical_record_view.dart';
import 'package:medilink/features/user/user_module.dart';

/// Dossier médical du patient connecté.
class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final int? _patientId = getIt<SessionService>().currentUser?.patientId;
  late final MedicalRecordController? _controller =
      _patientId == null ? null : (getIt<MedicalRecordController>(param1: _patientId)..load());

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final saved = await context.push<bool>(UserRoutes.editMedicalRecord);
    if (saved == true) {
      await _controller!.load();
      if (mounted) context.showSuccess('Dossier médical enregistré');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon dossier médical'),
        actions: [
          if (controller != null)
            IconButton(tooltip: 'Modifier', onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body:
          controller == null
              ? const EmptyState(
                icon: Icons.folder_off_outlined,
                title: 'Réservé aux patients',
                message: 'Le dossier médical est disponible depuis un compte patient.',
              )
              : ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final record = controller.record;
                  if (controller.isLoading && record == null) return const LoadingView();
                  if (record == null) {
                    return EmptyState.error(controller.error ?? 'Dossier indisponible', onRetry: controller.load);
                  }
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
                      children: [
                        if (record.completion < 100) ...[
                          _CompletionBanner(percent: record.completion, onTap: _edit),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        MedicalRecordView(record: record),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton:
          controller == null
              ? null
              : FloatingActionButton.extended(
                onPressed: _edit,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Mettre à jour'),
              ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.percent, required this.onTap});

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Dossier complété à $percent %', style: theme.textTheme.titleSmall)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: percent / 100, minHeight: 6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Un dossier complet aide vos médecins à mieux vous soigner, surtout en cas d\'urgence.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
