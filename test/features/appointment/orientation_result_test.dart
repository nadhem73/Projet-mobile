import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';

void main() {
  test('résumé selon le cas : spécialité, incertain, urgence', () {
    const cardio = OrientationResult(
      specialty: 'Cardiologie',
      urgency: OrientationUrgency.soon,
      reasons: ['palpitations'],
      confidence: 0.8,
    );
    expect(cardio.summary, contains('Cardiologie'));
    expect(cardio.urgency.allowsBooking, isTrue);

    const vague = OrientationResult(
      specialty: 'Médecine générale',
      urgency: OrientationUrgency.routine,
      confidence: 0.2,
    );
    expect(vague.isUncertain, isTrue);
    expect(vague.summary, contains('généraliste'));

    const urgent = OrientationResult(
      specialty: 'Cardiologie',
      urgency: OrientationUrgency.emergency,
      redFlags: ['douleur dans la poitrine'],
      confidence: 0.9,
    );
    expect(urgent.isEmergency, isTrue);
    expect(urgent.urgency.allowsBooking, isFalse);
    expect(urgent.summary, contains('190'));
  });

  test('JSON : aller-retour et valeurs manquantes', () {
    const r = OrientationResult(
      specialty: 'Dermatologie',
      urgency: OrientationUrgency.routine,
      reasons: ['bouton', 'démangeaisons'],
      confidence: 0.7,
    );
    final back = OrientationResult.fromJson(r.toJson());
    expect(back.specialty, 'Dermatologie');
    expect(back.urgency, OrientationUrgency.routine);
    expect(back.reasons, ['bouton', 'démangeaisons']);
    expect(back.source, OrientationSource.llm);

    final empty = OrientationResult.fromJson({'urgency': 'inconnue', 'confidence': 3});
    expect(empty.specialty, OrientationResult.defaultSpecialty);
    expect(empty.urgency, OrientationUrgency.routine);
    expect(empty.confidence, 1);
  });
}
