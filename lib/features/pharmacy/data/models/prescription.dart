/// Modèle représentant une ordonnance créée par un médecin (READ-ONLY pour module pharmacie).
///
/// Les ordonnances sont créées par le module Doctor.
/// Le module Pharmacy les utilise uniquement pour la recherche de pharmacies.
class Prescription {
  const Prescription({
    required this.prescriptionId,
    required this.patientId,
    required this.doctorId,
    this.diagnosis,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  final int prescriptionId;
  final int patientId;
  final int doctorId;
  final String? diagnosis;
  final String? notes;
  final DateTime createdAt;
  final List<PrescriptionItem> items;

  /// Crée une instance depuis une ligne de la base de données.
  factory Prescription.fromMap(Map<String, dynamic> map, {List<PrescriptionItem>? items}) {
    return Prescription(
      prescriptionId: map['prescription_id'] as int,
      patientId: map['patient_id'] as int,
      doctorId: map['doctor_id'] as int,
      diagnosis: map['diagnosis'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items ?? [],
    );
  }

  /// Liste des noms de médicaments prescrits (pour recherche de pharmacies).
  List<String> get medicineNames => items.map((item) => item.medicineName).toList();

  @override
  String toString() {
    return 'Prescription(id: $prescriptionId, patientId: $patientId, items: ${items.length})';
  }
}

/// Modèle représentant un item d'une ordonnance (un médicament prescrit).
class PrescriptionItem {
  const PrescriptionItem({
    required this.prescriptionItemId,
    required this.prescriptionId,
    required this.medicineName,
    this.dosage,
    required this.quantity,
    this.instructions,
  });

  final int prescriptionItemId;
  final int prescriptionId;
  final String medicineName; // Nom ou DCI du médicament
  final String? dosage;
  final int quantity;
  final String? instructions; // e.g., "2x par jour après repas"

  /// Crée une instance depuis une ligne de la base de données.
  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      prescriptionItemId: map['prescription_item_id'] as int,
      prescriptionId: map['prescription_id'] as int,
      medicineName: map['medicine_name'] as String,
      dosage: map['dosage'] as String?,
      quantity: map['quantity'] as int,
      instructions: map['instructions'] as String?,
    );
  }

  /// Nom complet formaté: "NAME dosage"
  String get fullName {
    if (dosage != null) return '$medicineName $dosage';
    return medicineName;
  }

  @override
  String toString() {
    return 'PrescriptionItem(id: $prescriptionItemId, name: $medicineName, quantity: $quantity)';
  }
}
