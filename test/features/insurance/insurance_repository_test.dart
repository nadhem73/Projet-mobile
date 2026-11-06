import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late AppDatabase database;
  late SessionService session;
  late InsuranceRepository repo;
  const patient = CurrentUser(
    userId: 2,
    role: UserRole.patient,
    nom: 'Ben Salah',
    prenom: 'Amira',
    email: 'patient@medilink.tn',
    patientId: 1,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    session = SessionService(await SharedPreferences.getInstance());
    repo = InsuranceRepository(database, session);
    await session.open(patient);
  });
  tearDown(() => database.close());

  Future<void> openInsurer({String company = 'CNAM'}) async {
    final rows = await database.db.query(
      'insurers',
      where: 'company = ?',
      whereArgs: [company],
    );
    final row = rows.first;
    await session.open(
      CurrentUser(
        userId: row['user_id'] as int,
        role: UserRole.insurer,
        nom: 'Agent',
        prenom: 'Test',
        email: 'agent@test.tn',
        insurerId: row['insurer_id'] as int,
        organization: company,
      ),
    );
  }

  test(
    'patient creates contract and claim; insurer records approval and payment',
    () async {
      final id = await repo.addContract(
        company: ' CNAM ',
        policyNumber: 'CN-1',
        coverageRate: .7,
      );
      final claim = await repo.submitClaim(contractId: id, amount: 50);
      expect(await repo.patientContracts(), hasLength(1));
      expect((await repo.patientClaims()).single['status'], 'SUBMITTED');
      await openInsurer();
      expect(await repo.insurerContracts(), hasLength(1));
      await repo.changeClaimStatus(claim, 'APPROVED');
      expect((await repo.insurerClaims()).single['reimbursed_amount'], 35.0);
      await repo.changeClaimStatus(claim, 'PAID');
      expect((await repo.insurerClaims()).single['status'], 'PAID');
      await expectLater(
        repo.changeClaimStatus(claim, 'REJECTED'),
        throwsA(isA<AppException>()),
      );
      await session.open(patient);
      expect((await repo.patientClaims()).single['status'], 'PAID');
    },
  );

  test('ownership, roles, company and validation are enforced', () async {
    final id = await repo.addContract(
      company: 'STAR',
      policyNumber: 'S-1',
      coverageRate: .8,
    );
    final claim = await repo.submitClaim(contractId: id, amount: 10);
    await expectLater(
      repo.submitClaim(contractId: id, amount: -1),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repo.addContract(company: '', policyNumber: '1', coverageRate: 2),
      throwsA(isA<AppException>()),
    );
    await session.open(
      const CurrentUser(
        userId: 99,
        role: UserRole.patient,
        nom: '',
        prenom: '',
        email: '',
        patientId: 999,
      ),
    );
    expect(await repo.patientContracts(), isEmpty);
    await expectLater(
      repo.submitClaim(contractId: id, amount: 10),
      throwsA(isA<AppException>()),
    );
    await openInsurer();
    expect(await repo.insurerClaims(), isEmpty);
    await expectLater(
      repo.changeClaimStatus(claim, 'APPROVED'),
      throwsA(isA<AppException>()),
    );
    expect(() => repo.patientContracts(), throwsA(isA<AppException>()));
  });

  test('inactive or expired contract cannot receive claims', () async {
    final id = await repo.addContract(
      company: 'CNAM',
      policyNumber: 'CN-2',
      coverageRate: .7,
    );
    await database.db.update(
      'insurance_contracts',
      {'status': 'SUSPENDED'},
      where: 'contract_id = ?',
      whereArgs: [id],
    );
    await expectLater(
      repo.submitClaim(contractId: id, amount: 10),
      throwsA(isA<AppException>()),
    );
    await database.db.update(
      'insurance_contracts',
      {'status': 'ACTIVE', 'end_date': '2000-01-01'},
      where: 'contract_id = ?',
      whereArgs: [id],
    );
    await expectLater(
      repo.submitClaim(contractId: id, amount: 10),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'dossier lifecycle, evidence snapshot, notifications and unchanged schema',
    () async {
      final before = await database.db.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type IN ('table', 'index') ORDER BY name",
      );
      final notifier = NotificationService(database);
      var signals = 0;
      notifier.addListener(() => signals++);
      repo = InsuranceRepository(database, session, notifier);
      final contract = await repo.addContract(
        company: 'cnam',
        policyNumber: 'DOC-1',
        coverageRate: .7,
      );
      final attachment = InsuranceAttachment(
        name: 'Facture',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKj8AAAAASUVORK5CYII=',
        ),
      );
      final id = await repo.submitClaim(
        contractId: contract,
        amount: 100,
        careDate: DateTime(2025, 1, 10),
        attachments: [attachment],
      );
      final submitted = InsuranceDossier.decode(
        (await repo.claim(id))['document_path'],
      );
      expect(submitted.attachments.single.bytes, attachment.bytes);
      expect(submitted.careDate, '2025-01-10');
      await openInsurer();
      final insurer = session.requireUser.userId;
      expect(
        (await notifier.forUser(
          insurer,
        )).any((n) => n.payload?['claimId'] == id),
        isTrue,
      );
      await repo.requestDocuments(
        id,
        'Merci de joindre une facture acquittée.',
      );
      await expectLater(
        repo.changeClaimStatus(id, 'APPROVED'),
        throwsA(isA<AppException>()),
      );
      await session.open(patient);
      expect(
        InsuranceDossier.decode(
          (await repo.claim(id))['document_path'],
        ).requestedDocuments,
        contains('facture'),
      );
      await repo.complementClaim(
        id,
        attachments: [attachment],
        note: 'Voici la copie acquittée.',
      );
      await openInsurer();
      await expectLater(
        repo.changeClaimStatus(
          id,
          'APPROVED',
          approvedAmount: 120,
          reason: 'test',
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        repo.changeClaimStatus(id, 'APPROVED', approvedAmount: 60),
        throwsA(isA<AppException>()),
      );
      await repo.changeClaimStatus(
        id,
        'APPROVED',
        approvedAmount: 60,
        reason: 'Plafond de la prestation.',
      );
      await repo.changeClaimStatus(id, 'PAID', reason: 'Référence V-123');
      await session.open(patient);
      final result = await repo.claim(id);
      expect(result['reimbursed_amount'], 60);
      final dossier = InsuranceDossier.decode(result['document_path']);
      expect(dossier.requestedDocuments, isNull);
      expect(dossier.events.map((e) => e['action']), [
        'SUBMITTED',
        'DOCUMENTS_REQUESTED',
        'COMPLEMENT',
        'APPROVED',
        'PAID',
      ]);
      expect(dossier.events.last['note'], 'Référence V-123');
      expect(
        (await notifier.forUser(
          patient.userId,
        )).where((n) => n.type == NotificationTypes.insurance),
        hasLength(3),
      );
      expect(signals, greaterThanOrEqualTo(5));
      expect(
        await database.db.rawQuery(
          "SELECT name, sql FROM sqlite_master WHERE type IN ('table', 'index') ORDER BY name",
        ),
        before,
      );
      expect(AppDatabase.version, 3);
      await expectLater(
        repo.complementClaim(id, attachments: [], note: 'trop tard'),
        throwsA(isA<AppException>()),
      );
      notifier.dispose();
    },
  );

  test(
    'scoped details and care links reject unrelated data; refusal needs a reason',
    () async {
      final contract = await repo.addContract(
        company: 'STAR',
        policyNumber: 'S-2',
        coverageRate: .8,
      );
      final id = await repo.submitClaim(contractId: contract, amount: 80);
      await expectLater(
        repo.submitClaim(
          contractId: contract,
          amount: 80,
          prescriptionId: 999999,
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        repo.addContract(
          company: 'star',
          policyNumber: 's-2',
          coverageRate: .7,
        ),
        throwsA(isA<AppException>()),
      );
      await openInsurer();
      await expectLater(repo.claim(id), throwsA(isA<AppException>()));
      await expectLater(
        repo.requestDocuments(id, 'facture'),
        throwsA(isA<AppException>()),
      );
      expect(() => repo.patientDocuments(), throwsA(isA<AppException>()));
      await session.open(patient);
      final cnam = await repo.addContract(
        company: 'CNAM',
        policyNumber: 'CN-R',
        coverageRate: .7,
      );
      final rejected = await repo.submitClaim(contractId: cnam, amount: 50);
      await openInsurer();
      await expectLater(
        repo.changeClaimStatus(rejected, 'REJECTED'),
        throwsA(isA<AppException>()),
      );
      await repo.changeClaimStatus(
        rejected,
        'REJECTED',
        reason: 'Prestation non couverte.',
      );
      await session.open(patient);
      expect(
        InsuranceDossier.decode(
          (await repo.claim(rejected))['document_path'],
        ).events.last['note'],
        'Prestation non couverte.',
      );
    },
  );

  test(
    'legacy document paths survive decisions and invalid documents are rejected',
    () async {
      final contract = await repo.addContract(
        company: 'CNAM',
        policyNumber: 'LEGACY',
        coverageRate: .7,
      );
      final id = await database.db.insert('insurance_claims', {
        'contract_id': contract,
        'amount': 20,
        'document_path': '/old/invoice.jpg',
      });
      await openInsurer();
      await repo.changeClaimStatus(id, 'APPROVED');
      expect(
        InsuranceDossier.decode(
          (await repo.claim(id))['document_path'],
        ).legacyPath,
        '/old/invoice.jpg',
      );
      await session.open(patient);
      await expectLater(
        repo.submitClaim(
          contractId: contract,
          amount: 10,
          attachments: [
            InsuranceAttachment(name: 'bad', bytes: base64Decode('YWJj')),
          ],
        ),
        throwsA(isA<AppException>()),
      );
    },
  );
}
