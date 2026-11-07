import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/blocked_slot.dart';
import 'package:medilink/features/doctor/data/repositories/blocked_slot_repository.dart';
import 'package:medilink/features/doctor/presentation/widgets/agenda_timeline.dart';

/// Formulaire « Bloquer un créneau » ; renvoie true si l'indisponibilité a été enregistrée.
Future<bool?> showBlockedSlotForm(BuildContext context, {required DateTime day}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
  builder: (_) => _BlockedSlotForm(day: day),
);

/// Fiche d'une indisponibilité avec bouton « Supprimer » ; renvoie true si elle a été supprimée.
Future<bool?> showBlockedSlotDetail(BuildContext context, BlockedSlot slot) => showModalBottomSheet<bool>(
  context: context,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
  builder: (_) => _BlockedSlotDetail(slot: slot),
);

class _BlockedSlotForm extends StatefulWidget {
  const _BlockedSlotForm({required this.day});

  final DateTime day;

  @override
  State<_BlockedSlotForm> createState() => _BlockedSlotFormState();
}

class _BlockedSlotFormState extends State<_BlockedSlotForm> {
  static const _suggestions = ['Réunion', 'Pause déjeuner', 'Formation', 'Garde', 'Personnel'];

  final _title = TextEditingController();
  final _note = TextEditingController();
  late DateTime _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    _day = widget.day.isBefore(today) ? today : DateUtils.dateOnly(widget.day);
    // Par défaut : prochaine heure pleine aujourd'hui, 09:00 un autre jour ; durée 1 h.
    final startHour = DateUtils.isSameDay(_day, now) ? (now.hour + 1).clamp(0, 22) : 9;
    _start = TimeOfDay(hour: startHour, minute: 0);
    _end = TimeOfDay(hour: startHour + 1, minute: 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) => DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  Future<void> _pickDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (picked == null) return;
    setState(() {
      if (start) {
        // Garde la même durée quand on déplace le début.
        final length = _toMinutes(_end) - _toMinutes(_start);
        _start = picked;
        final end = (_toMinutes(picked) + (length > 0 ? length : 60)).clamp(0, 23 * 60 + 59);
        _end = TimeOfDay(hour: end ~/ 60, minute: end % 60);
      } else {
        _end = picked;
      }
    });
  }

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await getIt<BlockedSlotRepository>().create(
        BlockedSlot(
          doctorId: getIt<SessionService>().requireUser.doctorId!,
          title: _title.text,
          start: _at(_start),
          end: _at(_end),
          note: _note.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('HH:mm');

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bloquer un créneau', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Les patients ne pourront pas réserver sur cette plage.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            MediTextField(
              label: 'Titre *',
              controller: _title,
              hint: 'Ex. Réunion de service',
              prefixIcon: Icons.event_note_rounded,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final s in _suggestions)
                  ActionChip(label: Text(s), onPressed: () => setState(() => _title.text = s)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PickerTile(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: toBeginningOfSentenceCase(DateFormat('EEEE d MMMM y', 'fr').format(_day)),
              onTap: _pickDay,
            ),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_rounded,
                    label: 'Début',
                    value: time.format(_at(_start)),
                    onTap: () => _pickTime(start: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_rounded,
                    label: 'Fin',
                    value: time.format(_at(_end)),
                    onTap: () => _pickTime(start: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            MediTextField(label: 'Note (facultatif)', controller: _note, maxLines: 2, prefixIcon: Icons.notes_rounded),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            MediButton(label: 'Bloquer ce créneau', icon: Icons.lock_rounded, isLoading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: AppColors.primarySurface,
        borderRadius: AppRadius.input,
        child: InkWell(
          borderRadius: AppRadius.input,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                      Text(value, style: theme.textTheme.titleSmall),
                    ],
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

class _BlockedSlotDetail extends StatefulWidget {
  const _BlockedSlotDetail({required this.slot});

  final BlockedSlot slot;

  @override
  State<_BlockedSlotDetail> createState() => _BlockedSlotDetailState();
}

class _BlockedSlotDetailState extends State<_BlockedSlotDetail> {
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await getIt<BlockedSlotRepository>().delete(
        widget.slot.id!,
        doctorId: getIt<SessionService>().requireUser.doctorId!,
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      context.showError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.slot;
    final time = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: blockedSlotColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: blockedSlotColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: toBeginningOfSentenceCase(DateFormat('EEEE d MMMM y', 'fr').format(s.start)),
          ),
          InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Heure',
            value: '${time.format(s.start)} – ${time.format(s.end)}',
          ),
          if (s.note != null) InfoRow(icon: Icons.notes_rounded, label: 'Note', value: s.note),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Les patients ne peuvent pas réserver sur cette plage.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          MediButton.outlined(
            label: 'Supprimer et libérer le créneau',
            icon: Icons.delete_outline_rounded,
            isLoading: _deleting,
            onPressed: _delete,
          ),
        ],
      ),
    );
  }
}
