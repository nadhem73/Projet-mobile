import 'package:intl/intl.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/doctor/data/models/blocked_slot.dart';

/// Indisponibilités du médecin (réunion, pause…).
///
/// Le module Rendez-vous lit la même table pour ne plus proposer ni accepter
/// ces créneaux aux patients (`AppointmentRepository.availableSlots` / `book`).
class BlockedSlotRepository {
  BlockedSlotRepository(this._database, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  /// Durée d'un rendez-vous (identique à `AppointmentRepository.slotLength`).
  static const _appointmentLength = Duration(minutes: 30);

  /// Plages du médecin qui chevauchent [from, to), triées par début.
  Future<List<BlockedSlot>> forDoctorBetween(int doctorId, DateTime from, DateTime to) async {
    final rows = await _database.db.query(
      DoctorTables.blockedSlots,
      where: 'doctor_id = ? AND start_time < ? AND end_time > ?',
      whereArgs: [doctorId, BlockedSlot.format(to), BlockedSlot.format(from)],
      orderBy: 'start_time ASC',
    );
    return rows.map(BlockedSlot.fromMap).toList();
  }

  /// Enregistre une indisponibilité.
  ///
  /// Refusée si : titre vide, fin avant le début, plage déjà passée, chevauchement
  /// avec une autre indisponibilité ou avec un rendez-vous patient déjà réservé.
  Future<BlockedSlot> create(BlockedSlot slot) async {
    if (slot.title.trim().isEmpty) throw const AppException('Indiquez un titre (ex. Réunion).', code: 'title');
    if (!slot.end.isAfter(slot.start)) {
      throw const AppException('L\'heure de fin doit être après l\'heure de début.', code: 'range');
    }
    if (!slot.end.isAfter(_clock())) throw const AppException('Cette plage est déjà passée.', code: 'past');

    final others = await forDoctorBetween(slot.doctorId, slot.start, slot.end);
    if (others.isNotEmpty) {
      final o = others.first;
      throw AppException('Cette plage chevauche « ${o.title} » (${_hours(o.start, o.end)}).', code: 'overlap');
    }

    // Un rendez-vous [t, t + 30 min) chevauche [début, fin) si début − 30 min < t < fin.
    final booked = await _database.db.rawQuery(
      'SELECT a.appointment_date_time, u.prenom, u.nom FROM ${AppointmentTables.appointments} a '
      'JOIN patients p ON p.patient_id = a.patient_id JOIN users u ON u.id = p.user_id '
      'WHERE a.doctor_id = ? AND a.status IN (?, ?) '
      'AND a.appointment_date_time > ? AND a.appointment_date_time < ? '
      'ORDER BY a.appointment_date_time LIMIT 1',
      [
        slot.doctorId,
        AppointmentStatus.pending,
        AppointmentStatus.confirmed,
        BlockedSlot.format(slot.start.subtract(_appointmentLength)),
        BlockedSlot.format(slot.end),
      ],
    );
    if (booked.isNotEmpty) {
      final r = booked.first;
      final at = DateTime.parse(r['appointment_date_time'] as String);
      throw AppException(
        '${r['prenom']} ${r['nom']} a déjà un rendez-vous à ${DateFormat('HH:mm').format(at)}. '
        'Choisissez une autre plage.',
        code: 'appointment',
      );
    }

    final id = await _database.db.insert(DoctorTables.blockedSlots, slot.toMap());
    final rows = await _database.db.query(DoctorTables.blockedSlots, where: 'blocked_slot_id = ?', whereArgs: [id]);
    return BlockedSlot.fromMap(rows.first);
  }

  /// Supprime une indisponibilité du médecin (le créneau redevient réservable).
  Future<void> delete(int id, {required int doctorId}) async {
    final count = await _database.db.delete(
      DoctorTables.blockedSlots,
      where: 'blocked_slot_id = ? AND doctor_id = ?',
      whereArgs: [id, doctorId],
    );
    if (count == 0) throw const AppException('Indisponibilité introuvable.', code: 'not_found');
  }

  static String _hours(DateTime from, DateTime to) =>
      '${DateFormat('HH:mm').format(from)} – ${DateFormat('HH:mm').format(to)}';
}
