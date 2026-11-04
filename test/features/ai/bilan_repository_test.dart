import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/data/ocr/bilan_parser.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';
import 'package:medilink/features/ai/data/repositories/doctor_directory.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late BilanRepository repository;
  late DoctorDirectory doctors;
  late NotificationService notifications;
  late int patientId;
  final parser = BilanParser();

  const text = '''
LABORATOIRE EL AMEN
Prélèvement du 02/03/2026
Glycémie 1,32 g/l 0,70 - 1,10
Hémoglobine 13,5 g/dl 12 - 16
Hemoglobme 13,1 g/dl 12 - 16
CRP 3 mg/l < 6
''';

  Future<ScanBilan> saveScan({String? id}) =>
      repository.save(parser.parse(text, id: id ?? BilanRepository.newLocalId(), patientId: patientId), rawText: text);

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    notifications = NotificationService(database);
    repository = BilanRepository(database, notifications, parser);
    doctors = DoctorDirectory(database);
    final rows = await database.db.rawQuery(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    patientId = rows.first['patient_id'] as int;
  });

  tearDown(() => database.db.close());

  test('identifiant local', () {
    final id = BilanRepository.newLocalId();
    expect(id, startsWith('local-'));
    expect(id, hasLength(6 + 32));
    expect(BilanRepository.newLocalId(), isNot(id));
  });

  test('enregistrement puis lecture d\'un bilan hors-ligne', () async {
    final bilan = await saveScan();
    expect(bilan.isLocal, isTrue);
    expect(bilan.synced, isFalse);
    expect(bilan.dateBilan, '2026-03-02');
    expect(bilan.resultats, hasLength(3));
    expect(bilan.resultats.every((r) => r.id > 0), isTrue, reason: 'ids SQLite');
    expect(bilan.abnormalCount, 1);
  });

  test('un patient ne lit pas le bilan d\'un autre', () async {
    final bilan = await saveScan();
    expect(() => repository.byId(bilan.id, patientId: patientId + 999), throwsA(isA<AppException>()));
  });

  test('correction d\'une valeur : statut recalculé, confiance manuelle', () async {
    final bilan = await saveScan();
    final glycemie = bilan.resultats.firstWhere((r) => r.testName == 'Glycémie');
    expect(glycemie.status, ResultStatus.anormal);

    final updated = await repository.updateResult(bilan.id, glycemie.id, patientId: patientId, valeur: '0,95');
    final fixed = updated.resultats.firstWhere((r) => r.id == glycemie.id);
    expect(fixed.valeur, '0,95');
    expect(fixed.status, ResultStatus.normal);
    expect(fixed.confiance, BilanRepository.manualConfidence);
    expect(fixed.needsCheck, isFalse);
  });

  test('confirmation : le bilan devient en lecture seule', () async {
    final bilan = await saveScan();
    final confirmed = await repository.confirm(bilan.id, patientId: patientId);
    expect(confirmed.status, BilanStatus.confirmed);
    expect(
      () => repository.updateResult(bilan.id, bilan.resultats.first.id, patientId: patientId, valeur: '1'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'confirmed')),
    );
  });

  test('envoi à un médecin : revue en attente + notification', () async {
    final bilan = await saveScan();
    final list = await doctors.all();
    expect(list, isNotEmpty);
    final doctor = list.first;

    expect(
      () => repository.assignDoctor(bilan.id, patientId: patientId, doctor: doctor, patientName: 'Ali'),
      throwsA(isA<AppException>()),
      reason: 'il faut d\'abord valider',
    );

    await repository.confirm(bilan.id, patientId: patientId);
    final sent = await repository.assignDoctor(bilan.id, patientId: patientId, doctor: doctor, patientName: 'Ali');
    expect(sent.doctorId, doctor.id);
    expect(sent.reviewStatus, ReviewStatus.enAttente);
    expect(sent.doctorName, startsWith('Dr '));

    final notes = await database.db.query('notifications', where: 'user_id = ?', whereArgs: [doctor.userId]);
    expect(notes.any((n) => (n['title'] as String).contains('bilan')), isTrue);
  });

  test('pagination, compteur d\'anomalies et suppression', () async {
    for (var i = 0; i < 23; i++) {
      await saveScan();
    }
    final first = await repository.page(patientId);
    expect(first.content, hasLength(20));
    expect(first.totalPages, 2);
    expect(first.isLast, isFalse);
    expect(first.content.first.resultCount, 3);
    expect(first.content.first.abnormalCount, 1);
    expect(first.content.first.synced, isFalse);

    final second = await repository.page(patientId, page: 1);
    expect(second.content, hasLength(3));
    expect(second.isLast, isTrue);

    await repository.delete(second.content.first.id, patientId: patientId);
    expect((await repository.page(patientId, page: 1)).content, hasLength(2));
    expect(() => repository.delete(second.content.first.id, patientId: patientId), throwsA(isA<AppException>()));
  });

  test('synchronisation : le bilan local est remplacé par celui du serveur', () async {
    final local = await saveScan();
    expect(await repository.unsynced(patientId), hasLength(1));

    final server = local.copyWith(id: '3f6c2a1e-8b7d-4c1a-9f0e-2d5b6a7c8e90');
    final saved = await repository.replaceWithServer(local.id, server, patientId: patientId);
    expect(saved.synced, isTrue);
    expect(saved.isLocal, isFalse);
    expect(await repository.unsynced(patientId), isEmpty);
    expect(() => repository.byId(local.id, patientId: patientId), throwsA(isA<AppException>()));
  });

  test('évolution : uniquement les bilans confirmés, triés par date', () async {
    final a = await saveScan();
    await repository.confirm(a.id, patientId: patientId);

    final b = parser.parse(
      text.replaceAll('02/03/2026', '10/01/2026').replaceAll('1,32', '1,05'),
      id: BilanRepository.newLocalId(),
      patientId: patientId,
    );
    await repository.save(b);
    await repository.confirm(b.id, patientId: patientId);
    await saveScan(); // non confirmé : ignoré

    expect(await repository.trackedTests(patientId), contains('Glycémie'));
    final points = await repository.evolution(patientId, 'Glycémie');
    expect(points.map((p) => p.value), [1.05, 1.32]);
    expect(points.first.min, 0.7);
    expect(points.first.max, 1.1);
  });

  test('scénario complet : scan → correction → envoi → le médecin lit et traite', () async {
    Future<List<Map<String, Object?>>> notificationsOf(int? userId) =>
        database.db.query('notifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'notification_id');
    final patientUserId =
        (await database.db.query('patients', where: 'patient_id = ?', whereArgs: [patientId])).first['user_id'] as int;

    // 1. Patient : scan puis correction d'une valeur mal lue.
    final scanned = await saveScan();
    final glycemie = scanned.resultats.firstWhere((r) => r.testName == 'Glycémie');
    await repository.updateResult(scanned.id, glycemie.id, patientId: patientId, valeur: '1,02');

    // 2. Patient : validation puis envoi au médecin choisi.
    final doctor = (await doctors.all()).firstWhere((d) => d.email == 'dr.benali@medilink.tn');
    await repository.confirm(scanned.id, patientId: patientId);
    await repository.assignDoctor(scanned.id, patientId: patientId, doctor: doctor, patientName: 'Ali Ben Salah');
    expect(
      () => repository.assignDoctor(scanned.id, patientId: patientId, doctor: doctor, patientName: 'Ali'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'already_sent')),
    );

    // 3. Médecin : le bilan apparaît dans « Bilans reçus », en attente.
    final inbox = await repository.forDoctor(doctor.id, status: ReviewStatus.enAttente);
    expect(inbox.content.single.id, scanned.id);
    expect(inbox.content.single.patientName, isNotEmpty);
    expect((await notificationsOf(doctor.userId)).last['title'], 'Nouveau bilan à examiner');

    // Un autre médecin n'y a pas accès.
    final other = (await doctors.all()).firstWhere((d) => d.id != doctor.id);
    expect(() => repository.byIdForDoctor(scanned.id, doctorId: other.id), throwsA(isA<AppException>()));
    expect((await repository.forDoctor(other.id)).content, isEmpty);

    // 4. Médecin : ouverture → « Lu », valeurs corrigées visibles, patient prévenu.
    final opened = await repository.markRead(scanned.id, doctorId: doctor.id);
    expect(opened.reviewStatus, ReviewStatus.lu);
    expect(opened.resultats.firstWhere((r) => r.testName == 'Glycémie').valeur, '1,02');
    expect((await notificationsOf(patientUserId)).last['title'], 'Bilan consulté');

    // 5. Médecin : traité, avec un commentaire que le patient voit.
    await repository.markTreated(scanned.id, doctorId: doctor.id, comment: 'Résultats normaux, contrôle dans 6 mois.');
    final seenByPatient = await repository.byId(scanned.id, patientId: patientId);
    expect(seenByPatient.reviewStatus, ReviewStatus.traite);
    expect(seenByPatient.doctorComment, 'Résultats normaux, contrôle dans 6 mois.');
    expect(seenByPatient.doctorName, startsWith('Dr '));
    expect((await notificationsOf(patientUserId)).last['body'], contains('contrôle dans 6 mois'));
    expect((await repository.forDoctor(doctor.id, status: ReviewStatus.traite)).content, hasLength(1));
  });

  test('un bilan non validé n\'est jamais visible par un médecin', () async {
    final bilan = await saveScan();
    final doctor = (await doctors.all()).first;
    await database.db.update('bilans', {'doctor_id': doctor.id}, where: 'bilan_id = ?', whereArgs: [bilan.id]);
    expect((await repository.forDoctor(doctor.id)).content, isEmpty);
    expect(() => repository.byIdForDoctor(bilan.id, doctorId: doctor.id), throwsA(isA<AppException>()));
  });
}
