import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Parcours complet : connexion avec chaque rôle → bon panel → déconnexion.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues({'medilink.onboarding_done': true});
    await initialize();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'medilink.onboarding_done': true});
    await getIt.reset();
    final database = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    await configureDependencies(appModules, database: database);
    try {
      app.appStore = getIt<AppStore>();
    } catch (_) {
      // Déjà initialisé par un test précédent (late final).
    }
  });

  /// Avance le temps sans attendre la fin des animations infinies (spinners).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> login(WidgetTester tester, String email) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MediLinkApp());
    await tester.pump(const Duration(seconds: 2)); // splash
    await settle(tester);
    expect(find.text('Bon retour !'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
    await tester.tap(find.text('Se connecter'));
    await settle(tester);
  }

  testWidgets('patient : panel, dossier médical puis déconnexion', (tester) async {
    await login(tester, 'patient@medilink.tn');
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Amira Ben Salah'), findsOneWidget);

    await tester.tap(find.text('Dossier'));
    await settle(tester);
    expect(find.text('Mon dossier médical'), findsOneWidget);
    expect(find.text('Pénicilline'), findsOneWidget);

    await tester.tap(find.text('Mettre à jour'));
    await settle(tester);
    expect(find.text('Modifier mon dossier'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Se déconnecter'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Se déconnecter'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await settle(tester);
    expect(find.text('Bon retour !'), findsOneWidget);
  });

  testWidgets('médecin : panel médecin avec son nom', (tester) async {
    // Le tableau de bord médecin (écran hérité du template, module Médecin)
    // déborde avec la police de test : ces débordements sont ignorés ici.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('overflowed')) original?.call(details);
    };
    try {
      await login(tester, 'dr.benali@medilink.tn');
      expect(find.text('Dr Sami Benali'), findsOneWidget);
      expect(find.text('Cardiologie'), findsOneWidget);
    } finally {
      FlutterError.onError = original;
    }
  });

  testWidgets('pharmacien : panel pharmacie', (tester) async {
    await login(tester, 'pharmacie@medilink.tn');
    expect(find.text('Espace pharmacien'), findsOneWidget);
    expect(find.text('Pharmacie Ennour'), findsOneWidget);

    await tester.tap(find.byTooltip('Mon profil'));
    await settle(tester);
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('TN-PH-2001'), findsOneWidget);
  });

  testWidgets('assureur : panel assurance', (tester) async {
    await login(tester, 'assurance@medilink.tn');
    expect(find.text('Espace assureur'), findsOneWidget);
    expect(find.text('CNAM'), findsOneWidget);
  });

  testWidgets('inscription d\'un pharmacien depuis le formulaire', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MediLinkApp());
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    await tester.tap(find.text('Créer un compte'));
    await settle(tester);

    await tester.tap(find.text('Pharmacien'));
    await tester.tap(find.text('Continuer'));
    await settle(tester);

    Future<void> fill(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.scrollUntilVisible(field, 150, scrollable: find.byType(Scrollable).first);
      await tester.enterText(field, value);
    }

    await fill('Prénom', 'Nour');
    await fill('Nom', 'Haddad');
    await fill('Adresse e-mail', 'nour@pharma.tn');
    await fill('Téléphone', '55 123 456');
    await fill('Nom de la pharmacie', 'Pharmacie El Amal');
    await fill('N° d\'autorisation d\'exercice', 'PH-777');
    await fill('Adresse', '12 rue de Rome');
    await fill('Ville', 'Bizerte');
    await fill('Mot de passe', 'Pharma2026');
    await fill('Confirmer le mot de passe', 'Pharma2026');

    final consent = find.byType(Checkbox);
    await tester.scrollUntilVisible(consent, 150, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(consent);
    await settle(tester); // attendre la fin du défilement (les taps sont ignorés pendant)
    await tester.tap(consent);
    final submit = find.text('Créer mon compte');
    await tester.ensureVisible(submit);
    await settle(tester);
    await tester.tap(submit);
    await settle(tester);

    expect(find.text('Espace pharmacien'), findsOneWidget);
    expect(find.text('Pharmacie El Amal'), findsOneWidget);
  });
}
