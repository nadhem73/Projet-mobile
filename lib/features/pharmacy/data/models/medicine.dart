/// Modèle représentant un médicament du catalogue (~2,700 items).
///
/// Le catalogue est global et partagé par toutes les pharmacies.
/// Chaque pharmacie gère son propre stock via [PharmacyStock].
class Medicine {
  const Medicine({
    this.medicineId,
    required this.name,
    this.dosage,
    this.forme,
    this.presentation,
    required this.price,
    this.remboursement,
    this.dci,
    this.type,
    required this.prescriptionRequired,
    this.imageUrl,
    required this.createdAt,
  });

  final int? medicineId;
  final String name;
  final String? dosage;
  final String? forme; // Comprimés, Gélules, Sirop, etc.
  final String? presentation; // B/30, B/28, etc.
  final double price; // Prix en TND
  final double? remboursement; // Montant remboursement
  final String? dci; // Dénomination Commune Internationale
  final String? type; // Antipsychotiques, Anticonvulsivants, etc.
  final bool prescriptionRequired; // true = "Oui", false = "Non"
  final String? imageUrl;
  final DateTime createdAt;

  /// Crée une instance depuis une ligne de la base de données.
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      medicineId: map['medicine_id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      forme: map['forme'] as String?,
      presentation: map['presentation'] as String?,
      price: (map['price'] as num).toDouble(),
      remboursement: map['remboursement'] != null ? (map['remboursement'] as num).toDouble() : null,
      dci: map['dci'] as String?,
      type: map['type'] as String?,
      prescriptionRequired: (map['prescription_required'] as int) == 1,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Crée une instance depuis une ligne CSV.
  /// Format CSV: Name;Dosage;Forme;Presentation;Price;Remboursement;DCI;Type;Prescription;Image
  factory Medicine.fromCsv(List<String> fields) {
    return Medicine(
      name: fields[0].trim(),
      dosage: fields.length > 1 && fields[1].isNotEmpty ? fields[1].trim() : null,
      forme: fields.length > 2 && fields[2].isNotEmpty ? fields[2].trim() : null,
      presentation: fields.length > 3 && fields[3].isNotEmpty ? fields[3].trim() : null,
      price: fields.length > 4 && fields[4].isNotEmpty ? double.tryParse(fields[4].trim()) ?? 0.0 : 0.0,
      remboursement: fields.length > 5 && fields[5].isNotEmpty ? double.tryParse(fields[5].trim()) : null,
      dci: fields.length > 6 && fields[6].isNotEmpty ? fields[6].trim() : null,
      type: fields.length > 7 && fields[7].isNotEmpty ? fields[7].trim() : null,
      prescriptionRequired: fields.length > 8 && fields[8].trim().toLowerCase() == 'oui',
      imageUrl: fields.length > 9 && fields[9].isNotEmpty ? fields[9].trim() : null,
      createdAt: DateTime.now(),
    );
  }

  /// Convertit vers un Map pour insertion/mise à jour dans SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (medicineId != null) 'medicine_id': medicineId,
      'name': name,
      'dosage': dosage,
      'forme': forme,
      'presentation': presentation,
      'price': price,
      'remboursement': remboursement,
      'dci': dci,
      'type': type,
      'prescription_required': prescriptionRequired ? 1 : 0,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copie avec modifications.
  Medicine copyWith({
    int? medicineId,
    String? name,
    String? dosage,
    String? forme,
    String? presentation,
    double? price,
    double? remboursement,
    String? dci,
    String? type,
    bool? prescriptionRequired,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Medicine(
      medicineId: medicineId ?? this.medicineId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      forme: forme ?? this.forme,
      presentation: presentation ?? this.presentation,
      price: price ?? this.price,
      remboursement: remboursement ?? this.remboursement,
      dci: dci ?? this.dci,
      type: type ?? this.type,
      prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Nom complet formaté: "NAME dosage forme"
  String get fullName {
    final parts = <String>[name];
    if (dosage != null) parts.add(dosage!);
    if (forme != null) parts.add(forme!);
    return parts.join(' ');
  }

  /// Prix formaté avec devise.
  String get formattedPrice => '$price TND';

  /// Vérifie si le médicament contient le terme de recherche (nom ou DCI).
  bool matches(String searchTerm) {
    final term = searchTerm.toLowerCase();
    return name.toLowerCase().contains(term) || (dci?.toLowerCase().contains(term) ?? false);
  }

  @override
  String toString() {
    return 'Medicine(id: $medicineId, name: $name, dosage: $dosage, price: $price TND, dci: $dci)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medicine && other.medicineId == medicineId;
  }

  @override
  int get hashCode => medicineId.hashCode;
}
