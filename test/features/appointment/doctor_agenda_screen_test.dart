import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Agenda de la semaine du médecin, sur les données de démo.
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

  testWidgets('le médecin voit ses rendez-vous en choisissant le jour', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    // Le tableau de bord médecin (écran hérité du template) peut déborder avec la police de test.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(const MediLinkApp());
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), 'dr.benali@medilink.tn');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
    await tester.tap(find.text('Se connecter'));
    await settle(tester);

    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(AppointmentRoutes.doctorAgenda);
    await settle(tester);
    expect(find.text('Mon agenda'), findsOneWidget);

    // Rendez-vous de démo : dans 3 jours à 10h, « Contrôle cardiologique ».
    final demoDay = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 3)));
    final key = ValueKey('agenda-day-${DateFormat('yyyy-MM-dd').format(demoDay)}');
    if (find.byKey(key).evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Semaine suivante'));
      await settle(tester);
    }
    await tester.tap(find.byKey(key));
    await settle(tester);

    expect(find.text('1 rendez-vous'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('Contrôle cardiologique'), findsOneWidget);
    expect(find.text('Confirmé'), findsOneWidget);

    // Le lendemain : journée libre.
    final nextKey = ValueKey('agenda-day-${DateFormat('yyyy-MM-dd').format(demoDay.add(const Duration(days: 1)))}');
    if (find.byKey(nextKey).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(nextKey));
      await settle(tester);
      expect(find.text('Journée libre'), findsOneWidget);
    }
  });
}
