import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/services/llm_orientation_service.dart';
import 'package:medilink/features/appointment/data/services/orientation_engine.dart';
import 'package:medilink/features/appointment/data/services/symptom_analyzer.dart';

/// Réponse au format OpenAI « chat/completions » contenant [content].
http.Response chatResponse(String content, {int status = 200}) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'choices': [
        {
          'message': {'role': 'assistant', 'content': content},
        },
      ],
    }),
  ),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  const offline = SymptomAnalyzer();

  group('lecture de la réponse du modèle', () {
    test('JSON simple', () {
      final r =
          LlmOrientationService.parseContent(
            '{"specialty":"Cardiologie","urgency":"soon","reasons":["palpitations"],"redFlags":[],"confidence":0.85}',
          )!;
      expect(r.specialty, 'Cardiologie');
      expect(r.urgency, OrientationUrgency.soon);
      expect(r.reasons, ['palpitations']);
      expect(r.source, OrientationSource.llm);
    });

    test('JSON entouré de ```json et de texte, spécialité en minuscules', () {
      final r =
          LlmOrientationService.parseContent(
            'Voici ma réponse :\n```json\n{"specialty":"dermatologie","urgency":"routine","reasons":["a","b","c","d","e"],'
            '"confidence":0.7}\n```',
          )!;
      expect(r.specialty, 'Dermatologie');
      expect(r.reasons, hasLength(4)); // 4 raisons maximum
    });

    test('réponses inexploitables → null', () {
      expect(LlmOrientationService.parseContent('Je ne sais pas'), isNull);
      expect(LlmOrientationService.parseContent('{"specialty": "Médecin magique", "urgency": "soon"}'), isNull);
      expect(LlmOrientationService.parseContent('{"specialty": "ORL", "urgency": "demain"}'), isNull);
      expect(LlmOrientationService.parseContent('{pas du json}'), isNull);
    });
  });

  group('appel HTTP', () {
    test('requête au format OpenAI avec la clé, et lecture de la réponse', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return chatResponse('{"specialty":"ORL","urgency":"routine","reasons":["oreille bouchée"],"confidence":0.8}');
      });
      final llm = LlmOrientationService(
        client,
        apiKey: 'test-key',
        baseUrl: 'https://llm.test/v1/',
        model: 'mon-modele',
      );

      final r = await llm.analyze("J'ai l'oreille bouchée");
      expect(r!.specialty, 'ORL');
      expect(sent.url.toString(), 'https://llm.test/v1/chat/completions');
      expect(sent.headers['Authorization'], 'Bearer test-key');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], 'mon-modele');
      expect((body['messages'] as List).last['content'], "J'ai l'oreille bouchée");
      expect((body['messages'] as List).first['content'], contains('Cardiologie'));
    });

    test('sans clé : aucun appel réseau', () async {
      var calls = 0;
      final llm = LlmOrientationService(MockClient((_) async => (calls++, chatResponse('{}')).$2), apiKey: '');
      expect(llm.isEnabled, isFalse);
      expect(await llm.analyze('mal au ventre'), isNull);
      expect(calls, 0);
    });

    test('quota dépassé (429) ou réseau coupé → null', () async {
      final quota = LlmOrientationService(
        MockClient((_) async => http.Response('{"error":"quota"}', 429)),
        apiKey: 'k',
      );
      expect(await quota.analyze('mal au ventre'), isNull);

      final offlineNet = LlmOrientationService(
        MockClient((_) async => throw http.ClientException('pas de réseau')),
        apiKey: 'k',
      );
      expect(await offlineNet.analyze('mal au ventre'), isNull);
    });
  });

  group('moteur hybride', () {
    OrientationEngine engineWith(String content, {void Function()? onCall}) => OrientationEngine(
      offline,
      LlmOrientationService(
        MockClient((_) async {
          onCall?.call();
          return chatResponse(content);
        }),
        apiKey: 'k',
      ),
    );

    test('le LLM comprend une phrase que les mots-clés ne reconnaissent pas', () async {
      const text = "Depuis quelques jours j'ai l'impression que tout tourne quand je me lève du lit";
      final engine = engineWith(
        '{"specialty":"ORL","urgency":"soon","reasons":["vertiges positionnels"],"confidence":0.7}',
      );
      final r = await engine.analyze(text);
      expect(r.source, OrientationSource.llm);
      expect(r.specialty, 'ORL');
    });

    test('urgence repérée hors ligne : le LLM n\'est même pas appelé', () async {
      var called = false;
      final engine = engineWith(
        '{"specialty":"Dermatologie","urgency":"routine","confidence":0.9}',
        onCall: () => called = true,
      );
      final r = await engine.analyze("J'ai une douleur dans la poitrine");
      expect(r.isEmergency, isTrue);
      expect(called, isFalse);
    });

    test('urgence repérée par le LLM : elle est gardée', () async {
      final engine = engineWith(
        '{"specialty":"Neurologie","urgency":"emergency","redFlags":["trouble soudain de la parole"],"confidence":0.9}',
      );
      final r = await engine.analyze('Mon mari parle bizarrement depuis ce matin');
      expect(r.isEmergency, isTrue);
      expect(r.redFlags, ['trouble soudain de la parole']);
    });

    test('réponse inutilisable du LLM → analyse hors ligne', () async {
      final engine = engineWith('Désolé, je ne peux pas répondre.');
      final r = await engine.analyze("J'ai des boutons qui grattent");
      expect(r.source, OrientationSource.offline);
      expect(r.specialty, 'Dermatologie');
    });

    test('LLM non configuré → analyse hors ligne', () async {
      const engine = OrientationEngine(offline, null);
      expect(engine.usesLlm, isFalse);
      expect((await engine.analyze("J'ai des palpitations")).source, OrientationSource.offline);
    });
  });
}
