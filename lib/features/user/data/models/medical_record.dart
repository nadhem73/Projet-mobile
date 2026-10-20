/// Dossier médical d'un patient (table `medical_records`, cahier des charges §10.7).
///
/// Utilisable par les autres modules en lecture seule
/// (ex. le médecin consulte le dossier d'un patient).
class MedicalRecord {
  const MedicalRecord({
    this.id,
    required this.patientId,
    this.gender,
    this.bloodGroup,
    this.height,
    this.weight,
    this.allergies,
    this.chronicDiseases,
    this.currentTreatment,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.insuranceCompany,
    this.insuranceNumber,
    this.updatedAt,
  });

  /// Dossier vide (patient qui n'a encore rien renseigné).
  const MedicalRecord.empty(this.patientId)
    : id = null,
      gender = null,
      bloodGroup = null,
      height = null,
      weight = null,
      allergies = null,
      chronicDiseases = null,
      currentTreatment = null,
      emergencyContactName = null,
      emergencyContactPhone = null,
      insuranceCompany = null,
      insuranceNumber = null,
      updatedAt = null;

  final int? id;
  final int patientId;

  /// 'M' ou 'F'.
  final String? gender;
  final String? bloodGroup;

  /// Taille en cm.
  final double? height;

  /// Poids en kg.
  final double? weight;

  /// Liste séparée par des virgules (ex. « Pénicilline, Arachides »).
  final String? allergies;
  final String? chronicDiseases;
  final String? currentTreatment;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? insuranceCompany;
  final String? insuranceNumber;
  final DateTime? updatedAt;

  String? get genderLabel => switch (gender) {
    'M' => 'Homme',
    'F' => 'Femme',
    _ => null,
  };

  /// Indice de masse corporelle (kg/m²), null si taille ou poids manquant.
  double? get bmi {
    final h = height, w = weight;
    if (h == null || w == null || h <= 0) return null;
    final meters = h / 100;
    return w / (meters * meters);
  }

  /// Interprétation OMS de l'IMC.
  String? get bmiLabel {
    final value = bmi;
    if (value == null) return null;
    if (value < 18.5) return 'Insuffisance pondérale';
    if (value < 25) return 'Corpulence normale';
    if (value < 30) return 'Surpoids';
    return 'Obésité';
  }

  List<String> get allergyList => splitList(allergies);
  List<String> get chronicDiseaseList => splitList(chronicDiseases);

  /// Pourcentage des rubriques renseignées (affiché comme « dossier complété à X % »).
  int get completion {
    final fields = [
      gender,
      bloodGroup,
      height,
      weight,
      allergies,
      chronicDiseases,
      currentTreatment,
      emergencyContactName,
      emergencyContactPhone,
      insuranceCompany,
    ];
    final filled = fields.where((f) => f != null && f.toString().trim().isNotEmpty).length;
    return (filled * 100 / fields.length).round();
  }

  static List<String> splitList(String? raw) =>
      (raw ?? '').split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  factory MedicalRecord.fromMap(Map<String, Object?> map) => MedicalRecord(
    id: map['id'] as int?,
    patientId: map['patient_id'] as int,
    gender: map['gender'] as String?,
    bloodGroup: map['blood_group'] as String?,
    height: (map['height'] as num?)?.toDouble(),
    weight: (map['weight'] as num?)?.toDouble(),
    allergies: map['allergies'] as String?,
    chronicDiseases: map['chronic_diseases'] as String?,
    currentTreatment: map['current_treatment'] as String?,
    emergencyContactName: map['emergency_contact_name'] as String?,
    emergencyContactPhone: map['emergency_contact_phone'] as String?,
    insuranceCompany: map['insurance_company'] as String?,
    insuranceNumber: map['insurance_number'] as String?,
    updatedAt: map['updated_at'] == null ? null : DateTime.tryParse('${map['updated_at']}Z')?.toLocal(),
  );

  /// Colonnes modifiables (sans id ni date, gérés par le repository).
  Map<String, Object?> toMap() => {
    'patient_id': patientId,
    'gender': gender,
    'blood_group': bloodGroup,
    'height': height,
    'weight': weight,
    'allergies': _clean(allergies),
    'chronic_diseases': _clean(chronicDiseases),
    'current_treatment': _clean(currentTreatment),
    'emergency_contact_name': _clean(emergencyContactName),
    'emergency_contact_phone': _clean(emergencyContactPhone),
    'insurance_company': _clean(insuranceCompany),
    'insurance_number': _clean(insuranceNumber),
  };

  static String? _clean(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
