import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/presentation/widgets/appointment_card.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/controllers/doctor_appointment_detail_controller.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_agenda_tab.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/user_module.dart';

/// Détail d'un rendez-vous pour le médecin (ouvert depuis l'agenda ou « Agenda du jour »).
class DoctorAppointmentDetailScreen extends StatefulWidget {
  const DoctorAppointmentDetailScreen({super.key, required this.appointmentId});

  final int appointmentId;

  @override
  State<DoctorAppointmentDetailScreen> createState() => _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState extends State<DoctorAppointmentDetailScreen> {
  late final DoctorAppointmentDetailController _controller =
      getIt<DoctorAppointmentDetailController>()..load(widget.appointmentId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openConsultation(int consultationId) async {
    await context.push(DoctorRoutes.consultation(consultationId));
    // La consultation a pu être clôturée : rendez-vous « Terminé ».
    await _controller.load(widget.appointmentId);
  }

  Future<void> _start() async {
    final id = await _controller.startConsultation();
    if (!mounted) return;
    if (id == null) {
      context.showError(_controller.error ?? 'Impossible de démarrer la consultation');
      return;
    }
    await _openConsultation(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du rendez-vous')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (c.isLoading && c.appointment == null) return const LoadingView();
          final a = c.appointment;
          if (a == null) {
            return EmptyState.error(c.error ?? 'Rendez-vous introuvable', onRetry: () => c.load(widget.appointmentId));
          }
          return _content(c, a);
        },
      ),
    );
  }

  Widget _content(DoctorAppointmentDetailController c, Appointment a) {
    final end = a.dateTime.add(AppointmentRepository.slotLength);
    final date = toBeginningOfSentenceCase(DateFormat('EEEE d MMMM y', 'fr').format(a.dateTime));
    final hours = '${DateFormat('HH:mm').format(a.dateTime)} – ${DateFormat('HH:mm').format(end)}';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _StatusBanner(appointment: a),
        const SizedBox(height: AppSpacing.lg),

        _PatientCard(
          name: c.patient?.fullName ?? a.patientName,
          patient: c.patient,
          onTap: () => context.push(UserRoutes.doctorPatientRecord(a.patientId)),
        ),
        const SizedBox(height: AppSpacing.md),

        // Créneau et motif
        MediCard(
          child: Column(
            children: [
              InfoRow(icon: Icons.event_rounded, label: 'Date', value: date),
              InfoRow(icon: Icons.access_time_rounded, label: 'Heure', value: hours),
              InfoRow(icon: Icons.notes_rounded, label: 'Motif', value: a.reason ?? 'Non précisé'),
              if (a.createdAt != null)
                InfoRow(
                  icon: Icons.history_rounded,
                  label: 'Réservé le',
                  value: DateFormat("d MMMM y 'à' HH:mm", 'fr').format(a.createdAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (c.record != null) ...[_HealthCard(record: c.record!), const SizedBox(height: AppSpacing.xl)],

        ..._actions(c, a),
      ],
    );
  }

  List<Widget> _actions(DoctorAppointmentDetailController c, Appointment a) {
    final consultation = c.consultation;
    final Widget main;
    String? hint;

    if (consultation != null) {
      main = MediButton(
        label: consultation.isInProgress ? 'Reprendre la consultation' : 'Voir la consultation',
        icon: consultation.isInProgress ? Icons.play_arrow_rounded : Icons.description_outlined,
        onPressed: () => _openConsultation(consultation.id),
      );
    } else {
      hint = AppointmentConsultation.blockedReason(a, DateTime.now());
      main = MediButton(
        label: 'Démarrer la consultation',
        icon: Icons.medical_services_outlined,
        isLoading: c.isStarting,
        onPressed: hint == null ? _start : null,
      );
    }

    return [
      main,
      if (hint != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      MediButton.outlined(
        label: 'Dossier médical',
        icon: Icons.folder_shared_outlined,
        onPressed: () => context.push(UserRoutes.doctorPatientRecord(a.patientId)),
      ),
    ];
  }
}

/// Bandeau coloré : statut + message pour le médecin.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final color = a.status.color;
    final message = switch (a.status) {
      AppointmentState.confirmed when a.isUpcoming => 'Le patient a réservé ce créneau.',
      AppointmentState.pending when a.isUpcoming => 'Demande en attente de confirmation.',
      AppointmentState.cancelled => 'Ce rendez-vous a été annulé. Le créneau a été libéré.',
      AppointmentState.completed => 'Consultation terminée.',
      AppointmentState.noShow => 'Le patient ne s\'est pas présenté.',
      _ => 'L\'heure est passée et la consultation n\'a pas été clôturée.',
    };
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.card),
      child: Row(
        children: [
          Icon(a.status.icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.status.label,
                  style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient : nom, âge, téléphone. Toucher la carte ouvre son dossier médical.
class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.name, required this.patient, required this.onTap});

  final String name;
  final PatientIdentity? patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = patient;
    final details = [if (p?.age != null) '${p!.age} ans', if (p?.phone != null) p!.phone!].join(' · ');

    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          MediAvatar(initials: p?.initials ?? '', size: 52, color: AppColors.moduleDoctor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                if (details.isNotEmpty)
                  Text(details, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Résumé santé utile avant la consultation (dossier médical du patient).
class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.record});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    String? text(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final allergies = r.allergyList.join(', ');
    final chronic = r.chronicDiseaseList.join(', ');
    final rows = [
      if (text(r.bloodGroup) != null)
        InfoRow(icon: Icons.bloodtype_outlined, label: 'Groupe sanguin', value: r.bloodGroup),
      if (allergies.isNotEmpty)
        InfoRow(icon: Icons.warning_amber_rounded, label: 'Allergies', value: allergies, color: AppColors.error),
      if (chronic.isNotEmpty) InfoRow(icon: Icons.monitor_heart_outlined, label: 'Maladies chroniques', value: chronic),
      if (text(r.currentTreatment) != null)
        InfoRow(icon: Icons.medication_outlined, label: 'Traitement en cours', value: r.currentTreatment),
    ];

    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Santé', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            const InfoRow(icon: Icons.info_outline_rounded, label: 'Dossier médical', value: 'Non renseigné')
          else
            ...rows,
        ],
      ),
    );
  }
}
