import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/insurance/data/insurance_comparator.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/features/insurance/data/insurance_explanation_service.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/insurance_module.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_comparison_screen.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_contract_form.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_document_help_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late AppDatabase db;
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
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    session = SessionService(await SharedPreferences.getInstance());
    repo = InsuranceRepository(db, session);
    await session.open(patient);
  });
  tearDown(() => db.close());

  Future<void> openInsurer() async {
    final row =
        (await db.db.query(
          'insurers',
          where: 'company = ?',
          whereArgs: ['CNAM'],
        )).first;
    await session.open(
      CurrentUser(
        userId: row['user_id'] as int,
        role: UserRole.insurer,
        nom: 'Agent',
        prenom: 'Test',
        email: 'agent@test.tn',
        insurerId: row['insurer_id'] as int,
        organization: 'CNAM',
      ),
    );
  }

  Future<int> rejectClaim() async {
    final contract = await repo.addContract(
      company: 'CNAM',
      policyNumber: 'REVIEW',
      coverageRate: .7,
    );
    final id = await repo.submitClaim(contractId: contract, amount: 100);
    await openInsurer();
    await repo.changeClaimStatus(
      id,
      'REJECTED',
      reason: 'Justificatif insuffisant.',
    );
    await session.open(patient);
    return id;
  }

  test(
    'appeal preserves refusal, enforces ownership and supports a new decision without schema change',
    () async {
      final schema = await db.db.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type IN ('table', 'index') ORDER BY name",
      );
      final id = await rejectClaim();
      await expectLater(
        repo.submitAppeal(id, ''),
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
      await expectLater(
        repo.submitAppeal(id, 'Ce dossier ne m’appartient pas'),
        throwsA(isA<AppException>()),
      );
      await session.open(patient);
      await repo.submitAppeal(id, 'Merci de revoir mon dossier.');
      await expectLater(
        repo.submitAppeal(id, 'Encore'),
        throwsA(isA<AppException>()),
      );
      var claim = await repo.claim(id);
      expect(claim['status'], 'REJECTED');
      expect(insuranceClaimState(claim), 'APPEAL_PENDING');
      final before = InsuranceDossier.decode(claim['document_path']);
      expect(
        before.events
            .where((event) => event['action'] == 'REJECTED')
            .single['note'],
        'Justificatif insuffisant.',
      );
      await expectLater(
        repo.resolveAppeal(id, reopen: true, reason: 'Test'),
        throwsA(isA<AppException>()),
      );
      await openInsurer();
      expect(
        insuranceClaimState((await repo.insurerClaims()).single),
        'APPEAL_PENDING',
      );
      await repo.resolveAppeal(
        id,
        reopen: true,
        reason: 'Nouvel examen accepté.',
      );
      await expectLater(
        repo.resolveAppeal(id, reopen: true, reason: 'Encore'),
        throwsA(isA<AppException>()),
      );
      await repo.changeClaimStatus(id, 'APPROVED');
      await session.open(patient);
      claim = await repo.claim(id);
      expect(claim['status'], 'APPROVED');
      final actions = InsuranceDossier.decode(
        claim['document_path'],
      ).events.map((event) => event['action']);
      expect(
        actions,
        containsAllInOrder([
          'REJECTED',
          'APPEAL_SUBMITTED',
          'APPEAL_REOPENED',
          'APPROVED',
        ]),
      );
      await expectLater(
        repo.submitAppeal(id, 'Trop tard'),
        throwsA(isA<AppException>()),
      );
      expect(
        await db.db.rawQuery(
          "SELECT name, sql FROM sqlite_master WHERE type IN ('table', 'index') ORDER BY name",
        ),
        schema,
      );
    },
  );

  test(
    'insurer can maintain the refusal and cannot process an appeal twice',
    () async {
      final id = await rejectClaim();
      await repo.submitAppeal(id, 'Révision demandée.');
      await openInsurer();
      await repo.resolveAppeal(
        id,
        reopen: false,
        reason: 'Refus confirmé après examen.',
      );
      await expectLater(
        repo.resolveAppeal(id, reopen: true, reason: 'Trop tard'),
        throwsA(isA<AppException>()),
      );
      await session.open(patient);
      final claim = await repo.claim(id);
      expect(claim['status'], 'REJECTED');
      expect(insuranceClaimState(claim), 'REJECTED');
      expect(
        InsuranceDossier.decode(claim['document_path']).appealStatus,
        'UPHELD',
      );
      await expectLater(
        repo.submitAppeal(id, 'Encore'),
        throwsA(isA<AppException>()),
      );
    },
  );

  testWidgets(
    'patient submits an appeal and insurer reopens it through the UI',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final id = await rejectClaim();
      await getIt.reset();
      final notifications = NotificationService(db);
      getIt.registerSingleton<InsuranceRepository>(repo);
      getIt.registerSingleton<SessionService>(session);
      getIt.registerSingleton<NotificationService>(notifications);
      final router = GoRouter(
        initialLocation: '/insurance/claim/$id',
        routes: const InsuranceModule().routes,
      );
      addTearDown(() async {
        router.dispose();
        notifications.dispose();
        await getIt.reset();
      });
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tap('Demander une révision');
      await tester.enterText(
        find.widgetWithText(TextField, 'Motif de votre recours'),
        'Merci de réexaminer le justificatif.',
      );
      await tap('Confirmer');
      expect(find.text('Recours demandé'), findsOneWidget);
      await openInsurer();
      router.go('/insurer/dashboard');
      await tester.pumpAndSettle();
      expect(find.text('1 à traiter'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Recours à examiner'),
        findsOneWidget,
      );
      await tap('Ouvrir le dossier');
      await tap('Rouvrir le dossier');
      await tester.enterText(
        find.widgetWithText(TextField, 'Réponse au recours'),
        'Le dossier sera réexaminé.',
      );
      await tap('Confirmer');
      expect(find.text('Dossier rouvert après recours'), findsOneWidget);
      expect(find.text('Approuver'), findsOneWidget);
      final row = await repo.claim(id);
      expect(row['status'], 'SUBMITTED');
      expect(
        InsuranceDossier.decode(
          row['document_path'],
        ).events.any((e) => e['action'] == 'REJECTED'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'demo ranking filters budget, validates input and scores priorities deterministically',
    () {
      expect(rankDemoOffers(10, {'consultations'}), isEmpty);
      expect(rankDemoOffers(double.nan, {'consultations'}), isEmpty);
      expect(rankDemoOffers(60, {}), isEmpty);
      expect(rankDemoOffers(60, {'not-a-benefit'}), isEmpty);
      final ranked = rankDemoOffers(70, {'consultations', 'dental'});
      expect(ranked.first.offer.id, 'demo_complete');
      expect(ranked.first.matches, 2);
      expect(ranked.first.score, closeTo(70 + 30 * 5 / 70, .001));
      expect(ranked.every((row) => row.offer.monthlyCost <= 70), isTrue);
    },
  );

  testWidgets(
    'company suggestions and warning use actual active local insurers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: InsuranceContractForm(repo: repo))),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'CNAM'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organisme (ex. CNAM)'),
        'ERDF',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Aucun assureur actif ne correspond'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.widgetWithText(ActionChip, 'CNAM'));
      await tester.tap(find.widgetWithText(ActionChip, 'CNAM'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Aucun assureur actif ne correspond'),
        findsNothing,
      );
      expect(find.text('CNAM'), findsWidgets);
    },
  );

  testWidgets(
    'comparator updates ranking and handles empty or invalid budgets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: InsuranceComparisonScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('1. Essentielle'), findsOneWidget);
      await tester.ensureVisible(find.text('Dentaire'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dentaire'));
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Budget mensuel maximum (TND)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Budget mensuel maximum (TND)'),
        '70',
      );
      await tester.pumpAndSettle();
      expect(find.text('1. Complète'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Budget mensuel maximum (TND)'),
        '10',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Aucune offre fictive'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Budget mensuel maximum (TND)'),
        'NaN',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Saisissez un budget'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('comparator requests an AI explanation with only demo inputs', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: InsuranceComparisonScreen(
          createService:
              () => InsuranceExplanationService(
                client: MockClient((request) async {
                  requests++;
                  expect(jsonDecode(request.body), {
                    'task': 'compare',
                    'offer_id': 'demo_essential',
                    'budget': 60.0,
                    'priorities': ['consultations'],
                  });
                  return http.Response(
                    jsonEncode({
                      'explanation':
                          'Cette offre fictive correspond à votre priorité.',
                    }),
                    200,
                  );
                }),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button =
        find.widgetWithText(OutlinedButton, 'Pourquoi cette offre ?').first;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(
      find.text('Cette offre fictive correspond à votre priorité.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'document help requires consent and refuses to send a changed instruction',
    (tester) async {
      final contract = await repo.addContract(
        company: 'CNAM',
        policyNumber: 'DOC-HELP',
        coverageRate: .7,
      );
      final id = await repo.submitClaim(contractId: contract, amount: 100);
      await openInsurer();
      await repo.requestDocuments(id, 'Facture acquittée demandée.');
      await session.open(patient);
      var calls = 0;
      final service = InsuranceExplanationService(
        client: MockClient((request) async {
          calls++;
          expect(jsonDecode(request.body), {
            'task': 'documents',
            'instruction': 'Facture acquittée demandée.',
          });
          return http.Response(
            jsonEncode({'explanation': 'Une facture acquittée est demandée.'}),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InsuranceDocumentHelpDialog(
              repo: repo,
              claimId: id,
              instruction: 'Facture acquittée demandée.',
              service: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Expliquer'),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 0);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Expliquer'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      final row = await repo.claim(id);
      final dossier = InsuranceDossier.decode(row['document_path'])
        ..requestedDocuments = 'Nouvelle consigne';
      await db.db.update(
        'insurance_claims',
        {'document_path': dossier.encode()},
        where: 'claim_id = ?',
        whereArgs: [id],
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Expliquer'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('La consigne a changé'), findsOneWidget);
    },
  );
}
