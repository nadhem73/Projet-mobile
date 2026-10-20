import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/presentation/controllers/medical_record_controller.dart';
import 'package:medilink/features/user/presentation/widgets/image_picking.dart';
import 'package:medilink/features/user/presentation/widgets/medical_file_widgets.dart';
import 'package:medilink/features/user/presentation/widgets/medical_record_view.dart';
import 'package:medilink/features/user/user_module.dart';

/// Dossier médical du patient connecté : résumé, vaccins, documents, accès.
class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> with SingleTickerProviderStateMixin {
  final int? _patientId = getIt<SessionService>().currentUser?.patientId;
  late final MedicalRecordController? _controller =
      _patientId == null ? null : (getIt<MedicalRecordController>(param1: _patientId)..load());
  late final TabController _tabs = TabController(length: 4, vsync: this)..addListener(_onTab);

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
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

  Future<void> _addVaccination([Vaccination? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VaccinationSheet(controller: _controller!, existing: existing),
    );
    if (saved == true && mounted) context.showSuccess('Carnet de vaccination mis à jour');
  }

  Future<void> _deleteVaccination(Vaccination v) async {
    final confirm = await _confirm('Supprimer le vaccin « ${v.name} » ?');
    if (!confirm || !mounted) return;
    final error = await _controller!.deleteVaccination(v.id!);
    if (mounted && error != null) context.showError(error);
  }

  Future<void> _addDocument() async {
    final choice = await pickImage(context, title: 'Ajouter un document');
    if (choice is! PickedImage || !mounted) return;
    final details = await showDialog<(String, DocumentCategory)>(
      context: context,
      builder: (_) => const _DocumentDetailsDialog(),
    );
    if (details == null || !mounted) return;
    final error = await _controller!.addDocument(details.$1, details.$2, choice.bytes);
    if (!mounted) return;
    error == null ? context.showSuccess('Document ajouté') : context.showError(error);
  }

  Future<void> _deleteDocument(MedicalDocument d) async {
    final error = await _controller!.deleteDocument(d.id!);
    if (mounted) error == null ? context.showSuccess('Document supprimé') : context.showError(error);
  }

  Future<bool> _confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(title),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
              ],
            ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dossier médical')),
        body: const EmptyState(
          icon: Icons.folder_off_outlined,
          title: 'Réservé aux patients',
          message: 'Le dossier médical est disponible depuis un compte patient.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon dossier médical'),
        actions: [
          IconButton(
            tooltip: 'Carte d\'urgence',
            onPressed: () => context.push(UserRoutes.emergencyCard),
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
          IconButton(tooltip: 'Modifier', onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [Tab(text: 'Résumé'), Tab(text: 'Vaccins'), Tab(text: 'Documents'), Tab(text: 'Accès')],
        ),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final record = controller.record;
          if (controller.isLoading && record == null) return const LoadingView();
          if (record == null) {
            return EmptyState.error(controller.error ?? 'Dossier indisponible', onRetry: controller.load);
          }
          Widget page(Widget child) => RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
              children: [child],
            ),
          );
          return TabBarView(
            controller: _tabs,
            children: [
              page(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (record.completion < 100) ...[
                      _CompletionBanner(percent: record.completion, onTap: _edit),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    MedicalRecordView(record: record, age: controller.identity?.age),
                  ],
                ),
              ),
              page(
                VaccinationList(
                  vaccinations: controller.vaccinations,
                  onTap: _addVaccination,
                  onDelete: _deleteVaccination,
                ),
              ),
              page(DocumentGrid(documents: controller.documents, onDelete: _deleteDocument)),
              page(AccessLogList(entries: controller.accessLog)),
            ],
          );
        },
      ),
      floatingActionButton: switch (_tabs.index) {
        0 => FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Mettre à jour'),
        ),
        1 => FloatingActionButton.extended(
          onPressed: _addVaccination,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter un vaccin'),
        ),
        2 => FloatingActionButton.extended(
          onPressed: _addDocument,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Ajouter un document'),
        ),
        _ => null,
      },
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
            'Sexe, groupe sanguin, taille, poids et contact d\'urgence aident vos médecins '
            'et les secours en cas d\'urgence.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Ajout ou modification d'un vaccin.
class _VaccinationSheet extends StatefulWidget {
  const _VaccinationSheet({required this.controller, this.existing});

  final MedicalRecordController controller;
  final Vaccination? existing;

  @override
  State<_VaccinationSheet> createState() => _VaccinationSheetState();
}

class _VaccinationSheetState extends State<_VaccinationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _dose = TextEditingController(text: widget.existing?.dose);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late DateTime? _date = widget.existing?.date;
  late final _dateText = TextEditingController(text: _date == null ? '' : DateFormat('dd/MM/yyyy').format(_date!));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _dose, _notes, _dateText]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Date de vaccination',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateText.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.controller.saveVaccination(
      Vaccination(
        id: widget.existing?.id,
        patientId: widget.controller.patientId,
        name: _name.text,
        date: _date!,
        dose: _dose.text,
        notes: _notes.text,
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Ajouter un vaccin' : 'Modifier le vaccin',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _name.text),
                optionsBuilder: (value) {
                  final q = value.text.toLowerCase();
                  return q.isEmpty
                      ? Vaccination.suggestions
                      : Vaccination.suggestions.where((s) => s.toLowerCase().contains(q));
                },
                onSelected: (v) => _name.text = v,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmit) => TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (v) => _name.text = v,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Vaccin',
                        prefixIcon: Icon(Icons.vaccines_outlined, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Indiquez le nom du vaccin' : null,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(
                label: 'Date',
                controller: _dateText,
                prefixIcon: Icons.event_outlined,
                readOnly: true,
                onTap: _pickDate,
                validator: (_) => _date == null ? 'Choisissez la date' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(label: 'Dose (facultatif)', hint: '1re dose, rappel...', controller: _dose),
              const SizedBox(height: AppSpacing.md),
              MediTextField(label: 'Remarque (facultatif)', controller: _notes, textInputAction: TextInputAction.done),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              MediButton(label: 'Enregistrer', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre et catégorie d'un document ajouté.
class _DocumentDetailsDialog extends StatefulWidget {
  const _DocumentDetailsDialog();

  @override
  State<_DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<_DocumentDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  DocumentCategory _category = DocumentCategory.analysis;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Détails du document'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Titre', hintText: 'Ex. Bilan sanguin juin 2026'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Donnez un titre au document' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<DocumentCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final c in DocumentCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(children: [Icon(c.icon, size: 18), const SizedBox(width: AppSpacing.sm), Text(c.label)]),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) Navigator.pop(context, (_title.text.trim(), _category));
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
