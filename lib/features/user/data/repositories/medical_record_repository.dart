import 'dart:typed_data';

import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';

/// Dossier médical d'un patient : fiche, vaccins, documents.
///
/// Côté médecin, passer par `MedicalAccessRepository` (contrôle d'accès + traçabilité).
class MedicalRecordRepository {
  MedicalRecordRepository(this._database);

  final AppDatabase _database;

  // ---- Fiche ----

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

  Future<PatientIdentity> identity(int patientId) async {
    final rows = await _database.db.rawQuery(
      'SELECT p.patient_id, p.date_naissance, u.nom, u.prenom, u.phone '
      'FROM patients p JOIN users u ON u.id = p.user_id WHERE p.patient_id = ?',
      [patientId],
    );
    if (rows.isEmpty) throw const AppException('Patient introuvable', code: 'not_found');
    final r = rows.first;
    return PatientIdentity(
      patientId: patientId,
      nom: r['nom'] as String,
      prenom: r['prenom'] as String,
      phone: r['phone'] as String?,
      dateNaissance: DateTime.tryParse(r['date_naissance'] as String? ?? ''),
    );
  }

  // ---- Vaccins ----

  Future<List<Vaccination>> vaccinations(int patientId) async {
    final rows = await _database.db.query(
      UserTables.vaccinations,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC, vaccination_id DESC',
    );
    return rows.map(Vaccination.fromMap).toList();
  }

  Future<void> saveVaccination(Vaccination vaccination) async {
    if (vaccination.name.trim().isEmpty) throw const AppException('Indiquez le nom du vaccin');
    if (vaccination.date.isAfter(DateTime.now())) throw const AppException('La date ne peut pas être dans le futur');
    if (vaccination.id == null) {
      await _database.db.insert(UserTables.vaccinations, vaccination.toMap());
    } else {
      await _database.db.update(
        UserTables.vaccinations,
        vaccination.toMap(),
        where: 'vaccination_id = ? AND patient_id = ?',
        whereArgs: [vaccination.id, vaccination.patientId],
      );
    }
  }

  Future<void> deleteVaccination({required int patientId, required int vaccinationId}) => _database.db.delete(
    UserTables.vaccinations,
    where: 'vaccination_id = ? AND patient_id = ?',
    whereArgs: [vaccinationId, patientId],
  );

  // ---- Documents ----

  /// Taille maximale d'un document (les images sont compressées à la sélection).
  static const int maxDocumentBytes = 3 * 1024 * 1024;

  Future<List<MedicalDocument>> documents(int patientId) async {
    final rows = await _database.db.query(
      UserTables.medicalDocuments,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC, document_id DESC',
    );
    return rows.map(MedicalDocument.fromMap).toList();
  }

  Future<void> addDocument({
    required int patientId,
    required String title,
    required DocumentCategory category,
    required Uint8List data,
  }) async {
    if (title.trim().isEmpty) throw const AppException('Donnez un titre au document');
    if (data.length > maxDocumentBytes) throw const AppException('Image trop lourde (3 Mo maximum)');
    await _database.db.insert(UserTables.medicalDocuments, {
      'patient_id': patientId,
      'title': title.trim(),
      'category': category.dbValue,
      'data': data,
    });
  }

  Future<void> deleteDocument({required int patientId, required int documentId}) => _database.db.delete(
    UserTables.medicalDocuments,
    where: 'document_id = ? AND patient_id = ?',
    whereArgs: [documentId, patientId],
  );
}
