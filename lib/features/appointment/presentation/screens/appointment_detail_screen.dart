import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/presentation/controllers/appointment_detail_controller.dart';
import 'package:medilink/features/appointment/presentation/widgets/appointment_card.dart';
import 'package:medilink/features/appointment/presentation/widgets/cancel_appointment_dialog.dart';
import 'package:medilink/features/appointment/presentation/widgets/doctor_card.dart';

/// Détail d'un rendez-vous du patient : statut, date, médecin, lieu, motif, annulation.
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final int appointmentId;

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late final AppointmentDetailController _controller = getIt<AppointmentDetailController>(param1: widget.appointmentId)
    ..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancel(Appointment a) async {
    if (!await confirmCancelAppointment(context, a)) return;
    final error = await _controller.cancel();
    if (!mounted) return;
    error == null ? context.showSuccess('Rendez-vous annulé') : context.showError(error);
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
          if (a == null) return EmptyState.error(c.error ?? 'Rendez-vous introuvable', onRetry: c.load);
          return _content(a, c.doctor, c.isCancelling);
        },
      ),
    );
  }

  Widget _content(Appointment a, DoctorSummary? doctor, bool isCancelling) {
    final theme = Theme.of(context);
    final end = a.dateTime.add(AppointmentRepository.slotLength);
    final date = toBeginningOfSentenceCase(DateFormat('EEEE d MMMM y', 'fr').format(a.dateTime));
    final hours = '${DateFormat('HH:mm').format(a.dateTime)} – ${DateFormat('HH:mm').format(end)}';
    final address = [doctor?.address, doctor?.city]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .fold<List<String>>([], (parts, p) => parts.any((x) => x.contains(p)) ? parts : [...parts, p])
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _StatusBanner(appointment: a),
        const SizedBox(height: AppSpacing.lg),

        // Médecin
        MediCard(
          onTap: () => context.push(AppointmentRoutes.doctor(a.doctorId)),
          child: Row(
            children: [
              MediAvatar(initials: a.doctorInitials, size: 52, color: AppColors.moduleAppointment),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.doctorName, style: theme.textTheme.titleMedium),
                    if (a.specialty != null)
                      Text(
                        a.specialty!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.moduleAppointment),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quand, où, combien, pourquoi
        MediCard(
          child: Column(
            children: [
              InfoRow(icon: Icons.event_rounded, label: 'Date', value: date),
              InfoRow(icon: Icons.access_time_rounded, label: 'Heure', value: hours),
              if (address.isNotEmpty) InfoRow(icon: Icons.place_outlined, label: 'Adresse', value: address),
              if (doctor?.fee != null)
                InfoRow(icon: Icons.payments_outlined, label: 'Consultation', value: formatFee(doctor!.fee!)),
              InfoRow(icon: Icons.notes_rounded, label: 'Motif', value: a.reason ?? 'Non précisé'),
              if (a.createdAt != null)
                InfoRow(
                  icon: Icons.history_rounded,
                  label: 'Réservé le',
                  value: DateFormat('d MMMM y', 'fr').format(a.createdAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (a.canCancel)
          MediButton.outlined(
            label: 'Annuler le rendez-vous',
            icon: Icons.event_busy_rounded,
            isLoading: isCancelling,
            onPressed: () => _cancel(a),
          )
        else
          MediButton(
            label: 'Reprendre rendez-vous',
            icon: Icons.event_repeat_rounded,
            onPressed: () => context.push(AppointmentRoutes.doctor(a.doctorId)),
          ),
      ],
    );
  }
}

/// Bandeau coloré en haut : statut + message adapté.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final color = a.status.color;
    final message = switch (a.status) {
      AppointmentState.confirmed when a.isUpcoming =>
        'Votre rendez-vous est confirmé. Pensez à arriver 10 minutes en avance.',
      AppointmentState.pending when a.isUpcoming => 'En attente de confirmation par le médecin.',
      AppointmentState.cancelled => 'Ce rendez-vous a été annulé. Le créneau a été libéré.',
      AppointmentState.completed => 'Consultation terminée.',
      AppointmentState.noShow => 'Vous ne vous êtes pas présenté(e) à ce rendez-vous.',
      _ => 'La date de ce rendez-vous est passée.',
    };
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
