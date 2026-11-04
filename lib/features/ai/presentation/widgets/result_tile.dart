import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/presentation/widgets/range_gauge.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';

/// Un résultat d'analyse : valeur + unité colorées selon le statut, référence,
/// valeur antérieure, jauge, badge « à vérifier » et édition inline.
class ResultTile extends StatefulWidget {
  const ResultTile({super.key, required this.result, required this.showPrevious, this.onSave});

  final BilanResult result;

  /// Format ANCIEN_PATIENT : afficher la colonne « valeur antérieure ».
  final bool showPrevious;

  /// `null` = lecture seule. Renvoie un message d'erreur ou `null` si enregistré.
  final Future<String?> Function(String valeur)? onSave;

  @override
  State<ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<ResultTile> {
  bool _editing = false;
  bool _saving = false;
  String? _error;
  late final TextEditingController _input = TextEditingController(text: widget.result.valeur);

  @override
  void didUpdateWidget(covariant ResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.result.valeur != widget.result.valeur) _input.text = widget.result.valeur;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave!(_input.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      if (error == null) _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.result;
    final color = r.status.color;
    final value = r.numericValue;
    final reference = r.referenceLabel;

    return MediCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: r.status.isOutOfRange ? color.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(r.status.icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(r.testName, style: theme.textTheme.titleSmall)),
              if (r.needsCheck)
                const StatusBadge(label: 'À vérifier', color: AppColors.accent, icon: Icons.visibility_rounded),
              if (widget.onSave != null && !_editing)
                IconButton(
                  tooltip: 'Corriger la valeur',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => setState(() => _editing = true),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_editing)
            _EditRow(
              controller: _input,
              unit: r.unite,
              saving: _saving,
              error: _error,
              onSave: _save,
              onCancel:
                  () => setState(() {
                    _editing = false;
                    _error = null;
                    _input.text = r.valeur;
                  }),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  r.valeur.replaceAll('.', ','),
                  style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(r.unite, style: theme.textTheme.bodySmall),
                ),
                const Spacer(),
                Text(r.status.label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
              ],
            ),
          if (value != null && r.hasRange) ...[
            const SizedBox(height: AppSpacing.sm),
            RangeGauge(value: value, min: r.referenceMin, max: r.referenceMax, status: r.status),
          ],
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                reference == null ? 'Référence non lue' : 'Référence : $reference ${r.hasRange ? r.unite : ''}',
                style: theme.textTheme.bodySmall,
              ),
              if (widget.showPrevious && r.valeurAncienne != null)
                Text(
                  'Antérieur : ${r.valeurAncienne!.replaceAll('.', ',')} ${r.unite}'
                  '${r.dateAncienne != null ? ' (${_shortDate(r.dateAncienne!)})' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.controller,
    required this.unit,
    required this.saving,
    required this.error,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final String unit;
  final bool saving;
  final String? error;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
            decoration: InputDecoration(isDense: true, labelText: 'Valeur', suffixText: unit, errorText: error),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (saving)
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
        else ...[
          IconButton(tooltip: 'Annuler', icon: const Icon(Icons.close_rounded), onPressed: onCancel),
          IconButton.filled(tooltip: 'Enregistrer', icon: const Icon(Icons.check_rounded), onPressed: onSave),
        ],
      ],
    );
  }
}
