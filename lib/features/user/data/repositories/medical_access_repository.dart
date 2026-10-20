import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// Dossier médical tel qu'il est présenté à un médecin.
class PatientMedicalFile {
  const PatientMedicalFile({
    required this.patient,
    required this.record,
    required this.vaccinations,
    required this.documents,
  });

  final PatientIdentity patient;
  final MedicalRecord record;
  final List<Vaccination> vaccinations;
  final List<MedicalDocument> documents;
}

/// Accès des médecins au dossier médical (cahier des charges §13.1).
///
/// Règle : un médecin ne consulte que le dossier d'un patient qui a (ou a eu)
/// un rendez-vous non annulé avec lui. Chaque consultation est enregistrée et
/// le patient est notifié (au plus une fois par jour et par médecin).
class MedicalAccessRepository {
  MedicalAccessRepository(this._database, this._records, this._notifications);

  final AppDatabase _database;
  final MedicalRecordRepository _records;
  final NotificationService _notifications;

  /// Patients ayant un rendez-vous non annulé avec ce médecin.
  Future<List<PatientIdentity>> patientsOf(int doctorId, {String query = ''}) async {
    final q = query.trim();
    final rows = await _database.db.rawQuery(
      '''
      SELECT p.patient_id, p.date_naissance, u.nom, u.prenom, u.phone,
             MAX(a.appointment_date_time) AS last_appointment
      FROM appointments a
      JOIN patients p ON p.patient_id = a.patient_id
      JOIN users u ON u.id = p.user_id
      WHERE a.doctor_id = ? AND a.status <> 'CANCELLED'
        ${q.isEmpty ? '' : "AND (u.nom LIKE ? OR u.prenom LIKE ? OR (u.prenom || ' ' || u.nom) LIKE ?)"}
      GROUP BY p.patient_id
      ORDER BY last_appointment DESC
      ''',
      [doctorId, if (q.isNotEmpty) ...List.filled(3, '%$q%')],
    );
    return [
      for (final r in rows)
        PatientIdentity(
          patientId: r['patient_id'] as int,
          nom: r['nom'] as String,
          prenom: r['prenom'] as String,
          phone: r['phone'] as String?,
          dateNaissance: DateTime.tryParse(r['date_naissance'] as String? ?? ''),
          lastAppointment: DateTime.tryParse(r['last_appointment'] as String? ?? ''),
        ),
    ];
  }

  Future<bool> canAccess({required int doctorId, required int patientId}) async {
    final rows = await _database.db.rawQuery(
      "SELECT 1 FROM appointments WHERE doctor_id = ? AND patient_id = ? AND status <> 'CANCELLED' LIMIT 1",
      [doctorId, patientId],
    );
    return rows.isNotEmpty;
  }

  /// Ouvre le dossier pour un médecin : vérifie le droit d'accès, trace la
  /// consultation et prévient le patient.
  Future<PatientMedicalFile> openAsDoctor({required int doctorId, required int patientId}) async {
    if (!await canAccess(doctorId: doctorId, patientId: patientId)) {
      throw const AppException('Accès refusé : ce patient n\'a pas de rendez-vous avec vous.', code: 'forbidden');
    }

    final alreadyToday = await _database.db.rawQuery(
      "SELECT 1 FROM ${UserTables.recordAccessLog} WHERE doctor_id = ? AND patient_id = ? "
      "AND date(accessed_at) = date('now') LIMIT 1",
      [doctorId, patientId],
    );
    await _database.db.insert(UserTables.recordAccessLog, {'doctor_id': doctorId, 'patient_id': patientId});

    if (alreadyToday.isEmpty) {
      final rows = await _database.db.rawQuery(
        'SELECT du.prenom, du.nom, pu.id AS patient_user_id FROM doctors d JOIN users du ON du.id = d.user_id, '
        'patients p JOIN users pu ON pu.id = p.user_id WHERE d.doctor_id = ? AND p.patient_id = ?',
        [doctorId, patientId],
      );
      if (rows.isNotEmpty) {
        final r = rows.first;
        await _notifications.notify(
          userId: r['patient_user_id'] as int,
          type: NotificationTypes.medicalRecord,
          title: 'Votre dossier a été consulté',
          body: 'Dr ${r['prenom']} ${r['nom']} a consulté votre dossier médical.',
        );
      }
    }

    return PatientMedicalFile(
      patient: await _records.identity(patientId),
      record: await _records.forPatient(patientId),
      vaccinations: await _records.vaccinations(patientId),
      documents: await _records.documents(patientId),
    );
  }

  /// Historique des consultations du dossier (vu par le patient).
  Future<List<RecordAccess>> accessLog(int patientId) async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT u.prenom, u.nom, d.specialty, l.accessed_at
      FROM ${UserTables.recordAccessLog} l
      JOIN doctors d ON d.doctor_id = l.doctor_id
      JOIN users u ON u.id = d.user_id
      WHERE l.patient_id = ?
      ORDER BY l.accessed_at DESC, l.access_id DESC
      LIMIT 100
      ''',
      [patientId],
    );
    return [
      for (final r in rows)
        RecordAccess(
          doctorName: 'Dr ${r['prenom']} ${r['nom']}',
          specialty: r['specialty'] as String,
          accessedAt: parseSqlDateTime(r['accessed_at'] as String)!,
        ),
    ];
  }
}
