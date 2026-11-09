import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/features/insurance/data/insurance_explanation_service.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_explanation_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _DemoConfigBundle extends CachingAssetBundle {
  _DemoConfigBundle(this.content);
  final String? content;

  @override
  Future<ByteData> load(String key) async {
    if (content == null) throw FlutterError('Missing asset');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content!)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'direct mode loads the ignored local asset and handles a missing key',
    () async {
      final service = InsuranceExplanationService(
        configAssets: _DemoConfigBundle('local-demo-key\n'),
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer local-demo-key');
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Explication'},
                },
              ],
            }),
            200,
          );
        }),
      );
      expect(
        await service.explain({'status': 'SUBMITTED', 'amount_tnd': 120}),
        'Explication',
      );
      service.dispose();
      final missing = InsuranceExplanationService(
        configAssets: _DemoConfigBundle(null),
      );
      await expectLater(
        missing.explain({'status': 'SUBMITTED', 'amount_tnd': 120}),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Clé Groq absente'),
          ),
        ),
      );
      missing.dispose();
    },
  );

  test(
    'direct Groq requests handle the three tasks without forwarding identity',
    () async {
      var calls = 0;
      final service = InsuranceExplanationService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          calls++;
          expect(
            request.url.toString(),
            'https://api.groq.com/openai/v1/chat/completions',
          );
          expect(request.headers['authorization'], 'Bearer test-key');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List<dynamic>;
          final facts =
              jsonDecode(messages[1]['content'] as String)
                  as Map<String, dynamic>;
          if (calls == 1) {
            expect(facts, {'status': 'SUBMITTED', 'amount_tnd': 100});
          }
          if (calls == 2) {
            expect(facts, {'instruction': 'Envoyez la facture'});
          }
          if (calls == 3) {
            expect(facts['offer']['name'], 'Essentielle');
            expect(facts['budget_tnd'], 50);
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Explication'},
                },
              ],
            }),
            200,
          );
        }),
      );
      expect(
        await service.explain({'status': 'SUBMITTED', 'amount_tnd': 100}),
        'Explication',
      );
      expect(
        await service.explain({
          'task': 'documents',
          'instruction': 'Envoyez la facture',
        }),
        'Explication',
      );
      expect(
        await service.explain({
          'task': 'compare',
          'offer_id': 'demo_essential',
          'budget': 50,
          'priorities': ['pharmacy'],
        }),
        'Explication',
      );
      await expectLater(
        service.explain({
          'status': 'SUBMITTED',
          'amount_tnd': 100,
          'name': 'private',
        }),
        throwsA(isA<AppException>()),
      );
      expect(calls, 3);
      service.dispose();
    },
  );

  test(
    'direct mode reports missing credentials and hides provider errors',
    () async {
      final missing = InsuranceExplanationService(
        apiKey: '',
        client: MockClient((_) async => http.Response('', 500)),
      );
      await expectLater(
        missing.explain({}),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Clé Groq absente'),
          ),
        ),
      );
      final denied = InsuranceExplanationService(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response('secret provider details', 401),
        ),
      );
      await expectLater(
        denied.explain({'status': 'SUBMITTED', 'amount_tnd': 100}),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('refusé'),
          ),
        ),
      );
      missing.dispose();
      denied.dispose();
    },
  );

  test(
    'only status and amounts are sent, without identity, free text or clinical links',
    () async {
      final dossier = InsuranceDossier(
        requestedDocuments: 'Facture acquittée',
        events: [
          {'action': 'SUBMITTED', 'actor': 'Patient privé', 'note': 'secret'},
        ],
      );
      final facts = explanationFacts({
        'status': 'SUBMITTED',
        'amount': 100.0,
        'prenom': 'Privé',
        'policy_number': 'SECRET',
        'consultation_id': 42,
        'document_path': dossier.encode(),
      });
      expect(facts, {'status': 'WAITING_DOCUMENTS', 'amount_tnd': 100.0});
      final service = InsuranceExplanationService(
        url: 'http://127.0.0.1:8787/explain',
        client: MockClient((request) async {
          expect(request.url.toString(), 'http://127.0.0.1:8787/explain');
          expect(jsonDecode(request.body), facts);
          expect(request.body, isNot(contains('SECRET')));
          return http.Response(
            jsonEncode({'explanation': 'Consultez la demande de pièces.'}),
            200,
          );
        }),
      );
      expect(await service.explain(facts), 'Consultez la demande de pièces.');
      service.dispose();
    },
  );

  test('unsafe address and invalid service response are rejected', () async {
    var sent = false;
    final service = InsuranceExplanationService(
      url: 'http://example.com/explain',
      client: MockClient((_) async {
        sent = true;
        return http.Response('{}', 200);
      }),
    );
    await expectLater(service.explain({}), throwsA(isA<AppException>()));
    expect(sent, isFalse);
    service.dispose();
    final invalid = InsuranceExplanationService(
      url: 'http://127.0.0.1:8787/explain',
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(invalid.explain({}), throwsA(isA<AppException>()));
    invalid.dispose();
  });

  test('generated markdown markers and technical statuses are readable', () {
    expect(
      cleanInsuranceExplanation('**Statut** : *SUBMITTED*'),
      'Statut : en cours d’examen',
    );
    expect(
      cleanInsuranceExplanation('## Résultat\n`PAID`'),
      'Résultat\nmarquée payée',
    );
  });

  test(
    'relay failure is described without displaying provider response text',
    () async {
      final service = InsuranceExplanationService(
        url: 'http://127.0.0.1:8787/explain',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'code': 'provider_unreachable',
              'private': 'not to display',
            }),
            502,
          ),
        ),
      );
      await expectLater(
        service.explain({}),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            contains('ne peut pas joindre Groq'),
          ),
        ),
      );
      service.dispose();
    },
  );

  testWidgets('opens and sends once; retry fetches the latest dossier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    final session = SessionService(await SharedPreferences.getInstance());
    await session.open(
      const CurrentUser(
        userId: 2,
        role: UserRole.patient,
        nom: 'Ben Salah',
        prenom: 'Amira',
        email: 'patient@medilink.tn',
        patientId: 1,
      ),
    );
    final repo = InsuranceRepository(db, session);
    final contract = await repo.addContract(
      company: 'CNAM',
      policyNumber: 'PRIVATE',
      coverageRate: .7,
    );
    final id = await repo.submitClaim(contractId: contract, amount: 100);
    final claim = await repo.claim(id);
    var calls = 0;
    final service = InsuranceExplanationService(
      url: 'http://127.0.0.1:8787/explain',
      client: MockClient((request) async {
        calls++;
        expect(request.body, isNot(contains('PRIVATE')));
        if (calls == 1) {
          expect(jsonDecode(request.body)['amount_tnd'], 100);
          return http.Response(
            jsonEncode({'code': 'provider_unreachable'}),
            502,
          );
        }
        if (calls == 2 || calls == 7) {
          expect(jsonDecode(request.body)['amount_tnd'], 80);
        } else {
          final expectedStatus =
              {
                3: 'APPROVED',
                4: 'REJECTED',
                5: 'PAID',
                6: 'WAITING_DOCUMENTS',
              }[calls]!;
          expect(jsonDecode(request.body), {
            'status': expectedStatus,
            'amount_tnd': 120.0,
            if (expectedStatus == 'APPROVED' || expectedStatus == 'PAID')
              'accepted_amount_tnd': 84.0,
          });
        }
        return http.Response(
          jsonEncode({'explanation': 'Votre demande attend une décision.'}),
          200,
        );
      }),
    );
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.lightTheme,
        home: Scaffold(
          body: InsuranceExplanationDialog(
            claim: claim,
            repo: repo,
            service: service,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.textContaining('ne peut pas joindre Groq'), findsOneWidget);
    await repo.correctClaim(id, amount: 80, reason: 'Correction');
    await tester.ensureVisible(find.text('Réessayer'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Réessayer'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Votre demande attend une décision.'), findsOneWidget);
    await tester.ensureVisible(find.text('Approuvée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approuvée'));
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(find.text('EXEMPLE FICTIF'), findsOneWidget);
    for (final label in [
      'Refusée',
      'Paiement indiqué',
      'Pièces attendues',
      'Mon dossier',
    ]) {
      final chip = find.widgetWithText(ChoiceChip, label);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    expect(calls, 7);
    expect(find.text('VOTRE DEMANDE'), findsOneWidget);
    expect((await repo.claim(id))['status'], 'SUBMITTED');
    expect((await repo.claim(id))['amount'], 80);
    expect(tester.takeException(), isNull);
  });
}
