import 'package:flutter/material.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/ai/medical_safety_checker.dart';
import 'package:medilink/features/user/data/ai/medical_summary_service.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';

extension AlertLevelStyle on AlertLevel {
  Color get color => switch (this) {
    AlertLevel.critical => AppColors.error,
    AlertLevel.warning => AppColors.warning,
    AlertLevel.info => AppColors.info,
  };

  IconData get icon => switch (this) {
    AlertLevel.critical => Icons.report_rounded,
    AlertLevel.warning => Icons.warning_amber_rounded,
    AlertLevel.info => Icons.lightbulb_outline_rounded,
  };
}

/// Petit badge « IA » placé à côté des contenus générés automatiquement.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'IA'});

  final String label;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: label, color: AppColors.moduleUser, icon: Icons.auto_awesome_rounded);
}

/// Alertes du moteur de règles (allergie ↔ traitement, contre-indications,
/// vaccins). [forPatient] adapte le ton pour le patient.
class SafetyAlertsCard extends StatelessWidget {
  const SafetyAlertsCard({super.key, required this.alerts, this.forPatient = false});

  final List<SafetyAlert> alerts;
  final bool forPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worst = alerts.isEmpty ? null : alerts.first.level;
    final color = worst?.color ?? AppColors.success;

    return MediCard(
      color: color.withValues(alpha: 0.05),
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(worst?.icon ?? Icons.verified_user_rounded, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  alerts.isEmpty
                      ? 'Aucune incohérence détectée'
                      : '${alerts.length} point${alerts.length > 1 ? 's' : ''} de vigilance',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const AiBadge(label: 'Analyse IA'),
            ],
          ),
          if (alerts.isEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Allergies, maladies chroniques, traitement et vaccins ont été croisés automatiquement.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          for (final alert in alerts) ...[
            const SizedBox(height: AppSpacing.md),
            _AlertRow(level: alert.level, title: alert.title, detail: alert.detail),
          ],
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              forPatient
                  ? 'Ces alertes sont générées automatiquement : parlez-en à votre médecin, '
                      'n\'arrêtez jamais un traitement de vous-même.'
                  : 'Alertes générées par règles à partir du dossier : à confirmer cliniquement.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.level, this.title, required this.detail});

  final AlertLevel level;
  final String? title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(level.icon, size: 18, color: level.color)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: level.color),
                ),
              Text(detail, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Synthèse clinique IA du dossier (vue médecin), générée à la demande.
class AiSummaryCard extends StatefulWidget {
  const AiSummaryCard({super.key, required this.file});

  final PatientMedicalFile file;

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard> {
  final _service = getIt<MedicalSummaryService>();
  Future<AiMedicalSummary>? _summary;

  void _generate() {
    final summary = _service.summarize(widget.file);
    setState(() {
      _summary = summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      color: AppColors.moduleUser.withValues(alpha: 0.04),
      borderColor: AppColors.moduleUser.withValues(alpha: 0.3),
      child: FutureBuilder(
        future: _summary,
        builder: (context, snapshot) {
          final header = Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.moduleUser),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Synthèse IA du dossier', style: theme.textTheme.titleSmall)),
              if (snapshot.hasData)
                IconButton(
                  tooltip: 'Régénérer',
                  visualDensity: VisualDensity.compact,
                  onPressed: _generate,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          );

          if (_summary == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Résumé clinique, alertes et questions à poser, préparés par l\'IA avant la consultation. '
                  'Les données sont anonymisées (aucun nom ni coordonnée).',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                MediButton(label: 'Générer la synthèse', icon: Icons.auto_awesome_rounded, onPressed: _generate),
              ],
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: AppSpacing.md),
                Text('Analyse du dossier en cours…', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            );
          }
          final s = snapshot.data;
          if (s == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.sm),
                const Text('Synthèse indisponible.'),
                MediButton.text(label: 'Réessayer', onPressed: _generate),
              ],
            );
          }
          return _SummaryContent(header: header, summary: s);
        },
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.header, required this.summary});

  final Widget header;
  final AiMedicalSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget list(String title, IconData icon, List<String> items) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.moduleUser),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 2),
              child: Text('• $item', style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            StatusBadge(
              label: summary.source,
              color: summary.isFromLlm ? AppColors.moduleUser : AppColors.textMuted,
              icon: summary.isFromLlm ? Icons.cloud_done_outlined : Icons.offline_bolt_outlined,
            ),
          ],
        ),
        if (summary.fallbackReason != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(summary.fallbackReason!, style: muted),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(summary.summary, style: theme.textTheme.bodyMedium),
        if (summary.alerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          for (final a in summary.alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AlertRow(level: a.level, detail: a.message),
            ),
        ],
        if (summary.keyPoints.isNotEmpty) list('Points clés', Icons.checklist_rounded, summary.keyPoints),
        if (summary.questions.isNotEmpty) list('Questions à poser', Icons.help_outline_rounded, summary.questions),
        if (summary.missingData.isNotEmpty) list('Informations manquantes', Icons.pending_outlined, summary.missingData),
        const SizedBox(height: AppSpacing.md),
        Text('Aide à la décision : ne remplace pas le jugement clinique du médecin.', style: muted),
      ],
    );
  }
}
