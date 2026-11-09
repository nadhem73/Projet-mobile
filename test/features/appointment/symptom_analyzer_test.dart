import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/constants/medical_specialties.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/services/symptom_analyzer.dart';

void main() {
  const analyzer = SymptomAnalyzer();

  test('toutes les spécialités des règles existent dans la liste du projet', () {
    final used = {
      ...SymptomAnalyzer.rules.map((r) => r.specialty),
      ...SymptomAnalyzer.redFlags.map((f) => f.specialty).whereType<String>(),
      'Pédiatrie',
      OrientationResult.defaultSpecialty,
    };
    for (final s in used) {
      expect(MedicalSpecialties.all, contains(s), reason: s);
    }
  });

  test('les mots-clés sont écrits sans accents ni majuscules (sinon ils ne matchent jamais)', () {
    final all = [
      for (final r in SymptomAnalyzer.rules) ...r.keywords,
      for (final f in SymptomAnalyzer.redFlags) ...f.keywords,
      ...SymptomAnalyzer.childKeywords,
      ...SymptomAnalyzer.soonKeywords,
    ];
    for (final k in all) {
      expect(SymptomAnalyzer.normalize(k), k, reason: k);
    }
  });

  group('spécialité', () {
    final cases = {
      "J'ai des palpitations et un essoufflement quand je monte les escaliers depuis une semaine": 'Cardiologie',
      "J'ai des boutons rouges sur les bras et ça me gratte beaucoup": 'Dermatologie',
      "J'ai mal à l'oreille droite et un sifflement dans l'oreille": 'ORL',
      "Ma vue baisse, je vois flou de loin": 'Ophtalmologie',
      "Mal au ventre et diarrhée depuis deux jours": 'Gastro-entérologie',
      "Je tousse beaucoup la nuit, je pense que c'est mon asthme": 'Pneumologie',
      "J'ai des migraines très fortes et des vertiges": 'Neurologie',
      "Mal au dos et au genou quand je marche": 'Rhumatologie',
      "Je me suis tordu la cheville, je pense que c'est une entorse": 'Orthopédie',
      "Mes règles sont très irrégulières": 'Gynécologie',
      "Ça me brûle quand j'urine": 'Urologie',
      "Mon taux de sucre est trop élevé, je suis diabétique": 'Endocrinologie',
      "Je suis très stressé et j'ai des crises d'angoisse": 'Psychiatrie',
      "J'ai une carie, mal aux dents depuis hier": 'Médecine dentaire',
      "J'ai de la fièvre et des courbatures, je pense que c'est la grippe": 'Médecine générale',
    };
    cases.forEach((text, expected) {
      test(expected, () => expect(analyzer.analyze(text).specialty, expected, reason: text));
    });
  });

  test('exemple complet : cardiologie, à consulter cette semaine, raisons', () {
    final r = analyzer.analyze(
      "J'ai des palpitations et un essoufflement quand je monte les escaliers depuis une semaine",
    );
    expect(r.specialty, 'Cardiologie');
    expect(r.urgency, OrientationUrgency.soon);
    expect(r.reasons, containsAll(['palpitations', 'essoufflement']));
    expect(r.confidence, greaterThan(0.7));
    expect(r.source, OrientationSource.offline);
  });

  group('urgences (190)', () {
    test('douleur dans la poitrine → urgence cardiologique', () {
      final r = analyzer.analyze("J'ai une forte douleur dans la poitrine qui descend dans le bras");
      expect(r.isEmergency, isTrue);
      expect(r.specialty, 'Cardiologie');
      expect(r.redFlags, ['douleur dans la poitrine']);
      expect(r.urgency.allowsBooking, isFalse);
    });

    test('difficulté à respirer, AVC, idées suicidaires', () {
      expect(analyzer.analyze("J'ai du mal à respirer").isEmergency, isTrue);
      expect(analyzer.analyze("Mon père a la bouche de travers et n'arrive plus à parler").isEmergency, isTrue);
      final r = analyzer.analyze("Je n'en peux plus, j'ai envie de mourir");
      expect(r.isEmergency, isTrue);
      expect(r.specialty, 'Psychiatrie');
    });
  });

  group('cas particuliers', () {
    test('les négations sont ignorées', () {
      final r = analyzer.analyze("J'ai mal à la gorge mais pas de fièvre");
      expect(r.specialty, 'ORL');
      expect(r.reasons, isNot(contains('fièvre')));
      expect(r.urgency, OrientationUrgency.routine);
      expect(analyzer.analyze("Je n'ai pas de douleur dans la poitrine, juste des boutons").isEmergency, isFalse);
    });

    test('enfant → Pédiatrie, sauf pour les dents', () {
      final r = analyzer.analyze('Mon fils de 4 ans a de la fièvre et tousse');
      expect(r.specialty, 'Pédiatrie');
      expect(r.urgency, OrientationUrgency.soon);
      expect(analyzer.analyze('Ma fille a mal aux dents').specialty, 'Médecine dentaire');
    });

    test('rien de reconnu → généraliste, confiance faible', () {
      final r = analyzer.analyze('Je ne me sens pas bien en ce moment');
      expect(r.specialty, OrientationResult.defaultSpecialty);
      expect(r.isUncertain, isTrue);
    });

    test('pas de faux positifs sur des morceaux de mots', () {
      // « rein » dans « freiner », « dent » dans « accident », « chute » de cheveux.
      expect(
        analyzer.analyze("J'ai dû freiner après un accident de voiture, j'ai mal au dos").specialty,
        'Rhumatologie',
      );
      expect(analyzer.analyze("J'ai une chute de cheveux importante").specialty, 'Dermatologie');
    });

    test('accents, majuscules et apostrophes typographiques', () {
      expect(analyzer.analyze('FIÈVRE ET COURBATURES').specialty, 'Médecine générale');
      expect(analyzer.analyze('J’ai mal à l’oreille').specialty, 'ORL');
    });
  });
}
