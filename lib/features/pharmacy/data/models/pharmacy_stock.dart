/// Modèle représentant le stock d'un médicament dans une pharmacie spécifique.
///
/// Relation: Un stock lie une [pharmacyId] à un [medicineId].
/// Contrainte UNIQUE(pharmacy_id, medicine_id) dans la base.
class PharmacyStock {
  const PharmacyStock({
    this.stockId,
    required this.pharmacyId,
    required this.medicineId,
    required this.inStock,
    required this.quantity,
    this.shelfLocation,
    this.customPrice,
    this.expirationDate,
    this.manufacturingDate,
    this.lastRestockDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? stockId;
  final int pharmacyId;
  final int medicineId;
  final bool inStock; // true = disponible, false = rupture
  final int quantity;
  final String? shelfLocation; // Emplacement (A12, B18, Rayon5, etc.)
  final double? customPrice; // Prix personnalisé de vente de la pharmacie (DT)
  final DateTime? expirationDate;
  final DateTime? manufacturingDate;
  final DateTime? lastRestockDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Crée une instance depuis une ligne de la base de données.
  factory PharmacyStock.fromMap(Map<String, dynamic> map) {
    return PharmacyStock(
      stockId: map['stock_id'] as int?,
      pharmacyId: map['pharmacy_id'] as int,
      medicineId: map['medicine_id'] as int,
      inStock: (map['in_stock'] as int) == 1,
      quantity: map['quantity'] as int,
      shelfLocation: map['shelf_location'] as String?,
      customPrice: (map['custom_price'] as num?)?.toDouble(),
      expirationDate: map['expiration_date'] != null ? DateTime.parse(map['expiration_date'] as String) : null,
      manufacturingDate: map['manufacturing_date'] != null ? DateTime.parse(map['manufacturing_date'] as String) : null,
      lastRestockDate: map['last_restock_date'] != null ? DateTime.parse(map['last_restock_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Crée une instance depuis une ligne CSV de stock.
  /// Format CSV: id_medicament;quantite_en_stock;date_fabrication;date_expiration;emplacement;dernier_reapprovisionnement
  factory PharmacyStock.fromCsv(List<String> fields, int pharmacyId) {
    return PharmacyStock(
      pharmacyId: pharmacyId,
      medicineId: fields.isNotEmpty ? int.tryParse(fields[0].trim()) ?? 0 : 0,
      inStock: true, // Par défaut, si dans le CSV, c'est en stock
      quantity: fields.length > 1 && fields[1].isNotEmpty ? int.tryParse(fields[1].trim()) ?? 0 : 0,
      manufacturingDate: fields.length > 2 && fields[2].isNotEmpty ? DateTime.tryParse(fields[2].trim()) : null,
      expirationDate: fields.length > 3 && fields[3].isNotEmpty ? DateTime.tryParse(fields[3].trim()) : null,
      shelfLocation: fields.length > 4 && fields[4].isNotEmpty ? fields[4].trim() : null,
      lastRestockDate: fields.length > 5 && fields[5].isNotEmpty ? DateTime.tryParse(fields[5].trim()) : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convertit vers un Map pour insertion/mise à jour dans SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (stockId != null) 'stock_id': stockId,
      'pharmacy_id': pharmacyId,
      'medicine_id': medicineId,
      'in_stock': inStock ? 1 : 0,
      'quantity': quantity,
      'shelf_location': shelfLocation,
      'custom_price': customPrice,
      'expiration_date': expirationDate?.toIso8601String(),
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'last_restock_date': lastRestockDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copie avec modifications.
  PharmacyStock copyWith({
    int? stockId,
    int? pharmacyId,
    int? medicineId,
    bool? inStock,
    int? quantity,
    String? shelfLocation,
    double? customPrice,
    DateTime? expirationDate,
    DateTime? manufacturingDate,
    DateTime? lastRestockDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PharmacyStock(
      stockId: stockId ?? this.stockId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      medicineId: medicineId ?? this.medicineId,
      inStock: inStock ?? this.inStock,
      quantity: quantity ?? this.quantity,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      customPrice: customPrice ?? this.customPrice,
      expirationDate: expirationDate ?? this.expirationDate,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifie si le stock est bas (quantité inférieure au seuil).
  /// Prix effectif appliqué (prix custom de l'officine ou prix national de base)
  double effectivePrice(double basePrice) => customPrice ?? basePrice;

  bool isLowStock(int threshold) => quantity < threshold;

  /// Vérifie si le médicament expire bientôt (dans les X mois).
  bool isExpiringSoon(int months) {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month + months, now.day);
    return expirationDate!.isBefore(threshold);
  }

  /// Vérifie si le médicament est expiré.
  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  /// Statut formaté pour l'affichage.
  String get statusLabel {
    if (!inStock) return 'Rupture';
    if (isExpired) return 'Expiré';
    if (isExpiringSoon(6)) return 'Expire bientôt';
    if (isLowStock(10)) return 'Stock faible';
    return 'Disponible';
  }

  @override
  String toString() {
    return 'PharmacyStock(id: $stockId, pharmacyId: $pharmacyId, medicineId: $medicineId, '
        'inStock: $inStock, quantity: $quantity, location: $shelfLocation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PharmacyStock && other.stockId == stockId;
  }

  @override
  int get hashCode => stockId.hashCode;
}
