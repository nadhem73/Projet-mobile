import 'dart:math' as math;
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_availability.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/stock_repository.dart';

/// Repository pour trouver les pharmacies proches avec disponibilité des médicaments.
///
/// Algorithme de classement:
/// 1. Recherche les médicaments correspondants dans le catalogue (avec alias et DCI)
/// 2. Pour chaque pharmacie proche, vérifie le stock réel (in_stock = 1 ET quantity > 0)
/// 3. Calcule un score : ouvert maintenant > disponibilité > proximité GPS
/// 4. Trie par score décroissant (ouvertes en premier)
class PharmacyFinderRepository {
  PharmacyFinderRepository(
    this._pharmacyRepo,
    this._medicineRepo,
    this._stockRepo,
  );

  final PharmacyRepository _pharmacyRepo;
  final MedicineRepository _medicineRepo;
  final StockRepository _stockRepo;

  static final Map<String, List<String>> _searchAliases = {
    'augmentin': ['amoclan', 'clavor', 'mediclav', 'novaclav', 'amoxicilline'],
    'amoclan': ['amoclan', 'augmentin', 'clavor', 'mediclav', 'novaclav', 'amoxicilline'],
    'spasfon': ['antispasm', 'actafon', 'anaspasm', 'phloroglucinol', 'colocalm'],
    'antispasm': ['antispasm', 'spasfon', 'actafon', 'anaspasm', 'phloroglucinol'],
    'doliprane': ['doliprane', 'adol', 'panadol', 'paracetamol', 'efferalgan'],
    'adol': ['adol', 'doliprane', 'panadol', 'paracetamol', 'efferalgan'],
    'panadol': ['panadol', 'doliprane', 'adol', 'novadol', 'paracetamol'],
    'paracetamol': ['doliprane', 'adol', 'panadol', 'efferalgan', 'paracetamol'],
    'paracétamol': ['doliprane', 'adol', 'panadol', 'efferalgan', 'paracetamol'],
    'amoxicilline': ['clamoxyl', 'amoxal', 'galamox', 'saifoxyl', 'amoclan', 'novamox'],
    'clamoxyl': ['clamoxyl', 'amoclan', 'amoxicilline'],
    'voltarene': ['voltarene', 'diclofenac'],
    'voltarène': ['voltarene', 'diclofenac'],
    'flagyl': ['flagyl', 'flamet', 'metronidazole'],
    'solupred': ['solupred', 'prednisolone'],
    'ventoline': ['ventoline', 'salbutamol'],
  };

  /// Trouve les pharmacies proches avec disponibilité des médicaments.
  Future<List<PharmacyAvailability>> findNearbyPharmacies({
    required List<String> medicineNames,
    required double userLatitude,
    required double userLongitude,
    List<Medicine>? specificMedicines,
    double radiusKm = 10.0,
    int maxResults = 25,
  }) async {
    if (medicineNames.isEmpty) return [];

    // 1. Recherche de tous les médicaments candidats par terme
    final candidateMap = await _findCandidateMedicines(
      medicineNames,
      specificMedicines: specificMedicines,
    );
    final hasAnyCandidate = candidateMap.values.any((c) => c.exact.isNotEmpty || c.equivalents.isNotEmpty);
    if (!hasAnyCandidate) return [];

    // 2. Récupère les pharmacies dans le rayon initial
    var nearbyPharmacies = await _pharmacyRepo.getWithinRadius(
      userLatitude,
      userLongitude,
      radiusKm,
    );

    // Si aucune pharmacie dans le rayon initial, élargir la zone de recherche (jusqu'à 30 km)
    if (nearbyPharmacies.isEmpty) {
      nearbyPharmacies = await _pharmacyRepo.getWithinRadius(
        userLatitude,
        userLongitude,
        math.max(radiusKm * 2.5, 30.0),
      );
    }

    if (nearbyPharmacies.isEmpty) {
      // Fallback sur toutes les pharmacies disponibles
      nearbyPharmacies = await _pharmacyRepo.getAll();
    }

    if (nearbyPharmacies.isEmpty) return [];

    // 3. Pour chaque pharmacie, vérifie la disponibilité
    final availabilities = <PharmacyAvailability>[];

    for (final pharmacy in nearbyPharmacies) {
      final availability = await _checkPharmacyAvailability(
        pharmacy,
        candidateMap,
        userLatitude,
        userLongitude,
      );

      // On garde les pharmacies qui ont au moins 1 médicament disponible
      if (availability.availableCount > 0) {
        availabilities.add(availability);
      }
    }

    // 4. Si aucune pharmacie n'a le médicament dans le rayon initial, tester avec un rayon élargi
    if (availabilities.isEmpty && radiusKm < 25.0) {
      final allPharmacies = await _pharmacyRepo.getAll();
      for (final pharmacy in allPharmacies) {
        final availability = await _checkPharmacyAvailability(
          pharmacy,
          candidateMap,
          userLatitude,
          userLongitude,
        );
        if (availability.availableCount > 0) {
          availabilities.add(availability);
        }
      }
    }

    // 5. Trie par score de disponibilité (décroissant : ouvertes en premier)
    availabilities.sort((a, b) {
      final aOpen = a.pharmacy.isOpenNow;
      final bOpen = b.pharmacy.isOpenNow;
      if (aOpen && !bOpen) return -1;
      if (!aOpen && bOpen) return 1;
      return b.availabilityScore.compareTo(a.availabilityScore);
    });

    // 6. Limite le nombre de résultats
    return availabilities.take(maxResults).toList();
  }

