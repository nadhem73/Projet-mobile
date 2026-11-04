import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/medicament.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/presentation/controllers/prescription_editor_controller.dart';

/// Rédaction d'une ordonnance pendant une consultation en cours.
///
/// Renvoie `true` (via `context.pop`) quand l'ordonnance a été enregistrée.
class PrescriptionEditorScreen extends StatefulWidget {
  const PrescriptionEditorScreen({super.key, required this.consultationId});

  final int consultationId;

  @override
  State<PrescriptionEditorScreen> createState() => _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState extends State<PrescriptionEditorScreen> {
  late final _controller = getIt<PrescriptionEditorController>()..load(widget.consultationId);
  final _search = TextEditingController();
  final _note = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _search.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _controller.search(value));
  }

  Future<void> _add({Medicament? medicament, String? freeName}) async {
    final item = await showModalBottomSheet<PrescriptionItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder:
          (_) => _ItemSheet(
            initial: PrescriptionItem(
              medicamentId: medicament?.id,
              medicamentName: medicament?.name ?? freeName ?? '',
              dosage: medicament?.dosage,
              forme: medicament?.forme,
              voieAdministration: 'orale',
            ),
            nameEditable: medicament == null,
          ),
    );
    if (item == null) return;
    _search.clear();
    _controller.clearResults();
    await _controller.addItem(item);
  }

  Future<void> _edit(int index) async {
    final current = _controller.items[index];
    final item = await showModalBottomSheet<PrescriptionItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => _ItemSheet(initial: current, nameEditable: current.medicamentId == null),
    );
    if (item != null) await _controller.replaceItem(index, item);
  }

  Future<void> _submit() async {
    if (_controller.warnings.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              title: const Text('Allergie signalée'),
              content: Text(_controller.warnings.join('\n')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Modifier')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Prescrire quand même')),
              ],
            ),
      );
      if (proceed != true) return;
    }
    final error = await _controller.submit(note: _note.text);
    if (!mounted) return;
    if (error != null) {
      context.showError(error);
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller.consultation;
        return Scaffold(
          appBar: AppBar(title: Text(c == null ? 'Nouvelle ordonnance' : 'Ordonnance · ${c.patientName}')),
          body: _body(),
          bottomNavigationBar:
              c == null
                  ? null
                  : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: MediButton(
                        label: 'Valider l\'ordonnance',
                        icon: Icons.check_rounded,
                        isLoading: _controller.isSaving,
                        onPressed: _controller.items.isEmpty || _controller.isSaving ? null : _submit,
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _body() {
    if (_controller.isLoading) return const LoadingView();
    if (_controller.consultation == null) {
      return EmptyState.error(_controller.error ?? 'Consultation introuvable');
    }
    final theme = Theme.of(context);
    final query = _search.text.trim();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final warning in _controller.warnings)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: AppRadius.card),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(warning, style: const TextStyle(color: AppColors.error))),
              ],
            ),
          ),
        MediTextField(
          label: 'Rechercher un médicament',
          hint: 'Nom ou DCI (ex. paracétamol)',
          controller: _search,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            setState(() {});
            _onSearch(v);
          },
        ),
        if (_controller.isSearching) const LinearProgressIndicator(),
        if (_controller.apiOffline && query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Catalogue des médicaments indisponible : vous pouvez saisir le nom librement.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
        for (final m in _controller.results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
            title: Text(m.name),
            subtitle: m.details.isEmpty ? null : Text(m.details),
            trailing: const Icon(Icons.add_circle_outline_rounded),
            onTap: () => _add(medicament: m),
          ),
        if (query.length >= 2 && !_controller.isSearching)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_note_rounded),
            title: Text('Ajouter « $query » manuellement'),
            onTap: () => _add(freeName: query),
          ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: 'Médicaments prescrits (${_controller.items.length})'),
        const SizedBox(height: AppSpacing.sm),
        if (_controller.items.isEmpty)
          Text('Recherchez un médicament pour l\'ajouter à l\'ordonnance.', style: theme.textTheme.bodyMedium)
        else
          for (var i = 0; i < _controller.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ItemCard(
                item: _controller.items[i],
                onEdit: () => _edit(i),
                onRemove: () => _controller.removeItem(i),
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
        MediTextField(label: 'Note pour le patient (facultatif)', controller: _note, maxLines: 3),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onEdit, required this.onRemove});

  final PrescriptionItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [item.dosage, item.forme, item.voieAdministration].whereType<String>().join(' · ');
    return MediCard(
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicamentName, style: theme.textTheme.titleSmall),
                if (details.isNotEmpty) Text(details, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('${item.posologie} — ${item.dureeTraitement}', style: theme.textTheme.bodyMedium),
                if ((item.instruction ?? '').isNotEmpty)
                  Text(item.instruction!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Retirer',
            icon: const Icon(Icons.close_rounded, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Formulaire d'une ligne d'ordonnance (posologie, durée...).
class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.initial, required this.nameEditable});

  final PrescriptionItem initial;
  final bool nameEditable;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.medicamentName);
  late final _dosage = TextEditingController(text: widget.initial.dosage);
  late final _forme = TextEditingController(text: widget.initial.forme);
  late final _posologie = TextEditingController(text: widget.initial.posologie);
  late final _duree = TextEditingController(text: widget.initial.dureeTraitement);
  late final _voie = TextEditingController(text: widget.initial.voieAdministration);
  late final _instruction = TextEditingController(text: widget.initial.instruction);

  static const _durations = ['3 jours', '5 jours', '7 jours', '10 jours', '1 mois', '3 mois'];

  @override
  void dispose() {
    for (final c in [_name, _dosage, _forme, _posologie, _duree, _voie, _instruction]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null;

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      PrescriptionItem(
        medicamentId: widget.initial.medicamentId,
        medicamentName: _name.text.trim(),
        dosage: _dosage.text,
        forme: _forme.text,
        posologie: _posologie.text,
        dureeTraitement: _duree.text,
        voieAdministration: _voie.text,
        instruction: _instruction.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial.medicamentName.isEmpty ? 'Médicament' : widget.initial.medicamentName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.nameEditable) ...[
                MediTextField(label: 'Nom du médicament *', controller: _name, validator: _required),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(child: MediTextField(label: 'Dosage', hint: '500 mg', controller: _dosage)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: MediTextField(label: 'Forme', hint: 'comprimé', controller: _forme)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(
                label: 'Posologie *',
                hint: '1 comprimé matin et soir',
                controller: _posologie,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(label: 'Durée du traitement *', hint: '7 jours', controller: _duree, validator: _required),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final d in _durations)
                    ActionChip(label: Text(d), onPressed: () => setState(() => _duree.text = d)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(label: 'Voie d\'administration', hint: 'orale', controller: _voie),
              const SizedBox(height: AppSpacing.md),
              MediTextField(
                label: 'Instructions',
                hint: 'À prendre pendant le repas',
                controller: _instruction,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),
              MediButton(label: 'Ajouter à l\'ordonnance', icon: Icons.check_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
