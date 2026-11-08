import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_agenda_controller.dart';
import 'package:medilink/features/appointment/presentation/widgets/appointment_card.dart';

/// Agenda du médecin connecté : semaine en haut, rendez-vous du jour choisi en dessous.
///
/// Utilisable comme page (route `AppointmentRoutes.doctorAgenda`) ou comme onglet
/// du tableau de bord médecin (module Médecin).
class DoctorAgendaScreen extends StatefulWidget {
  const DoctorAgendaScreen({super.key, this.onAppointmentTap});

  /// Action au tap sur un rendez-vous (ex. démarrer la consultation, module Médecin).
  final ValueChanged<Appointment>? onAppointmentTap;

  @override
  State<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends State<DoctorAgendaScreen> {
  late final DoctorAgendaController _controller = getIt<DoctorAgendaController>()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon agenda'),
        actions: [
          TextButton.icon(
            onPressed: _controller.goToToday,
            icon: const Icon(Icons.today_rounded),
            label: const Text("Aujourd'hui"),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return Column(children: [_WeekHeader(controller: c), const Divider(height: 1), Expanded(child: _dayList(c))]);
        },
      ),
    );
  }

  Widget _dayList(DoctorAgendaController c) {
    if (c.isLoading && c.weekAppointments.isEmpty) return const LoadingView();
    if (c.error != null) return EmptyState.error(c.error!, onRetry: c.load);

    final day = c.selectedDay;
    final items = c.dayAppointments;
    final theme = Theme.of(context);
    final title = toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr').format(day));

    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              Text(
                items.isEmpty ? 'Aucun rendez-vous' : '${items.length} rendez-vous',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: Icons.event_available_rounded,
                title: 'Journée libre',
                message: 'Aucun patient n\'a réservé ce jour-là.',
              ),
            )
          else
            for (final a in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _AgendaTile(
                  appointment: a,
                  onTap: widget.onAppointmentTap == null ? null : () => widget.onAppointmentTap!(a),
                ),
              ),
        ],
      ),
    );
  }
}

/// « < 2 – 8 novembre 2026 > » + les 7 jours de la semaine avec le nombre de rendez-vous.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.controller});

  final DoctorAgendaController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Semaine précédente',
                onPressed: c.previousWeek,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(_weekLabel(c.weekStart), textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: 'Semaine suivante',
                onPressed: c.nextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final day in c.weekDays)
                Expanded(
                  child: _DayCell(
                    key: ValueKey('agenda-day-${DateFormat('yyyy-MM-dd').format(day)}'),
                    day: day,
                    count: c.countOn(day),
                    selected: DateUtils.isSameDay(day, c.selectedDay),
                    isToday: DateUtils.isSameDay(day, c.today),
                    onTap: () => c.selectDay(day),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// « 2 – 8 novembre 2026 » ou « 28 oct. – 3 nov. 2026 » si la semaine change de mois.
  static String _weekLabel(DateTime monday) {
    final sunday = DateUtils.addDaysToDate(monday, 6);
    if (monday.month == sunday.month) {
      return '${monday.day} – ${DateFormat('d MMMM y', 'fr').format(sunday)}';
    }
    return '${DateFormat('d MMM', 'fr').format(monday)} – ${DateFormat('d MMM y', 'fr').format(sunday)}';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.count,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.moduleAppointment;
    final fg = selected ? Colors.white : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? accent : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: isToday && !selected ? const BorderSide(color: accent, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE', 'fr').format(day).replaceAll('.', ''),
                  style: theme.textTheme.labelSmall?.copyWith(color: selected ? Colors.white70 : AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: theme.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                // Pastille : nombre de rendez-vous du jour (rien si 0).
                SizedBox(
                  height: 18,
                  child:
                      count == 0
                          ? null
                          : Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '$count',
                              style: theme.textTheme.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w700),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un rendez-vous dans l'agenda : heure, patient, motif, statut.
class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = appointment;
    final end = a.dateTime.add(AppointmentRepository.slotLength);
    final time = DateFormat('HH:mm');

    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  time.format(a.dateTime),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(time.format(end), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            width: 3,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: a.status.color, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.patientName, style: theme.textTheme.titleSmall),
                if (a.reason != null) ...[
                  const SizedBox(height: 2),
                  Text(a.reason!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(label: a.status.label, color: a.status.color, icon: a.status.icon),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
