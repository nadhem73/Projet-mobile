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

/// Onglet « Rendez-vous » du panel patient, sur les données de démo.
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('le patient voit ses vrais rendez-vous et peut en annuler un', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MediLinkApp());
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), 'patient@medilink.tn');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
    await tester.tap(find.text('Se connecter'));
    await settle(tester);

    // Onglet Rendez-vous de la barre du bas.
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Rendez-vous')));
    await settle(tester);

    expect(find.text('Mes rendez-vous'), findsOneWidget);
    expect(find.text('À venir (1)'), findsOneWidget);
    expect(find.text('Dr Sami Benali'), findsOneWidget);
    expect(find.text('Contrôle cardiologique'), findsOneWidget);
    expect(find.text('Confirmé'), findsOneWidget);

    // Détail du rendez-vous.
    await tester.tap(find.text('Dr Sami Benali'));
    await settle(tester);
    expect(find.text('Détail du rendez-vous'), findsOneWidget);
    expect(find.text('Contrôle cardiologique'), findsOneWidget);
    expect(find.text('10:00 – 10:30'), findsOneWidget);
    expect(find.text('Annuler le rendez-vous'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // Annulation avec confirmation.
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await settle(tester);
    await tester.tap(find.text('Annuler le rendez-vous'));
    await settle(tester);
    expect(find.text('Aucun rendez-vous à venir'), findsOneWidget);

    // Onglet Passés : le rendez-vous annulé + l'ancien rendez-vous terminé.
    await tester.tap(find.text('Passés'));
    await settle(tester);
    expect(find.text('Annulé'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);

    // ----- Nouveau rendez-vous : recherche → fiche → jour → heure → réservation -----
    await tester.tap(find.text('À venir'));
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('Trouver un médecin'), findsOneWidget);
    expect(find.text('3 médecins'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'gharbi');
    await settle(tester);
    expect(find.text('1 médecin'), findsOneWidget);
    await tester.tap(find.text('Dr Youssef Gharbi'));
    await settle(tester);
    expect(find.text('Choisissez un jour'), findsOneWidget);

    // Demain (ou après-demain si demain est dimanche) : toujours des heures libres.
    var day = DateTime.now().add(const Duration(days: 1));
    if (day.weekday == DateTime.sunday) day = day.add(const Duration(days: 1));
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    if (day.month != DateTime.now().month) {
      await tester.tap(find.byIcon(Icons.chevron_right)); // mois suivant
      await settle(tester);
    }
    final dayCell = find.descendant(of: find.byType(CalendarDatePicker), matching: find.text('${day.day}'));
    await tester.ensureVisible(dayCell);
    await settle(tester);
    await tester.tap(dayCell);
    await settle(tester);
    final firstSlot = find.byType(ChoiceChip).first;
    await tester.ensureVisible(firstSlot);
    await tester.tap(firstSlot);
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Grain de beauté');
    await tester.tap(find.textContaining('Réserver le'));
    await settle(tester);

    expect(find.text('Rendez-vous confirmé'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);

    // Retour automatique sur « Mes rendez-vous », liste à jour.
    expect(find.text('Mes rendez-vous'), findsOneWidget);
    expect(find.text('À venir (1)'), findsOneWidget);
    expect(find.text('Dr Youssef Gharbi'), findsOneWidget);
    expect(find.text('Grain de beauté'), findsOneWidget);
  });
}
