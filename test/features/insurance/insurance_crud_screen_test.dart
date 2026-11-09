import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/insurance_module.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  testWidgets(
    'patient edits and deletes unused contracts then corrects and withdraws a claim at 320px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
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
      final repo = InsuranceRepository(db, session);
      await getIt.reset();
      getIt.registerSingleton<InsuranceRepository>(repo);
      final router = GoRouter(
        initialLocation: '/insurance',
        routes: const InsuranceModule().routes,
      );
      addTearDown(() async {
        router.dispose();
        await getIt.reset();
        await db.close();
      });
      final id = await repo.addContract(
        company: 'CNAM',
        policyNumber: 'TYPO',
        coverageRate: .7,
      );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppThemeData.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        final target = find.text(text);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tap('Modifier');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Numéro de contrat'),
        'CN-FIXED',
      );
      await tap('Enregistrer');
      expect(find.text('N° CN-FIXED'), findsOneWidget);
      await tap('Supprimer');
      await tap('Annuler');
      expect(await repo.patientContracts(), hasLength(1));
      await tap('Supprimer');
      await tap('Confirmer');
      expect(await repo.patientContracts(), isEmpty);
      final second = await repo.addContract(
        company: 'CNAM',
        policyNumber: 'NEW',
        coverageRate: .7,
      );
      expect(second, isNot(id));
      final claim = await repo.submitClaim(contractId: second, amount: 100);
      await tester.pumpAndSettle();
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
      await tap('Désactiver');
      await tap('Confirmer');
      expect((await repo.patientClaims()).single['claim_id'], claim);
      await tap('Réactiver');
      await tap('Confirmer');
      await tap('Ouvrir le dossier');
      expect(find.text('Expliquer mon dossier'), findsOneWidget);
      expect(
        find.textContaining('Envoie l’état et les montants à Groq'),
        findsOneWidget,
      );
      await tap('Corriger les informations');
      await tester.enterText(
        find.widgetWithText(TextField, 'Frais corrigés (TND)'),
        '80',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Date des soins (facultatif)'),
        '2025-02-30',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Motif de la correction'),
        'Erreur de montant',
      );
      await tap('Confirmer');
      expect(find.textContaining('Utilisez AAAA-MM-JJ'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Date des soins (facultatif)'),
        '2025-02-28',
      );
      await tap('Confirmer');
      expect(find.text('Frais déclarés : 80.000 TND'), findsOneWidget);
      await tap('Retirer ma demande');
      await tester.enterText(
        find.widgetWithText(TextField, 'Motif du retrait'),
        'Mauvais organisme',
      );
      await tap('Confirmer');
      expect(find.text('Retirée'), findsOneWidget);
      expect(find.text('Corriger les informations'), findsNothing);
      expect(find.text('Compléter mon dossier'), findsNothing);
      expect(find.text('Demande retirée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
