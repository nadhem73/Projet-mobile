import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';

/// En-tête d'un bilan : type, laboratoire, date, compteurs, revue du médecin.
class BilanHeader extends StatelessWidget {
  const BilanHeader({super.key, required this.bilan, this.showPatient = false});

  final ScanBilan bilan;

  /// Vue médecin : affiche le nom du patient.
  final bool showPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = bilan.date;
    final review = bilan.reviewStatus;
    final comment = bilan.doctorComment;
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(bilan.typeBilan, style: theme.textTheme.titleLarge)),
              StatusBadge(
                label: bilan.status.label,
                color: bilan.isConfirmed ? AppColors.success : AppColors.warning,
                icon: bilan.isConfirmed ? Icons.verified_rounded : Icons.pending_rounded,
              ),
            ],
          ),
          if (showPatient) InfoRow(icon: Icons.person_rounded, label: 'Patient', value: bilan.patientName),
          InfoRow(
            icon: Icons.biotech_rounded,
            label: 'Laboratoire',
            value: bilan.laboratoire.isEmpty ? null : bilan.laboratoire,
          ),
          InfoRow(
            icon: Icons.event_rounded,
            label: 'Date du bilan',
            value: date == null ? null : DateFormat('d MMMM yyyy', 'fr').format(date),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              StatusBadge(
                label: '${bilan.resultats.length} valeur${bilan.resultats.length > 1 ? 's' : ''}',
                color: AppColors.primary,
              ),
              if (bilan.abnormalCount > 0)
                StatusBadge(
                  label: '${bilan.abnormalCount} hors norme',
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
              if (!bilan.synced && !showPatient)
                const StatusBadge(label: 'Non synchronisé', color: AppColors.textMuted, icon: Icons.cloud_off_rounded),
              if (review != null)
                StatusBadge(
                  label:
                      bilan.doctorName == null || showPatient ? review.label : '${review.label} · ${bilan.doctorName}',
                  color: review.color,
                  icon: review.icon,
                ),
            ],
          ),
          if (comment != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: AppRadius.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commentaire${bilan.doctorName == null ? '' : ' de ${bilan.doctorName}'}',
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(comment, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