  /// Recherche tous les médicaments candidats correspondant aux termes demandés.
  /// Sépare les candidats en exacts (même marque et dosage) et équivalents (génériques / DCI).
  Future<Map<String, ({List<Medicine> exact, List<Medicine> equivalents})>> _findCandidateMedicines(
    List<String> medicineNames, {
    List<Medicine>? specificMedicines,
  }) async {
    final map = <String, ({List<Medicine> exact, List<Medicine> equivalents})>{};

    for (var i = 0; i < medicineNames.length; i++) {
      final term = medicineNames[i];
      final clean = term.trim().toLowerCase();
      final seenIds = <int>{};
      final exactCandidates = <Medicine>[];
      final equivCandidates = <Medicine>[];

      // Médicament spécifique sélectionné via l'interface
      final specific = (specificMedicines != null && i < specificMedicines.length)
          ? specificMedicines[i]
          : null;

      if (specific != null && specific.medicineId != null) {
        seenIds.add(specific.medicineId!);
        exactCandidates.add(specific);
      }

      // 1. Recherche directe (Nom, DCI, Dosage, Forme)
      final direct = await _medicineRepo.search(clean);
      for (final m in direct) {
        if (m.medicineId != null && seenIds.add(m.medicineId!)) {
          final mNameLower = m.name.toLowerCase();
          // Est-ce une correspondance de marque directe ?
          final firstWord = clean.split(RegExp(r'\s+')).first;
          if (mNameLower.contains(firstWord) || firstWord.contains(mNameLower)) {
            exactCandidates.add(m);
          } else {
            equivCandidates.add(m);
          }
        }
      }

      // Trier les exacts : même dosage en premier, puis dosage proche
      final requestedDosage = specific?.dosage?.toLowerCase() ??
          (RegExp(r'\b(\d+\s*(?:mg|g|ml|%))\b', caseSensitive: false).firstMatch(clean)?.group(1)?.toLowerCase());

      exactCandidates.sort((a, b) {
        if (specific != null) {
          if (a.medicineId == specific.medicineId) return -1;
          if (b.medicineId == specific.medicineId) return 1;
        }
        if (requestedDosage != null) {
          final aHasDosage = a.dosage?.toLowerCase().contains(requestedDosage) ?? false;
          final bHasDosage = b.dosage?.toLowerCase().contains(requestedDosage) ?? false;
          if (aHasDosage && !bHasDosage) return -1;
          if (bHasDosage && !aHasDosage) return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // 2. Recherche avec alias / équivalents thérapeutiques
      final firstToken = clean.split(RegExp(r'\s+')).first;
      final normalized = firstToken.replaceAll(RegExp(r'[éèêë]'), 'e').replaceAll(RegExp(r'[àâ]'), 'a');
      final aliases = _searchAliases[firstToken] ?? _searchAliases[normalized] ?? [];

      for (final alias in aliases) {
        final aliasMeds = await _medicineRepo.search(alias);
        for (final m in aliasMeds) {
          if (m.medicineId != null && seenIds.add(m.medicineId!)) {
            final mNameLower = m.name.toLowerCase();
            if (mNameLower.contains(firstToken) || firstToken.contains(mNameLower)) {
              exactCandidates.add(m);
            } else {
              equivCandidates.add(m);
            }
          }
        }
      }

      // Trier les équivalents : même dosage en priorité
      if (requestedDosage != null) {
        equivCandidates.sort((a, b) {
          final aHasDosage = a.dosage?.toLowerCase().contains(requestedDosage) ?? false;
          final bHasDosage = b.dosage?.toLowerCase().contains(requestedDosage) ?? false;
          if (aHasDosage && !bHasDosage) return -1;
          if (!aHasDosage && bHasDosage) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      }

      map[term] = (exact: exactCandidates, equivalents: equivCandidates);
    }

    return map;
  }

  /// Vérifie la disponibilité des médicaments dans une pharmacie.
  Future<PharmacyAvailability> _checkPharmacyAvailability(
    Pharmacy pharmacy,
    Map<String, ({List<Medicine> exact, List<Medicine> equivalents})> candidateMap,
    double userLatitude,
    double userLongitude,
  ) async {
    final available = <String>[];
    final unavailable = <String>[];
    final availableDetails = <AvailableMedicineInfo>[];

    for (final entry in candidateMap.entries) {
      final term = entry.key;
      final exactCandidates = entry.value.exact;
      final equivCandidates = entry.value.equivalents;

      bool matched = false;

      // 1. Vérifier en priorité les médicaments de la marque exacte
      if (exactCandidates.isNotEmpty) {
        final exactIds = exactCandidates.map((m) => m.medicineId!).toList();
        final exactInStock = await _stockRepo.getInStockFromList(pharmacy.pharmacyId!, exactIds);

        if (exactInStock.isNotEmpty) {
          final inStockIds = exactInStock.map((s) => s.medicineId).toSet();
          // Choisir selon l'ordre de priorité des exacts (dosage demandé en premier)
          final matchedMed = exactCandidates.firstWhere((m) => inStockIds.contains(m.medicineId));

          final display = matchedMed.dosage != null && matchedMed.dosage!.isNotEmpty
              ? '${matchedMed.name} (${matchedMed.dosage})'
              : matchedMed.name;
          available.add(display);
          final stockItem = exactInStock.firstWhere((s) => s.medicineId == matchedMed.medicineId);
          final itemPrice = stockItem.customPrice ?? matchedMed.price;
          availableDetails.add(AvailableMedicineInfo(
            medicineId: matchedMed.medicineId,
            name: matchedMed.name,
            dosage: matchedMed.dosage,
            forme: matchedMed.forme,
            imageUrl: matchedMed.imageUrl,
            price: itemPrice,
            isGenericEquivalent: false,
            originalSearchTerm: term,
          ));
          matched = true;
        }
      }

      // 2. Si non trouvé dans la marque exacte, vérifier les équivalents thérapeutiques
      if (!matched && equivCandidates.isNotEmpty) {
        final equivIds = equivCandidates.map((m) => m.medicineId!).toList();
        final equivInStock = await _stockRepo.getInStockFromList(pharmacy.pharmacyId!, equivIds);

        if (equivInStock.isNotEmpty) {
          final inStockIds = equivInStock.map((s) => s.medicineId).toSet();
          final matchedMed = equivCandidates.firstWhere((m) => inStockIds.contains(m.medicineId));

          final display = matchedMed.dosage != null && matchedMed.dosage!.isNotEmpty
              ? '${matchedMed.name} (${matchedMed.dosage}) [Équivalent]'
              : '${matchedMed.name} [Équivalent]';
          available.add(display);
          final stockItem = equivInStock.firstWhere((s) => s.medicineId == matchedMed.medicineId);
          final itemPrice = stockItem.customPrice ?? matchedMed.price;
          availableDetails.add(AvailableMedicineInfo(
            medicineId: matchedMed.medicineId,
            name: matchedMed.name,
            dosage: matchedMed.dosage,
            forme: matchedMed.forme,
            imageUrl: matchedMed.imageUrl,
            price: itemPrice,
            isGenericEquivalent: true,
            originalSearchTerm: term,
          ));
          matched = true;
        }
      }

      if (!matched) {
        unavailable.add(term);
      }
    }

    final distance = calculateDistance(
      userLatitude,
      userLongitude,
      pharmacy.latitude,
      pharmacy.longitude,
    );

    return PharmacyAvailability(
      pharmacy: pharmacy,
      availableMedicines: available,
      unavailableMedicines: unavailable,
      distance: distance,
      availableMedicineDetails: availableDetails,
    );
  }

  /// Calcule la distance entre deux points GPS (formule de Haversine).
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Rayon de la Terre en km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  /// Convertit des degrés en radians.
  double _toRadians(double degrees) => degrees * (math.pi / 180);

  /// Formate la distance pour l'affichage.
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Estime le temps de trajet à pied (vitesse moyenne 4,5 km/h).
  String estimateWalkingTime(double distanceKm) {
    final minutes = (distanceKm / 4.5 * 60).round();
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  /// Estime le temps de trajet en voiture (vitesse moyenne urbaine 30 km/h).
  String estimateDrivingTime(double distanceKm) {
    final minutes = (distanceKm / 30.0 * 60).round();
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min en voiture';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}
