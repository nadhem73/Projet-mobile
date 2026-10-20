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

/// Parcours complets dans l'application (connexion, panels, dossier médical,
/// administration, mot de passe oublié...).
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

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MediLinkApp());
    await tester.pump(const Duration(seconds: 2)); // splash
    await settle(tester);
    expect(find.text('Bon retour !'), findsOneWidget);
  }

  Future<void> login(WidgetTester tester, String email, {String password = DatabaseSeeder.demoPassword}) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), password);
    await tester.tap(find.text('Se connecter'));
    await settle(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester); // les taps sont ignorés pendant un défilement
    await tester.tap(finder);
    await settle(tester);
  }

  /// Ignore les débordements des écrans hérités du template (police de test).
  Future<void> ignoringLegacyOverflow(Future<void> Function() body) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('overflowed')) original?.call(details);
    };
    try {
      await body();
    } finally {
      FlutterError.onError = original;
    }
  }

  testWidgets('patient : panel, onglets du dossier, carte d\'urgence, proches, déconnexion', (tester) async {
    await openApp(tester);
    await login(tester, 'patient@medilink.tn');
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Amira Ben Salah'), findsOneWidget);

    await tester.tap(find.text('Dossier'));
    await settle(tester);
    expect(find.text('Mon dossier médical'), findsOneWidget);
    expect(find.text('Pénicilline'), findsOneWidget);

    await tapVisible(tester, find.text('Vaccins'));
    expect(find.text('BCG'), findsOneWidget);
    expect(find.text('Ajouter un vaccin'), findsOneWidget);

    await tapVisible(tester, find.text('Accès'));
    expect(find.text('Aucune consultation'), findsOneWidget);

    await tester.tap(find.byTooltip('Carte d\'urgence'));
    await settle(tester);
    expect(find.text('URGENCE MÉDICALE'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    await tapVisible(tester, find.text('Mes proches'));
    expect(find.text('Youssef Ben Salah'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Se déconnecter'), 200, scrollable: find.byType(Scrollable).last);
    await tapVisible(tester, find.text('Se déconnecter'));
    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await settle(tester);
    expect(find.text('Bon retour !'), findsOneWidget);
  });

  testWidgets('médecin : dossiers de ses patients, consultation tracée', (tester) async {
    await ignoringLegacyOverflow(() async {
      await openApp(tester);
      await login(tester, 'dr.benali@medilink.tn');
      expect(find.text('Dr Sami Benali'), findsOneWidget);

      await tapVisible(tester, find.text('Dossiers médicaux'));
      expect(find.text('Dossiers de mes patients'), findsOneWidget);
      await tester.tap(find.text('Amira Ben Salah'));
      await settle(tester);
      expect(find.textContaining('Consultation enregistrée'), findsOneWidget);
      expect(find.text('Pénicilline'), findsOneWidget);
    });
  });

  testWidgets('pharmacien et assureur : panels et profil', (tester) async {
    await openApp(tester);
    await login(tester, 'pharmacie@medilink.tn');
    expect(find.text('Espace pharmacien'), findsOneWidget);
    expect(find.text('Pharmacie Ennour'), findsOneWidget);
    await tester.tap(find.byTooltip('Mon profil'));
    await settle(tester);
    expect(find.text('TN-PH-2001'), findsOneWidget);
  });

  testWidgets('assureur : panel assurance', (tester) async {
    await openApp(tester);
    await login(tester, 'assurance@medilink.tn');
    expect(find.text('Espace assureur'), findsOneWidget);
    expect(find.text('CNAM'), findsOneWidget);
  });

  testWidgets('administrateur : valide le compte en attente, qui peut alors se connecter', (tester) async {
    await openApp(tester);
    await login(tester, 'dr.haddad@medilink.tn');
    expect(find.textContaining('en attente de validation'), findsOneWidget);

    await login(tester, 'admin@medilink.tn');
    expect(find.text('Espace administrateur'), findsOneWidget);
    expect(find.text('Mariem Haddad'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Valider'));
    expect(find.text('Tout est à jour'), findsOneWidget);

    await tester.tap(find.byTooltip('Mon profil'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Se déconnecter'), 200, scrollable: find.byType(Scrollable).last);
    await tapVisible(tester, find.text('Se déconnecter'));
    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await settle(tester);

    await ignoringLegacyOverflow(() async {
      await login(tester, 'dr.haddad@medilink.tn');
      expect(find.text('Dr Mariem Haddad'), findsOneWidget);
    });
  });

  testWidgets('mot de passe oublié : code SMS puis connexion avec le nouveau mot de passe', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Mot de passe oublié ?'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), 'patient@medilink.tn');
    await tester.enterText(find.widgetWithText(TextFormField, 'Téléphone du compte'), '22 345 678');
    await tapVisible(tester, find.text('Recevoir un code'));

    // Mode démo : le code est affiché à l'écran (pas de passerelle SMS).
    final demo = tester.widget<Text>(find.textContaining('votre code est'));
    final code = RegExp(r'\d{6}').firstMatch(demo.data!)!.group(0)!;
    await tester.enterText(find.widgetWithText(TextFormField, 'Code à 6 chiffres'), code);
    await tester.enterText(find.widgetWithText(TextFormField, 'Nouveau mot de passe'), 'Nouveau2026');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), 'Nouveau2026');
    await tapVisible(tester, find.text('Réinitialiser le mot de passe'));

    expect(find.text('Bon retour !'), findsOneWidget);
    await login(tester, 'patient@medilink.tn', password: 'Nouveau2026');
    expect(find.text('Services'), findsOneWidget);
  });

  testWidgets('inscription d\'un pharmacien : demande en attente de validation', (tester) async {
    await openApp(tester);
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

    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Créer mon compte'));

    expect(find.text('Demande envoyée'), findsOneWidget);
    await tester.tap(find.text('Compris'));
    await settle(tester);
    expect(find.text('Bon retour !'), findsOneWidget);
  });
}
