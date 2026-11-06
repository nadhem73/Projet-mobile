// Outils de texte partagés par les briques IA du module User.

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
};

/// Minuscules, sans accents, espaces normalisés : « Pénicilline » → « penicilline ».
String normalizeMedicalText(String? input) {
  final lower = (input ?? '').toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Mots-clés (déjà normalisés) présents dans [normalizedText].
///
/// La correspondance se fait en début de mot : « aspirine » trouve
/// « aspirine 100 mg », mais « ains » ne trouve pas « certains ».
List<String> findKeywords(String normalizedText, Iterable<String> keywords) => [
  for (final k in keywords)
    if (RegExp('(^|[^a-z0-9])${RegExp.escape(k)}').hasMatch(normalizedText)) k,
];
