import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/doctor/presentation/widgets/prescription_tile.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Parcours consultation → ordonnance → clôture (médecin), puis lecture de
/// l'ordonnance (patient).
void main() {
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

  // Base en mémoire neuve pour chaque test (sinon elle est partagée).
  tearDown(() => database.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> openAndLogin(WidgetTester tester, String email) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MediLinkApp());
    await tester.pump(const Duration(seconds: 2)); // splash
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
    await tester.tap(find.text('Se connecter'));
    await settle(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // Les listes paresseuses ne construisent pas les éléments hors écran.
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
    }
    await tester.ensureVisible(finder);
    await settle(tester);
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

  Future<int> idOf(String sql) async => (await database.db.rawQuery(sql)).first.values.first as int;

  testWidgets('médecin : démarrer, prescrire, clôturer', (tester) async {
    await ignoringLegacyOverflow(() async {
      await openAndLogin(tester, 'dr.benali@medilink.tn');

      await tester.tap(find.byTooltip('Consultations'));
      await settle(tester);
      expect(find.text('Amira Ben Salah'), findsOneWidget);
      await tapVisible(tester, find.text('Démarrer la consultation'));

      expect(find.text('Allergies : Pénicilline'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Motif de consultation'), 'Palpitations');
      await tester.enterText(find.widgetWithText(TextFormField, 'Température'), '37,5');

      // Rédaction de l'ordonnance (API médicaments injoignable en test : saisie libre).
      await tapVisible(tester, find.widgetWithText(TextButton, 'Nouvelle'));
      expect(find.text('Ordonnance · Amira Ben Salah'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Rechercher un médicament'), 'Doliprane');
      await settle(tester);
      await tapVisible(tester, find.text('Ajouter « Doliprane » manuellement'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Posologie *'), '1 g si fièvre');
      await tapVisible(tester, find.text('5 jours'));
      await tapVisible(tester, find.text('Ajouter à l\'ordonnance'));
      expect(find.text('1 g si fièvre — 5 jours'), findsOneWidget);
      await tester.tap(find.text('Valider l\'ordonnance'));
      await settle(tester);

      expect(find.text('Ordonnance enregistrée'), findsOneWidget);
      expect(find.text('Doliprane'), findsOneWidget);

      await tapVisible(tester, find.text('Clôturer la consultation'));
      await tester.tap(find.widgetWithText(FilledButton, 'Clôturer'));
      await settle(tester);
      expect(find.text('Consultation clôturée'), findsWidgets);
    });

    final patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    final prescriptions = await getIt<PrescriptionRepository>().forPatient(patientId);
    expect(prescriptions.single.items.single.medicamentName, 'Doliprane');
    final consultation = await getIt<ConsultationRepository>().byId(prescriptions.single.consultationId!);
    expect(consultation.motif, 'Palpitations');
    expect(consultation.vitals.temperature, 37.5);
  });

  testWidgets('patient : liste et détail de ses ordonnances', (tester) async {
    final patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    final doctorId = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
    );
    final consultations = getIt<ConsultationRepository>();
    final c = await consultations.start(doctorId: doctorId, patientId: patientId);
    await consultations.saveClinical(c.id, doctorId: doctorId, motif: 'Contrôle');
    await getIt<PrescriptionRepository>().create(
      consultationId: c.id,
      doctorId: doctorId,
      items: const [
        PrescriptionItem(medicamentName: 'Bisoprolol', posologie: '1 cp le matin', dureeTraitement: '3 mois'),
      ],
    );
    await consultations.close(c.id, doctorId: doctorId);

    await openAndLogin(tester, 'patient@medilink.tn');
    await tapVisible(tester, find.text('Ordonnances'));
    expect(find.text('Mes ordonnances'), findsOneWidget);
    final tile = find.byType(PrescriptionTile);
    expect(tile, findsOneWidget);
    expect(find.descendant(of: tile, matching: find.text('Dr Sami Benali')), findsOneWidget);

    await tester.tap(tile);
    await settle(tester);
    expect(find.text('Bisoprolol'), findsOneWidget);
    expect(find.text('1 cp le matin'), findsOneWidget);
    expect(find.text('À présenter en pharmacie'), findsOneWidget);
  });
}
