import 'dart:math' as math;

import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/data/ocr/lab_test_dictionary.dart';

/// Niveaux de confiance d'une ligne extraite (mêmes valeurs que le backend).
abstract final class OcrConfidence {
  static const high = 'haute';
  static const medium = 'moyenne';
  static const low = 'faible';
}

/// Transforme le texte brut de l'OCR (Tesseract / ML Kit) en [ScanBilan].
///
/// Portage Dart de `ai-service/app/ocr/parser.py` : normalisation des noms,
/// fuzzy matching sur [labTests], alias d'unités, références `a - b`,
/// `a à b`, `< x`, `> x`, valeur antérieure, date et laboratoire.
///
/// Classe pure (sans Flutter) : entièrement testable.
class BilanParser {
  BilanParser({this.minSimilarity = 0.72, this.criticalRatio = 0.5});

  /// Similarité minimale (0..1) pour rattacher un nom lu à une analyse connue.
  final double minSimilarity;

  /// Écart relatif à la borne au-delà duquel une valeur est CRITIQUE
  /// (0.5 = plus de 50 % au-dessus du max ou en dessous du min).
  final double criticalRatio;

  // ---------------------------------------------------------------------------
  // Point d'entrée
  // ---------------------------------------------------------------------------

  ScanBilan parse(String rawText, {String id = '${ScanBilan.localPrefix}preview', int patientId = 0}) {
    final lines = _lines(rawText);
    final headerSaysPrevious = lines.any((l) => _previousColumn.hasMatch(normalizeLabel(l)));

    final results = <BilanResult>[];
    final seen = <String>{};
    final categories = <LabCategory>[];
    for (final line in lines) {
      if (_isStopLine(line)) {
        if (results.isNotEmpty) break;
        continue;
      }
      if (isNoiseLine(line)) continue;
      final row = parseLine(line, id: results.length + 1);
      if (row == null || !seen.add(row.result.testName)) continue;
      results.add(row.result);
      if (row.category != null) categories.add(row.category!);
    }

    final hasPrevious = headerSaysPrevious || results.any((r) => r.valeurAncienne != null);
    return ScanBilan(
      id: id,
      typeBilan: _typeBilan(lines, categories),
      format: hasPrevious ? BilanFormat.ancienPatient : BilanFormat.nouveauPatient,
      dateBilan: extractDate(lines) ?? '',
      laboratoire: extractLaboratory(lines) ?? '',
      status: BilanStatus.pending,
      patientId: patientId,
      resultats: results,
      synced: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Statut
  // ---------------------------------------------------------------------------

  /// Hors plage → ANORMAL ; écart > [criticalRatio] de la borne → CRITIQUE.
  ResultStatus computeStatus(double? value, double? min, double? max) {
    if (value == null || (min == null && max == null)) return ResultStatus.nonApplicable;
    if (max != null && value > max) {
      return value > max * (1 + criticalRatio) ? ResultStatus.critique : ResultStatus.anormal;
    }
    if (min != null && value < min) {
      return value < min * (1 - criticalRatio) ? ResultStatus.critique : ResultStatus.anormal;
    }
    return ResultStatus.normal;
  }

  // ---------------------------------------------------------------------------
  // Lignes
  // ---------------------------------------------------------------------------

  static final _separator = RegExp(r'^[-=*_.\s|]{3,}$');
  static final _previousColumn = RegExp(r'anteri|precedent|ancien');

  List<String> _lines(String text) =>
      text
          .replaceAll('\r', '\n')
          .replaceAll('﻿', '')
          .split('\n')
          .map((l) => l.replaceAll(RegExp(r'[ \t|]+'), ' ').trim())
          .where((l) => l.length >= 3 && !_separator.hasMatch(l))
          .toList();

  static final _stopWords = RegExp(r'\b(signature|cachet|le biologiste|valide par|biologiste responsable)\b');

  bool _isStopLine(String line) => _stopWords.hasMatch(normalizeLabel(line));

  static final _phone = RegExp(r'(\+?216[\s.]?)?\b\d{2}[\s.]\d{3}[\s.]\d{3}\b');
  static final _noiseWords = RegExp(
    r'\b(tel|tél|telephone|fax|gsm|e ?mail|site|www|adresse|rue|avenue|av|boulevard|bd|route|km|cite|residence|'
    r'immeuble|imm|bp|code postal|patient|nom|prenom|ne le|nee le|age|ans|sexe|dossier|matricule|cin|'
    r'prescripteur|docteur|dr|medecin|page|edite|imprime|prelevement|prelev|analyses?|resultats?|examens?|'
    r'unites?|references?|valeurs? usuelles|normes|mf|rib|republique|ministere)\b',
  );

  /// En-têtes, adresses, téléphones, identité du patient...
  bool isNoiseLine(String line) {
    final norm = normalizeLabel(line);
    if (_phone.hasMatch(line)) return true;
    if (!RegExp(r'\d').hasMatch(line)) return true; // pas de valeur → rien à extraire
    if (_noiseWords.hasMatch(norm)) {
      // « Glycémie (résultat) 1,02 g/l » reste une ligne de résultat.
      final tokens = _tokens(line);
      final idx = _valueIndex(tokens);
      if (idx > 0 && _matchTest(tokens.sublist(0, idx)) != null) return false;
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Extraction d'une ligne
  // ---------------------------------------------------------------------------

  static const _countUnits = {'/mm3', '10^3/mm3', '10^9/l'};
  static final _num = RegExp(r'^\d+(?:[.,]\d+)?$');
  static final _numWithSuffix = RegExp(r'^(\d+(?:[.,]\d+)?)(\S+)$');
  static final _threshold = RegExp(r'^[<>≤≥]\d+(?:[.,]\d+)?$');
  static final _ocrDigits = RegExp(r'^[\dOoIl]+(?:[.,][\dOoIl]+)?$');

  /// Découpe en mots, recolle `<` / `>` isolés au nombre suivant et corrige
  /// les confusions O/0 et l/1 dans les nombres (« 1O,5 » → « 10,5 »).
  List<String> _tokens(String line) {
    final raw = line.split(' ').where((t) => t.isNotEmpty).toList();
    final out = <String>[];
    for (var i = 0; i < raw.length; i++) {
      var t = raw[i];
      if (RegExp(r'^[<>≤≥]$').hasMatch(t) && i + 1 < raw.length) {
        t = '$t${raw[++i]}';
      }
      if (RegExp(r'\d').hasMatch(t) && _ocrDigits.hasMatch(t)) {
        t = t.replaceAll(RegExp('[Oo]'), '0').replaceAll(RegExp('[Il]'), '1');
      }
      out.add(t);
    }
    return out;
  }

  /// Index du premier mot qui est une valeur (nombre, seuil, ou nombre collé à une unité).
  int _valueIndex(List<String> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (_num.hasMatch(t) || _threshold.hasMatch(t)) return i;
      final m = _numWithSuffix.firstMatch(t);
      if (m != null && canonicalUnit(m.group(2)!) != null) return i;
    }
    return -1;
  }

  /// Fusionne les milliers séparés par une espace (« 250 000 » → « 250000 »)
  /// sur les numérations (/mm3), où ce format est courant.
  String _mergeThousands(String line) {
    if (!RegExp(r"mm[3³']|/mm\b", caseSensitive: false).hasMatch(line)) return line;
    final pattern = RegExp(r'(?<![\d.,])(\d{1,3}) (\d{3})(?![\d.,])');
    var previous = '';
    var current = line;
    while (previous != current) {
      previous = current;
      current = current.replaceAllMapped(pattern, (m) => '${m[1]}${m[2]}');
    }
    return current;
  }

  /// Extrait un résultat d'une ligne, ou `null` si ce n'est pas une ligne de résultat.
  ParsedRow? parseLine(String line, {int id = 0}) {
    final tokens = _tokens(_mergeThousands(line));
    final valueIdx = _valueIndex(tokens);
    if (valueIdx <= 0) return null;

    // ---- Nom ----
    final nameTokens = tokens.sublist(0, valueIdx);
    final match = _matchTest(nameTokens);

    // ---- Valeur (éventuellement collée à l'unité : « 13,5g/dl ») ----
    var valueToken = tokens[valueIdx];
    final rest = tokens.sublist(valueIdx + 1);
    final glued = _numWithSuffix.firstMatch(valueToken);
    if (glued != null && !_num.hasMatch(valueToken)) {
      valueToken = glued.group(1)!;
      rest.insert(0, glued.group(2)!);
    }
    final valeur = valueToken.replaceAll(RegExp(r'[≤]'), '<').replaceAll(RegExp(r'[≥]'), '>');

    // ---- Unité ----
    String unit = '';
    for (var i = 0; i < rest.length; i++) {
      final u = canonicalUnit(rest[i]);
      if (u != null) {
        unit = u;
        rest.removeAt(i);
        break;
      }
    }

    // ---- Référence, date et valeur antérieures ----
    var remaining = rest.join(' ');
    String? dateAncienne;
    final dateMatch = _dateAny.firstMatch(remaining);
    if (dateMatch != null) {
      dateAncienne = _isoDate(dateMatch);
      remaining = remaining.replaceRange(dateMatch.start, dateMatch.end, ' ');
    }
    final ref = extractReference(remaining);
    remaining = ref.rest;
    final previous = RegExp(r'(?<![\d.,])\d+(?:[.,]\d+)?(?![\d.,])').firstMatch(remaining)?.group(0);

    // Analyse inconnue : acceptée seulement si la ligne a la forme complète d'un résultat.
    final String testName;
    if (match != null) {
      // Formule leucocytaire : le bilan donne le % puis la valeur absolue.
      final isAbsolute = match.def.units.first == '%' && _countUnits.contains(unit);
      testName = isAbsolute ? '${match.def.name} (valeur absolue)' : match.def.name;
    } else {
      final rawName = nameTokens.join(' ').replaceAll(RegExp(r'^[^\p{L}]+|[^\p{L}\d)]+$', unicode: true), '');
      final looksLikeResult = unit.isNotEmpty && (ref.min != null || ref.max != null);
      if (!looksLikeResult || rawName.length < 3 || rawName.length > 40) return null;
      testName = rawName;
    }

    // ---- Confiance ----
    final unitAccepted = match != null && unit.isNotEmpty && match.def.units.contains(unit);
    final String confiance;
    if (match == null || match.score < 0.9 || (unit.isNotEmpty && !unitAccepted)) {
      confiance = OcrConfidence.low;
    } else if (unitAccepted && (ref.min != null || ref.max != null)) {
      confiance = OcrConfidence.high;
    } else {
      confiance = OcrConfidence.medium;
    }

    final value = parseNumber(valeur);
    return ParsedRow(
      BilanResult(
        id: id,
        testName: testName,
        valeur: valeur,
        unite: unit,
        referenceMin: ref.min,
        referenceMax: ref.max,
        referenceText: ref.text,
        valeurAncienne: previous,
        dateAncienne: dateAncienne,
        status: computeStatus(value, ref.min, ref.max),
        confiance: confiance,
      ),
      match?.def.category,
    );
  }

  // ---------------------------------------------------------------------------
  // Références
  // ---------------------------------------------------------------------------

  static const _n = r'(?<![\d.,])(\d+(?:[.,]\d+)?)';
  static final _range = RegExp('$_n\\s*(?:[-–—]|\\s(?:à|a|au)\\s)\\s*$_n', caseSensitive: false);
  static final _lessThan = RegExp('(?:<|≤|inf(?:[ée]rieur)?\\.?\\s*(?:à|a))\\s*=?\\s*$_n', caseSensitive: false);
  static final _greaterThan = RegExp('(?:>|≥|sup(?:[ée]rieur)?\\.?\\s*(?:à|a))\\s*=?\\s*$_n', caseSensitive: false);

  /// `a - b`, `a à b`, `(a-b)`, `< x`, `> x` ; [ReferenceMatch.rest] = texte restant.
  ReferenceMatch extractReference(String text) {
    double toNum(String s) => double.parse(s.replaceAll(',', '.'));
    String cut(Match m) => text.replaceRange(m.start, m.end, ' ').replaceAll(RegExp(r'[()\[\]]'), ' ').trim();

    final range = _range.firstMatch(text);
    if (range != null) {
      final a = toNum(range[1]!), b = toNum(range[2]!);
      return ReferenceMatch(math.min(a, b), math.max(a, b), range[0]!.trim(), cut(range));
    }
    final lt = _lessThan.firstMatch(text);
    if (lt != null) return ReferenceMatch(null, toNum(lt[1]!), '< ${lt[1]}', cut(lt));
    final gt = _greaterThan.firstMatch(text);
    if (gt != null) return ReferenceMatch(toNum(gt[1]!), null, '> ${gt[1]}', cut(gt));
    return ReferenceMatch(null, null, null, text.trim());
  }

  // ---------------------------------------------------------------------------
  // Fuzzy matching
  // ---------------------------------------------------------------------------

  /// Meilleure analyse connue pour un nom lu, ou `null` si similarité < [minSimilarity].
  ///
  /// Compare chaque suite de mots consécutifs du nom (« taux d'hémoglobine »
  /// → « hemoglobine ») à chaque alias ; à score égal, la plus longue gagne
  /// (« hémoglobine glycosylée » → HbA1c et non Hémoglobine).
  TestMatch? _matchTest(List<String> nameTokens) {
    final words =
        normalizeLabel(
          nameTokens.join(' '),
        ).replaceAll(RegExp(r"[^a-z0-9\s]"), ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 8) return null;

    TestMatch? best;
    var bestLength = 0;
    for (var len = words.length; len >= 1; len--) {
      for (var start = 0; start + len <= words.length; start++) {
        final candidate = words.sublist(start, start + len).join(' ');
        for (final def in labTests) {
          for (final alias in def.aliases) {
            // Alias très courts (« hb », « vs ») : égalité stricte uniquement.
            final score = alias.length <= 3 ? (candidate == alias ? 1.0 : 0.0) : similarity(candidate, alias);
            if (score < minSimilarity) continue;
            final better = best == null || score > best.score + 1e-9 || (score > best.score - 1e-9 && len > bestLength);
            if (better) {
              best = TestMatch(def, score);
              bestLength = len;
            }
          }
        }
      }
    }
    return best;
  }

  /// Similarité de Levenshtein normalisée (1 = identique).
  static double similarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    return 1 - _levenshtein(a, b) / math.max(a.length, b.length);
  }

  static int _levenshtein(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = math.min(math.min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
      }
      previous = current;
    }
    return previous[b.length];
  }

  // ---------------------------------------------------------------------------
  // Métadonnées
  // ---------------------------------------------------------------------------

  /// `jj/mm/aa(aa)`, `jj.mm.aaaa`, `jj-mm-aaaa`, `aaaa-mm-jj` (pas `4.5-10`, une référence).
  static final _dateAny = RegExp(
    r'\b(\d{1,2})/(\d{1,2})/(\d{4}|\d{2})\b|\b(\d{1,2})[.\-](\d{1,2})[.\-](\d{4})\b|\b(\d{4})-(\d{2})-(\d{2})\b',
  );
  static final _birth = RegExp(r'\b(ne|nee|naissance|age)\b');
  static final _dateHint = RegExp(r'\b(prelev\w*|bilan|edite|date|du|le|recu)\b');

  /// Date du bilan (ISO `yyyy-MM-dd`) : priorité aux lignes « prélevé le… »,
  /// jamais la date de naissance.
  String? extractDate(List<String> lines) {
    String? fallback;
    for (final line in lines) {
      final norm = normalizeLabel(line);
      if (_birth.hasMatch(norm)) continue;
      for (final m in _dateAny.allMatches(line)) {
        final iso = _isoDate(m);
        if (iso == null) continue;
        if (_dateHint.hasMatch(norm)) return iso;
        fallback ??= iso;
      }
    }
    return fallback;
  }

  String? _isoDate(Match m) {
    int d, mo, y;
    if (m[7] != null) {
      y = int.parse(m[7]!);
      mo = int.parse(m[8]!);
      d = int.parse(m[9]!);
    } else {
      final base = m[1] != null ? 1 : 4;
      d = int.parse(m[base]!);
      mo = int.parse(m[base + 1]!);
      y = int.parse(m[base + 2]!);
      if (y < 100) y += 2000;
    }
    if (mo < 1 || mo > 12 || d < 1 || d > 31 || y < 1950 || y > 2100) return null;
    return '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  static final _labWords = RegExp(
    r'\b(laboratoire|labo|biolab|clinique|polyclinique|hopital|centre|cabinet|institut pasteur)\b',
  );

  /// Nom du laboratoire, cherché dans les 15 premières lignes : d'abord une
  /// ligne qui COMMENCE par « Laboratoire… » (pas « Service laboratoire »).
  String? extractLaboratory(List<String> lines) {
    final head = lines.take(15).where((l) => !_phone.hasMatch(l)).toList();
    for (final strict in [true, false]) {
      for (final line in head) {
        final norm = normalizeLabel(line);
        final match = _labWords.firstMatch(norm);
        if (match != null && (!strict || match.start == 0)) return line.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      }
    }
    return null;
  }

  String _typeBilan(List<String> lines, List<LabCategory> categories) {
    final header = normalizeLabel(lines.take(25).join(' '));
    if (RegExp(r'\b(nfs|hemogramme|numeration formule|hematologie)\b').hasMatch(header)) return 'NFS';
    if (RegExp(r'\bbiochimie\b').hasMatch(header)) return 'Biochimie';
    final distinct = categories.toSet();
    if (distinct.length == 1) {
      return distinct.first == LabCategory.hematologie ? 'NFS' : distinct.first.label;
    }
    return 'Bilan biologique';
  }
}

/// Résultat brut d'une ligne + famille de l'analyse reconnue.
class ParsedRow {
  const ParsedRow(this.result, this.category);

  final BilanResult result;
  final LabCategory? category;
}

class TestMatch {
  const TestMatch(this.def, this.score);

  final LabTestDef def;
  final double score;
}

class ReferenceMatch {
  const ReferenceMatch(this.min, this.max, this.text, this.rest);

  final double? min;
  final double? max;
  final String? text;

  /// Texte de la ligne une fois la référence retirée.
  final String rest;
}
