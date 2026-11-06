import 'dart:math';

import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/ai_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/data/models/doctor_option.dart';
import 'package:medilink/features/ai/data/models/evolution_point.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/data/ocr/bilan_parser.dart';
import 'package:sqflite/sqflite.dart';

/// Bilans du patient stockés dans SQLite (tables `bilans` / `bilan_results`).
///
/// Mêmes opérations que l'API `/api/bilans` (confirmer, corriger une valeur,
/// envoyer à un médecin...), utilisables hors-ligne.
class BilanRepository {
  BilanRepository(this._database, this._notifications, this._parser);

  final AppDatabase _database;
  final NotificationService _notifications;
  final BilanParser _parser;

  Database get _db => _database.db;

  static const int pageSize = 20;

  /// Confiance attribuée à une valeur corrigée à la main.
  static const manualConfidence = 'manuelle';

  /// Identifiant d'un bilan analysé hors-ligne : `local-<32 hex>`.
  static String newLocalId() {
    final random = Random.secure();
    final hex = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return '${ScanBilan.localPrefix}$hex';
  }

  // ---------------------------------------------------------------------------
  // Écriture
  // ---------------------------------------------------------------------------

  /// Enregistre un bilan et ses résultats (remplace un bilan de même id).
  Future<ScanBilan> save(ScanBilan bilan, {String? rawText}) async {
    await _db.transaction((txn) async {
      await txn.delete(AiTables.bilans, where: 'bilan_id = ?', whereArgs: [bilan.id]);
      await txn.insert(AiTables.bilans, bilan.toMap(rawText: rawText));
      for (final r in bilan.resultats) {
        await txn.insert(AiTables.bilanResults, r.toMap(bilan.id));
      }
    });
    return byId(bilan.id, patientId: bilan.patientId);
  }

  /// Remplace un bilan analysé hors-ligne par la version renvoyée par le serveur.
  Future<ScanBilan> replaceWithServer(String localId, ScanBilan server, {required int patientId}) async {
    await delete(localId, patientId: patientId);
    return save(server.copyWith(synced: true));
  }

  /// Corrige une valeur ; le statut est recalculé à partir de la plage.
  Future<ScanBilan> updateResult(
    String bilanId,
    int resultId, {
    required int patientId,
    String? valeur,
    String? valeurAncienne,
    double? referenceMin,
    double? referenceMax,
    String? referenceText,
  }) async {
    final bilan = await byId(bilanId, patientId: patientId);
    _ensureEditable(bilan);
    final current = bilan.resultats.where((r) => r.id == resultId).firstOrNull;
    if (current == null) throw const AppException('Résultat introuvable.', code: 'not_found');

    final updated = current.copyWith(
      valeur: valeur?.trim(),
      valeurAncienne: valeurAncienne?.trim(),
      referenceMin: referenceMin,
      referenceMax: referenceMax,
      referenceText: referenceText?.trim(),
    );
    final status = _parser.computeStatus(updated.numericValue, updated.referenceMin, updated.referenceMax);
    await _db.update(
      AiTables.bilanResults,
      {
        'valeur': updated.valeur,
        'valeur_ancienne': updated.valeurAncienne,
        'reference_min': updated.referenceMin,
        'reference_max': updated.referenceMax,
        'reference_text': updated.referenceText,
        'status': status.value,
        'confiance': manualConfidence,
      },
      where: 'result_id = ? AND bilan_id = ?',
      whereArgs: [resultId, bilanId],
    );
    return byId(bilanId, patientId: patientId);
  }

  Future<ScanBilan> confirm(String id, {required int patientId}) async {
    final bilan = await byId(id, patientId: patientId);
    _ensureEditable(bilan);
    if (bilan.resultats.isEmpty) {
      throw const AppException('Aucune valeur à valider : ajoutez ou rescannez le bilan.', code: 'empty');
    }
    await _db.update(AiTables.bilans, {'status': BilanStatus.confirmed.value}, where: 'bilan_id = ?', whereArgs: [id]);
    return byId(id, patientId: patientId);
  }

