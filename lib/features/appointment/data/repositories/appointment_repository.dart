import 'package:flutter/foundation.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Rendez-vous : consultation, créneaux libres, réservation, annulation.
///
/// Règle §14 : un créneau ne peut pas être réservé par deux patients
/// (vérifié ici, et garanti par l'index unique `ux_appointments_slot`).
class AppointmentRepository {
  AppointmentRepository(this._database, this._doctors, this._notifications, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DoctorSearchRepository _doctors;
  final NotificationService _notifications;
  final DateTime Function() _clock;

  /// Prévient les écrans qu'un rendez-vous a été pris ou annulé (pour recharger leurs listes).
  final ValueNotifier<int> changes = ValueNotifier(0);

  /// Durée d'un rendez-vous (écart entre deux heures proposées).
  static const slotLength = Duration(minutes: 30);

  /// Statut donné à un nouveau rendez-vous.
  /// Mettre `pending` si le médecin doit confirmer chaque demande.
  static const initialStatus = AppointmentState.confirmed;

  static const _active = "('${AppointmentStatus.pending}','${AppointmentStatus.confirmed}')";

  // Rendez-vous + nom du médecin, spécialité, nom du patient.
  static const _select = '''
    SELECT a.*, d.specialty,
           du.nom AS doctor_nom, du.prenom AS doctor_prenom,
           pu.nom AS patient_nom, pu.prenom AS patient_prenom
    FROM appointments a
    JOIN doctors d   ON d.doctor_id = a.doctor_id
    JOIN users du    ON du.id = d.user_id
    JOIN patients p  ON p.patient_id = a.patient_id
    JOIN users pu    ON pu.id = p.user_id
  ''';

  // ---------------------------------------------------------------------------
  // Lecture
  // ---------------------------------------------------------------------------

  Future<Appointment?> byId(int appointmentId) async {
    final rows = await _database.db.rawQuery('$_select WHERE a.appointment_id = ? LIMIT 1', [appointmentId]);
    return rows.isEmpty ? null : Appointment.fromMap(rows.first);
  }

  /// Rendez-vous à venir du patient (en attente ou confirmés), du plus proche au plus lointain.
  Future<List<Appointment>> upcomingForPatient(int patientId) async {
    final rows = await _database.db.rawQuery(
      '$_select WHERE a.patient_id = ? AND a.status IN $_active AND a.appointment_date_time >= ? '
      'ORDER BY a.appointment_date_time ASC',
      [patientId, Appointment.formatDateTime(_clock())],
    );
    return rows.map(Appointment.fromMap).toList();
  }

  /// Historique du patient : rendez-vous passés, annulés ou terminés, du plus récent au plus ancien.
  Future<List<Appointment>> pastForPatient(int patientId) async {
    final rows = await _database.db.rawQuery(
      '$_select WHERE a.patient_id = ? AND NOT (a.status IN $_active AND a.appointment_date_time >= ?) '
      'ORDER BY a.appointment_date_time DESC',
      [patientId, Appointment.formatDateTime(_clock())],
    );
    return rows.map(Appointment.fromMap).toList();
  }

  /// Rendez-vous non annulés d'un médecin pour une journée (pour son agenda).
  Future<List<Appointment>> forDoctorOnDay(int doctorId, DateTime day) async {
    final rows = await _database.db.rawQuery(
      "$_select WHERE a.doctor_id = ? AND a.status <> '${AppointmentStatus.cancelled}' "
      'AND a.appointment_date_time LIKE ? ORDER BY a.appointment_date_time ASC',
      [doctorId, '${_dayKey(day)}%'],
    );
    return rows.map(Appointment.fromMap).toList();
  }

  /// Rendez-vous non annulés d'un médecin entre [from] (inclus) et [to] (exclu),
  /// triés par date. Sert à l'agenda de la semaine.
  Future<List<Appointment>> forDoctorBetween(int doctorId, DateTime from, DateTime to) async {
    final rows = await _database.db.rawQuery(
      "$_select WHERE a.doctor_id = ? AND a.status <> '${AppointmentStatus.cancelled}' "
      'AND a.appointment_date_time >= ? AND a.appointment_date_time < ? '
      'ORDER BY a.appointment_date_time ASC',
      [doctorId, Appointment.formatDateTime(from), Appointment.formatDateTime(to)],
    );
    return rows.map(Appointment.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Créneaux libres
  // ---------------------------------------------------------------------------

  /// Heures encore réservables chez ce médecin pour ce jour :
  /// horaires de travail, moins les créneaux déjà pris, moins les heures déjà passées.
  Future<List<DateTime>> availableSlots(int doctorId, DateTime day) async {
    final doctor = await _doctors.byId(doctorId);
    if (doctor == null) return const [];

    final taken = await _takenSlots(doctorId, day);
    final now = _clock();
    return doctor.workingHours
        .slotsFor(day, slotLength: slotLength)
        .where((slot) => slot.isAfter(now) && !taken.contains(Appointment.formatDateTime(slot)))
        .toList();
  }

  Future<Set<String>> _takenSlots(int doctorId, DateTime day) async {
    final rows = await _database.db.rawQuery(
      "SELECT appointment_date_time FROM appointments WHERE doctor_id = ? AND status <> '${AppointmentStatus.cancelled}' "
      'AND appointment_date_time LIKE ?',
      [doctorId, '${_dayKey(day)}%'],
    );
    return {for (final r in rows) r['appointment_date_time'] as String};
  }

  // ---------------------------------------------------------------------------
  // Réservation / annulation
  // ---------------------------------------------------------------------------

  /// Réserve un créneau pour le patient et prévient le médecin.
  ///
  /// Lève une [AppException] si le créneau est passé, hors horaires ou déjà pris.
  Future<Appointment> book({
    required int patientId,
    required int doctorId,
    required DateTime dateTime,
    String? reason,
  }) async {
    final slot = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);

    if (!slot.isAfter(_clock())) {
      throw const AppException('Ce créneau est déjà passé.', code: 'slot_past');
    }

    final doctor = await _doctors.byId(doctorId);
    if (doctor == null) {
      throw const AppException("Ce médecin n'accepte pas de rendez-vous pour le moment.", code: 'doctor_unavailable');
    }
    if (!doctor.workingHours.slotsFor(slot, slotLength: slotLength).contains(slot)) {
      throw const AppException('Ce créneau ne fait pas partie des horaires du médecin.', code: 'slot_closed');
    }

    final key = Appointment.formatDateTime(slot);
    final clash = await _database.db.rawQuery(
      'SELECT 1 FROM appointments WHERE patient_id = ? AND appointment_date_time = ? AND status IN $_active LIMIT 1',
      [patientId, key],
    );
    if (clash.isNotEmpty) {
      throw const AppException('Vous avez déjà un rendez-vous à cette heure-là.', code: 'patient_busy');
    }

    final appointment = Appointment(
      dateTime: slot,
      doctorId: doctorId,
      patientId: patientId,
      reason: reason,
      status: initialStatus,
    );

    final int id;
    try {
      id = await _database.db.insert(AppointmentTables.appointments, appointment.toMap());
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException(
          'Ce créneau vient d\'être réservé par un autre patient. Choisissez-en un autre.',
          code: 'slot_taken',
          cause: e,
        );
      }
      rethrow;
    }

    final saved = (await byId(id))!;
    changes.value++;
    await _notifyDoctor(
      doctorId,
      title: 'Nouveau rendez-vous',
      body: '${saved.patientName} — ${_readable(slot)}${saved.reason == null ? '' : ' (${saved.reason})'}',
      appointmentId: id,
    );
    return saved;
  }

  /// Annule un rendez-vous à venir du patient et prévient le médecin.
  Future<void> cancel({required int appointmentId, required int patientId}) async {
    final appointment = await byId(appointmentId);
    if (appointment == null || appointment.patientId != patientId) {
      throw const AppException('Rendez-vous introuvable.', code: 'not_found');
    }
    if (!appointment.status.isActive || !appointment.dateTime.isAfter(_clock())) {
      throw const AppException('Ce rendez-vous ne peut plus être annulé.', code: 'not_cancellable');
    }

    final updated = await _database.db.rawUpdate(
      'UPDATE appointments SET status = ? WHERE appointment_id = ? AND status IN $_active',
      [AppointmentStatus.cancelled, appointmentId],
    );
    if (updated == 0) {
      throw const AppException('Ce rendez-vous ne peut plus être annulé.', code: 'not_cancellable');
    }
    changes.value++;

    await _notifyDoctor(
      appointment.doctorId,
      title: 'Rendez-vous annulé',
      body: '${appointment.patientName} a annulé son rendez-vous du ${_readable(appointment.dateTime)}.',
      appointmentId: appointmentId,
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _notifyDoctor(
    int doctorId, {
    required String title,
    required String body,
    required int appointmentId,
  }) async {
    final rows = await _database.db.rawQuery('SELECT user_id FROM doctors WHERE doctor_id = ?', [doctorId]);
    if (rows.isEmpty) return;
    await _notifications.notify(
      userId: rows.first['user_id'] as int,
      type: NotificationTypes.appointment,
      title: title,
      body: body,
      payload: {'appointmentId': appointmentId},
    );
  }

  /// 2026-11-07
  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 07/11/2026 à 09:30
  static String _readable(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
