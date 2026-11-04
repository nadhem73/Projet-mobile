import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';

/// Couleur et icône associées à chaque statut de rendez-vous.
extension AppointmentStateStyle on AppointmentState {
  Color get color => switch (this) {
    AppointmentState.pending => AppColors.warning,
    AppointmentState.confirmed => AppColors.success,
    AppointmentState.cancelled => AppColors.error,
    AppointmentState.completed => AppColors.textMuted,
    AppointmentState.noShow => AppColors.accent,
  };

  IconData get icon => switch (this) {
    AppointmentState.pending => Icons.hourglass_top_rounded,
    AppointmentState.confirmed => Icons.check_circle_rounded,
    AppointmentState.cancelled => Icons.cancel_rounded,
    AppointmentState.completed => Icons.task_alt_rounded,
    AppointmentState.noShow => Icons.person_off_rounded,
  };
}

/// Carte d'un rendez-vous : date, médecin, heure, motif et statut.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, this.onTap, this.onCancel});

  final Appointment appointment;
  final VoidCallback? onTap;

  /// Affiche un bouton « Annuler » si fourni (et si le rendez-vous est annulable).
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = appointment;
    final muted = !a.status.isActive;

    return MediCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBox(date: a.dateTime, muted: muted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.doctorName, style: theme.textTheme.titleMedium),
                    if (a.specialty != null) ...[
                      const SizedBox(height: 2),
                      Text(a.specialty!, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    StatusBadge(label: a.status.label, color: a.status.color, icon: a.status.icon),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.moduleAppointment),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  DateFormat("EEEE d MMMM 'à' HH:mm", 'fr').format(a.dateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (a.reason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.notes_rounded, size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(a.reason!, style: theme.textTheme.bodySmall)),
              ],
            ),
          ],
          if (onCancel != null && a.canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.event_busy_rounded, size: 18),
                label: const Text('Annuler'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.date, required this.muted});

  final DateTime date;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textMuted : AppColors.moduleAppointment;
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.card),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(
            DateFormat('MMM', 'fr').format(date).replaceAll('.', ''),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
