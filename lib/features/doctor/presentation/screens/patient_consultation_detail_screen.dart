import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/controllers/patient_consultations_controller.dart';
import 'package:medilink/features/doctor/presentation/widgets/prescription_tile.dart';

/// Côté patient : compte rendu en lecture seule d'une consultation clôturée
/// (motif, constantes, diagnostic, contrôle conseillé, ordonnances).
class PatientConsultationDetailScreen extends StatefulWidget {
  const PatientConsultationDetailScreen({super.key, required this.consultationId});

  final int consultationId;

  @override
  State<PatientConsultationDetailScreen> createState() => _PatientConsultationDetailScreenState();
}

class _PatientConsultationDetailScreenState extends State<PatientConsultationDetailScreen> {
  late final _controller = getIt<PatientConsultationsController>()..loadDetail(widget.consultationId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller.consultation;
          if (_controller.isLoading && c == null) return const LoadingView();
          if (c == null) {
            return EmptyState.error(
              _controller.error ?? 'Consultation introuvable.',
              onRetry: () => _controller.loadDetail(widget.consultationId),
            );
          }
          return _content(context, c);
        },
      ),
    );
  }

  Widget _content(BuildContext context, Consultation c) {
    final theme = Theme.of(context);
    final v = c.vitals;
    final bmi = v.bmi;
    String fmt(double value) => NumberFormat('0.#', 'fr').format(value);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MediCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.doctorName, style: theme.textTheme.titleMedium),
              if (c.doctorSpecialty != null) Text(c.doctorSpecialty!, style: theme.textTheme.bodySmall),
              const Divider(height: AppSpacing.xl),
              if (c.startTime != null)
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: DateFormat("d MMMM yyyy 'à' HH:mm", 'fr').format(c.startTime!),
                ),
              if (c.followUpDate != null)
                InfoRow(
                  icon: Icons.event_repeat_rounded,
                  label: 'Contrôle conseillé',
                  value: DateFormat('d MMMM yyyy', 'fr').format(c.followUpDate!),
                ),
            ],
          ),
        ),
        if (!v.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Constantes'),
          const SizedBox(height: AppSpacing.sm),
          MediCard(
            child: Column(
              children: [
                if (v.bloodPressure != null)
                  InfoRow(icon: Icons.favorite_outline_rounded, label: 'Tension', value: '${v.bloodPressure} cmHg'),
                if (v.temperature != null)
                  InfoRow(icon: Icons.thermostat_rounded, label: 'Température', value: '${fmt(v.temperature!)} °C'),
                if (v.height != null)
                  InfoRow(icon: Icons.height_rounded, label: 'Taille', value: '${fmt(v.height!)} cm'),
                if (v.weight != null)
                  InfoRow(icon: Icons.monitor_weight_outlined, label: 'Poids', value: '${fmt(v.weight!)} kg'),
                if (bmi != null) InfoRow(icon: Icons.calculate_outlined, label: 'IMC', value: fmt(bmi)),
              ],
            ),
          ),
        ],
        for (final (title, text) in [('Motif', c.motif), ('Observation', c.observation), ('Diagnostic', c.diagnostic)])
          if ((text ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: title),
            const SizedBox(height: AppSpacing.sm),
            MediCard(child: SizedBox(width: double.infinity, child: Text(text!))),
          ],
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Ordonnances (${_controller.prescriptions.length})'),
        const SizedBox(height: AppSpacing.sm),
        if (_controller.prescriptions.isEmpty)
          Text('Aucune ordonnance pour cette consultation.', style: theme.textTheme.bodyMedium)
        else
          for (final p in _controller.prescriptions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PrescriptionTile(
                prescription: p,
                showPatient: false,
                onTap: () => context.push(DoctorRoutes.prescription(p.id)),
              ),
            ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
