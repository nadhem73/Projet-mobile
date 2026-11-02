import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/controllers/consultation_controller.dart';
import 'package:medilink/features/doctor/presentation/widgets/prescription_tile.dart';
import 'package:medilink/features/user/user_module.dart';

/// Consultation vue par le médecin : saisie clinique, ordonnances, clôture.
/// Une consultation clôturée s'affiche en lecture seule.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key, required this.consultationId});

  final int consultationId;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _controller = getIt<ConsultationController>();
  final _motif = TextEditingController();
  final _diagnostic = TextEditingController();
  final _observation = TextEditingController();
  final _bloodPressure = TextEditingController();
  final _temperature = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  DateTime? _followUp;

  @override
  void initState() {
    super.initState();
    _controller.load(widget.consultationId).then((_) => _fill());
    for (final c in [_height, _weight]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in [_motif, _diagnostic, _observation, _bloodPressure, _temperature, _height, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill() {
    final c = _controller.consultation;
    if (c == null || !mounted) return;
    String num(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
    _motif.text = c.motif ?? '';
    _diagnostic.text = c.diagnostic ?? '';
    _observation.text = c.observation ?? '';
    _bloodPressure.text = c.vitals.bloodPressure ?? '';
    _temperature.text = num(c.vitals.temperature);
    _height.text = num(c.vitals.height);
    _weight.text = num(c.vitals.weight);
    _followUp = c.followUpDate;
    // Taille et poids du dossier médical si la consultation n'en a pas encore.
    final record = _controller.record;
    if (c.isInProgress && record != null) {
      if (_height.text.isEmpty) _height.text = num(record.height);
      if (_weight.text.isEmpty) _weight.text = num(record.weight);
    }
  }

  /// Nombre saisi (virgule acceptée). Renvoie null si vide, NaN si invalide.
  double? _parse(TextEditingController c) {
    final text = c.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? double.nan;
  }

  VitalSigns? _readVitals() {
    final values = [_temperature, _height, _weight].map(_parse).toList();
    if (values.any((v) => v != null && v.isNaN)) {
      context.showError('Les constantes doivent être des nombres.');
      return null;
    }
    final bp = _bloodPressure.text.trim();
    return VitalSigns(
      bloodPressure: bp.isEmpty ? null : bp,
      temperature: values[0],
      height: values[1],
      weight: values[2],
    );
  }

  Future<void> _save() async {
    final vitals = _readVitals();
    if (vitals == null) return;
    final error = await _controller.save(
      motif: _motif.text,
      diagnostic: _diagnostic.text,
      observation: _observation.text,
      vitals: vitals,
    );
    if (!mounted) return;
    error == null ? context.showSuccess('Consultation enregistrée') : context.showError(error);
  }

  Future<void> _close() async {
    final vitals = _readVitals();
    if (vitals == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clôturer la consultation ?'),
            content: Text(
              _controller.prescriptions.isEmpty
                  ? 'Aucune ordonnance n\'a été rédigée. La consultation ne sera plus modifiable.'
                  : 'Le patient recevra ${_controller.prescriptions.length == 1 ? 'son ordonnance' : 'ses ${_controller.prescriptions.length} ordonnances'}. '
                      'La consultation ne sera plus modifiable.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clôturer')),
            ],
          ),
    );
    if (confirmed != true) return;
    final error = await _controller.saveAndClose(
      motif: _motif.text,
      diagnostic: _diagnostic.text,
      observation: _observation.text,
      vitals: vitals,
      followUpDate: _followUp,
    );
    if (!mounted) return;
    error == null ? context.showSuccess('Consultation clôturée') : context.showError(error);
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUp ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('fr'),
    );
    if (picked != null) setState(() => _followUp = picked);
  }

  Future<void> _newPrescription() async {
    // Enregistrer d'abord la saisie pour ne rien perdre.
    final vitals = _readVitals();
    if (vitals == null) return;
    final error = await _controller.save(
      motif: _motif.text,
      diagnostic: _diagnostic.text,
      observation: _observation.text,
      vitals: vitals,
    );
    if (!mounted) return;
    if (error != null) {
      context.showError(error);
      return;
    }
    final created = await context.push<bool>(DoctorRoutes.prescriptionFor(widget.consultationId));
    await _controller.refreshPrescriptions();
    if (created == true && mounted) context.showSuccess('Ordonnance enregistrée');
  }

  Future<void> _deletePrescription(Prescription p) async {
    final error = await _controller.deletePrescription(p);
    if (!mounted) return;
    error == null ? context.showSuccess('Ordonnance supprimée') : context.showError(error);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller.consultation;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Consultation'),
            actions: [
              if (c != null)
                IconButton(
                  tooltip: 'Dossier médical',
                  icon: const Icon(Icons.folder_shared_outlined),
                  onPressed: () => context.push(UserRoutes.doctorPatientRecord(c.patientId)),
                ),
            ],
          ),
          body: _body(c),
        );
      },
    );
  }

  Widget _body(Consultation? c) {
    if (_controller.isLoading && c == null) return const LoadingView();
    if (c == null) {
      return EmptyState.error(
        _controller.error ?? 'Consultation introuvable',
        onRetry: () => _controller.load(widget.consultationId).then((_) => _fill()),
      );
    }
    final editable = c.isInProgress;
    final theme = Theme.of(context);
    final bmi = VitalSigns(height: _parse(_height), weight: _parse(_weight)).bmi;
    final allergies = _controller.record?.allergyList ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _PatientHeader(consultation: c),
        if (allergies.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), _AllergyBanner(allergies: allergies)],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Constantes'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _vital('Tension', _bloodPressure, 'cmHg', editable, hint: '12/8', numeric: false)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _vital('Température', _temperature, '°C', editable)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _vital('Taille', _height, 'cm', editable)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _vital('Poids', _weight, 'kg', editable)),
          ],
        ),
        if (bmi != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('IMC : ${bmi.toStringAsFixed(1)}', style: theme.textTheme.titleSmall),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Examen clinique'),
        const SizedBox(height: AppSpacing.sm),
        MediTextField(label: 'Motif de consultation', controller: _motif, maxLines: 2, readOnly: !editable),
        const SizedBox(height: AppSpacing.md),
        MediTextField(label: 'Observation / examen', controller: _observation, maxLines: 4, readOnly: !editable),
        const SizedBox(height: AppSpacing.md),
        MediTextField(label: 'Diagnostic', controller: _diagnostic, maxLines: 2, readOnly: !editable),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Ordonnances',
          actionLabel: editable ? 'Nouvelle' : null,
          onAction: editable ? _newPrescription : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_controller.prescriptions.isEmpty)
          Text('Aucune ordonnance.', style: theme.textTheme.bodyMedium)
        else
          for (final p in _controller.prescriptions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PrescriptionTile(
                prescription: p,
                showPatient: false,
                onTap: () => context.push(DoctorRoutes.prescription(p.id)),
                onDelete: editable ? () => _deletePrescription(p) : null,
              ),
            ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Suivi'),
        const SizedBox(height: AppSpacing.sm),
        MediCard(
          onTap: editable ? _pickFollowUp : null,
          child: Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _followUp == null
                      ? (editable ? 'Programmer un contrôle (facultatif)' : 'Pas de contrôle prévu')
                      : 'Contrôle le ${DateFormat('d MMMM yyyy', 'fr').format(_followUp!)}',
                ),
              ),
              if (editable && _followUp != null)
                IconButton(
                  tooltip: 'Retirer',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _followUp = null),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (editable) ...[
          MediButton.outlined(
            label: 'Enregistrer',
            icon: Icons.save_outlined,
            isLoading: _controller.isSaving,
            onPressed: _controller.isSaving ? null : _save,
          ),
          const SizedBox(height: AppSpacing.md),
          MediButton(
            label: 'Clôturer la consultation',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _controller.isSaving ? null : _close,
          ),
        ] else
          Center(
            child: StatusBadge(
              label:
                  c.endTime == null
                      ? 'Consultation clôturée'
                      : 'Clôturée le ${DateFormat("d MMM yyyy 'à' HH:mm", 'fr').format(c.endTime!)}',
              color: AppColors.success,
              icon: Icons.lock_outline_rounded,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _vital(
    String label,
    TextEditingController controller,
    String unit,
    bool editable, {
    String? hint,
    bool numeric = true,
  }) {
    return MediTextField(
      label: label,
      controller: controller,
      hint: hint,
      readOnly: !editable,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.datetime,
      suffix: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Text(unit, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.consultation});

  final Consultation consultation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = consultation;
    final age = c.ageAt(DateTime.now());
    final initials = c.patientName.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
    return MediCard(
      child: Row(
        children: [
          MediAvatar(initials: initials.toUpperCase(), size: 52),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.patientName, style: theme.textTheme.titleMedium),
                Text(
                  [
                    if (age != null) '$age ans',
                    if (c.startTime != null) DateFormat("d MMM yyyy 'à' HH:mm", 'fr').format(c.startTime!),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: c.isInProgress ? 'En cours' : 'Clôturée',
            color: c.isInProgress ? AppColors.info : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _AllergyBanner extends StatelessWidget {
  const _AllergyBanner({required this.allergies});

  final List<String> allergies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: AppRadius.card),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Allergies : ${allergies.join(', ')}',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
