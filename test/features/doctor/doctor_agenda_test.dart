import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/doctor/presentation/screens/doctor_agenda_tab.dart';
import 'package:medilink/features/doctor/presentation/widgets/agenda_timeline.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Agenda du médecin (tableau de bord) → consultation du rendez-vous.
void main() {
  group('AppointmentConsultation.blockedReason', () {
    setUpAll(() => initializeDateFormatting('fr'));

    final now = DateTime(2026, 11, 7, 14);
    Appointment rdv(DateTime at, AppointmentState status) =>
        Appointment(id: 1, dateTime: at, doctorId: 1, patientId: 1, status: status);

    test('un rendez-vous du jour (même passé ou plus tard) peut être ouvert', () {
      expect(
        AppointmentConsultation.blockedReason(rdv(DateTime(2026, 11, 7, 9), AppointmentState.confirmed), now),
        isNull,
      );
      expect(
        AppointmentConsultation.blockedReason(rdv(DateTime(2026, 11, 7, 18), AppointmentState.pending), now),
        isNull,
      );
    });

    test('un rendez-vous d\'un jour passé non clôturé peut encore être ouvert', () {
      expect(
        AppointmentConsultation.blockedReason(rdv(DateTime(2026, 11, 3, 9), AppointmentState.confirmed), now),
        isNull,
      );
    });

    test('un rendez-vous futur ne peut être démarré que le jour même', () {
      expect(
        AppointmentConsultation.blockedReason(rdv(DateTime(2026, 11, 10, 10), AppointmentState.confirmed), now),
        contains('10 novembre'),
      );
    });

    test('terminé : la consultation se rouvre ; annulé ou absent : refusé', () {
      expect(
        AppointmentConsultation.blockedReason(rdv(DateTime(2026, 11, 3), AppointmentState.completed), now),
        isNull,
      );
      expect(AppointmentConsultation.blockedReason(rdv(now, AppointmentState.cancelled), now), isNotNull);
      expect(AppointmentConsultation.blockedReason(rdv(now, AppointmentState.noShow), now), isNotNull);
    });
  });

  testWidgets('frise : la ligne « Maintenant » se place entre le passé et l\'à venir', (tester) async {
    await initializeDateFormatting('fr');
    final now = DateTime(2026, 11, 7, 12);
    Appointment rdv(int hour, String reason) => Appointment(
      id: hour,
      dateTime: DateTime(2026, 11, 7, hour),
      doctorId: 1,
      patientId: 1,
      reason: reason,
      status: AppointmentState.confirmed,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgendaTimeline(appointments: [rdv(8, 'Matin'), rdv(16, 'Après-midi')], now: now, showNow: true),
          ),
        ),
      ),
    );

    final nowY = tester.getTopLeft(find.text('Maintenant')).dy;
    expect(tester.getTopLeft(find.text('Matin')).dy, lessThan(nowY));
    expect(tester.getTopLeft(find.text('Après-midi')).dy, greaterThan(nowY));
    expect(find.text('12:00'), findsOneWidget);
  });

  group('tableau de bord médecin', () {
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

    /// Ignore les débordements des écrans hérités du template (police de test).
    void ignoreLegacyOverflow() {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('overflowed')) original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);
    }

    Future<void> openAsDrBenali(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      ignoreLegacyOverflow();
      await tester.pumpWidget(const MediLinkApp());
      await tester.pump(const Duration(seconds: 2)); // splash
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), 'dr.benali@medilink.tn');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
      await tester.tap(find.text('Se connecter'));
      await settle(tester);
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
      }
      await tester.ensureVisible(finder);
      await settle(tester);
      await tester.tap(finder);
      await settle(tester);
    }

    /// Fait défiler jusqu'à [finder] (les listes ne construisent pas les éléments hors écran).
    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
        await settle(tester);
      }
    }

    testWidgets('« Agenda du jour » affiche le rendez-vous réel et ouvre sa consultation', (tester) async {
      // Rendez-vous d'aujourd'hui chez Dr Benali pour la patiente de démo.
      final doctorId = await idOf(
        "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
      );
      final patientId = await idOf(
        "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
      );
      final now = DateTime.now();
      final appointmentId = await database.db.insert(AppointmentTables.appointments, {
        'appointment_date_time': Appointment.formatDateTime(DateTime(now.year, now.month, now.day, 8)),
        'reason': 'Douleur thoracique',
        'status': AppointmentStatus.confirmed,
        'doctor_id': doctorId,
        'patient_id': patientId,
      });

      await openAsDrBenali(tester);

      expect(find.text('Agenda du jour'), findsOneWidget);
      expect(find.text('08:00 - 08:30'), findsOneWidget);
      expect(find.text('Douleur thoracique'), findsOneWidget);

      // Détail du rendez-vous : patient, créneau, motif, résumé santé.
      await tapVisible(tester, find.text('Douleur thoracique'));
      expect(find.text('Détail du rendez-vous'), findsOneWidget);
      expect(find.text('Amira Ben Salah'), findsOneWidget);
      expect(find.text('08:00 – 08:30'), findsOneWidget);
      expect(find.text('Douleur thoracique'), findsOneWidget);
      expect(find.text('Pénicilline'), findsOneWidget);
      await scrollTo(tester, find.text('Dossier médical'));
      expect(find.text('Dossier médical'), findsOneWidget);
      expect(await database.db.query('consultations'), isEmpty);

      // Démarrage : écran de consultation du module Médecin, lié au rendez-vous.
      await tapVisible(tester, find.text('Démarrer la consultation'));
      expect(find.text('Allergies : Pénicilline'), findsOneWidget);
      final linked = await database.db.query('consultations', where: 'appointment_id = ?', whereArgs: [appointmentId]);
      expect(linked, hasLength(1));

      // Clôture : le détail affiche « Terminé », puis l'accueil se met à jour.
      await tapVisible(tester, find.text('Clôturer la consultation'));
      await tester.tap(find.widgetWithText(FilledButton, 'Clôturer'));
      await settle(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
      await settle(tester);
      expect(find.text('Détail du rendez-vous'), findsOneWidget);
      await scrollTo(tester, find.text('Voir la consultation'));
      expect(find.text('Voir la consultation'), findsOneWidget);
      GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
      await settle(tester);

      final status = await database.db.query(
        AppointmentTables.appointments,
        columns: ['status'],
        where: 'appointment_id = ?',
        whereArgs: [appointmentId],
      );
      expect(status.single['status'], AppointmentStatus.completed);
      expect(find.text('Terminé'), findsOneWidget);
    });

    testWidgets('l\'onglet Agenda ouvre le détail ; un rendez-vous futur ne peut pas être démarré', (tester) async {
      await openAsDrBenali(tester);

      await tester.tap(find.byTooltip('Agenda'));
      await settle(tester);
      expect(find.text('Mon agenda'), findsOneWidget);

      // Rendez-vous de démo : dans 3 jours, « Contrôle cardiologique ».
      final demoDay = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 3)));
      final key = ValueKey('agenda-day-${DateFormat('yyyy-MM-dd').format(demoDay)}');
      if (find.byKey(key).evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Semaine suivante'));
        await settle(tester);
      }
      await tester.tap(find.byKey(key));
      await settle(tester);

      await tester.tap(find.text('Contrôle cardiologique'));
      await settle(tester);
      expect(find.text('Détail du rendez-vous'), findsOneWidget);
      expect(find.text('Amira Ben Salah'), findsOneWidget);
      expect(find.text('Contrôle cardiologique'), findsOneWidget);
      expect(find.text('Confirmé'), findsOneWidget);
      await scrollTo(tester, find.textContaining('jour du rendez-vous'));
      expect(find.textContaining('jour du rendez-vous'), findsOneWidget);

      // Bouton désactivé : rien n'est créé.
      await tester.tap(find.text('Démarrer la consultation'));
      await settle(tester);
      expect(find.text('Détail du rendez-vous'), findsOneWidget);
      expect(await database.db.query('consultations'), isEmpty);
    });

    testWidgets('le médecin bloque un créneau avec « + », le voit dans l\'agenda, puis le libère', (tester) async {
      await openAsDrBenali(tester);
      await tester.tap(find.byTooltip('Agenda'));
      await settle(tester);

      // Jour du rendez-vous de démo (dans 3 jours, 10:00) : le formulaire propose 09:00 – 10:00.
      final demoDay = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 3)));
      final key = ValueKey('agenda-day-${DateFormat('yyyy-MM-dd').format(demoDay)}');
      if (find.byKey(key).evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Semaine suivante'));
        await settle(tester);
      }
      await tester.tap(find.byKey(key));
      await settle(tester);

      await tester.tap(find.byTooltip('Bloquer un créneau'));
      await settle(tester);
      expect(find.text('Les patients ne pourront pas réserver sur cette plage.'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsWidgets);
      await tester.tap(find.widgetWithText(ActionChip, 'Réunion'));
      await settle(tester);
      await tapVisible(tester, find.text('Bloquer ce créneau'));

      final rows = await database.db.query('doctor_blocked_slots');
      expect(rows.single['title'], 'Réunion');
      expect(rows.single['start_time'], Appointment.formatDateTime(demoDay.add(const Duration(hours: 9))));
      expect(rows.single['end_time'], Appointment.formatDateTime(demoDay.add(const Duration(hours: 10))));

      // Frise : la réunion (09:00) avant le rendez-vous patient (10:00).
      expect(find.text('Indisponible'), findsOneWidget);
      expect(find.text('1 rendez-vous · 1 bloqué'), findsOneWidget);
      final meetingY = tester.getTopLeft(find.text('Réunion')).dy;
      expect(meetingY, lessThan(tester.getTopLeft(find.text('Amira Ben Salah')).dy));

      // Libérer le créneau.
      await tester.ensureVisible(find.text('Réunion'));
      await settle(tester);
      await tester.tap(find.text('Réunion'));
      await settle(tester);
      expect(find.text('Supprimer et libérer le créneau'), findsOneWidget);
      await tester.tap(find.text('Supprimer et libérer le créneau'));
      await settle(tester);
      expect(find.text('Indisponible'), findsNothing);
      expect(await database.db.query('doctor_blocked_slots'), isEmpty);
    });
  });
}
