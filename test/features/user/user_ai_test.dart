import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medilink/features/user/data/ai/document_classifier.dart';
import 'package:medilink/features/user/data/ai/medical_safety_checker.dart';
import 'package:medilink/features/user/data/ai/medical_summary_service.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';

void main() {
  const checker = MedicalSafetyChecker();
  final now = DateTime(2026, 11, 6);

  group('MedicalSafetyChecker', () {
    test('allergie à la pénicilline + Augmentin → alerte critique', () {
      const record = MedicalRecord(patientId: 1, allergies: 'Pénicilline', currentTreatment: 'Augmentin 1g x2/j');
      final alerts = checker.check(record: record, now: now);
      expect(alerts.first.level, AlertLevel.critical);
      expect(alerts.first.title, contains('Allergie'));
      expect(alerts.first.evidence, containsAll(['penicilline', 'augmentin']));
    });

    test('allergie à la pénicilline + céphalosporine → risque croisé', () {
      const record = MedicalRecord(patientId: 1, allergies: 'pénicilline', currentTreatment: 'Céfixime 200 mg');
      final alerts = checker.check(record: record, now: now);
      expect(alerts.single.level, AlertLevel.warning);
      expect(alerts.single.title, contains('croisée'));
    });

    test('asthme + propranolol → contre-indication critique', () {
      const record = MedicalRecord(patientId: 1, chronicDiseases: 'Asthme', currentTreatment: 'Propranolol 40 mg');
      final alerts = checker.check(record: record, now: now);
      expect(alerts.any((a) => a.level == AlertLevel.critical && a.title.contains('Bêtabloquants')), isTrue);
    });

    test('anticoagulant + aspirine → interaction hémorragique', () {
      const record = MedicalRecord(patientId: 1, currentTreatment: 'Sintrom 4 mg, Aspirine 100 mg');
      final alerts = checker.check(record: record, now: now);
      expect(alerts.any((a) => a.title.contains('hémorragique')), isTrue);
    });

    test('metformine sans diabète déclaré → suggestion de compléter', () {
      const record = MedicalRecord(patientId: 1, currentTreatment: 'Metformine 850');
      final alerts = checker.check(record: record, now: now);
      expect(alerts.single.level, AlertLevel.info);
      expect(alerts.single.detail, contains('diabète'));
    });

    test('rappel tétanos de plus de 10 ans', () {
      const record = MedicalRecord(patientId: 1);
      final alerts = checker.check(
        record: record,
        age: 40,
        now: now,
        vaccinations: [Vaccination(patientId: 1, name: 'Tétanos', date: DateTime(2012, 3, 1))],
      );
      expect(alerts.single.title, 'Rappel tétanos dépassé');
    });

    test('dossier cohérent → aucune alerte', () {
      const record = MedicalRecord(
        patientId: 1,
        allergies: 'Arachides',
        chronicDiseases: 'Hypertension',
        currentTreatment: 'Amlodipine 5 mg',
        height: 175,
        weight: 70,
      );
      expect(checker.check(record: record, now: now), isEmpty);
    });

    test('« ains » ne correspond pas à « certains »', () {
      const record = MedicalRecord(patientId: 1, allergies: 'certains pollens', currentTreatment: 'Ibuprofène');
      expect(checker.check(record: record, now: now), isEmpty);
    });
  });

  group('DocumentClassifier', () {
    const classifier = DocumentClassifier();

    test('bilan sanguin → Analyse, sous-type et date du document', () {
      final s = classifier.classify(
        'LABORATOIRE D\'ANALYSES MÉDICALES - Tunis\nDate : 12/05/2026\n'
        'Hémoglobine 13,5 g/dL   Leucocytes 6 500 /mm3   Plaquettes 250 000\n'
        'Glycémie à jeun 0,92 g/L  Valeurs de référence 0,70 - 1,10',
      )!;
      expect(s.category, DocumentCategory.analysis);
      expect(s.title, 'Bilan glycémique — mai 2026');
      expect(s.confidence, greaterThan(0.6));
      expect(s.keywords, isNotEmpty);
    });

    test('ordonnance', () {
      final s = classifier.classify(
        'Dr Ben Salah - Médecine générale\nORDONNANCE\nAmoxicilline 1 g : 1 comprimé 3 fois par jour pendant 7 jours\n'
        'Doliprane 1000 mg QSP 1 boîte',
        now: now,
      )!;
      expect(s.category, DocumentCategory.prescription);
      expect(s.title, startsWith('Ordonnance'));
    });

    test('imagerie', () {
      final s = classifier.classify('Centre de radiologie\nIRM du genou droit\nCoupes sagittales, conclusion : ...')!;
      expect(s.category, DocumentCategory.imaging);
      expect(s.title, startsWith('IRM'));
    });

    test('compte rendu', () {
      final s = classifier.classify(
        'Cher confrère, je vous adresse le compte rendu d\'hospitalisation de votre patient. Antécédents : ...',
      )!;
      expect(s.category, DocumentCategory.report);
    });

    test('texte non médical → aucune proposition', () {
      expect(classifier.classify('Liste de courses : pain, lait, oeufs, tomates'), isNull);
    });
  });

  group('MedicalSummaryService', () {
    final file = PatientMedicalFile(
      patient: PatientIdentity(
        patientId: 7,
        nom: 'Trabelsi',
        prenom: 'Amira',
        phone: '22 333 444',
        dateNaissance: DateTime(1980, 1, 1),
      ),
      record: const MedicalRecord(
        patientId: 7,
        gender: 'F',
        allergies: 'Pénicilline',
        currentTreatment: 'Amoxicilline',
        insuranceNumber: 'CNAM-123456',
      ),
      vaccinations: const [],
      documents: const [],
    );

    test('sans clé → synthèse locale avec les alertes du moteur de règles', () async {
      final service = MedicalSummaryService(MockClient((_) async => http.Response('', 500)), configured: false);
      final s = await service.summarize(file);
      expect(s.isFromLlm, isFalse);
      expect(s.alerts.first.level, AlertLevel.critical);
    });

    test('appel Claude : données anonymisées et réponse structurée', () async {
      late Map<String, dynamic> sent;
      final client = MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.headers['x-api-key'], 'test-key');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'model': 'claude-opus-5-5',
              'stop_reason': 'end_turn',
              'content': [
                {
                  'type': 'text',
                  'text': jsonEncode({
                    'synthese': 'Patiente de 46 ans allergique à la pénicilline.',
                    'points_cles': ['Allergie pénicilline'],
                    'alertes': [
                      {'niveau': 'critique', 'message': 'Amoxicilline contre-indiquée'},
                    ],
                    'questions_a_poser': ['Qui a prescrit l\'amoxicilline ?'],
                    'donnees_manquantes': ['Groupe sanguin'],
                  }),
                },
              ],
            }),
          ),
          200,
        );
      });
      final service = MedicalSummaryService(client, apiKey: 'test-key', configured: true);
      final s = await service.summarize(file);

      expect(s.isFromLlm, isTrue);
      expect(s.alerts.single.level, AlertLevel.critical);
      expect(s.questions, hasLength(1));
      expect(sent['model'], 'claude-opus-5-5');
      expect(sent['output_config']['format']['type'], 'json_schema');
      final prompt = jsonEncode(sent['messages']);
      for (final secret in ['Trabelsi', 'Amira', '22 333 444', 'CNAM-123456']) {
        expect(prompt.contains(secret), isFalse, reason: '$secret ne doit pas être envoyé');
      }
      expect(prompt, contains('Amoxicilline'));
    });

    test('erreur réseau → repli sur la synthèse locale', () async {
      final service = MedicalSummaryService(
        MockClient((_) async => http.Response('overloaded', 529)),
        apiKey: 'k',
        configured: true,
      );
      final s = await service.summarize(file);
      expect(s.isFromLlm, isFalse);
      expect(s.fallbackReason, contains('indisponible'));
    });
  });
}