  /// Envoie le bilan à [doctor] (revue « en attente ») et le notifie.
  Future<ScanBilan> assignDoctor(
    String id, {
    required int patientId,
    required DoctorOption doctor,
    required String patientName,
  }) async {
    final bilan = await byId(id, patientId: patientId);
    if (!bilan.isConfirmed) {
      throw const AppException('Validez le bilan avant de l\'envoyer à un médecin.', code: 'not_confirmed');
    }
    if (bilan.doctorId != null) {
      throw AppException('Ce bilan a déjà été envoyé à ${bilan.doctorName ?? 'un médecin'}.', code: 'already_sent');
    }
    await _db.update(
      AiTables.bilans,
      {'doctor_id': doctor.id, 'review_status': ReviewStatus.enAttente.value},
      where: 'bilan_id = ?',
      whereArgs: [id],
    );
    final userId = doctor.userId;
    if (userId != null) {
      final anomalies = bilan.abnormalCount;
      await _notifications.notify(
        userId: userId,
        type: NotificationTypes.medicalRecord,
        title: 'Nouveau bilan à examiner',
        body:
            '$patientName vous a envoyé son bilan « ${bilan.typeBilan} »'
            '${anomalies > 0 ? ' ($anomalies valeur${anomalies > 1 ? 's' : ''} hors norme)' : ''}.',
        payload: {'bilanId': id, 'patientId': patientId},
      );
    }
    return byId(id, patientId: patientId);
  }

  // ---------------------------------------------------------------------------
  // Côté médecin
  // ---------------------------------------------------------------------------

  /// Ouverture par le médecin : « En attente » → « Lu » (le patient est prévenu).
  Future<ScanBilan> markRead(String id, {required int doctorId}) async {
    final bilan = await byIdForDoctor(id, doctorId: doctorId);
    if (bilan.reviewStatus != ReviewStatus.enAttente) return bilan;
    await _setReview(id, ReviewStatus.lu);
    await _notifyPatient(bilan, 'Bilan consulté', '${bilan.doctorName ?? 'Votre médecin'} a consulté votre bilan.');
    return byIdForDoctor(id, doctorId: doctorId);
  }

  /// Revue terminée, avec un commentaire facultatif pour le patient.
  Future<ScanBilan> markTreated(String id, {required int doctorId, String? comment}) async {
    final bilan = await byIdForDoctor(id, doctorId: doctorId);
    final text = comment?.trim();
    await _setReview(id, ReviewStatus.traite, comment: (text == null || text.isEmpty) ? null : text);
    await _notifyPatient(
      bilan,
      'Bilan examiné',
      '${bilan.doctorName ?? 'Votre médecin'} a examiné votre bilan « ${bilan.typeBilan} »'
          '${text == null || text.isEmpty ? '.' : ' : $text'}',
    );
    return byIdForDoctor(id, doctorId: doctorId);
  }

  Future<void> _setReview(String id, ReviewStatus status, {String? comment}) => _db.update(
    AiTables.bilans,
    {'review_status': status.value, if (status == ReviewStatus.traite) 'doctor_comment': comment},
    where: 'bilan_id = ?',
    whereArgs: [id],
  );

  Future<void> _notifyPatient(ScanBilan bilan, String title, String body) async {
    final rows = await _db.query(
      'patients',
      columns: ['user_id'],
      where: 'patient_id = ?',
      whereArgs: [bilan.patientId],
    );
    if (rows.isEmpty) return;
    await _notifications.notify(
      userId: rows.first['user_id'] as int,
      type: NotificationTypes.medicalRecord,
      title: title,
      body: body,
      payload: {'bilanId': bilan.id},
    );
  }

  Future<void> delete(String id, {required int patientId}) async {
    final count = await _db.delete(
      AiTables.bilans,
      where: 'bilan_id = ? AND patient_id = ?',
      whereArgs: [id, patientId],
    );
    if (count == 0) throw const AppException('Bilan introuvable.', code: 'not_found');
  }

  void _ensureEditable(ScanBilan bilan) {
    if (bilan.isConfirmed) {
      throw const AppException('Ce bilan est validé : il ne peut plus être modifié.', code: 'confirmed');
    }
  }

  // ---------------------------------------------------------------------------
  // Lecture
  // ---------------------------------------------------------------------------

  Future<ScanBilan> byId(String id, {required int patientId}) =>
      _load('b.bilan_id = ? AND b.patient_id = ?', [id, patientId]);

  /// Bilan envoyé au médecin [doctorId] (lecture seule, bilans validés uniquement).
  Future<ScanBilan> byIdForDoctor(String id, {required int doctorId}) =>
      _load('b.bilan_id = ? AND b.doctor_id = ? AND b.status = ?', [id, doctorId, BilanStatus.confirmed.value]);

  static const _bilanSelect = '''
      SELECT b.*,
             CASE WHEN du.id IS NULL THEN NULL ELSE 'Dr ' || du.prenom || ' ' || du.nom END AS doctor_name,
             pu.prenom || ' ' || pu.nom AS patient_name
      FROM bilans b
      LEFT JOIN doctors d ON d.doctor_id = b.doctor_id
      LEFT JOIN users du ON du.id = d.user_id
      LEFT JOIN patients p ON p.patient_id = b.patient_id
      LEFT JOIN users pu ON pu.id = p.user_id
  ''';

