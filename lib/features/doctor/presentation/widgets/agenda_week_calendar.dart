import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';

/// Carte « Date du rendez-vous » de l'agenda médecin : mois (sélecteur de date),
/// jours de la semaine avec le jour choisi en pastille verticale, et un point
/// sous les jours qui ont des rendez-vous.
class AgendaWeekCalendar extends StatelessWidget {
  const AgendaWeekCalendar({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.today,
    required this.countOn,
    required this.onSelectDay,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onPickDate,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final DateTime today;
  final int Function(DateTime day) countOn;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<DateTime> onPickDate;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2),
      helpText: 'Aller au jour',
    );
    if (picked != null) onPickDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = toBeginningOfSentenceCase(DateFormat('MMMM y', 'fr').format(selectedDay));

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDeep.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Date du rendez-vous',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              // Pastille du mois : ouvre un sélecteur de date.
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        month,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Glisser à gauche / à droite pour changer de semaine.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -200) onNextWeek();
              if (v > 200) onPreviousWeek();
            },
            child: Row(
              children: [
                _Arrow(icon: Icons.chevron_left_rounded, tooltip: 'Semaine précédente', onTap: onPreviousWeek),
                for (final day in days)
                  Expanded(
                    child: _DayPill(
                      key: ValueKey('agenda-day-${DateFormat('yyyy-MM-dd').format(day)}'),
                      day: day,
                      selected: DateUtils.isSameDay(day, selectedDay),
                      isToday: DateUtils.isSameDay(day, today),
                      count: countOn(day),
                      onTap: () => onSelectDay(day),
                    ),
                  ),
                _Arrow(icon: Icons.chevron_right_rounded, tooltip: 'Semaine suivante', onTap: onNextWeek),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon, color: AppColors.textMuted),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 24, minHeight: 40),
  );
}

/// Un jour : nom court + numéro. Le jour choisi est une pastille verticale pleine.
class _DayPill extends StatelessWidget {
  const _DayPill({
    super.key,
    required this.day,
    required this.selected,
    required this.isToday,
    required this.count,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = toBeginningOfSentenceCase(DateFormat('EEE', 'fr').format(day).replaceAll('.', ''));
    final numberColor =
        selected
            ? Colors.white
            : isToday
            ? AppColors.primary
            : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient:
                selected
                    ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primaryLight, AppColors.primary],
                    )
                    : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white70 : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${day.day}',
                style: theme.textTheme.titleMedium?.copyWith(color: numberColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Point : au moins un rendez-vous ce jour-là.
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      count == 0
                          ? Colors.transparent
                          : selected
                          ? Colors.white
                          : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
