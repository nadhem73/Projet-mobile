import 'dart:convert';

/// Plage horaire d'une journée, ex. 08:30-12:30 (en minutes depuis minuit).
class TimeRange {
  const TimeRange(this.startMinutes, this.endMinutes);

  final int startMinutes;
  final int endMinutes;

  /// Lit une plage au format "HH:MM-HH:MM". Renvoie null si le format est invalide.
  static TimeRange? tryParse(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return null;
    final start = _minutes(parts[0]);
    final end = _minutes(parts[1]);
    if (start == null || end == null || end <= start) return null;
    return TimeRange(start, end);
  }

  static int? _minutes(String hhmm) {
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  @override
  String toString() => '${_format(startMinutes)}-${_format(endMinutes)}';

  static String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

/// Horaires de travail d'un médecin (colonne `doctor_profiles.working_hours`).
///
/// Format JSON en base : `{"mon":["08:30-12:30","14:00-17:00"], "sat":["09:00-12:00"]}`.
/// Un jour absent = jour de fermeture.
class WorkingHours {
  const WorkingHours(this.days);

  /// Clé : jour de la semaine au format [DateTime.weekday] (1 = lundi ... 7 = dimanche).
  final Map<int, List<TimeRange>> days;

  static const empty = WorkingHours({});

  static const _dayKeys = {'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7};

  /// Lit le JSON stocké en base. Un JSON absent ou invalide donne des horaires vides.
  factory WorkingHours.fromJson(String? json) {
    if (json == null || json.trim().isEmpty) return empty;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return empty;
      final days = <int, List<TimeRange>>{};
      decoded.forEach((key, value) {
        final weekday = _dayKeys[key];
        if (weekday == null || value is! List) return;
        final ranges = value.whereType<String>().map(TimeRange.tryParse).whereType<TimeRange>().toList();
        if (ranges.isNotEmpty) days[weekday] = ranges;
      });
      return WorkingHours(days);
    } on FormatException {
      return empty;
    }
  }

  String toJson() {
    final keyOf = {for (final e in _dayKeys.entries) e.value: e.key};
    return jsonEncode({
      for (final e in days.entries) keyOf[e.key]!: [for (final r in e.value) r.toString()],
    });
  }

  bool isOpenOn(DateTime day) => days.containsKey(day.weekday);

  /// Tous les créneaux théoriques d'une journée (sans tenir compte des rendez-vous déjà pris).
  ///
  /// Un créneau n'est proposé que s'il se termine avant la fin de la plage.
  List<DateTime> slotsFor(DateTime day, {Duration slotLength = const Duration(minutes: 30)}) {
    final step = slotLength.inMinutes;
    if (step <= 0) return const [];
    final slots = <DateTime>[];
    for (final range in days[day.weekday] ?? const <TimeRange>[]) {
      for (var m = range.startMinutes; m + step <= range.endMinutes; m += step) {
        slots.add(DateTime(day.year, day.month, day.day, m ~/ 60, m % 60));
      }
    }
    return slots;
  }
}
