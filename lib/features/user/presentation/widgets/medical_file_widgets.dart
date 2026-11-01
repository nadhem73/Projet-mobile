import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';

/// Liste des vaccins. [onDelete] null = lecture seule (vue médecin).
class VaccinationList extends StatelessWidget {
  const VaccinationList({super.key, required this.vaccinations, this.onDelete, this.onTap});

  final List<Vaccination> vaccinations;
  final ValueChanged<Vaccination>? onDelete;
  final ValueChanged<Vaccination>? onTap;

  @override
  Widget build(BuildContext context) {
    if (vaccinations.isEmpty) {
      return const EmptyState(
        icon: Icons.vaccines_outlined,
        title: 'Aucun vaccin enregistré',
        message: 'Ajoutez vos vaccins pour garder votre carnet de vaccination à jour.',
      );
    }
    final theme = Theme.of(context);
    final date = DateFormat('d MMM yyyy', 'fr');
    return Column(
      children: [
        for (final v in vaccinations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: MediCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              onTap: onTap == null ? null : () => onTap!(v),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.vaccines_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: theme.textTheme.titleSmall),
                        Text(
                          [date.format(v.date), if (v.dose != null) v.dose!, if (v.notes != null) v.notes!].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => onDelete!(v),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Grille de documents (miniatures). Un appui ouvre le document en plein écran.
class DocumentGrid extends StatelessWidget {
  const DocumentGrid({super.key, required this.documents, this.onDelete});

  final List<MedicalDocument> documents;

  /// null = lecture seule (vue médecin).
  final ValueChanged<MedicalDocument>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Aucun document',
        message: 'Photographiez vos analyses, radios ou comptes rendus pour les retrouver ici.',
      );
    }
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 200,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: documents.length,
      itemBuilder: (context, i) {
        final d = documents[i];
        return Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card, side: BorderSide(color: theme.dividerColor)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => DocumentViewerScreen(document: d, onDelete: onDelete))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.memory(
                    d.data,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(d.category.icon, size: 40, color: theme.dividerColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                      Row(
                        children: [
                          Icon(d.category.icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              d.category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Affichage plein écran d'un document (zoom au pincement).
class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({super.key, required this.document, this.onDelete});

  final MedicalDocument document;
  final ValueChanged<MedicalDocument>? onDelete;

  @override
  Widget build(BuildContext context) {
    final created = document.createdAt;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              [
                document.category.label,
                if (created != null) DateFormat('d MMM yyyy', 'fr').format(created),
              ].join(' · '),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Supprimer ce document ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                        ],
                      ),
                );
                if (confirm == true && context.mounted) {
                  onDelete!(document);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: InteractiveViewer(maxScale: 5, child: Center(child: Image.memory(document.data))),
    );
  }
}

/// Historique des consultations du dossier par les médecins.
class AccessLogList extends StatelessWidget {
  const AccessLogList({super.key, required this.entries});

  final List<RecordAccess> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = DateFormat('d MMM yyyy à HH:mm', 'fr');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: AppRadius.card),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.info),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Seuls les médecins avec qui vous avez un rendez-vous peuvent consulter votre dossier. '
                  'Chaque consultation est enregistrée ici.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (entries.isEmpty)
          const EmptyState(
            icon: Icons.visibility_off_outlined,
            title: 'Aucune consultation',
            message: 'Aucun médecin n\'a encore consulté votre dossier.',
          )
        else
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MediCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.doctorName, style: theme.textTheme.titleSmall),
                          Text(
                            '${e.specialty} · ${format.format(e.accessedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
