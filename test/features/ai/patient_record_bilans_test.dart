import 'dart:typed_data';

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
import 'package:medilink/features/ai/ai_module.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/presentation/widgets/medical_file_widgets.dart';
import 'package:medilink/features/user/user_module.dart';
import 'package:medilink/main.dart' as app;
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Dossier médical vu par le médecin : les bilans scannés du patient
/// apparaissent dans l'onglet « Documents ».
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues({'medilink.onboarding_done': true});
    await initialize();
  });

  late AppDatabase database;
  late int patientId;

  Future<int> idOf(String sql) async => (await database.db.rawQuery(sql)).first.values.first as int;

  Future<void> addBilan(String id, {required String type, required String status, int? doctorId}) async {
    await database.db.insert('bilans', {
      'bilan_id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'type_bilan': type,
      'date_bilan': '2026-10-15',
      'laboratoire': 'Laboratoire Pasteur',
      'status': status,
      'review_status': doctorId == null ? null : 'EN_ATTENTE',
    });
    await database.db.insert('bilan_results', {
      'bilan_id': id,
      'test_name': 'Hémoglobine',
      'valeur': '10.2',
      'unite': 'g/dL',
      'reference_min': 12.0,
      'reference_max': 16.0,
      'status': 'ANORMAL',
    });
  }

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
    patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
  });

  tearDown(() => database.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Renvoie le gestionnaire d'erreurs d'origine, pour réactiver la détection des
  /// débordements sur nos écrans (ceux du template hérité sont ignorés).
  Future<void Function(FlutterErrorDetails)?> loginAndOpen(WidgetTester tester, String email, String route) async {
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
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), DatabaseSeeder.demoPassword);
    await tester.tap(find.text('Se connecter'));
    await settle(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(route);
    await settle(tester);
    return original;
  }

  testWidgets('onglet Documents : bilans validés du patient, ouverture en lecture seule', (tester) async {
    final benali = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
    );
    final gharbi = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.gharbi@medilink.tn'",
    );
    await addBilan('local-nfs', type: 'NFS', status: 'CONFIRMED');
    // Envoyé à Dr Benali : badge « Envoyé à vous · à lire » (ne doit pas déborder).
    await addBilan('local-hba1c', type: 'Hémoglobine glyquée', status: 'CONFIRMED', doctorId: benali);
    // Envoyé à un autre médecin : visible aussi (fait partie du dossier).
    await addBilan('local-lipides', type: 'Bilan lipidique', status: 'CONFIRMED', doctorId: gharbi);
    // Pas encore vérifié par le patient : masqué.
    await addBilan('local-brouillon', type: 'Glycémie', status: 'PENDING');

    // Dr Benali a un rendez-vous avec la patiente de démo → accès au dossier.
    final strict = await loginAndOpen(tester, 'dr.benali@medilink.tn', UserRoutes.doctorPatientRecord(patientId));
    FlutterError.onError = strict;
    await tester.tap(find.text('Documents').first);
    await settle(tester);

    // Synthèse et sections.
    expect(find.text('Documents médicaux'), findsOneWidget);
    expect(find.text('Bilans de laboratoire'), findsOneWidget);
    expect(find.text('NFS'), findsOneWidget);
    expect(find.text('Bilan lipidique'), findsOneWidget);
    expect(find.text('Glycémie'), findsNothing);
    expect(find.text('Envoyé à vous · à lire'), findsOneWidget);
    expect(find.text('1 hors norme'), findsNWidgets(3));

    final emptyDocs = find.textContaining('aucun document (radios');
    await tester.scrollUntilVisible(emptyDocs, 200, scrollable: find.byType(Scrollable).last);
    expect(emptyDocs, findsOneWidget);

    // Filtre « Documents » : les bilans disparaissent ; « Bilans » : l'inverse.
    await tester.tap(find.byKey(const ValueKey('documents-filter-documents')));
    await settle(tester);
    expect(find.text('NFS'), findsNothing);
    expect(find.text('Pièces jointes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('documents-filter-bilans')));
    await settle(tester);
    expect(find.text('Pièces jointes'), findsNothing);
    expect(find.text('NFS'), findsOneWidget);

    await tester.tap(find.text('NFS'));
    await settle(tester);
    expect(find.text('Hémoglobine'), findsWidgets); // points d'attention + résultats

    // Lecture depuis le dossier : le statut de revue du bilan envoyé n'est pas modifié.
    final lipides = await database.db.query('bilans', where: 'bilan_id = ?', whereArgs: ['local-lipides']);
    expect(lipides.single['review_status'], 'EN_ATTENTE');
  });

  testWidgets('pièces jointes : galerie avec catégorie et titre, ouverture plein écran', (tester) async {
    // Octets non décodables : la vignette affiche l'icône de la catégorie.
    await getIt<MedicalRecordRepository>().addDocument(
      patientId: patientId,
      title: 'Radio thorax',
      category: DocumentCategory.imaging,
      data: Uint8List.fromList([1, 2, 3, 4]),
    );

    final strict = await loginAndOpen(tester, 'dr.benali@medilink.tn', UserRoutes.doctorPatientRecord(patientId));
    // Une image illisible est attendue ici (vignette de repli) : seules les erreurs de mise en page comptent.
    FlutterError.onError = (details) {
      if (details.exception is! Exception) strict?.call(details);
    };
    await tester.tap(find.text('Documents').first);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('documents-filter-documents')));
    await settle(tester);

    expect(find.text('Pièces jointes'), findsOneWidget);
    expect(find.text('Radio thorax'), findsOneWidget);
    expect(find.text('Imagerie'), findsOneWidget);

    await tester.tap(find.text('Radio thorax'));
    await settle(tester);
    expect(find.byType(DocumentViewerScreen), findsOneWidget);
  });

  testWidgets('page du bilan : synthèse, points d\'attention, filtre et valeur précédente', (tester) async {
    await database.db.insert('bilans', {
      'bilan_id': 'local-nfs',
      'patient_id': patientId,
      'type_bilan': 'NFS',
      'format': 'ANCIEN_PATIENT',
      'date_bilan': '2026-10-15',
      'laboratoire': 'Laboratoire Pasteur',
      'status': 'CONFIRMED',
    });
    Future<void> result(String name, String value, double min, double max, String status, {String? before}) =>
        database.db.insert('bilan_results', {
          'bilan_id': 'local-nfs',
          'test_name': name,
          'valeur': value,
          'unite': 'g/dL',
          'reference_min': min,
          'reference_max': max,
          'status': status,
          'valeur_ancienne': before,
          'date_ancienne': before == null ? null : '2026-03-12',
        });
    await result('Hémoglobine', '13.5', 12, 16, 'NORMAL', before: '12.8');
    await result('Leucocytes', '14.2', 4, 10, 'ANORMAL');
    await result('Plaquettes', '40', 150, 400, 'CRITIQUE');

    final strict = await loginAndOpen(
      tester,
      'dr.benali@medilink.tn',
      AiRoutes.patientRecordBilan(patientId, 'local-nfs'),
    );
    FlutterError.onError = strict;
    await tester.pump();
    await settle(tester);

    // En-tête : type, laboratoire, compteurs.
    expect(find.text('NFS'), findsWidgets);
    expect(find.textContaining('Laboratoire Pasteur'), findsOneWidget);
    expect(find.text('Hors norme'), findsWidgets);
    expect(find.text('Critiques'), findsOneWidget);

    // Points d'attention : les deux valeurs hors norme, critique en premier.
    expect(find.text('Points d\'attention'), findsOneWidget);
    final plaquettesY = tester.getTopLeft(find.text('Plaquettes').first).dy;
    expect(plaquettesY, lessThan(tester.getTopLeft(find.text('Leucocytes').first).dy));

    // Résultats détaillés : statut + sens de l'écart.
    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('Anormal · Élevé'), 200, scrollable: scrollable);
    expect(find.text('Anormal · Élevé'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Critique · Bas'), 200, scrollable: scrollable);
    expect(find.text('Critique · Bas'), findsOneWidget);

    // Filtre « Normaux » : seule l'hémoglobine reste, avec sa valeur précédente.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('results-filter-normal')), -200, scrollable: scrollable);
    await tester.tap(find.byKey(const ValueKey('results-filter-normal')));
    await settle(tester);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.textContaining('Précédent : 12.8 g/dL'), findsOneWidget);

    // Filtre « Hors norme ».
    await tester.tap(find.byKey(const ValueKey('results-filter-abnormal')));
    await settle(tester);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.textContaining('Précédent'), findsNothing);
  });

  testWidgets('un médecin sans rendez-vous avec le patient n\'a pas accès à ses bilans', (tester) async {
    await addBilan('local-nfs', type: 'NFS', status: 'CONFIRMED');

    // Dr Gharbi n'a aucun rendez-vous avec la patiente de démo.
    await loginAndOpen(tester, 'dr.gharbi@medilink.tn', AiRoutes.patientRecordBilan(patientId, 'local-nfs'));

    expect(find.textContaining('Accès refusé'), findsOneWidget);
    expect(find.text('Hémoglobine'), findsNothing);
  });
}
