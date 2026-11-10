import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/doctor/data/models/lab_request.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';

/// Demandes de bilan rédigées pendant une consultation.
///
/// Mêmes règles que les ordonnances : modifiables tant que la consultation est
/// en cours, visibles du patient (onglet Documents) une fois qu'elle est clôturée.
class LabRequestRepository {
  LabRequestRepository(this._database, this._consultations, this._access);

  final AppDatabase _database;
  final ConsultationRepository _consultations;
  final MedicalAccessRepository _access;

  static const String _select = '''
    SELECT lr.*,
           pu.nom AS patient_nom, pu.prenom AS patient_prenom,
           du.nom AS doctor_nom, du.prenom AS doctor_prenom, d.specialty
    FROM ${DoctorTables.labRequests} lr
    JOIN patients p ON p.patient_id = lr.patient_id
    JOIN users pu ON pu.id = p.user_id
    JOIN doctors d ON d.doctor_id = lr.doctor_id
    JOIN users du ON du.id = d.user_id
  ''';

  /// Seules les demandes des consultations clôturées (ou sans consultation) sont publiées.
  static const String _published =
      '(lr.consultation_id IS NULL OR EXISTS (SELECT 1 FROM ${DoctorTables.consultations} c '
      "WHERE c.consultation_id = lr.consultation_id AND c.status = '${ConsultationStatus.closed}'))";

  /// Rédige une demande de bilan pour la consultation [consultationId] (en cours).
  Future<LabRequest> create({
    required int consultationId,
    required int doctorId,
    required List<String> tests,
    String? note,
  }) async {
    final consultation = await _consultations.byId(consultationId, doctorId: doctorId);
    _requireOpen(consultation.isClosed);
    final cleaned = <String>[];
    for (final t in tests) {
      final v = t.trim();
      if (v.isNotEmpty && !cleaned.any((c) => c.toLowerCase() == v.toLowerCase())) cleaned.add(v);
    }
    if (cleaned.isEmpty) throw const AppException('Choisissez au moins une analyse.', code: 'empty');

    final trimmedNote = note?.trim();
    final id = await _database.db.insert(DoctorTables.labRequests, {
      'consultation_id': consultation.id,
      'doctor_id': consultation.doctorId,
      'patient_id': consultation.patientId,
      'tests': LabRequest.encodeTests(cleaned),
      'note': trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    });
    return byId(id);
  }

  /// Supprime une demande tant que sa consultation est en cours.
  Future<void> delete(int labRequestId, {required int doctorId}) async {
    final request = await byId(labRequestId);
    final consultationId = request.consultationId;
    if (consultationId == null) {
      throw const AppException('Cette demande de bilan ne peut plus être supprimée.', code: 'closed');
    }
    final consultation = await _consultations.byId(consultationId, doctorId: doctorId);
    _requireOpen(consultation.isClosed);
    await _database.db.delete(DoctorTables.labRequests, where: 'lab_request_id = ?', whereArgs: [labRequestId]);
  }

  Future<LabRequest> byId(int id) async {
    final rows = await _database.db.rawQuery('$_select WHERE lr.lab_request_id = ?', [id]);
    if (rows.isEmpty) throw const AppException('Demande de bilan introuvable.', code: 'not_found');
    return LabRequest.fromMap(rows.first);
  }

  /// Demandes rédigées pendant une consultation (brouillons compris).
  Future<List<LabRequest>> forConsultation(int consultationId) =>
      _list('WHERE lr.consultation_id = ?', [consultationId]);

  /// Demandes publiées d'un patient (consultations clôturées), les plus récentes d'abord.
  Future<List<LabRequest>> forPatient(int patientId) => _list('WHERE lr.patient_id = ? AND $_published', [patientId]);

  /// Demande [id] telle que [user] a le droit de la voir : le patient les
  /// siennes une fois publiées, le médecin celles qu'il a rédigées ou celles
  /// d'un patient dont il peut ouvrir le dossier.
  Future<LabRequest> viewableBy(int id, CurrentUser user) async {
    final request = await byId(id);
    final published = request.consultationId == null || (await _consultations.byId(request.consultationId!)).isClosed;
    final allowed = switch (user.role) {
      UserRole.patient => request.patientId == user.patientId && published,
      UserRole.doctor =>
        request.doctorId == user.doctorId ||
            (published && await _access.canAccess(doctorId: user.doctorId!, patientId: request.patientId)),
      UserRole.pharmacist || UserRole.insurer || UserRole.admin => false,
    };
    if (!allowed) throw const AppException('Demande de bilan introuvable.', code: 'not_found');
    return request;
  }

  Future<List<LabRequest>> _list(String where, List<Object?> args) async {
    final rows = await _database.db.rawQuery(
      '$_select $where ORDER BY lr.created_at DESC, lr.lab_request_id DESC',
      args,
    );
    return rows.map(LabRequest.fromMap).toList();
  }

  static void _requireOpen(bool isClosed) {
    if (isClosed) {
      throw const AppException(
        'La consultation est clôturée : ses demandes de bilan ne sont plus modifiables.',
        code: 'closed',
      );
    }
  }
}
