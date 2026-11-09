/// Niveau d'urgence conseillé par l'assistant d'orientation.
enum OrientationUrgency {
  /// Signe de gravité : appeler le SAMU (190) ou aller aux urgences, pas de rendez-vous.
  emergency('Urgence', 'Appelez le SAMU au 190 ou rendez-vous aux urgences les plus proches.'),

  /// À voir rapidement : rendez-vous dans les prochains jours.
  soon('À consulter cette semaine', 'Prenez rendez-vous dans les prochains jours.'),

  /// Pas pressé : rendez-vous quand cela vous arrange.
  routine('Consultation classique', 'Vous pouvez prendre rendez-vous quand cela vous arrange.');

  const OrientationUrgency(this.label, this.advice);

  final String label;
  final String advice;

  /// Un rendez-vous classique n'est proposé que hors urgence.
  bool get allowsBooking => this != emergency;
}

/// D'où vient l'analyse.
enum OrientationSource {
  /// Analyse par mots-clés sur le téléphone (sans internet).
  offline,

  /// Analyse par un modèle de langage en ligne.
  llm,
}

/// Résultat de l'analyse des symptômes décrits par le patient.
///
/// Ce n'est pas un diagnostic : l'assistant indique seulement vers quelle
/// spécialité s'orienter et avec quelle urgence.
class OrientationResult {
  const OrientationResult({
    required this.specialty,
    required this.urgency,
    this.reasons = const [],
    this.redFlags = const [],
    this.confidence = 0,
    this.source = OrientationSource.offline,
  });

  /// Spécialité conseillée, avec le même nom que dans la table `doctors`
  /// (ex. « Cardiologie », « Médecine générale »).
  final String specialty;
  final OrientationUrgency urgency;

  /// Pourquoi cette spécialité (ex. « palpitations », « essoufflement à l'effort »).
  final List<String> reasons;

  /// Signes de gravité repérés (ex. « douleur dans la poitrine »).
  final List<String> redFlags;

  /// Confiance de l'analyse, entre 0 et 1.
  final double confidence;
  final OrientationSource source;

  /// Spécialité par défaut quand rien de précis n'est reconnu.
  static const defaultSpecialty = 'Médecine générale';

  /// Rappel affiché sous chaque réponse de l'assistant.
  static const disclaimer =
      "Cet assistant ne remplace pas un avis médical : il vous oriente vers un spécialiste, il ne pose pas de diagnostic.";

  bool get isEmergency => urgency == OrientationUrgency.emergency;

  /// Rien de précis reconnu : on oriente vers un généraliste.
  bool get isUncertain => confidence < 0.4;

  /// Phrase courte affichée par l'assistant, ex. « Je vous conseille de consulter en Cardiologie ».
  String get summary {
    if (isEmergency) return 'Vos symptômes peuvent être graves. ${urgency.advice}';
    if (isUncertain) {
      return 'Je ne suis pas certain de la spécialité. Je vous conseille de commencer par un médecin généraliste.';
    }
    return 'Je vous conseille de consulter en $specialty. ${urgency.advice}';
  }

  /// Conversion depuis une réponse JSON (utile pour le LLM, étape 6).
  factory OrientationResult.fromJson(Map<String, Object?> json, {OrientationSource source = OrientationSource.llm}) =>
      OrientationResult(
        specialty:
            (json['specialty'] as String?)?.trim().isNotEmpty == true
                ? (json['specialty'] as String).trim()
                : defaultSpecialty,
        urgency: OrientationUrgency.values.firstWhere(
          (u) => u.name == json['urgency'],
          orElse: () => OrientationUrgency.routine,
        ),
        reasons: [for (final r in (json['reasons'] as List?) ?? const []) '$r'],
        redFlags: [for (final r in (json['redFlags'] as List?) ?? const []) '$r'],
        confidence: ((json['confidence'] as num?) ?? 0).toDouble().clamp(0, 1),
        source: source,
      );

  Map<String, Object?> toJson() => {
    'specialty': specialty,
    'urgency': urgency.name,
    'reasons': reasons,
    'redFlags': redFlags,
    'confidence': confidence,
  };
}
