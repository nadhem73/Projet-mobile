import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// Ordonnances (cahier des charges §10.9 / §10.10).
///
/// Une ordonnance est rédigée pendant une consultation en cours. Une fois la
/// consultation clôturée, ses ordonnances ne peuvent plus être modifiées ni
/// supprimées (pour corriger, il faut une nouvelle consultation).
///
/// Les autres modules (pharmacie, assurance) lisent les ordonnances via
/// [byId] et [forPatient].
class PrescriptionRepository {
  PrescriptionRepository(this._database, this._consultations, this._records);

  final AppDatabase _database;
  final ConsultationRepository _consultations;
  final MedicalRecordRepository _records;

  static const String _select = '''
    SELECT pr.*,
           pu.nom AS patient_nom, pu.prenom AS patient_prenom,
           du.nom AS doctor_nom, du.prenom AS doctor_prenom, d.specialty
    FROM ${DoctorTables.prescriptions} pr
    JOIN patients p ON p.patient_id = pr.patient_id
    JOIN users pu ON pu.id = p.user_id
    JOIN doctors d ON d.doctor_id = pr.doctor_id
    JOIN users du ON du.id = d.user_id
  ''';

  /// Rédige une ordonnance pour la consultation [consultationId] (en cours).
  Future<Prescription> create({
    required int consultationId,
    required int doctorId,
    required List<PrescriptionItem> items,
    String? note,
  }) async {
    final consultation = await _requireEditable(consultationId, doctorId);
    if (items.isEmpty) throw const AppException('Ajoutez au moins un médicament.', code: 'empty');
    for (final item in items) {
      final error = item.validate();
      if (error != null) throw AppException(error, code: 'invalid_item');
    }

    final trimmedNote = note?.trim();
    final id = await _database.db.transaction((txn) async {
      final prescriptionId = await txn.insert(DoctorTables.prescriptions, {
        'consultation_id': consultation.id,
        'doctor_id': consultation.doctorId,
        'patient_id': consultation.patientId,
        'note': trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
      });
      for (final item in items) {
        await txn.insert(DoctorTables.prescriptionItems, item.toMap(prescriptionId));
      }
      return prescriptionId;
    });
    return byId(id);
  }

  /// Supprime une ordonnance tant que sa consultation est en cours.
  Future<void> delete(int prescriptionId, {required int doctorId}) async {
    final prescription = await byId(prescriptionId);
    final consultationId = prescription.consultationId;
    if (consultationId == null) {
      throw const AppException('Cette ordonnance ne peut plus être supprimée.', code: 'closed');
    }
    await _requireEditable(consultationId, doctorId);
    await _database.db.delete(DoctorTables.prescriptions, where: 'prescription_id = ?', whereArgs: [prescriptionId]);
  }

  Future<Prescription> byId(int id) async {
    final rows = await _database.db.rawQuery('$_select WHERE pr.prescription_id = ?', [id]);
    if (rows.isEmpty) throw const AppException('Ordonnance introuvable.', code: 'not_found');
    return Prescription.fromMap(rows.first, await _items(id));
  }

  /// Ordonnances d'un patient, les plus récentes d'abord. Seules celles des
  /// consultations clôturées sont visibles (les brouillons restent chez le médecin).
  Future<List<Prescription>> forPatient(int patientId) => _list(
    'WHERE pr.patient_id = ? AND (pr.consultation_id IS NULL OR EXISTS ('
    'SELECT 1 FROM ${DoctorTables.consultations} c WHERE c.consultation_id = pr.consultation_id '
    "AND c.status = '${ConsultationStatus.closed}'))",
    [patientId],
  );

  /// Ordonnances rédigées par un médecin (toutes consultations).
  Future<List<Prescription>> forDoctor(int doctorId) => _list('WHERE pr.doctor_id = ?', [doctorId]);

  /// Ordonnance [id] telle que [user] a le droit de la voir : le patient ne
  /// voit que les siennes (consultation clôturée), le médecin que celles qu'il
  /// a rédigées. Pharmaciens et assureurs y ont accès pour les traiter.
  Future<Prescription> viewableBy(int id, CurrentUser user) async {
    final prescription = await byId(id);
    final allowed = switch (user.role) {
      UserRole.patient =>
        prescription.patientId == user.patientId &&
            (prescription.consultationId == null || (await _consultations.byId(prescription.consultationId!)).isClosed),
      UserRole.doctor => prescription.doctorId == user.doctorId,
      UserRole.pharmacist || UserRole.insurer => true,
      UserRole.admin => false,
    };
    if (!allowed) throw const AppException('Ordonnance introuvable.', code: 'not_found');
    return prescription;
  }

  /// Ordonnances rédigées pendant une consultation.
  Future<List<Prescription>> forConsultation(int consultationId) =>
      _list('WHERE pr.consultation_id = ?', [consultationId]);

  /// Allergies du dossier médical qui correspondent à des médicaments prescrits.
  ///
  /// Comparaison simple sur le nom (insensible à la casse, dans les deux sens) :
  /// une aide à la vigilance, pas une base d'interactions médicamenteuses.
  Future<List<String>> allergyWarnings(int patientId, List<PrescriptionItem> items) async {
    final allergies = (await _records.forPatient(patientId)).allergyList;
    final warnings = <String>[];
    for (final item in items) {
      final name = item.medicamentName.toLowerCase().trim();
      if (name.isEmpty) continue;
      for (final allergy in allergies) {
        final a = allergy.toLowerCase().trim();
        if (a.isNotEmpty && (name.contains(a) || a.contains(name))) {
          warnings.add('${item.medicamentName} : le patient est allergique à « $allergy ».');
        }
      }
    }
    return warnings;
  }

  Future<List<Prescription>> _list(String where, List<Object?> args) async {
    final rows = await _database.db.rawQuery(
      '$_select $where ORDER BY pr.created_at DESC, pr.prescription_id DESC',
      args,
    );
    return [for (final r in rows) Prescription.fromMap(r, await _items(r['prescription_id'] as int))];
  }

  Future<List<PrescriptionItem>> _items(int prescriptionId) async {
    final rows = await _database.db.query(
      DoctorTables.prescriptionItems,
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
      orderBy: 'prescription_item_id',
    );
    return rows.map(PrescriptionItem.fromMap).toList();
  }

  Future<Consultation> _requireEditable(int consultationId, int doctorId) async {
    final consultation = await _consultations.byId(consultationId, doctorId: doctorId);
    if (consultation.isClosed) {
      throw const AppException(
        'La consultation est clôturée : ses ordonnances ne sont plus modifiables.',
        code: 'closed',
      );
    }
    return consultation;
  }
}
