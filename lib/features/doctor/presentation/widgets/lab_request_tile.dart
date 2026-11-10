import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/lab_request.dart';

/// Résumé d'une demande de bilan dans une liste (médecin ou patient).
class LabRequestTile extends StatelessWidget {
  const LabRequestTile({super.key, required this.request, this.onTap, this.onDelete, this.showDoctor = false});

  final LabRequest request;
  final VoidCallback? onTap;

  /// Bouton de suppression (consultation en cours uniquement).
  final VoidCallback? onDelete;
  final bool showDoctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = request;
    final count = r.tests.length;
    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.accentSurface, borderRadius: AppRadius.card),
            child: const Icon(Icons.biotech_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showDoctor && r.doctorName.isNotEmpty
                      ? r.doctorName
                      : 'Bilan : $count analyse${count > 1 ? 's' : ''}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  r.tests.join(', '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.createdAt != null)
                  Text(DateFormat('d MMM yyyy', 'fr').format(r.createdAt!), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Supprimer la demande de bilan',
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

/// Feuille de saisie d'une demande de bilan : analyses courantes à cocher,
/// analyse libre et note. Renvoie `(tests, note)` ou null si annulée.
class LabRequestSheet extends StatefulWidget {
  const LabRequestSheet({super.key});

  static Future<(List<String>, String?)?> show(BuildContext context) => showModalBottomSheet<(List<String>, String?)>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (_) => const LabRequestSheet(),
  );

  @override
  State<LabRequestSheet> createState() => _LabRequestSheetState();
}

class _LabRequestSheetState extends State<LabRequestSheet> {
  final _selected = <String>[];
  final _other = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    _note.dispose();
    super.dispose();
  }

  void _addOther() {
    final v = _other.text.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!_selected.any((s) => s.toLowerCase() == v.toLowerCase())) _selected.add(v);
      _other.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = _selected.where((s) => !LabRequest.commonTests.contains(s)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Demande de bilan', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('Cochez les analyses à réaliser au laboratoire.', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in [...LabRequest.commonTests, ...custom])
                    FilterChip(
                      label: Text(t),
                      selected: _selected.contains(t),
                      onSelected: (on) => setState(() => on ? _selected.add(t) : _selected.remove(t)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: MediTextField(
                      label: 'Autre analyse',
                      hint: 'Ex. Sérologie toxoplasmose',
                      controller: _other,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addOther(),
                    ),
                  ),
                  IconButton(tooltip: 'Ajouter l\'analyse', onPressed: _addOther, icon: const Icon(Icons.add_rounded)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(label: 'Note (facultatif)', hint: 'Ex. à jeun', controller: _note, maxLines: 2),
              const SizedBox(height: AppSpacing.lg),
              MediButton(
                label:
                    _selected.isEmpty
                        ? 'Ajouter la demande'
                        : 'Ajouter la demande (${_selected.length} analyse${_selected.length > 1 ? 's' : ''})',
                icon: Icons.biotech_rounded,
                onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, (List.of(_selected), _note.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
