/// Plage où le médecin n'est pas disponible (table `doctor_blocked_slots`) :
/// réunion, pause, formation… Les patients ne peuvent pas réserver dessus.
class BlockedSlot {
  const BlockedSlot({
    this.id,
    required this.doctorId,
    required this.title,
    required this.start,
    required this.end,
    this.note,
  });

  final int? id;
  final int doctorId;
  final String title;

  /// Début (inclus) et fin (exclue), heure locale.
  final DateTime start;
  final DateTime end;
  final String? note;

  Duration get duration => end.difference(start);

  /// Chevauche la plage [from, to) ?
  bool overlaps(DateTime from, DateTime to) => start.isBefore(to) && end.isAfter(from);

  /// Format stocké en base : 2026-11-10T09:00:00 (sans fuseau, heure locale).
  static String format(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute).toIso8601String().substring(0, 19);

  factory BlockedSlot.fromMap(Map<String, Object?> map) => BlockedSlot(
    id: map['blocked_slot_id'] as int,
    doctorId: map['doctor_id'] as int,
    title: map['title'] as String,
    start: DateTime.parse(map['start_time'] as String),
    end: DateTime.parse(map['end_time'] as String),
    note: map['note'] as String?,
  );

  Map<String, Object?> toMap() => {
    'doctor_id': doctorId,
    'title': title.trim(),
    'start_time': format(start),
    'end_time': format(end),
    'note': (note == null || note!.trim().isEmpty) ? null : note!.trim(),
  };
}
