import 'dart:math' as math;
import '../models/pharmacy_stock.dart';
import '../models/medicine.dart';

/// Association d'un médicament et de son stock en officine.
class PharmacyStockItem {
  final Medicine medicine;
  final PharmacyStock stock;

  const PharmacyStockItem({
    required this.medicine,
    required this.stock,
  });

  int get medicineId => medicine.medicineId ?? stock.medicineId;
  String get medicineName => medicine.name;
  int get quantity => stock.quantity;
  String? get shelfLocation => stock.shelfLocation;
  double get effectivePrice => stock.effectivePrice(medicine.price);
  bool get isOutOfStock => !stock.inStock || stock.quantity <= 0;
  bool get isLowStock => stock.isLowStock(10);
  bool get isExpiringSoon => stock.isExpiringSoon(3);
  DateTime? get expirationDate => stock.expirationDate;
  String? get dci => medicine.dci;
}

enum VoiceIntentType {
  checkStock,
  locateMedicine,
  adjustStockDecrement,
  adjustStockIncrement,
  checkPrice,
  checkExpiry,
  checkStockout,
  findGeneric,
  unknown,
}

class VoiceParseResult {
  final VoiceIntentType intent;
  final String rawQuery;
  final String? matchedMedicineName;
  final PharmacyStockItem? matchedItem;
  final Medicine? matchedNationalMedicine;
  final int? quantity;
  final double confidence;
  final String spokenResponse;
  final String? actionDetails;
  final List<PharmacyStockItem>? listResults;

  const VoiceParseResult({
    required this.intent,
    required this.rawQuery,
    this.matchedMedicineName,
    this.matchedItem,
    this.matchedNationalMedicine,
    this.quantity,
    this.confidence = 0.0,
    required this.spokenResponse,
    this.actionDetails,
    this.listResults,
  });
}

/// Service NLP intelligent pour analyser les commandes vocales du pharmacien
/// et faire correspondre les médicaments par distance phonétique / Levenshtein.
class PharmacyVoiceNLPService {
  static const Map<String, int> _numberWords = {
    'un': 1,
    'une': 1,
    'deux': 2,
    'trois': 3,
    'quatre': 4,
    'cinq': 5,
    'six': 6,
    'sept': 7,
    'huit': 8,
    'neuf': 9,
    'dix': 10,
    'onze': 11,
    'douze': 12,
    'quinze': 15,
    'vingt': 20,
    'trente': 30,
    'cinquante': 50,
    'cent': 100,
  };

  /// Analyse une commande vocale brute
  VoiceParseResult parseCommand({
    required String voiceInput,
    required List<PharmacyStockItem> currentStockItems,
    List<Medicine>? allCatalogMedicines,
  }) {
    final query = voiceInput.trim();
    if (query.isEmpty) {
      return const VoiceParseResult(
        intent: VoiceIntentType.unknown,
        rawQuery: '',
        spokenResponse: 'Je vous écoute. Comment puis-je vous aider dans votre stock ?',
      );
    }

    final normalized = _normalize(query);

    // 1. Détection de rupture générale
    if (_isStockoutQuery(normalized)) {
      final outOfStock = currentStockItems.where((s) => s.isOutOfStock).toList();
      final count = outOfStock.length;
      final speech = count == 0
          ? 'Excellente nouvelle, aucune rupture de stock détectée dans votre officine.'
          : 'Vous avez $count produit${count > 1 ? 's' : ''} en rupture de stock : ${_summarizeNames(outOfStock)}.';
      return VoiceParseResult(
        intent: VoiceIntentType.checkStockout,
        rawQuery: query,
        confidence: 0.95,
        spokenResponse: speech,
        actionDetails: '$count rupture(s)',
        listResults: outOfStock,
      );
    }

    // 2. Détection d'expiration prochaine
    if (_isExpiryQuery(normalized)) {
      final expiring = currentStockItems.where((s) => s.isExpiringSoon).toList();
      final count = expiring.length;
      final speech = count == 0
          ? 'Aucun médicament ne périme dans les 90 prochains jours.'
          : 'Attention, $count médicament${count > 1 ? 's expirent' : ' expire'} bientôt : ${_summarizeNames(expiring)}.';
      return VoiceParseResult(
        intent: VoiceIntentType.checkExpiry,
        rawQuery: query,
        confidence: 0.95,
        spokenResponse: speech,
        actionDetails: '$count produit(s) à surveiller',
        listResults: expiring,
      );
    }

    // 3. Détection de substitution / générique
    if (_isGenericQuery(normalized)) {
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null) {
        final dci = target.dci?.trim();
        List<PharmacyStockItem> equivalents = [];
        if (dci != null && dci.isNotEmpty) {
          equivalents = currentStockItems
              .where((s) =>
                  s.medicineId != target.medicineId &&
                  s.dci != null &&
                  _normalize(s.dci!).contains(_normalize(dci)) &&
                  s.quantity > 0)
              .toList();
        }

        if (equivalents.isNotEmpty) {
          final first = equivalents.first;
          final speech =
              'Générique disponible en stock : ${first.medicineName} (${first.quantity} boîtes en stock à ${first.effectivePrice.toStringAsFixed(3)} DT).';
          return VoiceParseResult(
            intent: VoiceIntentType.findGeneric,
            rawQuery: query,
            matchedMedicineName: target.medicineName,
            matchedItem: target.item,
            matchedNationalMedicine: target.nationalMedicine,
            confidence: target.score,
            spokenResponse: speech,
            actionDetails: 'Alternative trouvée : ${first.medicineName}',
            listResults: equivalents,
          );
        } else {
          return VoiceParseResult(
            intent: VoiceIntentType.findGeneric,
            rawQuery: query,
            matchedMedicineName: target.medicineName,
            matchedItem: target.item,
            matchedNationalMedicine: target.nationalMedicine,
            confidence: target.score,
            spokenResponse:
                'Aucun générique de ${target.medicineName} ayant la DCI ${dci ?? "identique"} n\'est actuellement disponible en stock.',
          );
        }
      }
    }

