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
  String get medicineName {
    final normName = medicine.name.toLowerCase();
    if (medicine.dosage != null && medicine.dosage!.trim().isNotEmpty) {
      final d = medicine.dosage!.trim();
      if (!normName.contains(d.toLowerCase())) {
        return '${medicine.name} $d';
      }
    }
    return medicine.name;
  }
  int get quantity => stock.quantity;
  String? get shelfLocation => stock.shelfLocation;
  double get effectivePrice => stock.effectivePrice(medicine.price);
  bool get isOutOfStock => !stock.inStock || stock.quantity <= 0;
  bool get isLowStock => stock.isLowStock(10);
  bool get isExpiringSoon => stock.isExpiringSoon(3);
  DateTime? get expirationDate => stock.expirationDate;
  String? get dci => medicine.dci;
  String? get dosage => medicine.dosage;
  String? get forme => medicine.forme;
  String? get presentation => medicine.presentation;

  /// Label complet pour la recherche NLP (nom + dosage + forme + présentation)
  String get fullSearchLabel => [
        medicine.name,
        medicine.dosage,
        medicine.forme,
        medicine.presentation,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
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
      final priceDetails = _extractNewPriceDetails(normalized);
      if (priceDetails != null) {
        final queryWithoutPrice = normalized
            .replaceAll(priceDetails.phrase, ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final target = _extractMedicineMatch(
          queryWithoutPrice,
          currentStockItems,
          allCatalogMedicines,
        );
        if (target != null) {
          final newPrice = priceDetails.value;
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
    }

    // 2. Modification de l'emplacement ("déplace doliprane au Rayon B", "mets spasfon au tiroir 2")
    if (_isLocationUpdateQuery(normalized)) {
      final locDetails = _extractNewLocationDetails(normalized);
      final queryWithoutLoc = locDetails != null
          ? normalized
              .replaceAll(locDetails.phrase, ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
          : normalized;
      final target = _extractMedicineMatch(
        queryWithoutLoc,
        currentStockItems,
        allCatalogMedicines,
      );
      if (target != null && locDetails != null) {
        final newLoc = locDetails.value;
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
      final qtyDetails = _extractQuantityDetails(normalized);
      final queryWithoutQty = qtyDetails != null
          ? normalized
              .replaceAll(qtyDetails.phrase, ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
          : normalized;
      final target = _extractMedicineMatch(
        queryWithoutQty,
        currentStockItems,
        allCatalogMedicines,
      );
      if (target != null && target.item != null && qtyDetails != null) {
        final qty = qtyDetails.value;
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
    final isDecrement = _isDecrementQuery(normalized);
    final isIncrement = _isIncrementQuery(normalized);

    if (isDecrement || isIncrement) {
      final qtyDetails = _extractQuantityDetails(normalized);
      final qty = qtyDetails?.value ?? 1;
      final queryWithoutQty = qtyDetails != null
          ? normalized
              .replaceAll(qtyDetails.phrase, ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
          : normalized;
      final target = _extractMedicineMatch(
        queryWithoutQty,
        currentStockItems,
        allCatalogMedicines,
      );
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

  static _ExtractedValue<double>? _extractNewPriceDetails(String text) {
    // 1. Suffixe explicite en devise : "8 dinars", "8 dt", "12.500 dt", "a 8 dinars"
    final currencyRegex = RegExp(
      r'(?:(?:a|à|=|de|vers|pour)\s+)?(\d+(?:[.,]\d+)?)\s*(?:dt|dinars?|millimes?)\b',
      caseSensitive: false,
    );
    final curMatch = currencyRegex.firstMatch(text);
    if (curMatch != null) {
      final numStr = curMatch.group(1);
      if (numStr != null) {
        final parsed = double.tryParse(numStr.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          return _ExtractedValue(value: parsed, phrase: curMatch.group(0)!);
        }
      }
    }

    // 2. Mots de chiffres français avec devise : "cinq dinars", "huit dt"
    for (final entry in _numberWords.entries) {
      final wordCurrencyRegex = RegExp(
        '(?:(?:a|à|=|de|vers|pour)\\s+)?(${entry.key})\\s*(?:dt|dinars?|millimes?)\\b',
        caseSensitive: false,
      );
      final match = wordCurrencyRegex.firstMatch(text);
      if (match != null) {
        return _ExtractedValue(value: entry.value.toDouble(), phrase: match.group(0)!);
      }
    }

    // 3. Préposition d'attribution explicite suivie d'un chiffre NON-dosage (ex: "à 8", "au prix de 12")
    final prepRegex = RegExp(
      r'(?:(?:au\s+prix\s+de|nouveau\s+prix\s+de|prix\s*(?:a|à|de)|fixe\s*(?:a|à)|mets\s*(?:a|à)|passe\s*(?:a|à)|\ba|\bà)\s*)(\d+(?:[.,]\d+)?)(?!\s*(?:mg|g|ml|mcg|ui|cp|comprime|gelule|sachet|flacon|ampoule|boite|boites|unite|unites))\b',
      caseSensitive: false,
    );
    final prepMatch = prepRegex.firstMatch(text);
    if (prepMatch != null) {
      final numStr = prepMatch.group(1);
      if (numStr != null) {
        final parsed = double.tryParse(numStr.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          return _ExtractedValue(value: parsed, phrase: prepMatch.group(0)!);
        }
      }
    }

    // 4. Mots de chiffres français après préposition d'attribution : "à huit", "prix à cinq"
    for (final entry in _numberWords.entries) {
      final prepWordRegex = RegExp(
        '(?:(?:au\\s+prix\\s+de|prix\\s*(?:a|à|de)|\\ba|\\bà)\\s+)(${entry.key})\\b',
        caseSensitive: false,
      );
      final match = prepWordRegex.firstMatch(text);
      if (match != null) {
        return _ExtractedValue(value: entry.value.toDouble(), phrase: match.group(0)!);
      }
    }

    // 5. Repli : chiffre numérique isolé en fin de phrase qui n'est pas un dosage
    final fallbackRegex = RegExp(
      r'\b(\d+(?:[.,]\d+)?)\s*(?:dt|dinars?|millimes?)?$',
      caseSensitive: false,
    );
    final fallbackMatch = fallbackRegex.firstMatch(text);
    if (fallbackMatch != null) {
      final numStr = fallbackMatch.group(1);
      if (numStr != null) {
        final parsed = double.tryParse(numStr.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          return _ExtractedValue(value: parsed, phrase: fallbackMatch.group(0)!);
        }
      }
    }

    return null;
  }

  static _ExtractedValue<String>? _extractNewLocationDetails(String text) {
    final match = RegExp(
      r'(?:au|dans|en|vers|a|sur)?\s*((?:rayon|etagere|tiroir|armoire|bac|frigo|comptoir|zone)\s*[a-z0-9\-]+(?:\s*(?:etagere|tiroir|bac|niveau|case)\s*[a-z0-9\-]+)?)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final rawLoc = match.group(1)!.trim();
      final formatted = rawLoc
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
      return _ExtractedValue(value: formatted, phrase: match.group(0)!);
    }
    return null;
  }

  static _ExtractedValue<int>? _extractQuantityDetails(String text) {
    // 1. Chiffre avec mot d'unité : "15 boîtes", "10 unités", "3 flacons"
    final unitMatch = RegExp(
      r'\b(\d+)\s*(?:boites?|unites?|flacons?|sachets?|ampoules?|tubes?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (unitMatch != null) {
      final val = int.tryParse(unitMatch.group(1)!);
      if (val != null) {
        return _ExtractedValue(value: val, phrase: unitMatch.group(0)!);
      }
    }

    // 2. Chiffre précédé d'une action/préposition (sans unité de dosage)
    final actionMatch = RegExp(
      r'(?:(?:stock\s*(?:a|à|=)|regle\s*(?:a|à)|fixe\s*(?:a|à)|ajoute|enleve|retire|vendu|consomme|recu)\s*)(\d+)(?!\s*(?:mg|g|ml|mcg|ui|cp))\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (actionMatch != null) {
      final val = int.tryParse(actionMatch.group(1)!);
      if (val != null) {
        return _ExtractedValue(value: val, phrase: actionMatch.group(0)!);
      }
    }

    // 3. Mots français avec mot d'unité
    for (final entry in _numberWords.entries) {
      final wordUnitMatch = RegExp(
        '\\b(${entry.key})\\s*(?:boites?|unites?|flacons?|sachets?)\\b',
        caseSensitive: false,
      ).firstMatch(text);
      if (wordUnitMatch != null) {
        return _ExtractedValue(value: entry.value, phrase: wordUnitMatch.group(0)!);
      }
    }

    // 4. Mots français précédés d'une action
    for (final entry in _numberWords.entries) {
      final wordActionMatch = RegExp(
        '(?:(?:stock\\s*(?:a|à|=)|ajoute|enleve|retire|vendu|recu)\\s+)(${entry.key})\\b',
        caseSensitive: false,
      ).firstMatch(text);
      if (wordActionMatch != null) {
        return _ExtractedValue(value: entry.value, phrase: wordActionMatch.group(0)!);
      }
    }

    // 5. Chiffre isolé NON-dosage (ex: "mets le stock à 15")
    final isolatedMatch = RegExp(
      r'(?:(?:a|à)\s+)?\b(\d+)\b(?!\s*(?:mg|g|ml|mcg|ui|cp))\s*$',
      caseSensitive: false,
    ).firstMatch(text);
    if (isolatedMatch != null) {
      final val = int.tryParse(isolatedMatch.group(1)!);
      if (val != null) {
        return _ExtractedValue(value: val, phrase: isolatedMatch.group(0)!);
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
    // Séparer les chiffres collés aux unités (ex: 500mg -> 500 mg, 1g -> 1 g)
    s = s.replaceAllMapped(RegExp(r'(\d+)([a-zA-Z]+)'), (m) => '${m[1]} ${m[2]}');
    s = s.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
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
      'remplace', 's il', 'vous', 'plait', 'donne', 'moi', 'le', 'la', 'les',
      'du', 'des', 'dans', 'notre', 'officine', 'pharmacie', 'change',
      'changer', 'mets', 'mettre', 'fixe', 'fixer', 'modifie', 'modifier',
      'regle', 'regler', 'ajuste', 'ajuster', 'deplace', 'deplacer', 'range',
      'ranger', 'place', 'placer', 'dt', 'dinar', 'dinars', 'millimes',
      'nouveau', 'nouvel', 'vers', 'sur', 'tiroir', 'etagere', 'armoire',
      'bac', 'frigo', 'zone', 'comptoir', 'j', 'je', 'ai', 'as', 'avons',
      'avez', 'ont', 'tu', 'elle', 'nous', 'ils', 'elles', 'pour', 'avec',
      'par', 'd', 'l', 'un', 'une', 'au', 'aux'
    ];
    for (final word in stopWords) {
      cleanedQuery = cleanedQuery.replaceAll(RegExp('\\b$word\\b'), ' ');
    }
    // Ne pas supprimer les chiffres pour préserver le dosage (ex: 500, 1000)
    cleanedQuery = cleanedQuery.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanedQuery.isEmpty) return null;

    _MatchedTarget? bestTarget;
    double bestScore = 0.0;

    for (final item in currentStockItems) {
      // Score on full label (name + dosage + forme + présentation) AND name alone —
      // keep whichever is higher so short queries still match by name only.
      final fullNorm = _normalize(item.fullSearchLabel);
      final nameNorm = _normalize(item.medicineName);
      final scoreFull = _calculateSimilarity(cleanedQuery, fullNorm);
      final scoreName = _calculateSimilarity(cleanedQuery, nameNorm);
      final score = scoreFull > scoreName ? scoreFull : scoreName;
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
        // Also match catalog medicines by full label
        final fullLabel = [med.name, med.dosage, med.forme, med.presentation]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        final fullNorm = _normalize(fullLabel);
        final nameNorm = _normalize(med.name);
        final scoreFull = _calculateSimilarity(cleanedQuery, fullNorm);
        final scoreName = _calculateSimilarity(cleanedQuery, nameNorm);
        final score = scoreFull > scoreName ? scoreFull : scoreName;
        if (score > bestScore) {
          bestScore = score;
          final normName = med.name.toLowerCase();
          String catalogName = med.name;
          if (med.dosage != null && med.dosage!.trim().isNotEmpty) {
            final d = med.dosage!.trim();
            if (!normName.contains(d.toLowerCase())) {
              catalogName = '${med.name} $d';
            }
          }
          bestTarget = _MatchedTarget(
            medicineName: catalogName,
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
    if (target.contains(query)) return 0.95;

    const medicalTokens = {'mg', 'g', 'ml', 'l', 'ui', 'cp', 'fl', 'b'};
    final queryWords = query
        .split(' ')
        .where((w) =>
            w.isNotEmpty &&
            (w.length > 2 ||
                medicalTokens.contains(w) ||
                RegExp(r'^\d+$').hasMatch(w)))
        .toList();
    final targetWords = target.split(' ').where((w) => w.isNotEmpty).toList();

    if (queryWords.isEmpty || targetWords.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (final qw in queryWords) {
      double bestWordScore = 0.0;
      for (final tw in targetWords) {
        if (qw == tw) {
          bestWordScore = 1.0;
          break;
        }

        // Chiffres numériques (dosage ex: 500 vs 1000)
        final isNumQ = RegExp(r'^\d+$').hasMatch(qw);
        final isNumT = RegExp(r'^\d+$').hasMatch(tw);
        if (isNumQ && isNumT) {
          continue;
        }

        if (tw.startsWith(qw) || qw.startsWith(tw)) {
          if (qw.length >= 3 && tw.length >= 3) {
            bestWordScore = math.max(bestWordScore, 0.90);
          }
        } else if (qw.length >= 4 && tw.length >= 4) {
          final dist = _levenshtein(qw, tw);
          final maxLen = math.max(qw.length, tw.length);
          if (maxLen > 0 && (dist / maxLen) <= 0.25) {
            bestWordScore = math.max(bestWordScore, 0.85);
          }
        }
      }
      totalScore += bestWordScore;
    }

    final coverage = totalScore / queryWords.length;
    return coverage.clamp(0.0, 1.0);
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

class _ExtractedValue<T> {
  final T value;
  final String phrase;

  const _ExtractedValue({
    required this.value,
    required this.phrase,
  });
}
