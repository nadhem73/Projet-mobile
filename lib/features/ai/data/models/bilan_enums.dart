/// Énumérations des bilans médicaux.
///
/// Chaque enum porte la valeur texte utilisée par l'API et par SQLite, et
/// [parse] tolère une valeur inconnue (repli sur une valeur par défaut) pour
/// ne jamais planter si le backend ajoute un statut.
library;

/// Statut d'une valeur par rapport à sa plage de référence.
enum ResultStatus {
  normal('NORMAL', 'Normal'),
  anormal('ANORMAL', 'Anormal'),
  critique('CRITIQUE', 'Critique'),
  nonApplicable('NON_APPLICABLE', 'Non applicable');

  const ResultStatus(this.value, this.label);

  final String value;
  final String label;

  static ResultStatus parse(Object? raw) =>
      values.firstWhere((e) => e.value == raw?.toString().toUpperCase(), orElse: () => nonApplicable);

  bool get isOutOfRange => this == anormal || this == critique;
}

/// Cycle de vie d'un bilan scanné.
enum BilanStatus {
  pending('PENDING', 'À valider'),
  confirmed('CONFIRMED', 'Validé'),
  rejected('REJECTED', 'Rejeté');

  const BilanStatus(this.value, this.label);

  final String value;
  final String label;

  static BilanStatus parse(Object? raw) =>
      values.firstWhere((e) => e.value == raw?.toString().toUpperCase(), orElse: () => pending);
}

/// Mise en page du bilan : `ancienPatient` = colonne « valeur antérieure ».
enum BilanFormat {
  nouveauPatient('NOUVEAU_PATIENT'),
  ancienPatient('ANCIEN_PATIENT');

  const BilanFormat(this.value);

  final String value;

  static BilanFormat parse(Object? raw) =>
      values.firstWhere((e) => e.value == raw?.toString().toUpperCase(), orElse: () => nouveauPatient);
}

/// Avancement de la revue par le médecin destinataire.
enum ReviewStatus {
  enAttente('EN_ATTENTE', 'En attente du médecin'),
  lu('LU', 'Lu par le médecin'),
  traite('TRAITE', 'Traité');

  const ReviewStatus(this.value, this.label);

  final String value;
  final String label;

  /// `null` si absent ou inconnu.
  static ReviewStatus? parse(Object? raw) {
    if (raw == null) return null;
    for (final e in values) {
      if (e.value == raw.toString().toUpperCase()) return e;
    }
    return null;
  }
}
