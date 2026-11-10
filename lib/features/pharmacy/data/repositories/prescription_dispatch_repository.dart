import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/database/schema/pharmacy_pharmacien_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/pharmacy/data/models/prescription_dispatch.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart' show sqlNow;

/// Envoi d'une ordonnance par le patient à la pharmacie de son choix, puis
/// suivi par le pharmacien (Envoyée → Prête → Délivrée).
class PrescriptionDispatchRepository {
  PrescriptionDispatchRepository(this._database, this._prescriptions);

  final AppDatabase _database;
  final PrescriptionRepository _prescriptions;

  static const String _table = PharmacyPharmacienTables.prescriptionDispatches;

  static const String _select = '''
    SELECT pd.*,
           ph.name AS pharmacy_name, ph.address AS pharmacy_address, ph.phone AS pharmacy_phone,
           pu.nom AS patient_nom, pu.prenom AS patient_prenom,
           du.nom AS doctor_nom, du.prenom AS doctor_prenom,
           (SELECT COUNT(*) FROM ${DoctorTables.prescriptionItems} pi
            WHERE pi.prescription_id = pd.prescription_id) AS item_count
    FROM $_table pd
    JOIN ${PharmacyPharmacienTables.pharmacies} ph ON ph.pharmacy_id = pd.pharmacy_id
    JOIN patients p ON p.patient_id = pd.patient_id
    JOIN users pu ON pu.id = p.user_id
    JOIN ${DoctorTables.prescriptions} pr ON pr.prescription_id = pd.prescription_id
    JOIN doctors d ON d.doctor_id = pr.doctor_id
    JOIN users du ON du.id = d.user_id
  ''';

  /// Envoie l'ordonnance [prescriptionId] du patient [user] à [pharmacyId].
  ///
  /// Si elle a déjà été envoyée et n'est pas encore prête, elle est
  /// redirigée vers la nouvelle pharmacie.
  Future<PrescriptionDispatch> send({
    required int prescriptionId,
    required int pharmacyId,
    required CurrentUser user,
  }) async {
    // Vérifie que l'ordonnance appartient au patient et qu'elle est publiée.
    final prescription = await _prescriptions.viewableBy(prescriptionId, user);
    if (!user.isPatient || prescription.patientId != user.patientId) {
      throw const AppException('Seul le patient peut envoyer son ordonnance.', code: 'forbidden');
    }

    final existing = await forPrescription(prescriptionId);
    if (existing != null) {
      if (!existing.canChangePharmacy) {
        throw AppException(
          'Ordonnance déjà ${existing.status.label.toLowerCase()} par ${existing.pharmacyName}.',
          code: 'locked',
        );
      }
      await _database.db.update(
        _table,
        {'pharmacy_id': pharmacyId, 'sent_at': sqlNow(), 'updated_at': sqlNow()},
        where: 'dispatch_id = ?',
        whereArgs: [existing.id],
      );
    } else {
      await _database.db.insert(_table, {
        'prescription_id': prescriptionId,
        'pharmacy_id': pharmacyId,
        'patient_id': prescription.patientId,
        'status': DispatchStatus.sent.code,
      });
    }
    return (await forPrescription(prescriptionId))!;
  }

  /// Envoi de l'ordonnance, ou null si le patient ne l'a pas encore envoyée.
  Future<PrescriptionDispatch?> forPrescription(int prescriptionId) async {
    final rows = await _database.db.rawQuery('$_select WHERE pd.prescription_id = ?', [prescriptionId]);
    return rows.isEmpty ? null : PrescriptionDispatch.fromMap(rows.first);
  }

  /// Ordonnances reçues par une pharmacie : à traiter d'abord, puis les plus récentes.
  Future<List<PrescriptionDispatch>> forPharmacy(int pharmacyId) async {
    final rows = await _database.db.rawQuery(
      "$_select WHERE pd.pharmacy_id = ? "
      "ORDER BY CASE pd.status WHEN 'SENT' THEN 0 WHEN 'READY' THEN 1 ELSE 2 END, pd.sent_at DESC, pd.dispatch_id DESC",
      [pharmacyId],
    );
    return rows.map(PrescriptionDispatch.fromMap).toList();
  }

  /// Pour chaque pharmacie, nombre de médicaments de l'ordonnance disponibles
  /// en stock (`pharmacy_id → nombre`). Aide le patient à choisir sa pharmacie.
  Future<Map<int, int>> availabilityByPharmacy(int prescriptionId) async {
    final rows = await _database.db.rawQuery(
      'SELECT ps.pharmacy_id, COUNT(DISTINCT ps.medicine_id) AS n '
      'FROM ${PharmacyPharmacienTables.pharmacyStock} ps '
      'WHERE ps.in_stock = 1 AND ps.quantity > 0 AND ps.medicine_id IN ('
      '  SELECT medicament_id FROM ${DoctorTables.prescriptionItems} '
      '  WHERE prescription_id = ? AND medicament_id IS NOT NULL) '
      'GROUP BY ps.pharmacy_id',
      [prescriptionId],
    );
    return {for (final r in rows) r['pharmacy_id'] as int: r['n'] as int};
  }

  /// Nombre d'ordonnances reçues encore à préparer.
  Future<int> pendingCount(int pharmacyId) async {
    final rows = await _database.db.rawQuery('SELECT COUNT(*) AS n FROM $_table WHERE pharmacy_id = ? AND status = ?', [
      pharmacyId,
      DispatchStatus.sent.code,
    ]);
    return rows.first['n'] as int? ?? 0;
  }

  /// Fait passer l'ordonnance à l'étape suivante (pharmacien de [pharmacyId] uniquement).
  Future<PrescriptionDispatch> advance(int dispatchId, {required int pharmacyId}) async {
    final rows = await _database.db.rawQuery('$_select WHERE pd.dispatch_id = ?', [dispatchId]);
    if (rows.isEmpty) throw const AppException('Ordonnance introuvable.', code: 'not_found');
    final dispatch = PrescriptionDispatch.fromMap(rows.first);
    if (dispatch.pharmacyId != pharmacyId) {
      throw const AppException('Cette ordonnance a été envoyée à une autre pharmacie.', code: 'forbidden');
    }
    final next = dispatch.status.next;
    if (next == null) throw const AppException('Ordonnance déjà délivrée.', code: 'delivered');
    await _database.db.update(
      _table,
      {'status': next.code, 'updated_at': sqlNow()},
      where: 'dispatch_id = ?',
      whereArgs: [dispatchId],
    );
    return (await forPrescription(dispatch.prescriptionId))!;
  }
}
