import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/data/ocr/bilan_parser.dart';
import 'package:medilink/features/ai/data/ocr/lab_test_dictionary.dart';

void main() {
  final parser = BilanParser();

  BilanResult line(String text) {
    final row = parser.parseLine(text);
    expect(row, isNotNull, reason: 'ligne non reconnue : $text');
    return row!.result;
  }

  group('normalisation', () {
    test('minuscules, sans accents, tiret → espace', () {
      expect(normalizeLabel('  HDL-Cholestérol  Total '), 'hdl cholesterol total');
      expect(normalizeLabel('Hématies / Éosinophiles'), 'hematies / eosinophiles');
    });

    test('alias d\'unités mal lues par l\'OCR', () {
      expect(canonicalUnit('mmoi'), 'mmol/l');
      expect(canonicalUnit('mmoli'), 'mmol/l');
      expect(canonicalUnit('mmo'), 'mmol/l');
      expect(canonicalUnit('umoli'), 'µmol/l');
      expect(canonicalUnit('jmol'), 'µmol/l');
      expect(canonicalUnit('wmol'), 'µmol/l');
      expect(canonicalUnit('µmol/l'), 'µmol/l');
      expect(canonicalUnit('uit'), 'UI/L');
      expect(canonicalUnit('U/L'), 'UI/L');
      expect(canonicalUnit('UI'), 'UI/L');
      expect(canonicalUnit('g/100ml'), 'g/dl');
      expect(canonicalUnit('Hématies'), isNull);
    });
  });

  group('extraction d\'une ligne', () {
    test('valeur à virgule décimale, unité et plage « a - b »', () {
      final r = line('Hémoglobine 13,5 g/dl 12 - 16');
      expect(r.testName, 'Hémoglobine');
      expect(r.valeur, '13,5');
      expect(r.numericValue, 13.5);
      expect(r.unite, 'g/dl');
      expect(r.referenceMin, 12);
      expect(r.referenceMax, 16);
      expect(r.status, ResultStatus.normal);
      expect(r.confiance, OcrConfidence.high);
    });

    test('point décimal et plage « a à b »', () {
      final r = line('Glycémie à jeun 1.32 g/l 0,70 à 1,10');
      expect(r.testName, 'Glycémie');
      expect(r.numericValue, 1.32);
      expect(r.referenceMin, 0.7);
      expect(r.referenceMax, 1.1);
      expect(r.status, ResultStatus.anormal);
    });

    test('unité mal lue « mmoi » corrigée en mmol/l', () {
      final r = line('Glycemie 5,2 mmoi 3,9 - 6,1');
      expect(r.unite, 'mmol/l');
      expect(r.status, ResultStatus.normal);
    });

    test('unités µmol/l et UI/L mal lues', () {
      expect(line('Créatinine 80 jmol 53 - 115').unite, 'µmol/l');
      expect(line('ASAT 25 uit < 40').unite, 'UI/L');
    });

    test('référence « < x » → borne max', () {
      final r = line('CRP 3 mg/l < 6');
      expect(r.referenceMin, isNull);
      expect(r.referenceMax, 6);
      expect(r.referenceLabel, '< 6');
      expect(r.status, ResultStatus.normal);
    });

    test('référence « > x » → borne min, valeur basse = ANORMAL', () {
      final r = line('HDL-Cholestérol 0,32 g/l > 0,40');
      expect(r.testName, 'Cholestérol HDL');
      expect(r.referenceMin, 0.4);
      expect(r.referenceMax, isNull);
      expect(r.status, ResultStatus.anormal);
    });

    test('écart > 50 % de la borne → CRITIQUE', () {
      expect(line('Glycémie 2,10 g/l 0,70 - 1,10').status, ResultStatus.critique);
      expect(line('Hémoglobine 5,5 g/dl 12 - 16').status, ResultStatus.critique);
    });

    test('seuil critique configurable', () {
      final strict = BilanParser(criticalRatio: 0.1);
      expect(strict.parseLine('Glycémie 1,25 g/l 0,70 - 1,10')!.result.status, ResultStatus.critique);
      expect(parser.computeStatus(1.25, 0.7, 1.1), ResultStatus.anormal);
      expect(parser.computeStatus(null, 0.7, 1.1), ResultStatus.nonApplicable);
      expect(parser.computeStatus(3, null, null), ResultStatus.nonApplicable);
    });

    test('format ancien patient : valeur antérieure et sa date', () {
      final r = line('Hématies .............. 4.91 Millions/mm³ 4.75 18/09/25 (4.6 - 6.0)');
      expect(r.testName, 'Globules rouges');
      expect(r.unite, '10^6/mm3');
      expect(r.valeurAncienne, '4.75');
      expect(r.dateAncienne, '2025-09-18');
      expect(r.referenceMin, 4.6);
      expect(r.referenceMax, 6.0);
    });

    test('milliers séparés par une espace sur les numérations', () {
      final r = line('Plaquettes .......... 312 000 /mm³ 295 000 18/09/25 (150000 - 450000)');
      expect(r.numericValue, 312000);
      expect(r.valeurAncienne, '295000');
      expect(r.referenceMax, 450000);
      expect(r.status, ResultStatus.normal);
    });

    test('formule : pourcentage puis valeur absolue', () {
      expect(line('Polynucléaires Neutrophiles ...... 60.8 % 18/09/25 (40 - 70)').testName, 'Neutrophiles');
      expect(
        line('Polynucléaire Neutrophiles ...... 4 490 mm3 4 910 18/09/25 (1800-7500)').testName,
        'Neutrophiles (valeur absolue)',
      );
    });

    test('fuzzy matching : nom mal lu reconnu (similarité ≥ 0.72)', () {
      expect(line('Hemoglobme 13,1 g/dl 12 - 16').testName, 'Hémoglobine');
      expect(line('Triglycerldes 1,2 g/l 0,4 - 1,5').testName, 'Triglycérides');
      expect(line('Cholesterol totaI 1,8 g/l 1,5 - 2,0').testName, 'Cholestérol total');
      final r = line('Hemoglobme 13,1 g/dl 12 - 16');
      expect(r.confiance, OcrConfidence.low, reason: 'nom approximatif → à vérifier');
      expect(r.needsCheck, isTrue);
    });

    test('fuzzy matching : nom trop éloigné rejeté', () {
      expect(parser.parseLine('Xyzwq 12 g/l'), isNull);
      expect(BilanParser.similarity('hemoglobine', 'hemoglobme'), greaterThanOrEqualTo(0.72));
      expect(BilanParser.similarity('potassium', 'plaquettes'), lessThan(0.72));
    });

    test('« hémoglobine glycosylée » → HbA1c et non Hémoglobine', () {
      final r = line('HEMOGLOBINE GLYCOSYLEE (HbA1c) 5.51 %');
      expect(r.testName, 'HbA1c');
      expect(r.unite, '%');
    });

    test('texte bruité : O lu à la place de 0, unité collée à la valeur', () {
      final r = line('Urée 0,3O g/l 0,15 - 0,45');
      expect(r.numericValue, 0.30);
      final glued = line('Hémoglobine 14,2g/dl 13 - 17');
      expect(glued.valeur, '14,2');
      expect(glued.unite, 'g/dl');
    });

    test('unité inattendue pour le test → confiance faible', () {
      final r = line('Hémoglobine 13,5 mmol/l 12 - 16');
      expect(r.confiance, OcrConfidence.low);
    });
  });

  group('lignes parasites', () {
    test('en-têtes, adresses, téléphones, identité ignorés', () {
      expect(parser.isNoiseLine('Tél : 73 680 123 - Fax : 73 680 124'), isTrue);
      expect(parser.isNoiseLine('12, Avenue Habib Bourguiba 5100 Mahdia'), isTrue);
      expect(parser.isNoiseLine('Code Patient : 202829'), isTrue);
      expect(parser.isNoiseLine('Dossier N° 260713/0024'), isTrue);
      expect(parser.isNoiseLine('REPUBLIQUE TUNISIENNE'), isTrue);
      expect(parser.isNoiseLine('Hémoglobine 13,5 g/dl 12 - 16'), isFalse);
    });
  });

  group('bilan complet', () {
    const hematologie = '''
REPUBLIQUE TUNISIENNE
MINISTERE DE LA SANTE
SERVICE LABORATOIRE
LABORATOIRE GROUPEMENT SANTE DE BASE MAHDIA
Mahdia, Le : 13/07/2026        Dossier N° 260713/0024
Résultats d'analyses   Nom ****  24/01/1960
Code Patient : 202829    SERVICE : ESSAAD
Antériorités   Valeurs usuelles
HEMATOLOGIE
HEMOGRAMME
Hématies .............. 4.91 Millions/mm³ 4.75 18/09/25 (4.6 - 6.0)
Hémoglobine ........... 13.6 g/dl 13.6 18/09/25 (13 - 17)
Hématocrite ........... 41.9 °o 41.7 18/09/25 (39 - 55)
VGM ................... 85.30 fl 87.80 18/09/25 (80 - 100)
TCMH .................. 27.70 pg 28.60 18/09/25 (27 - 33)
CCMH .................. 32.50 g/dl 32.60 18/09/25 (30 - 36)
Leucocytes ............ 7 380 mm³ 7 300 18/09/25 (4000 - 10000)
FORMULE
Polynucléaires Neutrophiles ...... 60.8 % 18/09/25 (40 - 70)
Polynucléaire Neutrophiles ....... 4 490 mm3 4 910 18/09/25 (1800-7500)
Polynucléaires Eosinophiles ...... 5.3 % 18/09/25 (0 - 4)
Lymphocytes ...................... 25.3 % 18/09/25 (20 - 50)
Monocytes ........................ 7.9 % 18/09/25 (2 - 8)
Plaquettes ....................... 312 000 /mm³ 295 000 18/09/25 (150000 - 450000)
VITESSE DE SEDIMENTATION
Première heure ......... 6 mm 8 22/12/25 (< 10)
Deuxième heure ......... 21 mm 22 22/12/25 (< 25)
Nous vous remercions de votre confiance
Le biologiste
''';

    test('hématologie, format ancien patient (photo réelle)', () {
      final bilan = parser.parse(hematologie, id: 'local-1', patientId: 7);
      expect(bilan.id, 'local-1');
      expect(bilan.patientId, 7);
      expect(bilan.status, BilanStatus.pending);
      expect(bilan.synced, isFalse);
      expect(bilan.format, BilanFormat.ancienPatient);
      expect(bilan.typeBilan, 'NFS');
      expect(bilan.laboratoire, 'LABORATOIRE GROUPEMENT SANTE DE BASE MAHDIA');
      expect(bilan.dateBilan, '2026-07-13', reason: 'date du bilan, pas la date de naissance');

      final names = bilan.resultats.map((r) => r.testName).toList();
      expect(
        names,
        containsAll([
          'Globules rouges',
          'Hémoglobine',
          'Hématocrite',
          'VGM',
          'TCMH',
          'CCMH',
          'Globules blancs',
          'Neutrophiles',
          'Neutrophiles (valeur absolue)',
          'Éosinophiles',
          'Lymphocytes',
          'Monocytes',
          'Plaquettes',
          'VS',
          'VS 2e heure',
        ]),
      );
      expect(names.toSet().length, names.length, reason: 'pas de doublon');

      BilanResult byName(String n) => bilan.resultats.firstWhere((r) => r.testName == n);
      expect(byName('Hématocrite').unite, '%');
      expect(byName('Globules blancs').numericValue, 7380);
      expect(byName('Éosinophiles').status, ResultStatus.anormal);
      expect(byName('VS').referenceMax, 10);
      expect(bilan.abnormalCount, 1);
    });

    test('biochimie, nouveau patient, unités bruitées', () {
      const text = '''
LABORATOIRE GROUPEMENT SANTE DE BASE MAHDIA
Mahdia, Le : 15/07/2026
BIOCHIMIE
HEMOGLOBINE GLYCOSYLEE (HbA1c) 5.51 %
CHOLESTEROL TOTAL ....... 4.40 mmoi (3.6 - 5.7)
HDL -CHOLESTEROL ........ 1.57 mmol/l > 1
TRIGLYCERIDES ........... 0.57 mmo/l (< 1.70)
CREATININE .............. 87 umoli (50 - 115)
ASAT (SGOT) ............. 28 UI/I (< 40)
ALAT (SGPT) ............. 27 uit (< 40)
Le biologiste
Signature
''';
      final bilan = parser.parse(text);
      expect(bilan.format, BilanFormat.nouveauPatient);
      expect(bilan.typeBilan, 'Biochimie');
      expect(bilan.dateBilan, '2026-07-15');
      expect(bilan.resultats.map((r) => r.testName), [
        'HbA1c',
        'Cholestérol total',
        'Cholestérol HDL',
        'Triglycérides',
        'Créatinine',
        'ASAT',
        'ALAT',
      ]);
      expect(bilan.resultats.map((r) => r.unite), ['%', 'mmol/l', 'mmol/l', 'mmol/l', 'µmol/l', 'UI/L', 'UI/L']);
      expect(bilan.resultats.every((r) => r.status != ResultStatus.anormal), isTrue);
    });

    test('texte vide ou illisible → aucun résultat, sans exception', () {
      expect(parser.parse('').resultats, isEmpty);
      expect(parser.parse('@@@ ### \n ~~~ \n ....').resultats, isEmpty);
    });
  });
}
