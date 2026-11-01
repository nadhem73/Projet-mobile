import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart' show sqlNow;
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';

/// Consultations médicales (cahier des charges §10.6).
///
/// Cycle de vie : [start] crée la consultation (`IN_PROGRESS`), [saveClinical]
/// enregistre motif, constantes et diagnostic, [close] la clôture (`CLOSED`) :
/// elle n'est alors plus modifiable et le rendez-vous lié passe à `COMPLETED`.
class ConsultationRepository {
  ConsultationRepository(this._database, this._access, this._notifications);

  final AppDatabase _database;
  final MedicalAccessRepository _access;
  final NotificationService _notifications;

  static const String _select = '''
    SELECT c.*,
           pu.nom AS patient_nom, pu.prenom AS patient_prenom, p.date_naissance,
           du.nom AS doctor_nom, du.prenom AS doctor_prenom, d.specialty
    FROM ${DoctorTables.consultations} c
    JOIN patients p ON p.patient_id = c.patient_id
    JOIN users pu ON pu.id = p.user_id
    JOIN doctors d ON d.doctor_id = c.doctor_id
    JOIN users du ON du.id = d.user_id
  ''';

  /// Démarre une consultation, à partir d'un rendez-vous ou non.
  ///
  /// Si une consultation existe déjà pour [appointmentId], elle est renvoyée
  /// au lieu d'en créer une seconde.
  Future<Consultation> start({required int doctorId, required int patientId, int? appointmentId}) async {
    if (appointmentId != null) {
      final rows = await _database.db.query(
        AppointmentTables.appointments,
        where: 'appointment_id = ?',
        whereArgs: [appointmentId],
      );
      if (rows.isEmpty) throw const AppException('Rendez-vous introuvable.', code: 'not_found');
      final appointment = rows.first;
      if (appointment['doctor_id'] != doctorId || appointment['patient_id'] != patientId) {
        throw const AppException('Ce rendez-vous ne vous concerne pas.', code: 'forbidden');
      }
      if (appointment['status'] == AppointmentStatus.cancelled) {
        throw const AppException('Ce rendez-vous a été annulé.', code: 'cancelled');
      }
      final existing = await _database.db.query(
        DoctorTables.consultations,
        columns: ['consultation_id'],
        where: 'appointment_id = ?',
        whereArgs: [appointmentId],
      );
      if (existing.isNotEmpty) return byId(existing.first['consultation_id'] as int, doctorId: doctorId);
    } else if (!await _access.canAccess(doctorId: doctorId, patientId: patientId)) {
      throw const AppException('Accès refusé : ce patient n\'a pas de rendez-vous avec vous.', code: 'forbidden');
    }

    final id = await _database.db.insert(DoctorTables.consultations, {
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'start_time': sqlNow(),
      'status': ConsultationStatus.inProgress,
    });
    return byId(id, doctorId: doctorId);
  }

  /// Consultation [id]. Avec [doctorId], vérifie qu'elle appartient à ce médecin.
  Future<Consultation> byId(int id, {int? doctorId}) async {
    final rows = await _database.db.rawQuery('$_select WHERE c.consultation_id = ?', [id]);
    if (rows.isEmpty) throw const AppException('Consultation introuvable.', code: 'not_found');
    final consultation = Consultation.fromMap(rows.first);
    if (doctorId != null && consultation.doctorId != doctorId) {
      throw const AppException('Cette consultation ne vous appartient pas.', code: 'forbidden');
    }
    return consultation;
  }

  /// Consultations d'un médecin, les plus récentes d'abord (filtre optionnel sur [status]).
  Future<List<Consultation>> forDoctor(int doctorId, {String? status}) async {
    final rows = await _database.db.rawQuery(
      '$_select WHERE c.doctor_id = ? ${status == null ? '' : 'AND c.status = ?'} '
      'ORDER BY c.start_time DESC, c.consultation_id DESC',
      [doctorId, if (status != null) status],
    );
    return rows.map(Consultation.fromMap).toList();
  }

