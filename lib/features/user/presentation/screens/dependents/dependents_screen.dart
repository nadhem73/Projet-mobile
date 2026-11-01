import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/constants/medical_specialties.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/dependent.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/presentation/controllers/dependents_controller.dart';

/// Proches gérés par le patient (enfants, parents...).
class DependentsScreen extends StatefulWidget {
  const DependentsScreen({super.key});

  @override
  State<DependentsScreen> createState() => _DependentsScreenState();
}

class _DependentsScreenState extends State<DependentsScreen> {
  late final DependentsController _controller = getIt<DependentsController>(
    param1: getIt<SessionService>().requireUser.patientId,
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([Dependent? existing]) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => DependentFormScreen(controller: _controller, existing: existing)));
    if (saved == true && mounted) {
      context.showSuccess(existing == null ? 'Proche ajouté' : 'Informations mises à jour');
    }
  }

  Future<void> _delete(Dependent d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Retirer ${d.prenom} de vos proches ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
            ],
          ),
    );
    if (confirm != true) return;
    final error = await _controller.delete(d.id!);
    if (mounted && error != null) context.showError(error);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes proches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Ajouter un proche'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.dependents.isEmpty) return const LoadingView();
          if (_controller.error != null) return EmptyState.error(_controller.error!, onRetry: _controller.load);
          if (_controller.dependents.isEmpty) {
            return const EmptyState(
              icon: Icons.family_restroom_rounded,
              title: 'Aucun proche',
              message: 'Ajoutez vos enfants ou parents pour gérer leurs informations de santé et leurs rendez-vous.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            children: [
              for (final d in _controller.dependents)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MediCard(
                    onTap: () => _openForm(d),
                    child: Row(
                      children: [
                        MediAvatar(initials: d.initials, size: 52, color: AppColors.moduleAppointment),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.fullName, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  d.relation.label,
                                  if (d.age != null) '${d.age} ans',
                                  if (d.bloodGroup != null) 'Groupe ${d.bloodGroup}',
                                ].join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                              if (MedicalRecord.splitList(d.allergies).isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                StatusBadge(
                                  label: 'Allergies : ${MedicalRecord.splitList(d.allergies).join(', ')}',
                                  color: AppColors.error,
                                  icon: Icons.warning_amber_rounded,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retirer',
                          onPressed: () => _delete(d),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Ajout / modification d'un proche. Revient avec `true` si enregistré.
class DependentFormScreen extends StatefulWidget {
  const DependentFormScreen({super.key, required this.controller, this.existing});

  final DependentsController controller;
  final Dependent? existing;

  @override
  State<DependentFormScreen> createState() => _DependentFormScreenState();
}

class _DependentFormScreenState extends State<DependentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _prenom = TextEditingController(text: widget.existing?.prenom);
  late final _nom = TextEditingController(text: widget.existing?.nom ?? getIt<SessionService>().currentUser?.nom);
  late final _allergies = TextEditingController(text: widget.existing?.allergies);
  late DateTime? _birth = widget.existing?.dateNaissance;
  late final _birthText = TextEditingController(text: _birth == null ? '' : DateFormat('dd/MM/yyyy').format(_birth!));
  late DependentRelation _relation = widget.existing?.relation ?? DependentRelation.child;
  late String? _gender = widget.existing?.gender;
  late String? _bloodGroup = widget.existing?.bloodGroup;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _allergies, _birthText]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(DateTime.now().year - 5),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Date de naissance',
    );
    if (picked == null) return;
    setState(() {
      _birth = picked;
      _birthText.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await widget.controller.save(
      Dependent(
        id: widget.existing?.id,
        patientId: widget.controller.patientId,
        nom: _nom.text,
        prenom: _prenom.text,
        relation: _relation,
        dateNaissance: _birth,
        gender: _gender,
        bloodGroup: _bloodGroup,
        allergies: _allergies.text,
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      context.showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Ajouter un proche' : 'Modifier le proche')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Lien de parenté', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final r in DependentRelation.values)
                  ChoiceChip(
                    label: Text(r.label),
                    selected: _relation == r,
                    onSelected: (_) => setState(() => _relation = r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: MediTextField(
                    label: 'Prénom',
                    controller: _prenom,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.required('Le prénom'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MediTextField(
                    label: 'Nom',
                    controller: _nom,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.required('Le nom'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            MediTextField(
              label: 'Date de naissance',
              controller: _birthText,
              prefixIcon: Icons.cake_outlined,
              readOnly: true,
              onTap: _pickBirth,
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: 'F', label: Text('Fille / Femme')),
                ButtonSegment(value: 'M', label: Text('Garçon / Homme')),
              ],
              selected: {if (_gender != null) _gender!},
              onSelectionChanged: (s) => setState(() => _gender = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Groupe sanguin', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in BloodGroups.all)
                  ChoiceChip(
                    label: Text(g),
                    selected: _bloodGroup == g,
                    onSelected: (selected) => setState(() => _bloodGroup = selected ? g : null),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            MediTextField(
              label: 'Allergies',
              hint: 'Séparées par des virgules',
              controller: _allergies,
              prefixIcon: Icons.warning_amber_rounded,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xl),
            MediButton(label: 'Enregistrer', icon: Icons.check_rounded, isLoading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
