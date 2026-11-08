import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/widgets/consultation_timer.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Durée maximale d'une consultation (30 min) et alerte du médecin.
void main() {
  group('ConsultationDuration', () {
    test('phases : normale, avertissement à 25 min, dépassement à 30 min', () {
      expect(ConsultationDuration.phaseOf(const Duration(minutes: 10)), ConsultationTimePhase.normal);
      expect(ConsultationDuration.phaseOf(const Duration(minutes: 25)), ConsultationTimePhase.warning);
      expect(ConsultationDuration.phaseOf(const Duration(minutes: 29, seconds: 59)), ConsultationTimePhase.warning);
      expect(ConsultationDuration.phaseOf(const Duration(minutes: 30)), ConsultationTimePhase.over);
    });

    test('affichage mm:ss, puis h:mm:ss', () {
      expect(ConsultationDuration.format(const Duration(minutes: 7, seconds: 5)), '07:05');
      expect(ConsultationDuration.format(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(ConsultationDuration.format(const Duration(seconds: -4)), '00:00');
    });
  });

  group('écran de consultation', () {
    setUpAll(() async {
      GoogleFonts.config.allowRuntimeFetching = false;
      sqfliteFfiInit();
      SharedPreferences.setMockInitialValues({'medilink.onboarding_done': true});
      await initialize();
    });

    late AppDatabase database;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'medilink.onboarding_done': true});
      await getIt.reset();
      database = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
      await configureDependencies(appModules, database: database);
      try {
        app.appStore = getIt<AppStore>();
      } catch (_) {
        // Déjà initialisé par un test précédent (late final).
      }
    });

    tearDown(() => database.close());

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<int> idOf(String sql) async => (await database.db.rawQuery(sql)).first.values.first as int;

    /// Consultation en cours chez Dr Benali, commencée il y a [ago].
    Future<int> consultationStarted(Duration ago) async {
      final doctorId = await idOf(
        "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
      );
      final patientId = await idOf(
        "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
      );
      return database.db.insert('consultations', {
        'doctor_id': doctorId,
        'patient_id': patientId,
        'start_time': sqlDateTime(DateTime.now().subtract(ago)),
        'status': 'IN_PROGRESS',
      });
    }

    Future<void> openConsultation(WidgetTester tester, int id) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('overflowed')) original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);

      await tester.pumpWidget(const MediLinkApp());
      await tester.pump(const Duration(seconds: 2)); // splash
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), 'dr.benali@medilink.tn');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
      await tester.tap(find.text('Se connecter'));
      await settle(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push(DoctorRoutes.consultation(id));
      await settle(tester);
    }

    Future<List<Map<String, Object?>>> doctorAlerts() => database.db.rawQuery(
      "SELECT n.* FROM notifications n JOIN users u ON u.id = n.user_id "
      "WHERE u.email = 'dr.benali@medilink.tn' AND n.title = 'Durée maximale de consultation atteinte'",
    );

    testWidgets('avant 30 min : minuteur affiché, pas d\'alerte', (tester) async {
      final id = await consultationStarted(const Duration(minutes: 10));
      await openConsultation(tester, id);

      expect(find.text('Durée de la consultation'), findsOneWidget);
      expect(find.textContaining('sur 30 min'), findsOneWidget);
      expect(find.text('30 minutes écoulées'), findsNothing);
      expect(await doctorAlerts(), isEmpty);
    });

    testWidgets('à 30 min : alerte à l\'écran + notification au médecin, une seule fois', (tester) async {
      final id = await consultationStarted(const Duration(minutes: 31));
      await openConsultation(tester, id);

      expect(find.text('30 minutes écoulées'), findsOneWidget);
      expect(find.textContaining('Amira Ben Salah'), findsWidgets);
      final alerts = await doctorAlerts();
      expect(alerts, hasLength(1));
      expect(alerts.single['body'], contains('Amira Ben Salah'));

      await tester.tap(find.text('Continuer'));
      await settle(tester);
      expect(find.text('30 minutes écoulées'), findsNothing);
      expect(find.textContaining('Durée maximale dépassée'), findsOneWidget);

      // Les secondes passent : pas de nouvelle alerte.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('30 minutes écoulées'), findsNothing);
      expect(await doctorAlerts(), hasLength(1));
    });

    testWidgets('« Clôturer maintenant » ouvre la clôture de la consultation', (tester) async {
      final id = await consultationStarted(const Duration(minutes: 45));
      await openConsultation(tester, id);

      await tester.tap(find.text('Clôturer maintenant'));
      await settle(tester);
      expect(find.text('Clôturer la consultation ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clôturer'));
      await settle(tester);

      final row = await database.db.query('consultations', where: 'consultation_id = ?', whereArgs: [id]);
      expect(row.single['status'], 'CLOSED');
      // Consultation clôturée : plus de minuteur.
      expect(find.text('Durée de la consultation'), findsNothing);
    });
  });
}