  /// Rendez-vous en attente ou confirmés du médecin, sans consultation, par date croissante.
  Future<List<AppointmentToStart>> appointmentsToStart(int doctorId) async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT a.appointment_id, a.patient_id, a.appointment_date_time, a.reason, a.status, u.nom, u.prenom
      FROM ${AppointmentTables.appointments} a
      JOIN patients p ON p.patient_id = a.patient_id
      JOIN users u ON u.id = p.user_id
      WHERE a.doctor_id = ? AND a.status IN (?, ?)
        AND NOT EXISTS (SELECT 1 FROM ${DoctorTables.consultations} c WHERE c.appointment_id = a.appointment_id)
      ORDER BY a.appointment_date_time
      ''',
      [doctorId, AppointmentStatus.pending, AppointmentStatus.confirmed],
    );
    return rows.map(AppointmentToStart.fromMap).toList();
  }

  /// Historique des consultations clôturées d'un patient (tous médecins).
  Future<List<Consultation>> forPatient(int patientId) async {
    final rows = await _database.db.rawQuery(
      '$_select WHERE c.patient_id = ? AND c.status = ? ORDER BY c.start_time DESC, c.consultation_id DESC',
      [patientId, ConsultationStatus.closed],
    );
    return rows.map(Consultation.fromMap).toList();
  }

  /// Enregistre la saisie clinique d'une consultation en cours.
  Future<Consultation> saveClinical(
    int id, {
    required int doctorId,
    String? motif,
    String? diagnostic,
    String? observation,
    VitalSigns vitals = const VitalSigns(),
  }) async {
    final consultation = await _requireEditable(id, doctorId);
    final error = vitals.validate();
    if (error != null) throw AppException(error, code: 'invalid_vitals');

    await _database.db.update(
      DoctorTables.consultations,
      {'motif': _clean(motif), 'diagnostic': _clean(diagnostic), 'observation': _clean(observation), ...vitals.toMap()},
      where: 'consultation_id = ?',
      whereArgs: [consultation.id],
    );
    return byId(id);
  }

  /// Clôture la consultation : elle devient non modifiable, le rendez-vous lié
  /// passe à `COMPLETED` et le patient est notifié.
  Future<Consultation> close(int id, {required int doctorId, DateTime? followUpDate}) async {
    final consultation = await _requireEditable(id, doctorId);
    final hasContent =
        (consultation.motif ?? '').isNotEmpty ||
        (consultation.observation ?? '').isNotEmpty ||
        (consultation.diagnostic ?? '').isNotEmpty ||
        !consultation.vitals.isEmpty;
    if (!hasContent) {
      throw const AppException(
        'Renseignez au moins le motif, les constantes ou une observation avant de clôturer.',
        code: 'empty',
      );
    }
    if (followUpDate != null) {
      final today = DateTime.now();
      if (followUpDate.isBefore(DateTime(today.year, today.month, today.day))) {
        throw const AppException('La date de contrôle ne peut pas être dans le passé.', code: 'invalid_date');
      }
    }

    final prescriptionIds = await _database.db.transaction((txn) async {
      await txn.update(
        DoctorTables.consultations,
        {
          'status': ConsultationStatus.closed,
          'end_time': sqlNow(),
          'follow_up_date': followUpDate?.toIso8601String().substring(0, 10),
        },
        where: 'consultation_id = ?',
        whereArgs: [id],
      );
      // TODO(doctor): passer par AppointmentRepository quand le module Rendez-vous l'exposera.
      if (consultation.appointmentId != null) {
        await txn.update(
          AppointmentTables.appointments,
          {'status': AppointmentStatus.completed},
          where: 'appointment_id = ?',
          whereArgs: [consultation.appointmentId],
        );
      }
      final rows = await txn.query(
        DoctorTables.prescriptions,
        columns: ['prescription_id'],
        where: 'consultation_id = ?',
        whereArgs: [id],
      );
      return [for (final r in rows) r['prescription_id'] as int];
    });

    await _notifyPatient(consultation, prescriptionIds);
    return byId(id);
  }

  Future<Consultation> _requireEditable(int id, int doctorId) async {
    final consultation = await byId(id, doctorId: doctorId);
    if (consultation.isClosed) {
      throw const AppException('Cette consultation est clôturée et ne peut plus être modifiée.', code: 'closed');
    }
    return consultation;
  }

  Future<void> _notifyPatient(Consultation consultation, List<int> prescriptionIds) async {
    final rows = await _database.db.rawQuery('SELECT user_id FROM patients WHERE patient_id = ?', [
      consultation.patientId,
    ]);
    if (rows.isEmpty) return;
    final userId = rows.first['user_id'] as int;
    final count = prescriptionIds.length;
    await _notifications.notify(
      userId: userId,
      type: count == 0 ? NotificationTypes.appointment : NotificationTypes.prescription,
      title: count == 0 ? 'Consultation terminée' : 'Nouvelle ordonnance disponible',
      body:
          count == 0
              ? '${consultation.doctorName} a clôturé votre consultation.'
              : '${consultation.doctorName} vous a remis ${count == 1 ? 'une ordonnance' : '$count ordonnances'}.',
      payload: {'consultationId': consultation.id, if (count > 0) 'prescriptionIds': prescriptionIds},
    );
  }

  static String? _clean(String? value) {
    final v = value?.trim();
    return v == null || v.isEmpty ? null : v;
  }
}
