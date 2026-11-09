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
  setStockQuantity,
  updatePrice,
  updateLocation,
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
  final double? newPrice;
  final String? newLocation;
  final double confidence;
  final String spokenResponse;
  final String? confirmationPrompt;
  final String? actionDetails;
  final List<PharmacyStockItem>? listResults;

  const VoiceParseResult({
    required this.intent,
    required this.rawQuery,
    this.matchedMedicineName,
    this.matchedItem,
    this.matchedNationalMedicine,
    this.quantity,
    this.newPrice,
    this.newLocation,
    this.confidence = 0.0,
    required this.spokenResponse,
    this.confirmationPrompt,
    this.actionDetails,
    this.listResults,
  });

  bool get requiresConfirmation =>
      intent == VoiceIntentType.updatePrice ||
      intent == VoiceIntentType.updateLocation ||
      intent == VoiceIntentType.setStockQuantity ||
      intent == VoiceIntentType.adjustStockDecrement ||
      intent == VoiceIntentType.adjustStockIncrement;
}

/// Service NLP intelligent pour analyser les commandes vocales du pharmacien
/// et faire correspondre les médicaments par distance phonétique / Levenshtein.
class PharmacyVoiceNLPService {
  static const Map<String, int> _numberWords = {
    'zero': 0,
    'zéro': 0,
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
        spokenResponse: 'Je vous écoute.',
      );
    }

    final normalized = _normalize(query);

    // 1. Modification du prix ("change le prix du doliprane à 5 DT", "mets le prix à 12.5 dt")
    if (_isPriceUpdateQuery(normalized)) {
      final newPrice = _extractNewPrice(normalized);
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null && newPrice != null) {
        final priceFormatted = newPrice.toStringAsFixed(3);
        final oldPriceFormatted = target.item != null
            ? target.item!.effectivePrice.toStringAsFixed(3)
            : (target.nationalMedicine?.price.toStringAsFixed(3) ?? '0.000');
        return VoiceParseResult(
          intent: VoiceIntentType.updatePrice,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          newPrice: newPrice,
          confidence: target.score,
          spokenResponse: 'Prix de ${target.medicineName} mis à $priceFormatted DT.',
          confirmationPrompt: 'Confirmez-vous le nouveau prix de ${target.medicineName} à $priceFormatted DT ?',
          actionDetails: '$oldPriceFormatted → $priceFormatted DT',
        );
      }
    }

    // 2. Modification de l'emplacement ("déplace doliprane au Rayon B", "mets spasfon au tiroir 2")
    if (_isLocationUpdateQuery(normalized)) {
      final newLoc = _extractNewLocation(query);
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null && newLoc != null) {
        final oldLoc = target.item?.shelfLocation ?? 'Non assigné';
        return VoiceParseResult(
          intent: VoiceIntentType.updateLocation,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          newLocation: newLoc,
          confidence: target.score,
          spokenResponse: '${target.medicineName} placé au $newLoc.',
          confirmationPrompt: 'Confirmez-vous le déplacement de ${target.medicineName} vers $newLoc ?',
          actionDetails: '$oldLoc → $newLoc',
        );
      }
    }

    // 3. Réglage direct du stock ("mets le stock de doliprane à 20", "fixe le stock à 15")
    if (_isSetStockQuery(normalized)) {
      final qty = _extractQuantity(normalized);
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null && target.item != null && qty != null) {
        final oldQty = target.item!.quantity;
        return VoiceParseResult(
          intent: VoiceIntentType.setStockQuantity,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedItem: target.item,
          matchedNationalMedicine: target.nationalMedicine,
          quantity: qty,
          confidence: target.score,
          spokenResponse: 'Stock de ${target.medicineName} réglé à $qty boîtes.',
          confirmationPrompt: 'Confirmez-vous le réglage du stock de ${target.medicineName} à $qty boîtes ?',
          actionDetails: '$oldQty → $qty boîtes',
        );
      }
    }

    // 4. Détection de rupture générale ("Qu'est-ce qui est en rupture ?")
    if (_isStockoutQuery(normalized)) {
      final outOfStock = currentStockItems.where((s) => s.isOutOfStock).toList();
      final count = outOfStock.length;
      final speech = count == 0
          ? 'Aucune rupture de stock.'
          : '$count rupture${count > 1 ? 's' : ''} : ${_summarizeNames(outOfStock)}.';
      return VoiceParseResult(
        intent: VoiceIntentType.checkStockout,
        rawQuery: query,
        confidence: 0.95,
        spokenResponse: speech,
        actionDetails: '$count rupture(s)',
        listResults: outOfStock,
      );
    }

    // 5. Détection d'expiration prochaine ("Qu'est-ce qui expire ?")
    if (_isExpiryQuery(normalized)) {
      final expiring = currentStockItems.where((s) => s.isExpiringSoon).toList();
      final count = expiring.length;
      final speech = count == 0
          ? 'Aucun médicament à périmer dans les 90 jours.'
          : '$count médicament${count > 1 ? 's expirent' : ' expire'} bientôt : ${_summarizeNames(expiring)}.';
      return VoiceParseResult(
        intent: VoiceIntentType.checkExpiry,
        rawQuery: query,
        confidence: 0.95,
        spokenResponse: speech,
        actionDetails: '$count produit(s) à surveiller',
        listResults: expiring,
      );
    }

    // 6. Détection de substitution / générique ("Générique de Doliprane")
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
              'Générique disponible : ${first.medicineName} (${first.quantity} boîtes à ${first.effectivePrice.toStringAsFixed(3)} DT).';
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
                'Aucun générique disponible en stock pour ${target.medicineName}.',
          );
        }
      }
    }

    // 7. Détection d'ajustement de stock (décrément / incrément)
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
            : '$qty boîte${qty > 1 ? 's ajoutées' : ' ajoutée'} au stock de ${target.medicineName}. Total : $newQty unités.';

        final confirmMsg = isDecrement
            ? 'Confirmez-vous le retrait de $qty boîte${qty > 1 ? "s" : ""} de ${target.medicineName} ?'
            : 'Confirmez-vous l\'ajout de $qty boîte${qty > 1 ? "s" : ""} de ${target.medicineName} ?';

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
          confirmationPrompt: confirmMsg,
          actionDetails: '$currentQty → $newQty boîtes',
        );
      }
    }

    // 8. Détection de localisation / rayon ("Où est le Doliprane ?")
    if (_isLocationQuery(normalized)) {
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null) {
        final location = target.item?.shelfLocation;
        final speech = (location != null && location.trim().isNotEmpty)
            ? '${target.medicineName} est au $location.'
            : '${target.medicineName} : aucun emplacement défini.';
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

    // 9. Détection de prix ("Quel est le prix du Doliprane ?")
    if (_isPriceQuery(normalized)) {
      final target = _extractMedicineMatch(normalized, currentStockItems, allCatalogMedicines);
      if (target != null) {
        final price = target.item?.effectivePrice ??
            target.nationalMedicine?.price ??
            0.0;
        final speech =
            '${target.medicineName} : ${price.toStringAsFixed(3)} Dinars.';
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

    // 10. Requête de stock par défaut ("Doliprane", "Combien de Spasfon")
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
          statusText = 'Rupture de stock.';
        } else if (item.isLowStock) {
          statusText = '${item.quantity} boîtes disponibles (stock faible)$loc';
        } else {
          statusText = '${item.quantity} boîtes disponibles$loc';
        }

        final speech = '${item.medicineName} : $statusText (${price.toStringAsFixed(3)} DT).';
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
        return VoiceParseResult(
          intent: VoiceIntentType.checkStock,
          rawQuery: query,
          matchedMedicineName: target.medicineName,
          matchedNationalMedicine: target.nationalMedicine,
          confidence: target.score,
          spokenResponse:
              '${target.medicineName} : Référencé au répertoire national (${target.nationalMedicine!.price.toStringAsFixed(3)} DT) mais absent du stock officine.',
          actionDetails: 'Répertoire national (0 en stock)',
        );
      }
    }

    // Non reconnu
    return VoiceParseResult(
      intent: VoiceIntentType.unknown,
      rawQuery: query,
      spokenResponse:
          'Commande non reconnue. Vous pouvez demander un stock, changer un prix, ou déplacer un produit.',
    );
  }

  // --- MÉTROLOGIE ET PATTERNS ---

  static bool _isPriceUpdateQuery(String text) {
    final hasPriceWord = text.contains('prix') || text.contains('tarif');
    final hasActionWord = text.contains('change') ||
        text.contains('changer') ||
        text.contains('modifie') ||
        text.contains('modifier') ||
        text.contains('mets') ||
        text.contains('mettre') ||
        text.contains('fixe') ||
        text.contains('fixer') ||
        text.contains('passe') ||
        text.contains('passer') ||
        text.contains('nouveau');
    return hasPriceWord && hasActionWord;
  }

  static bool _isLocationUpdateQuery(String text) {
    final hasLocWord = text.contains('rayon') ||
        text.contains('etagere') ||
        text.contains('tiroir') ||
        text.contains('armoire') ||
        text.contains('bac') ||
        text.contains('frigo') ||
        text.contains('emplacement');
    final hasActionWord = text.contains('change') ||
        text.contains('changer') ||
        text.contains('deplace') ||
        text.contains('deplacer') ||
        text.contains('range') ||
        text.contains('ranger') ||
        text.contains('mets') ||
        text.contains('mettre') ||
        text.contains('place') ||
        text.contains('placer');
    return hasLocWord && hasActionWord;
  }

  static bool _isSetStockQuery(String text) {
    return text.contains('mets le stock') ||
        text.contains('mettre le stock') ||
        text.contains('regle le stock') ||
        text.contains('regler le stock') ||
        text.contains('fixe le stock') ||
        text.contains('fixer le stock') ||
        text.contains('ajuste le stock') ||
        text.contains('ajuster le stock') ||
        text.contains('stock a') ||
        text.contains('stock =');
  }

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

  static bool isAffirmative(String text) {
    final norm = _normalize(text);
    return norm == 'oui' ||
        norm.startsWith('oui ') ||
        norm.endsWith(' oui') ||
        norm.contains('confirme') ||
        norm.contains('valide') ||
        norm.contains('d accord') ||
        norm.contains('daccord') ||
        norm.contains('ok') ||
        norm.contains('vas y') ||
        norm.contains('applique') ||
        norm.contains('enregistre');
  }

  static bool isNegative(String text) {
    final norm = _normalize(text);
    return norm == 'non' ||
        norm.startsWith('non ') ||
        norm.endsWith(' non') ||
        norm.contains('annule') ||
        norm.contains('stop') ||
        norm.contains('refuse') ||
        norm.contains('laisse') ||
        norm.contains('pas maintenant');
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

  static double? _extractNewPrice(String text) {
    // 1. Chercher un chiffre numérique avec décimale optionnelle : "5 dt", "5.500", "à 12.5 dt"
    final regex = RegExp(
      r'(?:a|à|=|de|prix|fixe|mets|mettre)?\s*(\d+(?:[.,]\d+)?)\s*(?:dt|dinars?|millimes?)?',
      caseSensitive: false,
    );
    for (final match in regex.allMatches(text)) {
      final numStr = match.group(1);
      if (numStr != null && numStr.isNotEmpty) {
        final parsed = double.tryParse(numStr.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    // 2. Mots de chiffres français
    for (final entry in _numberWords.entries) {
      if (text.contains(entry.key)) {
        return entry.value.toDouble();
      }
    }
    return null;
  }

  static String? _extractNewLocation(String text) {
    final match = RegExp(
      r'(?:au|dans|en|vers|a|sur)?\s*((?:rayon|etagere|tiroir|armoire|bac|frigo|comptoir|zone)\s*[a-z0-9\-]+(?:\s*(?:etagere|tiroir|bac|niveau|case)\s*[a-z0-9\-]+)?)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final rawLoc = match.group(1)!.trim();
      return rawLoc
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return null;
  }

  static int? _extractQuantity(String text) {
    final digitMatch = RegExp(r'\b(\d+)\b').firstMatch(text);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(1)!);
    }
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
    var cleanedQuery = normalizedQuery;
    final stopWords = [
      'combien', 'de', 'boite', 'boites', 'unite', 'unites', 'en', 'stock',
      'reste', 'il', 'est', 'ce', 'qu', 'on', 'a', 'ou', 'se', 'trouve',
      'emplacement', 'rayon', 'prix', 'coute', 'decremente', 'enleve',
      'retire', 'vendu', 'ajoute', 'recu', 'generique', 'substitut',
      'remplace', 's\'il', 'vous', 'plait', 'donne', 'moi', 'le', 'la', 'les',
      'du', 'des', 'dans', 'notre', 'officine', 'pharmacie', 'change',
      'changer', 'mets', 'mettre', 'fixe', 'fixer', 'modifie', 'modifier',
      'regle', 'regler', 'ajuste', 'ajuster', 'deplace', 'deplacer', 'range',
      'ranger', 'place', 'placer', 'dt', 'dinar', 'dinars', 'millimes',
      'nouveau', 'nouvel', 'vers', 'sur', 'tiroir', 'etagere', 'armoire',
      'bac', 'frigo', 'zone', 'comptoir'
    ];
    for (final word in stopWords) {
      cleanedQuery = cleanedQuery.replaceAll(RegExp('\\b$word\\b'), ' ');
    }
    cleanedQuery = cleanedQuery.replaceAll(RegExp(r'\b\d+\b'), ' ');
    for (final numKey in _numberWords.keys) {
      cleanedQuery = cleanedQuery.replaceAll(RegExp('\\b$numKey\\b'), ' ');
    }
    cleanedQuery = cleanedQuery.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanedQuery.isEmpty) return null;

    _MatchedTarget? bestTarget;
    double bestScore = 0.0;

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

  double _calculateSimilarity(String query, String target) {
    if (query == target) return 1.0;
    if (target.contains(query)) return 0.90;

    final queryWords = query.split(' ').where((w) => w.length > 2).toList();
    final targetWords = target.split(' ').where((w) => w.length > 2).toList();

    for (final qw in queryWords) {
      for (final tw in targetWords) {
        if (tw.startsWith(qw) || qw.startsWith(tw)) {
          return 0.85;
        }
        final dist = _levenshtein(qw, tw);
        final maxLen = math.max(qw.length, tw.length);
        if (maxLen > 0 && (dist / maxLen) <= 0.30) {
          return 0.80;
        }
      }
    }

    final overallDist = _levenshtein(query, target);
    final maxLen = math.max(query.length, target.length);
    if (maxLen == 0) return 1.0;
    return (1.0 - (overallDist / maxLen)).clamp(0.0, 1.0);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1,
          math.min(v0[j + 1] + 1, v0[j] + cost),
        );
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}

class _MatchedTarget {
  final String medicineName;
  final PharmacyStockItem? item;
  final Medicine? nationalMedicine;
  final double score;

  _MatchedTarget({
    required this.medicineName,
    this.item,
    this.nationalMedicine,
    required this.score,
  });

  String? get dci => item?.dci ?? nationalMedicine?.dci;
  int? get medicineId => item?.medicineId ?? nationalMedicine?.medicineId;
}
