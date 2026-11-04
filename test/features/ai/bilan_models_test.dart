import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/data/models/doctor_option.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';

/// Réponse de `POST /api/bilans/scan` (bilan-service, MediLink Tunisia),
/// au format renvoyé par `BilanService.toResponse`.
const _scanResponse = '''
{
  "id": "3f6c2a1e-8b7d-4c1a-9f0e-2d5b6a7c8e90",
  "typeBilan": "Hematologie",
  "format": "ANCIEN_PATIENT",
  "dateBilan": "2026-07-13",
  "laboratoire": "LABORATOIRE GROUPEMENT SANTE DE BASE MAHDIA",
  "status": "PENDING",
  "reviewStatus": null,
  "patientId": 12,
  "doctorId": null,
  "resultats": [
    {
      "id": 101, "testName": "hematies", "valeur": "4.91", "unite": "/mm3",
      "referenceMin": 4.6, "referenceMax": 6, "referenceText": "4.6 - 6.0",
      "valeurAncienne": "4.75", "dateAncienne": "2025-09-18",
      "status": "NORMAL", "confiance": "haute"
    },
    {
      "id": 102, "testName": "polynucleaires eosinophiles", "valeur": "5.3", "unite": "%",
      "referenceMin": 0, "referenceMax": 4, "referenceText": "0 - 4",
      "valeurAncienne": null, "dateAncienne": null,
      "status": "ANORMAL", "confiance": "moyenne"
    },
    {
      "id": 103, "testName": "vs", "valeur": "<5", "unite": "mm",
      "referenceMin": null, "referenceMax": null, "referenceText": "< 10",
      "valeurAncienne": null, "dateAncienne": null,
      "status": "NON_APPLICABLE", "confiance": "faible"
    }
  ]
}
''';

void main() {
  group('ScanBilan', () {
    test('fromJson sur une réponse réelle', () {
      final bilan = ScanBilan.fromJson(jsonDecode(_scanResponse) as Map<String, dynamic>);
      expect(bilan.id, '3f6c2a1e-8b7d-4c1a-9f0e-2d5b6a7c8e90');
      expect(bilan.isLocal, isFalse);
      expect(bilan.format, BilanFormat.ancienPatient);
      expect(bilan.status, BilanStatus.pending);
      expect(bilan.reviewStatus, isNull);
      expect(bilan.patientId, 12);
      expect(bilan.doctorId, isNull);
      expect(bilan.date, DateTime(2026, 7, 13));
      expect(bilan.resultats, hasLength(3));
      expect(bilan.abnormalCount, 1);

      final first = bilan.resultats.first;
      expect(first.referenceMax, 6.0, reason: 'un int JSON devient un double');
      expect(first.valeurAncienne, '4.75');
      expect(first.status, ResultStatus.normal);
      expect(first.needsCheck, isFalse);
      expect(bilan.resultats.last.needsCheck, isTrue);
      expect(bilan.resultats.last.referenceLabel, '< 10');
    });

    test('toJson → fromJson conserve toutes les valeurs', () {
      final json = jsonDecode(_scanResponse) as Map<String, dynamic>;
      final roundTrip = ScanBilan.fromJson(jsonDecode(jsonEncode(ScanBilan.fromJson(json).toJson())));
      expect(roundTrip.toJson(), ScanBilan.fromJson(json).toJson());
      expect(roundTrip.toJson()['format'], 'ANCIEN_PATIENT');
      expect((roundTrip.toJson()['resultats'] as List).first['referenceMin'], 4.6);
    });

    test('valeurs inconnues ou absentes : pas de plantage', () {
      final bilan = ScanBilan.fromJson({
        'id': 42,
        'format': 'FORMAT_FUTUR',
        'status': 'ARCHIVED',
        'reviewStatus': 'EN_COURS_DE_LECTURE',
        'resultats': [
          {'id': 1, 'testName': 'X', 'valeur': 3, 'status': 'TRES_BAS'},
        ],
      });
      expect(bilan.id, '42');
      expect(bilan.format, BilanFormat.nouveauPatient);
      expect(bilan.status, BilanStatus.pending);
      expect(bilan.reviewStatus, isNull);
      expect(bilan.typeBilan, 'Bilan');
      expect(bilan.resultats.single.status, ResultStatus.nonApplicable);
      expect(bilan.resultats.single.valeur, '3');
    });

    test('toMap / fromMap (SQLite)', () {
      final bilan = ScanBilan.fromJson(
        jsonDecode(_scanResponse) as Map<String, dynamic>,
      ).copyWith(synced: false, imagePath: '/tmp/a.jpg');
      final map = bilan.toMap(rawText: 'texte');
      expect(map['synced'], 0);
      expect(map['raw_text'], 'texte');
      final back = ScanBilan.fromMap(map, bilan.resultats);
      expect(back.synced, isFalse);
      expect(back.imagePath, '/tmp/a.jpg');
      expect(back.format, BilanFormat.ancienPatient);
    });
  });

  group('BilanResult', () {
    test('toMap / fromMap', () {
      const r = BilanResult(
        id: 0,
        testName: 'Glycémie',
        valeur: '1,32',
        unite: 'g/l',
        referenceMin: 0.7,
        referenceMax: 1.1,
        status: ResultStatus.anormal,
        confiance: 'haute',
      );
      final back = BilanResult.fromMap({...r.toMap('b1'), 'result_id': 9});
      expect(back.id, 9);
      expect(back.numericValue, 1.32);
      expect(back.referenceLabel, '0,7 – 1,1');
      expect(back.status, ResultStatus.anormal);
    });

    test('parseNumber et formatNumber', () {
      expect(parseNumber('13,5'), 13.5);
      expect(parseNumber('<5'), 5);
      expect(parseNumber('312 000'), 312000);
      expect(parseNumber('Négatif'), isNull);
      expect(formatNumber(12), '12');
      expect(formatNumber(0.45), '0,45');
    });
  });

  group('BilanSummary / page Spring', () {
    test('fromJson d\'une page', () {
      final page = BilanPage.fromJson({
        'content': [
          {
            'id': 'abc',
            'typeBilan': 'Biochimie',
            'dateBilan': '2026-07-15',
            'status': 'CONFIRMED',
            'resultCount': 9,
            'abnormalCount': 2,
            'reviewStatus': 'LU',
            'patientId': 12,
            'doctorId': 3,
          },
        ],
        'totalPages': 3,
        'number': 0,
        'size': 20,
      });
      expect(page.isLast, isFalse);
      final s = page.content.single;
      expect(s.status, BilanStatus.confirmed);
      expect(s.reviewStatus, ReviewStatus.lu);
      expect(s.abnormalCount, 2);
      expect(BilanSummary.fromJson(s.toJson()).toJson(), s.toJson());
    });
  });

  test('DoctorOption fromJson / toJson', () {
    final json = {
      'id': 3,
      'firstName': 'Sami',
      'lastName': 'Benali',
      'email': 'dr.benali@medilink.tn',
      'phone': '+21698000000',
      'specialty': 'Cardiologie',
      'hospital': 'Tunis',
      'licenseNumber': 'TN-123',
    };
    final d = DoctorOption.fromJson(json);
    expect(d.displayName, 'Dr Sami Benali');
    expect(d.initials, 'SB');
    expect(d.toJson(), json);
  });
}
