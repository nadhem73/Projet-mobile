import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/doctor/data/models/blocked_slot.dart';

/// Couleur d'un rendez-vous dans la frise (palette MediLink).
Color agendaColor(Appointment a, DateTime now) => switch (a.status) {
  AppointmentState.completed => AppColors.success,
  AppointmentState.pending => AppColors.warning,
  AppointmentState.cancelled || AppointmentState.noShow => AppColors.textMuted,
  // Confirmé : vert MediLink, orange si l'heure est passée sans clôture.
  AppointmentState.confirmed =>
    a.dateTime.add(AppointmentRepository.slotLength).isBefore(now) ? AppColors.accent : AppColors.primary,
};

/// Couleur des indisponibilités du médecin (réunion, pause…).
const Color blockedSlotColor = AppColors.moduleAdmin;

/// Frise verticale d'une journée : rendez-vous patients et indisponibilités du
/// médecin, triés par heure. Heure à gauche, ligne et pastille au centre, fiche
/// à droite. Si [showNow], une ligne « maintenant » est insérée au bon endroit.
class AgendaTimeline extends StatelessWidget {
  const AgendaTimeline({
    super.key,
    required this.appointments,
    this.blocks = const [],
    required this.now,
    required this.showNow,
    this.onTap,
    this.onBlockTap,
  });

  final List<Appointment> appointments;
  final List<BlockedSlot> blocks;
  final DateTime now;

  /// Afficher la ligne « maintenant » (jour sélectionné = aujourd'hui).
  final bool showNow;
  final ValueChanged<Appointment>? onTap;
  final ValueChanged<BlockedSlot>? onBlockTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm');
    final entries = <_Entry>[
      for (final a in appointments)
        _Entry(
          start: a.dateTime,
          title: a.patientName,
          chip: a.status.label,
          color: agendaColor(a, now),
          marker: a.status == AppointmentState.completed ? Icons.check_rounded : null,
          lines: [
            (Icons.notes_rounded, a.reason ?? 'Motif non précisé'),
            (Icons.calendar_today_rounded, _longDate(a.dateTime)),
            (
              Icons.access_time_rounded,
              '${time.format(a.dateTime)} – ${time.format(a.dateTime.add(AppointmentRepository.slotLength))}',
            ),
          ],
          onTap: onTap == null ? null : () => onTap!(a),
        ),
      for (final b in blocks)
        _Entry(
          start: b.start,
          title: b.title,
          chip: 'Indisponible',
          color: blockedSlotColor,
          marker: Icons.lock_rounded,
          lines: [
            if (b.note != null) (Icons.notes_rounded, b.note!),
            (Icons.calendar_today_rounded, _longDate(b.start)),
            (Icons.access_time_rounded, '${time.format(b.start)} – ${time.format(b.end)}'),
          ],
          onTap: onBlockTap == null ? null : () => onBlockTap!(b),
        ),
    ]..sort((x, y) => x.start.compareTo(y.start));

    final nowIndex = showNow ? entries.indexWhere((e) => e.start.isAfter(now)) : -1;
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i == nowIndex) children.add(_NowLine(now: now));
      children.add(_TimelineEntry(entry: entries[i], isFirst: i == 0, isLast: i == entries.length - 1));
    }
    if (showNow && nowIndex == -1) children.add(_NowLine(now: now));
    return Column(children: children);
  }

  static String _longDate(DateTime d) => toBeginningOfSentenceCase(DateFormat('EEEE d MMMM y', 'fr').format(d));
}

/// Une ligne de la frise (rendez-vous ou indisponibilité).
class _Entry {
  const _Entry({
    required this.start,
    required this.title,
    required this.chip,
    required this.color,
    required this.lines,
    this.marker,
    this.onTap,
  });

  final DateTime start;
  final String title;
  final String chip;
  final Color color;
  final List<(IconData, String)> lines;

  /// Icône dans la pastille (coche, cadenas) ; point plein si null.
  final IconData? marker;
  final VoidCallback? onTap;
}

const double _timeWidth = 52;
const double _railWidth = 32;

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.isFirst, required this.isLast});

  final _Entry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = entry;
    const rail = AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heure
          SizedBox(
            width: _timeWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                DateFormat('HH:mm').format(e.start),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Ligne + pastille
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                Container(width: 2, height: 4, color: isFirst ? Colors.transparent : rail),
                _Marker(color: e.color, icon: e.marker),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : rail)),
              ],
            ),
          ),
          // Fiche
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Material(
                color: e.color.withValues(alpha: 0.06),
                borderRadius: AppRadius.card,
                child: InkWell(
                  borderRadius: AppRadius.card,
                  onTap: e.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.card,
                      border: Border(left: BorderSide(color: e.color, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: e.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _StatusChip(label: e.chip, color: e.color),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final (icon, text) in e.lines) _Line(icon: icon, text: text),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de la frise : anneau coloré avec une icône (coche, cadenas) ou un point.
class _Marker extends StatelessWidget {
  const _Marker({required this.color, this.icon});

  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child:
          icon != null
              ? Icon(icon, size: 12, color: color)
              : Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
        ],
      ),
    );
  }
}

/// Ligne « maintenant » : heure actuelle, point et trait sur une bande claire.
class _NowLine extends StatelessWidget {
  const _NowLine({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primarySurface, AppColors.primarySurface.withValues(alpha: 0)]),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: _timeWidth,
              child: Text(
                DateFormat('HH:mm').format(now),
                style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              width: _railWidth,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                ),
              ),
            ),
            Expanded(child: Container(height: 2, color: AppColors.primary)),
            const SizedBox(width: AppSpacing.sm),
            Text('Maintenant', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
