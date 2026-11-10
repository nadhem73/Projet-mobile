import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/lab_request_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/doctor/presentation/widgets/lab_request_tile.dart';
import 'package:medilink/features/doctor/presentation/widgets/prescription_tile.dart';
import 'package:medilink/features/pharmacy/data/models/prescription_dispatch.dart';
import 'package:medilink/features/pharmacy/data/repositories/prescription_dispatch_repository.dart';
import 'package:medilink/features/user/user_module.dart';
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

  /// Liste de la page (en ignorant le défilement interne des champs multi-lignes).
  Finder pageScrollable() =>
      find.byElementPredicate((e) {
        if (e.widget is! Scrollable) return false;
        var inField = false;
        e.visitAncestorElements((a) {
          inField = a.widget is EditableText;
          return !inField;
        });
        return !inField;
      }).last;

  /// Les listes paresseuses ne construisent pas les éléments hors écran.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 200, scrollable: pageScrollable());
    }
    await tester.ensureVisible(finder);
    await settle(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> enterVisible(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextFormField, label);
    await scrollTo(tester, field);
    await tester.enterText(field, text);
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
      await enterVisible(tester, 'Température', '37,5');
      await enterVisible(tester, 'Motif de consultation', 'Palpitations');

      // Rédaction de l'ordonnance : seuls les médicaments du catalogue (table medicines) sont prescriptibles.
      await tapVisible(tester, find.widgetWithText(TextButton, 'Nouvelle'));
      expect(find.text('Ordonnance · Amira Ben Salah'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Rechercher un médicament'), 'Doliprane');
      await settle(tester);
      expect(find.textContaining('manuellement'), findsNothing);
      await tapVisible(tester, find.widgetWithText(ListTile, 'DOLIPRANE').first);
      await tester.enterText(find.widgetWithText(TextFormField, 'Posologie *'), '1 g si fièvre');
      await tapVisible(tester, find.text('5 jours'));
      await tapVisible(tester, find.text('Ajouter à l\'ordonnance'));
      expect(find.text('1 g si fièvre — 5 jours'), findsOneWidget);
      await tester.tap(find.text('Valider l\'ordonnance'));
      await settle(tester);

      expect(find.text('Ordonnance enregistrée'), findsOneWidget);
      expect(find.text('DOLIPRANE'), findsOneWidget);

      // Demande de bilan.
      await tapVisible(tester, find.widgetWithText(TextButton, 'Demander'));
      await tester.tap(find.widgetWithText(FilterChip, 'CRP'));
      await settle(tester);
      await tester.tap(find.text('Ajouter la demande (1 analyse)'));
      await settle(tester);
      expect(find.text('Demande de bilan ajoutée'), findsOneWidget);
      expect(find.text('CRP'), findsOneWidget);

      await tapVisible(tester, find.text('Clôturer la consultation'));
      await tester.tap(find.widgetWithText(FilledButton, 'Clôturer'));
      await settle(tester);
      expect(find.text('Consultation clôturée'), findsWidgets);
    });

    final patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    final prescriptions = await getIt<PrescriptionRepository>().forPatient(patientId);
    final item = prescriptions.single.items.single;
    expect(item.medicamentName, 'DOLIPRANE');
    // La ligne est rattachée à un médicament existant du catalogue.
    final medicine = await database.db.query('medicines', where: 'medicine_id = ?', whereArgs: [item.medicamentId]);
    expect(medicine.single['name'], 'DOLIPRANE');
    // Publiée avec l'ordonnance à la clôture (onglet Documents du patient).
    expect((await getIt<LabRequestRepository>().forPatient(patientId)).single.tests, ['CRP']);
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
    final prescription = await getIt<PrescriptionRepository>().create(
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

    // Envoi à la pharmacie choisie par le patient.
    await tapVisible(tester, find.text('Envoyer à une pharmacie'));
    expect(find.text('Choisir une pharmacie'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.local_pharmacy_rounded).first);
    await settle(tester);
    expect(find.textContaining('Ordonnance envoyée à'), findsOneWidget);
    expect(find.text('Envoyée'), findsOneWidget);
    expect(find.text('Changer de pharmacie'), findsOneWidget);
    final dispatch = await getIt<PrescriptionDispatchRepository>().forPrescription(prescription.id);
    expect(dispatch!.status, DispatchStatus.sent);
    expect(await getIt<PrescriptionDispatchRepository>().pendingCount(dispatch.pharmacyId), 1);
  });

  testWidgets('patient : ordonnances et bilans demandés dans l\'onglet Documents', (tester) async {
    final patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    final doctorId = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
    );
    final consultations = getIt<ConsultationRepository>();
    final c = await consultations.start(doctorId: doctorId, patientId: patientId);
    await consultations.saveClinical(c.id, doctorId: doctorId, motif: 'Bilan annuel');
    await getIt<PrescriptionRepository>().create(
      consultationId: c.id,
      doctorId: doctorId,
      items: const [PrescriptionItem(medicamentName: 'Vitamine D3', posologie: '1 ampoule', dureeTraitement: '3 mois')],
    );
    await getIt<LabRequestRepository>().create(
      consultationId: c.id,
      doctorId: doctorId,
      tests: const ['Glycémie à jeun', 'Bilan lipidique'],
    );

    await openAndLogin(tester, 'patient@medilink.tn');
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));

    // Consultation en cours : rien n'est encore publié.
    router.push(UserRoutes.medicalRecord);
    await settle(tester);
    await tester.tap(find.text('Documents'));
    await settle(tester);
    expect(find.text('Ordonnances (0)'), findsOneWidget);
    expect(find.text('Bilans demandés (0)'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Après la clôture : l'ordonnance et la demande de bilan apparaissent.
    await consultations.close(c.id, doctorId: doctorId);
    router.push(UserRoutes.medicalRecord);
    await settle(tester);
    await tester.tap(find.text('Documents'));
    await settle(tester);
    expect(find.text('Ordonnances (1)'), findsOneWidget);
    expect(find.text('Bilans demandés (1)'), findsOneWidget);
    expect(find.text('Glycémie à jeun, Bilan lipidique'), findsOneWidget);

    await tapVisible(tester, find.byType(LabRequestTile));
    expect(find.text('Analyses à réaliser (2)'), findsOneWidget);
  });

  testWidgets('patient : historique et compte rendu de ses consultations', (tester) async {
    final patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    final doctorId = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
    );
    final consultations = getIt<ConsultationRepository>();
    final c = await consultations.start(doctorId: doctorId, patientId: patientId);
    await consultations.saveClinical(
      c.id,
      doctorId: doctorId,
      motif: 'Toux persistante',
      diagnostic: 'Bronchite aiguë',
      vitals: const VitalSigns(temperature: 38.2),
    );
    await getIt<PrescriptionRepository>().create(
      consultationId: c.id,
      doctorId: doctorId,
      items: const [PrescriptionItem(medicamentName: 'Amoxicilline', posologie: '1 g x 2', dureeTraitement: '7 jours')],
    );
    await consultations.close(c.id, doctorId: doctorId);

    await openAndLogin(tester, 'patient@medilink.tn');
    await tapVisible(tester, find.text('Consultations'));
    expect(find.text('Mes consultations'), findsOneWidget);
    expect(find.text('Dr Sami Benali'), findsOneWidget);
    expect(find.text('Bronchite aiguë'), findsOneWidget);

    await tester.tap(find.text('Bronchite aiguë'));
    await settle(tester);
    expect(find.text('Toux persistante'), findsOneWidget);
    expect(find.text('38,2 °C'), findsOneWidget);
    expect(find.text('Ordonnances (1)'), findsOneWidget);
    expect(find.byType(PrescriptionTile), findsOneWidget);
  });

  testWidgets('pharmacien : reçoit l\'ordonnance, la prépare puis la délivre', (tester) async {
    final patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    final patientUserId = await idOf("SELECT id FROM users WHERE email = 'patient@medilink.tn'");
    final doctorId = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
    );
    final pharmacyId = await idOf(
      "SELECT ph.pharmacy_id FROM pharmacies ph JOIN users u ON u.id = ph.pharmacien_user_id "
      "WHERE u.email = 'pharmacie@medilink.tn'",
    );
    final consultations = getIt<ConsultationRepository>();
    final c = await consultations.start(doctorId: doctorId, patientId: patientId);
    await consultations.saveClinical(c.id, doctorId: doctorId, motif: 'Angine');
    final prescription = await getIt<PrescriptionRepository>().create(
      consultationId: c.id,
      doctorId: doctorId,
      items: const [PrescriptionItem(medicamentName: 'Amoxicilline', posologie: '1 g x 2', dureeTraitement: '6 jours')],
    );
    await consultations.close(c.id, doctorId: doctorId);
    await getIt<PrescriptionDispatchRepository>().send(
      prescriptionId: prescription.id,
      pharmacyId: pharmacyId,
      user: CurrentUser(
        userId: patientUserId,
        role: UserRole.patient,
        nom: 'Ben Salah',
        prenom: 'Amira',
        email: 'patient@medilink.tn',
        patientId: patientId,
      ),
    );

    await ignoringLegacyOverflow(() async {
      await openAndLogin(tester, 'pharmacie@medilink.tn');
      await tester.tap(find.text('Ordonnances'));
      await settle(tester);
      expect(find.text('Ordonnances reçues'), findsOneWidget);
      expect(find.text('Amira Ben Salah'), findsOneWidget);
      expect(find.text('Envoyée'), findsOneWidget);

      await tester.tap(find.text('Marquer prête'));
      await settle(tester);
      expect(find.text('Prête à retirer'), findsOneWidget);
      await tester.tap(find.text('Marquer délivrée'));
      await settle(tester);
      expect(find.text('Délivrée'), findsOneWidget);
      expect(find.text('Marquer délivrée'), findsNothing);
    });
    final dispatch = await getIt<PrescriptionDispatchRepository>().forPrescription(prescription.id);
    expect(dispatch!.status, DispatchStatus.delivered);
  });
}
