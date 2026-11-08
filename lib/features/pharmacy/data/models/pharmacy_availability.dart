import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';

/// Information détaillée sur un médicament disponible dans une pharmacie.
class AvailableMedicineInfo {
  const AvailableMedicineInfo({
    this.medicineId,
    required this.name,
    this.dosage,
    this.forme,
    this.imageUrl,
    this.price,
    this.isGenericEquivalent = false,
    this.originalSearchTerm,
  });

  final int? medicineId;
  final String name;
  final String? dosage;
  final String? forme;
  final String? imageUrl;
  final double? price;
  final bool isGenericEquivalent;
  final String? originalSearchTerm;

  String get displayTitle {
    final d = (dosage != null && dosage!.isNotEmpty) ? ' ($dosage)' : '';
    final eq = isGenericEquivalent ? ' [Équivalent]' : '';
    return '$name$d$eq';
  }
}

/// Résultat de la recherche de pharmacies avec disponibilité des médicaments.
///
/// Utilisé par le Pharmacy Finder pour afficher les pharmacies classées
/// en priorité par ouverture actuelle (ouvertes en premier), puis par disponibilité et distance.
class PharmacyAvailability {
  const PharmacyAvailability({
    required this.pharmacy,
    required this.availableMedicines,
    required this.unavailableMedicines,
    required this.distance,
    this.availableMedicineDetails = const [],
  });

  final Pharmacy pharmacy;
  final List<String> availableMedicines; // Noms des médicaments disponibles
  final List<String> unavailableMedicines; // Noms des médicaments non disponibles
  final double distance; // Distance en km
  final List<AvailableMedicineInfo> availableMedicineDetails; // Détails avec images

  /// Nombre total de médicaments recherchés.
  int get totalRequested => availableMedicines.length + unavailableMedicines.length;

  /// Nombre de médicaments disponibles.
  int get availableCount => availableMedicines.length;

  /// Pourcentage de disponibilité (0.0 à 1.0).
  double get availabilityRate {
    if (totalRequested == 0) return 0.0;
    return availableCount / totalRequested;
  }

  /// Score de disponibilité pour le tri.
  /// Priorité absolue : Pharmacie ouverte MAINTENANT > Taux de disponibilité > Distance.
  double get availabilityScore {
    // 1. Bonus massif pour pharmacie ouverte actuellement (10 000 points)
    final openBonus = pharmacy.isOpenNow ? 10000.0 : 0.0;

    // 2. Disponibilité des médicaments demandés (0 à 700 points)
    final availabilityFactor = availabilityRate * 700.0;

    // 3. Proximité GPS (0 à 300 points pour les plus proches jusqu'à 30km)
    final distanceFactor = (1.0 - (distance / 30.0).clamp(0.0, 1.0)) * 300.0;

    return openBonus + availabilityFactor + distanceFactor;
  }

  /// Label de disponibilité pour affichage.
  String get availabilityLabel {
    if (availableCount == totalRequested) return 'Tous disponibles';
    if (availableCount == 0) return 'Aucun disponible';
    return '$availableCount/$totalRequested disponibles';
  }

  /// Distance formatée pour affichage.
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Temps de trajet estimé à pied (4 km/h).
  String get estimatedWalkingTime {
    final minutes = (distance / 4 * 60).round();
    if (minutes < 1) return '<1 min';
    return '$minutes min à pied';
  }

  /// Copie avec modifications.
  PharmacyAvailability copyWith({
    Pharmacy? pharmacy,
    List<String>? availableMedicines,
    List<String>? unavailableMedicines,
    double? distance,
    List<AvailableMedicineInfo>? availableMedicineDetails,
  }) {
    return PharmacyAvailability(
      pharmacy: pharmacy ?? this.pharmacy,
      availableMedicines: availableMedicines ?? this.availableMedicines,
      unavailableMedicines: unavailableMedicines ?? this.unavailableMedicines,
      distance: distance ?? this.distance,
      availableMedicineDetails: availableMedicineDetails ?? this.availableMedicineDetails,
    );
  }

  @override
  String toString() {
    return 'PharmacyAvailability(pharmacy: ${pharmacy.name}, '
        'open: ${pharmacy.isOpenNow}, available: $availableCount/$totalRequested, distance: $formattedDistance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PharmacyAvailability && other.pharmacy.pharmacyId == pharmacy.pharmacyId;
  }

  @override
  int get hashCode => pharmacy.pharmacyId.hashCode;
}
