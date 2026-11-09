import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/insurance/insurance_module.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_forms.dart';
import 'package:medilink/features/shell/presentation/screens/notifications_screen.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_home_screen.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  testWidgets(
    'insurance button reacts to hover and press and remains clickable',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InsuranceMotion(
                child: FilledButton(
                  onPressed: () => taps++,
                  child: const Text('Action'),
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(0, 0));
      await gesture.moveTo(tester.getCenter(find.text('Action')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.025,
      );
      await gesture.down(tester.getCenter(find.text('Action')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .96,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      await gesture.removePointer();
    },
  );
  testWidgets('patient adds a contract and submits a claim', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    final session = SessionService(await SharedPreferences.getInstance());
    await session.open(
      const CurrentUser(
        userId: 2,
        role: UserRole.patient,
        nom: 'Ben Salah',
        prenom: 'Amira',
        email: 'patient@medilink.tn',
        patientId: 1,
      ),
    );
    await getIt.reset();
    getIt.registerSingleton<InsuranceRepository>(
      InsuranceRepository(db, session),
    );
    addTearDown(() async {
      await getIt.reset();
      await db.close();
    });
    await tester.pumpWidget(const MaterialApp(home: InsuranceHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Votre espace est pret'), findsOneWidget);
    expect(
      find.text('Aucun contrat enregistré. Ajoutez votre premier contrat.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Organisme (ex. CNAM)'),
      'CNAM',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro de contrat'),
      'CN-123',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('N° CN-123'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Nouvelle demande'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nouvelle demande'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montant des soins (TND)'),
      '100',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Frais déclarés : 100.000 TND'), findsOneWidget);
    expect(find.text('Estimation indicative : 70.000 TND'), findsOneWidget);
  });

  testWidgets(
    'insurer reviews, requests evidence, approves and notifies patient',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final db = await AppDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      final session = SessionService(await SharedPreferences.getInstance());
      const patient = CurrentUser(
        userId: 2,
        role: UserRole.patient,
        nom: 'Ben Salah',
        prenom: 'Amira',
        email: 'patient@medilink.tn',
        patientId: 1,
      );
      await session.open(patient);
      final notifications = NotificationService(db);
      final repo = InsuranceRepository(db, session, notifications);
      final contract = await repo.addContract(
        company: 'CNAM',
        policyNumber: 'TEST-UI',
        coverageRate: .7,
      );
      final id = await repo.submitClaim(contractId: contract, amount: 100);
      final row =
          (await db.db.query(
            'insurers',
            where: 'company = ?',
            whereArgs: ['CNAM'],
          )).single;
      final insurer = CurrentUser(
        userId: row['user_id'] as int,
        role: UserRole.insurer,
        nom: 'Jaziri',
        prenom: 'Mehdi',
        email: 'assurance@medilink.tn',
        insurerId: row['insurer_id'] as int,
        organization: 'CNAM',
      );
      await session.open(insurer);
      await getIt.reset();
      getIt.registerSingleton<InsuranceRepository>(repo);
      getIt.registerSingleton<SessionService>(session);
      getIt.registerSingleton<NotificationService>(notifications);
      final router = GoRouter(
        refreshListenable: session,
        initialLocation: '/insurer/dashboard',
        routes: [
          ...const InsuranceModule().routes,
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await getIt.reset();
        await db.close();
      });
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('1 à traiter'), findsOneWidget);
      await tester.tap(find.text('Refusée'));
      await tester.pumpAndSettle();
      expect(
        find.text('Aucune demande ne correspond à votre recherche.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Toutes'));
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tap('Ouvrir le dossier');
      expect(find.text('Expliquer mon dossier'), findsNothing);
      await tap('Demander des pièces');
      await tester.enterText(
        find.widgetWithText(TextField, 'Pièces attendues et consignes'),
        'Facture acquittée nécessaire',
      );
      await tap('Confirmer');
      expect(find.text('Facture acquittée nécessaire'), findsWidgets);
      expect(find.text('Approuver'), findsNothing);
      // Remount the route after changing the authenticated account, like a login.
      router.go('/insurance');
      await session.open(patient);
      router.go('/insurance/claim/$id');
      await tester.pumpAndSettle();
      await tap('Compléter mon dossier');
      await tester.enterText(
        find.widgetWithText(TextField, 'Votre réponse'),
        'Le document sera remis au guichet.',
      );
      await tap('Confirmer');
      await session.open(insurer);
      router.go('/insurer/dashboard');
      await tester.pumpAndSettle();
      await tap('Ouvrir le dossier');
      expect(find.text('Approuver'), findsNothing);
      await tap('Valider le complément');
      await tester.enterText(
        find.widgetWithText(TextField, 'Résultat de la vérification'),
        'Facture remise au guichet et vérifiée.',
      );
      await tap('Confirmer');
      await tap('Approuver');
      await tester.enterText(
        find.widgetWithText(TextField, 'Montant retenu (TND)'),
        '60',
      );
      await tap('Confirmer');
      expect(
        find.text('Indiquez un motif pour expliquer cette décision.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Motif de la décision'),
        'Plafond appliqué',
      );
      await tap('Confirmer');
      await tap('Marquer comme payée');
      expect(
        find.textContaining('ne déclenche aucun virement'),
        findsOneWidget,
      );
      await tap('Confirmer');
      await session.open(patient);
      router.go('/notifications');
      await tester.pumpAndSettle();
      expect(find.text('Demande #$id marquée payée'), findsOneWidget);
      await tester.tap(find.text('Voir le dossier').first);
      await tester.pumpAndSettle();
      expect(find.text('Payée'), findsOneWidget);
      expect(find.text('Plafond appliqué'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'simulator does not create claims; small claim dialog stays usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final contracts = <Map<String, Object?>>[
        {
          'contract_id': 1,
          'company': 'CNAM',
          'policy_number': 'X',
          'coverage_rate': .7,
          'status': 'ACTIVE',
        },
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InsuranceSimulator(contracts: contracts),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Simuler mon reste à charge'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Budget des soins (TND)'),
        '100',
      );
      await tester.pumpAndSettle();
      expect(find.text('Reste à charge estimé : 30.000 TND'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Budget des soins (TND)'),
        'NaN',
      );
      await tester.pumpAndSettle();
      expect(find.text('Montant entre 0 et 10 000 000.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('insurance layout fits width $width and dark mode', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final db = await AppDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      final session = SessionService(await SharedPreferences.getInstance());
      await session.open(
        const CurrentUser(
          userId: 2,
          role: UserRole.patient,
          nom: 'Ben Salah',
          prenom: 'Amira',
          email: 'patient@medilink.tn',
          patientId: 1,
        ),
      );
      await getIt.reset();
      getIt.registerSingleton<InsuranceRepository>(
        InsuranceRepository(db, session),
      );
      addTearDown(() async {
        await getIt.reset();
        await db.close();
      });
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const InsuranceHomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mon assurance'), findsOneWidget);
      final hero = find.byType(InsuranceHero);
      final expectedWidth =
          width < 380 ? width - 32 : (width - 48).clamp(0.0, 760.0);
      expect(tester.getSize(hero).width, expectedWidth);
      expect(
        tester
            .getSize(find.descendant(of: hero, matching: find.byType(Image)))
            .width,
        expectedWidth,
      );
      await tester.ensureVisible(find.text('Ajouter'));
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter un contrat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
