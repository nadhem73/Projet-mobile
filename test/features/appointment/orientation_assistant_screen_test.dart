import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/features/appointment/presentation/controllers/orientation_assistant_controller.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Assistant d'orientation : de la tuile de l'accueil jusqu'au rendez-vous réservé.
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

  Future<void> openAssistant(WidgetTester tester) async {
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

    final tile = find.text('Quel médecin consulter ?');
    await tester.ensureVisible(tile);
    await settle(tester);
    await tester.tap(tile);
    await settle(tester);
    expect(find.text('Assistant IA'), findsOneWidget);
    expect(find.textContaining('Décrivez-moi vos symptômes'), findsOneWidget);
  }

  testWidgets('symptômes → Cardiologie → « Oui, réservez » → rendez-vous confirmé', (tester) async {
    await openAssistant(tester);

    await tester.enterText(find.byType(TextField), "J'ai des palpitations et je m'essouffle vite");
    await tester.tap(find.byTooltip('Envoyer'));
    await settle(tester);

    expect(find.text('Analyse de vos symptômes'), findsOneWidget);
    expect(find.text('Cardiologie'), findsWidgets);
    expect(find.text('À consulter cette semaine'), findsOneWidget);
    expect(find.textContaining('Voulez-vous que je vous prenne rendez-vous avec Dr Sami Benali'), findsOneWidget);

    await tester.tap(find.text(OrientationAssistantController.yesReply));
    await settle(tester);
    expect(find.text('Rendez-vous confirmé'), findsOneWidget);

    // Le rendez-vous est bien dans « Mes rendez-vous ».
    await tester.tap(find.text('Voir'));
    await settle(tester);
    expect(find.text('Détail du rendez-vous'), findsOneWidget);
    expect(find.textContaining('Assistant IA : '), findsOneWidget);
  });

  testWidgets('urgence : bouton « Appeler le SAMU (190) », pas de proposition', (tester) async {
    await openAssistant(tester);

    await tester.enterText(find.byType(TextField), "J'ai une très forte douleur dans la poitrine");
    await tester.tap(find.byTooltip('Envoyer'));
    await settle(tester);

    expect(find.text('Appeler le SAMU (190)'), findsOneWidget);
    expect(find.textContaining('Voulez-vous que je vous prenne rendez-vous'), findsNothing);
  });
}
