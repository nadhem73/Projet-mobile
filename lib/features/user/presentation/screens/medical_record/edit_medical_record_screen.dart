import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/constants/medical_specialties.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/presentation/controllers/medical_record_controller.dart';

/// Modification du dossier médical. Revient avec `true` si enregistré.
class EditMedicalRecordScreen extends StatefulWidget {
  const EditMedicalRecordScreen({super.key});

  @override
  State<EditMedicalRecordScreen> createState() => _EditMedicalRecordScreenState();
}

class _EditMedicalRecordScreenState extends State<EditMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MedicalRecordController _controller = getIt<MedicalRecordController>(
    param1: getIt<SessionService>().requireUser.patientId,
  );

  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _allergies = TextEditingController();
  final _chronic = TextEditingController();
  final _treatment = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _insuranceNumber = TextEditingController();

  String? _gender;
  String? _bloodGroup;
  String? _insuranceCompany;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _controller.load().then((_) => _fill());
  }

  void _fill() {
    final r = _controller.record;
    if (r == null || !mounted) return;
    String num(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());
    setState(() {
      _gender = r.gender;
      _bloodGroup = r.bloodGroup;
      _insuranceCompany = r.insuranceCompany;
      _height.text = num(r.height);
      _weight.text = num(r.weight);
      _allergies.text = r.allergies ?? '';
      _chronic.text = r.chronicDiseases ?? '';
      _treatment.text = r.currentTreatment ?? '';
      _contactName.text = r.emergencyContactName ?? '';
      _contactPhone.text = r.emergencyContactPhone ?? '';
      _insuranceNumber.text = r.insuranceNumber ?? '';
      _filled = true;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _height,
      _weight,
      _allergies,
      _chronic,
      _treatment,
      _contactName,
      _contactPhone,
      _insuranceNumber,
    ]) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await _controller.save(
      MedicalRecord(
        patientId: _controller.patientId,
        gender: _gender,
        bloodGroup: _bloodGroup,
        height: _parse(_height.text),
        weight: _parse(_weight.text),
        allergies: _allergies.text,
        chronicDiseases: _chronic.text,
        currentTreatment: _treatment.text,
        emergencyContactName: _contactName.text,
        emergencyContactPhone: _contactPhone.text,
        insuranceCompany: _insuranceCompany,
        insuranceNumber: _insuranceNumber.text,
      ),
    );
    if (!mounted) return;
    if (ok) {
      context.pop(true);
    } else {
      context.showError(_controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon dossier')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_filled) {
            if (_controller.error != null) return EmptyState.error(_controller.error!, onRetry: _controller.load);
            return const LoadingView();
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SectionHeader(title: 'Informations générales'),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  segments: const [
                    ButtonSegment(value: 'F', label: Text('Femme'), icon: Icon(Icons.female_rounded)),
                    ButtonSegment(value: 'M', label: Text('Homme'), icon: Icon(Icons.male_rounded)),
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
                    for (final group in BloodGroups.all)
                      ChoiceChip(
                        label: Text(group),
                        selected: _bloodGroup == group,
                        onSelected: (selected) => setState(() => _bloodGroup = selected ? group : null),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: MediTextField(
                        label: 'Taille (cm)',
                        controller: _height,
                        prefixIcon: Icons.height_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.number(min: 40, max: 250, field: 'La taille'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MediTextField(
                        label: 'Poids (kg)',
                        controller: _weight,
                        prefixIcon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.number(min: 2, max: 400, field: 'Le poids'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Antécédents et traitements'),
                MediTextField(
                  label: 'Allergies',
                  hint: 'Pénicilline, arachides...',
                  helperText: 'Séparez les éléments par des virgules',
                  controller: _allergies,
                  prefixIcon: Icons.warning_amber_rounded,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'Maladies chroniques',
                  hint: 'Diabète, asthme...',
                  helperText: 'Séparez les éléments par des virgules',
                  controller: _chronic,
                  prefixIcon: Icons.monitor_heart_outlined,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'Traitement en cours',
                  hint: 'Médicaments pris régulièrement, posologie...',
                  controller: _treatment,
                  prefixIcon: Icons.medication_outlined,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Contact d\'urgence'),
                MediTextField(
                  label: 'Nom du contact',
                  controller: _contactName,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'Téléphone du contact',
                  controller: _contactPhone,
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.optionalPhone,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Assurance maladie'),
                DropdownButtonFormField<String>(
                  initialValue: InsuranceCompanies.all.contains(_insuranceCompany) ? _insuranceCompany : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Caisse / compagnie',
                    prefixIcon: Icon(Icons.health_and_safety_outlined, size: 20),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Aucune')),
                    for (final c in InsuranceCompanies.all) DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _insuranceCompany = v),
                ),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'N° d\'affilié',
                  controller: _insuranceNumber,
                  prefixIcon: Icons.numbers_rounded,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xl),
                MediButton(
                  label: 'Enregistrer',
                  icon: Icons.check_rounded,
                  isLoading: _controller.isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
