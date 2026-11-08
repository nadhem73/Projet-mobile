import 'package:medilink/features/ai/data/models/bilan_enums.dart';

/// Une ligne de résultat d'un bilan (`BilanResultDto` côté API).
class BilanResult {
  const BilanResult({
    required this.id,
    required this.testName,
    required this.valeur,
    required this.unite,
    this.referenceMin,
    this.referenceMax,
    this.referenceText,
    this.valeurAncienne,
    this.dateAncienne,
    this.status = ResultStatus.nonApplicable,
    this.confiance,
  });

  final int id;
  final String testName;
  final String valeur;
  final String unite;
  final double? referenceMin;
  final double? referenceMax;
  final String? referenceText;
  final String? valeurAncienne;
  final String? dateAncienne;
  final ResultStatus status;

  /// Confiance de l'extraction OCR (`HIGH`, `MEDIUM`, `LOW`...).
  final String? confiance;

  static const lowConfidence = 'LOW';

  /// Valeur numérique (virgule ou point décimal), `null` si non numérique.
  double? get numericValue => parseNumber(valeur);

  double? get numericAncienne => parseNumber(valeurAncienne);

  /// Badge « à vérifier » : extraction peu sûre.
  bool get needsCheck {
    final c = confiance?.toUpperCase();
    return c == 'LOW' || c == 'FAIBLE' || c == 'BASSE';
  }

  bool get hasRange => referenceMin != null || referenceMax != null;

  /// Référence lisible : « 12 – 16 », « < 6 », « > 0,4 » ou le texte brut.
  String? get referenceLabel {
    if (referenceMin != null && referenceMax != null) {
      return '${formatNumber(referenceMin!)} – ${formatNumber(referenceMax!)}';
    }
    if (referenceMax != null) return '< ${formatNumber(referenceMax!)}';
    if (referenceMin != null) return '> ${formatNumber(referenceMin!)}';
    final text = referenceText?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  BilanResult copyWith({
    String? valeur,
    String? valeurAncienne,
    double? referenceMin,
    double? referenceMax,
    String? referenceText,
    ResultStatus? status,
    String? confiance,
  }) => BilanResult(
    id: id,
    testName: testName,
    valeur: valeur ?? this.valeur,
    unite: unite,
    referenceMin: referenceMin ?? this.referenceMin,
    referenceMax: referenceMax ?? this.referenceMax,
    referenceText: referenceText ?? this.referenceText,
    valeurAncienne: valeurAncienne ?? this.valeurAncienne,
    dateAncienne: dateAncienne,
    status: status ?? this.status,
    confiance: confiance ?? this.confiance,
  );

  // ---------------------------------------------------------------------------
  // JSON (API)
  // ---------------------------------------------------------------------------

  factory BilanResult.fromJson(Map<String, dynamic> json) => BilanResult(
    id: (json['id'] as num?)?.toInt() ?? 0,
    testName: json['testName'] as String? ?? '',
    valeur: json['valeur']?.toString() ?? '',
    unite: json['unite'] as String? ?? '',
    referenceMin: (json['referenceMin'] as num?)?.toDouble(),
    referenceMax: (json['referenceMax'] as num?)?.toDouble(),
    referenceText: json['referenceText'] as String?,
    valeurAncienne: json['valeurAncienne']?.toString(),
    dateAncienne: json['dateAncienne'] as String?,
    status: ResultStatus.parse(json['status']),
    confiance: json['confiance']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'testName': testName,
    'valeur': valeur,
    'unite': unite,
    'referenceMin': referenceMin,
    'referenceMax': referenceMax,
    'referenceText': referenceText,
    'valeurAncienne': valeurAncienne,
    'dateAncienne': dateAncienne,
    'status': status.value,
    if (confiance != null) 'confiance': confiance,
  };

  // ---------------------------------------------------------------------------
  // SQLite (table bilan_results)
  // ---------------------------------------------------------------------------

  factory BilanResult.fromMap(Map<String, Object?> map) => BilanResult(
    id: map['result_id'] as int,
    testName: map['test_name'] as String? ?? '',
    valeur: map['valeur'] as String? ?? '',
    unite: map['unite'] as String? ?? '',
    referenceMin: (map['reference_min'] as num?)?.toDouble(),
    referenceMax: (map['reference_max'] as num?)?.toDouble(),
    referenceText: map['reference_text'] as String?,
    valeurAncienne: map['valeur_ancienne'] as String?,
    dateAncienne: map['date_ancienne'] as String?,
    status: ResultStatus.parse(map['status']),
    confiance: map['confiance'] as String?,
  );

  /// Colonnes à insérer (sans `result_id`, généré par SQLite).
  Map<String, Object?> toMap(String bilanId) => {
    'bilan_id': bilanId,
    'test_name': testName,
    'valeur': valeur,
    'unite': unite,
    'reference_min': referenceMin,
    'reference_max': referenceMax,
    'reference_text': referenceText,
    'valeur_ancienne': valeurAncienne,
    'date_ancienne': dateAncienne,
    'status': status.value,
    'confiance': confiance,
  };
}

/// `"13,5"` / `"13.5"` / `" 13 "` → 13.5 ; `null` si non numérique.
double? parseNumber(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(raw.replaceAll(' ', ''));
  if (match == null) return null;
  return double.tryParse(match.group(0)!.replaceAll(',', '.'));
}

/// 12.0 → « 12 », 0.45 → « 0,45 » (affichage à la française).
String formatNumber(double value) {
  final text = value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  return text.replaceAll('.', ',');
}