  Future<ScanBilan> _load(String where, List<Object?> args) async {
    final rows = await _db.rawQuery('$_bilanSelect WHERE $where', args);
    if (rows.isEmpty) throw const AppException('Bilan introuvable.', code: 'not_found');
    final id = rows.first['bilan_id'] as String;
    final results = await _db.query(
      AiTables.bilanResults,
      where: 'bilan_id = ?',
      whereArgs: [id],
      orderBy: 'result_id',
    );
    return ScanBilan.fromMap(rows.first, results.map(BilanResult.fromMap).toList());
  }

  /// Historique paginé du patient, du plus récent au plus ancien.
  Future<BilanPage> page(int patientId, {int page = 0, int size = pageSize}) =>
      _page('b.patient_id = ?', [patientId], page: page, size: size);

  /// Bilans reçus par le médecin [doctorId], filtrables par avancement de la revue.
  Future<BilanPage> forDoctor(int doctorId, {ReviewStatus? status, int page = 0, int size = pageSize}) => _page(
    'b.doctor_id = ? AND b.status = ?${status == null ? '' : ' AND b.review_status = ?'}',
    [doctorId, BilanStatus.confirmed.value, if (status != null) status.value],
    page: page,
    size: size,
  );

  Future<BilanPage> _page(String where, List<Object?> args, {required int page, required int size}) async {
    final total = Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM bilans b WHERE $where', args)) ?? 0;
    final rows = await _db.rawQuery(
      '''
      SELECT b.bilan_id, b.type_bilan, b.date_bilan, b.status, b.review_status, b.patient_id,
             b.doctor_id, b.synced, pu.prenom || ' ' || pu.nom AS patient_name,
             COUNT(r.result_id) AS result_count,
             COALESCE(SUM(CASE WHEN r.status IN ('ANORMAL', 'CRITIQUE') THEN 1 ELSE 0 END), 0) AS abnormal_count
      FROM bilans b
      LEFT JOIN bilan_results r ON r.bilan_id = b.bilan_id
      LEFT JOIN patients p ON p.patient_id = b.patient_id
      LEFT JOIN users pu ON pu.id = p.user_id
      WHERE $where
      GROUP BY b.bilan_id
      ORDER BY b.created_at DESC, b.rowid DESC
      LIMIT ? OFFSET ?
      ''',
      [...args, size, page * size],
    );
    return BilanPage(
      content: rows.map(BilanSummary.fromMap).toList(),
      page: page,
      totalPages: max(1, (total / size).ceil()),
    );
  }

  /// Bilans analysés hors-ligne, à renvoyer au serveur.
  Future<List<ScanBilan>> unsynced(int patientId) async {
    final rows = await _db.query(
      AiTables.bilans,
      columns: ['bilan_id'],
      where: 'patient_id = ? AND synced = 0',
      whereArgs: [patientId],
      orderBy: 'created_at',
    );
    return [for (final r in rows) await byId(r['bilan_id'] as String, patientId: patientId)];
  }

  /// Tests numériques présents dans au moins un bilan confirmé.
  Future<List<String>> trackedTests(int patientId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT r.test_name, COUNT(*) AS n
      FROM bilan_results r JOIN bilans b ON b.bilan_id = r.bilan_id
      WHERE b.patient_id = ? AND b.status = ?
      GROUP BY r.test_name
      ORDER BY n DESC, r.test_name
      ''',
      [patientId, BilanStatus.confirmed.value],
    );
    return rows.map((r) => r['test_name'] as String).toList();
  }

  /// Mesures de [testName] dans les bilans confirmés, de la plus ancienne à la plus récente.
  Future<List<EvolutionPoint>> evolution(int patientId, String testName) async {
    final rows = await _db.rawQuery(
      '''
      SELECT r.valeur, r.unite, r.reference_min, r.reference_max, b.date_bilan, b.created_at
      FROM bilan_results r JOIN bilans b ON b.bilan_id = r.bilan_id
      WHERE b.patient_id = ? AND b.status = ? AND r.test_name = ?
      ''',
      [patientId, BilanStatus.confirmed.value, testName],
    );
    final points = <EvolutionPoint>[];
    for (final r in rows) {
      final value = parseNumber(r['valeur'] as String?);
      final date =
          DateTime.tryParse(r['date_bilan'] as String? ?? '') ?? DateTime.tryParse(r['created_at'] as String? ?? '');
      if (value == null || date == null) continue;
      points.add(
        EvolutionPoint(
          date: date,
          value: value,
          min: (r['reference_min'] as num?)?.toDouble(),
          max: (r['reference_max'] as num?)?.toDouble(),
          unit: r['unite'] as String? ?? '',
        ),
      );
    }
    return points..sort((a, b) => a.date.compareTo(b.date));
  }
}
