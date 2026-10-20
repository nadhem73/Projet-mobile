/// Lien entre le patient et son proche.
enum DependentRelation {
  child('CHILD', 'Enfant'),
  spouse('SPOUSE', 'Conjoint(e)'),
  parent('PARENT', 'Parent'),
  other('OTHER', 'Autre');

  const DependentRelation(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static DependentRelation fromDb(String value) =>
      values.firstWhere((r) => r.dbValue == value, orElse: () => DependentRelation.other);
}

/// Proche géré par un patient (enfant, parent âgé...), table `dependents`.
///
/// Le module Rendez-vous peut l'utiliser pour réserver « pour un proche ».
class Dependent {
  const Dependent({
    this.id,
    required this.patientId,
    required this.nom,
    required this.prenom,
    required this.relation,
    this.dateNaissance,
    this.gender,
    this.bloodGroup,
    this.allergies,
  });

  final int? id;
  final int patientId;
  final String nom;
  final String prenom;
  final DependentRelation relation;
  final DateTime? dateNaissance;

  /// 'M' ou 'F'.
  final String? gender;
  final String? bloodGroup;
  final String? allergies;

  String get fullName => '$prenom $nom'.trim();
  String get initials => '${prenom.isEmpty ? '' : prenom[0]}${nom.isEmpty ? '' : nom[0]}'.toUpperCase();

  int? get age {
    final birth = dateNaissance;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
    return years;
  }

  factory Dependent.fromMap(Map<String, Object?> map) => Dependent(
    id: map['dependent_id'] as int,
    patientId: map['patient_id'] as int,
    nom: map['nom'] as String,
    prenom: map['prenom'] as String,
    relation: DependentRelation.fromDb(map['relation'] as String),
    dateNaissance: DateTime.tryParse(map['date_naissance'] as String? ?? ''),
    gender: map['gender'] as String?,
    bloodGroup: map['blood_group'] as String?,
    allergies: map['allergies'] as String?,
  );

  Map<String, Object?> toMap() {
    final allergyText = allergies?.trim();
    return {
      'patient_id': patientId,
      'nom': nom.trim(),
      'prenom': prenom.trim(),
      'relation': relation.dbValue,
      'date_naissance': dateNaissance?.toIso8601String().substring(0, 10),
      'gender': gender,
      'blood_group': bloodGroup,
      'allergies': (allergyText == null || allergyText.isEmpty) ? null : allergyText,
    };
  }
}
