import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';

/// Dossier médical des patients.
///
/// Les autres modules peuvent l'utiliser en lecture :
/// `getIt<MedicalRecordRepository>().forPatient(patientId)` (ex. espace médecin).
class MedicalRecordRepository {
  MedicalRecordRepository(this._database);

  final AppDatabase _database;

  /// Renvoie le dossier du patient (vide s'il n'a encore rien renseigné).
  Future<MedicalRecord> forPatient(int patientId) async {
    final rows = await _database.db.query(
      UserTables.medicalRecords,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      limit: 1,
    );
    return rows.isEmpty ? MedicalRecord.empty(patientId) : MedicalRecord.fromMap(rows.first);
  }

  /// Crée ou met à jour le dossier, puis renvoie la version enregistrée.
  Future<MedicalRecord> save(MedicalRecord record) async {
    final values = {...record.toMap(), 'updated_at': sqlNow()};
    final updated = await _database.db.update(
      UserTables.medicalRecords,
      values,
      where: 'patient_id = ?',
      whereArgs: [record.patientId],
    );
    if (updated == 0) await _database.db.insert(UserTables.medicalRecords, values);
    return forPatient(record.patientId);
  }
}
