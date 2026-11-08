import 'package:medilink/features/user/data/repositories/auth_repository.dart' show parseSqlDateTime;

/// Ligne d'ordonnance (table `prescription_items`).
///
/// [medicamentId] référence le dataset PostgreSQL ; il est null quand le
/// médicament a été saisi librement (API indisponible).
class PrescriptionItem {
  const PrescriptionItem({
    this.id,
    this.medicamentId,
    required this.medicamentName,
    this.dosage,
    this.forme,
    this.posologie,
    this.dureeTraitement,
    this.voieAdministration,
    this.instruction,
  });

  final int? id;
  final int? medicamentId;
  final String medicamentName;

  /// Ex. « 500 mg ».
  final String? dosage;

  /// Ex. « comprimé », « sirop ».
  final String? forme;

  /// Ex. « 1 comprimé matin et soir ».
  final String? posologie;

  /// Ex. « 7 jours ».
  final String? dureeTraitement;

  /// Ex. « orale ».
  final String? voieAdministration;

  /// Ex. « à prendre pendant le repas ».
  final String? instruction;

  /// Message d'erreur si la ligne est incomplète, sinon null.
  String? validate() {
    if (medicamentName.trim().isEmpty) return 'Chaque ligne doit indiquer un médicament.';
    if ((posologie ?? '').trim().isEmpty) return 'Posologie manquante pour $medicamentName.';
    if ((dureeTraitement ?? '').trim().isEmpty) return 'Durée de traitement manquante pour $medicamentName.';
    return null;
  }

  Map<String, Object?> toMap(int prescriptionId) => {
    'prescription_id': prescriptionId,
    'medicament_id': medicamentId,
    'medicament_name': medicamentName.trim(),
    'dosage': _clean(dosage),
    'forme': _clean(forme),
    'posologie': _clean(posologie),
    'duree_traitement': _clean(dureeTraitement),
    'voie_administration': _clean(voieAdministration),
    'instruction': _clean(instruction),
  };

  factory PrescriptionItem.fromMap(Map<String, Object?> map) => PrescriptionItem(
    id: map['prescription_item_id'] as int,
    medicamentId: map['medicament_id'] as int?,
    medicamentName: map['medicament_name'] as String,
    dosage: map['dosage'] as String?,
    forme: map['forme'] as String?,
    posologie: map['posologie'] as String?,
    dureeTraitement: map['duree_traitement'] as String?,
    voieAdministration: map['voie_administration'] as String?,
    instruction: map['instruction'] as String?,
  );

  static String? _clean(String? value) {
    final v = value?.trim();
    return v == null || v.isEmpty ? null : v;
  }
}

/// Ordonnance (table `prescriptions`) avec ses lignes et les noms pour l'affichage.
class Prescription {
  const Prescription({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.items,
    this.consultationId,
    this.note,
    this.createdAt,
    this.doctorName = '',
    this.doctorSpecialty,
    this.patientName = '',
  });

  final int id;
  final int? consultationId;
  final int doctorId;
  final int patientId;
  final String? note;
  final DateTime? createdAt;
  final List<PrescriptionItem> items;

  final String doctorName;
  final String? doctorSpecialty;
  final String patientName;

  /// Ligne issue de la requête de [PrescriptionRepository] (jointures users).
  factory Prescription.fromMap(Map<String, Object?> map, List<PrescriptionItem> items) => Prescription(
    id: map['prescription_id'] as int,
    consultationId: map['consultation_id'] as int?,
    doctorId: map['doctor_id'] as int,
    patientId: map['patient_id'] as int,
    note: map['note'] as String?,
    createdAt: parseSqlDateTime(map['created_at'] as String?),
    items: items,
    doctorName: 'Dr ${map['doctor_prenom'] ?? ''} ${map['doctor_nom'] ?? ''}'.trim(),
    doctorSpecialty: map['specialty'] as String?,
    patientName: '${map['patient_prenom'] ?? ''} ${map['patient_nom'] ?? ''}'.trim(),
  );
}