    // 4. Détection d'ajustement de stock (décrément / incrément)
    final qty = _extractQuantity(normalized) ?? 1;
    final isDecrement = _isDecrementQuery(normalized);
    final isIncrement = _isIncrementQuery(normalized);

    if (isDecrement || isIncrement) {
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null && target.item != null) {
        final currentQty = target.item!.quantity;
        final newQty = isDecrement
            ? math.max(0, currentQty - qty)
            : currentQty + qty;

        final speech = isDecrement
            ? 'Stock de ${target.medicineName} décrémenté de $qty. Il reste $newQty boîtes.'
            : '$qty boîte${qty > 1 ? 's' : ''} ajoutée${qty > 1 ? 's' : ''} au stock de ${target.medicineName}. Total : $newQty unités.';

        return VoiceParseResult(
          intent: isDecrement
              ? VoiceIntentType.adjustStockDecrement
              : VoiceIntentType.adjustStockIncrement,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          quantity: qty,
          confidence: target.score,
          spokenResponse: speech,
          actionDetails: '$currentQty → $newQty boîtes',
        );
      }
    }

    // 5. Détection de localisation / rayon
    if (_isLocationQuery(normalized)) {
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null) {
        final location = target.item?.shelfLocation;
        final speech = (location != null && location.trim().isNotEmpty)
            ? '${target.medicineName} est rangé à l\'emplacement $location.'
            : '${target.medicineName} n\'a pas d\'emplacement spécifique défini dans l\'officine.';
        return VoiceParseResult(
          intent: VoiceIntentType.locateMedicine,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          confidence: target.score,
          spokenResponse: speech,
          actionDetails: location ?? 'Non assigné',
        );
      }
    }

    // 6. Détection de prix
    if (_isPriceQuery(normalized)) {
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null) {
        final price = target.item?.effectivePrice ??
            target.nationalMedicine?.price ??
            0.0;
        final speech =
            'Le prix de ${target.medicineName} est de ${price.toStringAsFixed(3)} Dinars.';
        return VoiceParseResult(
          intent: VoiceIntentType.checkPrice,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          confidence: target.score,
          spokenResponse: speech,
          actionDetails: '${price.toStringAsFixed(3)} DT',
        );
      }
    }

    // 7. Requête de stock par défaut (ex: "Doliprane", "Combien de Spasfon", "Stock Inexium")
    final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
    if (target != null) {
      if (target.item != null) {
        final item = target.item!;
        final price = item.effectivePrice;
        final loc = item.shelfLocation != null && item.shelfLocation!.isNotEmpty
            ? ' au ${item.shelfLocation}'
            : '';
        String statusText;
        if (item.isOutOfStock) {
          statusText = 'Ce médicament est actuellement en rupture de stock.';
        } else if (item.isLowStock) {
          statusText = 'Attention, stock faible : il ne reste que ${item.quantity} boîtes$loc.';
        } else {
          statusText = '${item.quantity} boîtes disponibles en stock$loc.';
        }

        final speech = '${item.medicineName} : $statusText Prix : ${price.toStringAsFixed(3)} DT.';
        return VoiceParseResult(
          intent: VoiceIntentType.checkStock,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          confidence: target.score,
          spokenResponse: speech,
          actionDetails: '${item.quantity} en stock (${price.toStringAsFixed(3)} DT)',
        );
      } else if (target.nationalMedicine != null) {
        // Dans le catalogue national mais pas encore en stock officine
        return VoiceParseResult(
          intent: VoiceIntentType.checkStock,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedNationalMedicine: target.nationalMedicine,
          confidence: target.score,
          spokenResponse:
              '${target.medicineName} est référencé au répertoire national (${target.nationalMedicine!.price.toStringAsFixed(3)} DT) mais n\'est pas encore enregistré dans votre stock officine.',
          actionDetails: 'Répertoire national (0 en stock)',
        );
      }
    }

    // Non reconnu
    return VoiceParseResult(
      intent: VoiceIntentType.unknown,
      rawQuery: query,
      spokenResponse:
          'Désolé, je n\'ai pas trouvé de médicament correspondant dans votre stock pour "$query". Essayez par exemple : "Combien de Doliprane en stock ?"',
    );
  }

  // --- MÉTROLOGIE ET PATTERNS ---

  static bool _isStockoutQuery(String text) {
    return text.contains('rupture') ||
        text.contains('epuise') ||
        text.contains('zero stock') ||
        text.contains('manquant') ||
        text.contains('qu\'est-ce qui manque');
  }

  static bool _isExpiryQuery(String text) {
    return text.contains('expire') ||
        text.contains('perime') ||
        text.contains('peremption') ||
        text.contains('date limite') ||
        text.contains('bientot perime');
  }

  static bool _isGenericQuery(String text) {
    return text.contains('generique') ||
        text.contains('substitut') ||
        text.contains('remplace') ||
        text.contains('remplacer') ||
        text.contains('alternative') ||
        text.contains('equivalent');
  }

  static bool _isDecrementQuery(String text) {
    return text.contains('decremente') ||
        text.contains('enleve') ||
        text.contains('retire') ||
        text.contains('vendu') ||
        text.contains('vends') ||
        text.contains('consomme') ||
        text.contains('baisse') ||
        text.contains('moins');
  }

  static bool _isIncrementQuery(String text) {
    return text.contains('ajoute') ||
        text.contains('recu') ||
        text.contains('augmente') ||
        text.contains('entree') ||
        text.contains('reception') ||
        text.contains('livraison') ||
        text.contains('plus');
  }

  static bool _isLocationQuery(String text) {
    return text.contains('ou se trouve') ||
        text.contains('ou est') ||
        text.contains('emplacement') ||
        text.contains('rayon') ||
        text.contains('tiroir') ||
        text.contains('etagere') ||
        text.contains('trouve');
  }

  static bool _isPriceQuery(String text) {
    return text.contains('prix') ||
        text.contains('combien coute') ||
        text.contains('combien vaut') ||
        text.contains('tarif') ||
        text.contains('valeur');
  }

  static int? _extractQuantity(String text) {
    // 1. Chercher un chiffre numérique
    final digitMatch = RegExp(r'\b(\d+)\b').firstMatch(text);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(1)!);
    }
    // 2. Chercher les mots numériques en français
    for (final entry in _numberWords.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(text)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _summarizeNames(List<PharmacyStockItem> items) {
    if (items.isEmpty) return '';
    final names = items.take(3).map((e) => e.medicineName).toList();
    if (items.length > 3) {
      return '${names.join(", ")} et ${items.length - 3} autre(s)';
    }
    return names.join(', ');
  }

  static String _normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[àâä]'), 'a');
    s = s.replaceAll(RegExp(r'[îï]'), 'i');
    s = s.replaceAll(RegExp(r'[ôö]'), 'o');
    s = s.replaceAll(RegExp(r'[ùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ç]'), 'c');
    s = s.replaceAll(RegExp(r"[^\w\s\d]"), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Trouve le meilleur candidat médicament via scoring flou (Levenshtein + sous-chaînes)
  _MatchedTarget? _extractMedicineMatch(
    String normalizedQuery,
    List<PharmacyStockItem> currentStockItems,
    List<Medicine>? allCatalogMedicines,
  ) {
    // Nettoyer les mots-clés d'intention de la requête pour isoler le nom
    var cleanedQuery = normalizedQuery;
    final stopWords = [
      'combien', 'de', 'boite', 'boites', 'unite', 'unites', 'en', 'stock',
      'reste', 'il', 'est', 'ce', 'qu', 'on', 'a', 'ou', 'se', 'trouve',
      'emplacement', 'rayon', 'prix', 'coute', 'decremente', 'enleve',
      'retire', 'vendu', 'ajoute', 'recu', 'generique', 'substitut',
      'remplace', 's\'il', 'vous', 'plait', 'donne', 'moi', 'le', 'la', 'les',
      'du', 'des', 'dans', 'notre', 'officine', 'pharmacie'
    ];
    for (final word in stopWords) {
      cleanedQuery = cleanedQuery.replaceAll(RegExp('\\b$word\\b'), ' ');
    }
    // Retirer aussi les nombres
    cleanedQuery = cleanedQuery.replaceAll(RegExp(r'\b\d+\b'), ' ');
    for (final numKey in _numberWords.keys) {
      cleanedQuery = cleanedQuery.replaceAll(RegExp('\\b$numKey\\b'), ' ');
    }
    cleanedQuery = cleanedQuery.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanedQuery.isEmpty) return null;

    _MatchedTarget? bestTarget;
    double bestScore = 0.0;

    // 1. Rechercher en priorité dans le stock actif de la pharmacie
    for (final item in currentStockItems) {
      final nameNorm = _normalize(item.medicineName);
      final score = _calculateSimilarity(cleanedQuery, nameNorm);
      if (score > bestScore) {
        bestScore = score;
        bestTarget = _MatchedTarget(
          medicineName: item.medicineName,
          item: item,
          nationalMedicine: item.medicine,
          score: score,
        );
      }
    }

    // 2. Si le score est faible (< 0.55), chercher dans le grand catalogue national
    if (bestScore < 0.55 && allCatalogMedicines != null) {
      for (final med in allCatalogMedicines) {
        final nameNorm = _normalize(med.name);
        final score = _calculateSimilarity(cleanedQuery, nameNorm);
        if (score > bestScore) {
          bestScore = score;
          bestTarget = _MatchedTarget(
            medicineName: med.name,
            item: null,
            nationalMedicine: med,
            score: score,
          );
        }
      }
    }

    return (bestScore >= 0.40) ? bestTarget : null;
  }

  /// Score hybride entre inclusion de sous-chaîne et similarité de Levenshtein
  static double _calculateSimilarity(String query, String target) {
    if (query.isEmpty || target.isEmpty) return 0.0;
    if (target.contains(query)) {
      return 0.80 + (query.length / target.length) * 0.20;
    }
    // Comparaison mot par mot
    final queryWords = query.split(' ').where((w) => w.length > 2).toList();
    if (queryWords.isNotEmpty) {
      for (final qw in queryWords) {
        if (target.contains(qw)) {
          return 0.75;
        }
      }
    }

    // Levenshtein sur les premiers N caractères
    final minLen = math.min(query.length, target.length);
    final subTarget = target.substring(0, minLen);
    final dist = _levenshtein(query.substring(0, minLen), subTarget);
    final ratio = 1.0 - (dist / minLen);
    return math.max(0.0, ratio);
  }

  static int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        dp[i][j] = math.min(
          dp[i - 1][j] + 1,
          math.min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
        );
      }
    }
    return dp[m][n];
  }
}

class _MatchedTarget {
  final String medicineName;
  final PharmacyStockItem? item;
  final Medicine? nationalMedicine;
  final double score;

  const _MatchedTarget({
    required this.medicineName,
    this.item,
    this.nationalMedicine,
    required this.score,
  });

  int? get medicineId => item?.medicineId ?? nationalMedicine?.medicineId;
  String? get dci => item?.dci ?? nationalMedicine?.dci;
}
