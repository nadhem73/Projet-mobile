import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';

/// Résumé d'une ordonnance dans une liste (médecin ou patient).
class PrescriptionTile extends StatelessWidget {
  const PrescriptionTile({
    super.key,
    required this.prescription,
    this.onTap,
    this.onDelete,
    this.showPatient = true,
    this.showDoctor = false,
  });

  final Prescription prescription;
  final VoidCallback? onTap;

  /// Bouton de suppression (consultation en cours uniquement).
  final VoidCallback? onDelete;
  final bool showPatient;
  final bool showDoctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = prescription;
    final names = p.items.map((i) => i.medicamentName).join(', ');
    final title = [if (showDoctor) p.doctorName, if (showPatient) p.patientName].where((s) => s.isNotEmpty).join(' · ');
    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: AppRadius.card),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '${p.items.length} médicament${p.items.length > 1 ? 's' : ''}' : title,
                  style: theme.textTheme.titleSmall,
                ),
                Text(names, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (p.createdAt != null)
                  Text(DateFormat('d MMM yyyy', 'fr').format(p.createdAt!), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Supprimer l\'ordonnance',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: onDelete,
            )
          else if (onTap != null)
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
