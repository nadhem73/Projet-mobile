/// Dictionnaire des analyses reconnues par l'OCR hors-ligne et de leurs unités.
///
/// Porté depuis `ai-service/app/ocr/parser.py` (backend). Les alias sont déjà
/// normalisés (minuscules, sans accents, `-` → espace) : voir [normalizeLabel].
library;

/// Famille d'analyses, utilisée pour deviner le type du bilan.
enum LabCategory {
  hematologie('Hématologie'),
  biochimie('Biochimie'),
  hormonologie('Hormonologie'),
  inflammation('Inflammation');

  const LabCategory(this.label);

  final String label;
}

class LabTestDef {
  const LabTestDef(this.name, this.aliases, this.units, this.category);

  /// Nom affiché (« Hémoglobine »).
  final String name;

  /// Variantes normalisées rencontrées sur les bilans.
  final List<String> aliases;

  /// Unités acceptées (forme canonique, voir [canonicalUnit]).
  final List<String> units;
  final LabCategory category;
}

const _counts = ['/mm3', '10^3/mm3', '10^9/l', 'g/l'];
const _formule = ['%', '/mm3', '10^3/mm3', '10^9/l'];
const _lipides = ['g/l', 'mmol/l'];
const _enzymes = ['UI/L', 'µkat/l'];
const _bilirubine = ['mg/l', 'µmol/l'];

const List<LabTestDef> labTests = [
  // ---- Hématologie ----
  LabTestDef(
    'Globules rouges',
    ['globules rouges', 'hematies', 'erythrocytes', 'gr'],
    ['10^6/mm3', '10^12/l', '/mm3'],
    LabCategory.hematologie,
  ),
  LabTestDef('Hémoglobine', ['hemoglobine', 'hb', 'hgb'], ['g/dl', 'g/l'], LabCategory.hematologie),
  LabTestDef('Hématocrite', ['hematocrite', 'ht', 'hte', 'hct'], ['%'], LabCategory.hematologie),
  LabTestDef('VGM', ['vgm', 'volume globulaire moyen'], ['fl'], LabCategory.hematologie),
  LabTestDef('TCMH', ['tcmh', 'teneur corpusculaire moyenne en hemoglobine'], ['pg'], LabCategory.hematologie),
  LabTestDef(
    'CCMH',
    ['ccmh', 'concentration corpusculaire moyenne en hemoglobine'],
    ['%', 'g/dl'],
    LabCategory.hematologie,
  ),
  LabTestDef('Globules blancs', ['globules blancs', 'leucocytes', 'gb'], _counts, LabCategory.hematologie),
  LabTestDef('Plaquettes', ['plaquettes', 'thrombocytes', 'plq'], _counts, LabCategory.hematologie),
  LabTestDef(
    'VS',
    ['vs', 'vitesse de sedimentation', 'vs 1ere heure', 'vs 1 ere heure', 'premiere heure'],
    ['mm'],
    LabCategory.hematologie,
  ),
  LabTestDef('VS 2e heure', ['deuxieme heure', 'vs 2eme heure', 'vs 2e heure'], ['mm'], LabCategory.hematologie),
  LabTestDef('Neutrophiles', ['polynucleaires neutrophiles', 'neutrophiles', 'pnn'], _formule, LabCategory.hematologie),
  LabTestDef('Éosinophiles', ['polynucleaires eosinophiles', 'eosinophiles', 'pne'], _formule, LabCategory.hematologie),
  LabTestDef('Basophiles', ['polynucleaires basophiles', 'basophiles', 'pnb'], _formule, LabCategory.hematologie),
  LabTestDef('Lymphocytes', ['lymphocytes'], _formule, LabCategory.hematologie),
  LabTestDef('Monocytes', ['monocytes'], _formule, LabCategory.hematologie),

  // ---- Biochimie ----
  LabTestDef('Glycémie', ['glycemie', 'glycemie a jeun', 'glucose'], ['g/l', 'mmol/l', 'mg/dl'], LabCategory.biochimie),
  LabTestDef('Créatinine', ['creatinine', 'creatininemie'], ['mg/l', 'µmol/l'], LabCategory.biochimie),
  LabTestDef('Urée', ['uree', 'azotemie'], ['g/l', 'mmol/l'], LabCategory.biochimie),
  LabTestDef('Cholestérol total', ['cholesterol total', 'cholesterol'], _lipides, LabCategory.biochimie),
  LabTestDef('Cholestérol HDL', ['hdl cholesterol', 'cholesterol hdl', 'hdl'], _lipides, LabCategory.biochimie),
  LabTestDef('Cholestérol LDL', ['ldl cholesterol', 'cholesterol ldl', 'ldl'], _lipides, LabCategory.biochimie),
  LabTestDef('Triglycérides', ['triglycerides', 'tg'], _lipides, LabCategory.biochimie),
  LabTestDef('Fer sérique', ['fer serique', 'fer', 'sideremie'], ['µg/dl', 'µmol/l'], LabCategory.biochimie),
  LabTestDef('Acide urique', ['acide urique', 'uricemie'], ['mg/l', 'µmol/l'], LabCategory.biochimie),
  LabTestDef('Bilirubine totale', ['bilirubine totale', 'bilirubine t'], _bilirubine, LabCategory.biochimie),
  LabTestDef(
    'Bilirubine directe',
    ['bilirubine directe', 'bilirubine conjuguee', 'bilirubine d'],
    _bilirubine,
    LabCategory.biochimie,
  ),
  LabTestDef(
    'Bilirubine indirecte',
    ['bilirubine indirecte', 'bilirubine libre', 'bilirubine i'],
    _bilirubine,
    LabCategory.biochimie,
  ),
  LabTestDef('ASAT', ['asat', 'sgot', 'tgo', 'transaminases asat'], _enzymes, LabCategory.biochimie),
  LabTestDef('ALAT', ['alat', 'sgpt', 'tgp', 'transaminases alat'], _enzymes, LabCategory.biochimie),
  LabTestDef('Gamma GT', ['gamma gt', 'ggt', 'gamma glutamyl transferase', 'y gt'], _enzymes, LabCategory.biochimie),
  LabTestDef('PAL', ['pal', 'phosphatases alcalines', 'phosphatase alcaline'], _enzymes, LabCategory.biochimie),
  LabTestDef('Protéines totales', ['proteines totales', 'protidemie', 'proteinemie'], ['g/l'], LabCategory.biochimie),
  LabTestDef('Albumine', ['albumine', 'albuminemie'], ['g/l'], LabCategory.biochimie),
  LabTestDef('Sodium', ['sodium', 'natremie', 'na'], ['mmol/l', 'meq/l'], LabCategory.biochimie),
  LabTestDef('Potassium', ['potassium', 'kaliemie'], ['mmol/l', 'meq/l'], LabCategory.biochimie),
  LabTestDef('Calcium', ['calcium', 'calcemie'], ['mg/l', 'mmol/l'], LabCategory.biochimie),
  LabTestDef(
    'HbA1c',
    ['hba1c', 'hemoglobine glycosylee', 'hemoglobine glyquee'],
    ['%', 'mmol/mol'],
    LabCategory.biochimie,
  ),

  // ---- Hormonologie / inflammation ----
  LabTestDef('TSH', ['tsh', 'tsh us', 'tshus'], ['µUI/ml', 'mUI/l'], LabCategory.hormonologie),
  LabTestDef('CRP', ['crp', 'proteine c reactive'], ['mg/l'], LabCategory.inflammation),
];

/// Variantes OCR → unité canonique. Clés passées par [_unitKey].
const Map<String, List<String>> _unitVariants = {
  'mmol/l': ['mmol/l', 'mmol', 'mmoi', 'mmoi/l', 'mmoli', 'mmo', 'mmo/l', 'mmol/1', 'mmo1/l'],
  'µmol/l': ['umol/l', 'umol', 'umoli', 'umo/l', 'jmol', 'jmol/l', 'jmoli', 'wmol', 'wmol/l', 'umolt', 'umol/1'],
  'mmol/mol': ['mmol/mol'],
  'UI/L': ['ui/l', 'uit', 'u/l', 'ui', 'ul', 'iu/l', 'u.i/l', 'ui/1', 'ui/i', 'u/i', 'uii'],
  'µkat/l': ['ukat/l'],
  'g/dl': ['g/dl', 'g/100ml', 'gr/dl'],
  'g/l': ['g/l', 'g/1', 'gr/l'],
  'mg/l': ['mg/l', 'mg/1'],
  'mg/dl': ['mg/dl'],
  'µg/dl': ['ug/dl'],
  'µUI/ml': ['uui/ml', 'uiu/ml'],
  'mUI/l': ['mui/l'],
  'meq/l': ['meq/l'],
  '%': ['%', '°o', '°/o', 'o/o', '°.', '°', '"o', '%.'],
  'fl': ['fl', 'um3', 'u3'],
  'pg': ['pg'],
  'mm': ['mm', 'mm/h', 'mm/1h', 'mm/1ere'],
  '/mm3': ['/mm3', 'mm3', '/mm³', 'mm³', "mm'", "/mm'", 'elts/mm3', 'el/mm3'],
  '10^3/mm3': ['10^3/mm3', '103/mm3', '10³/mm3', '10e3/mm3', '10*3/mm3', 'x10^3/mm3', '10^3/ul', '10^3/µl'],
  '10^6/mm3': [
    '10^6/mm3',
    'millions/mm3',
    'millions/mm³',
    "millions/mm'",
    'm/mm3',
    '106/mm3',
    '10⁶/mm3',
    '10e6/mm3',
    '10*6/mm3',
    'x10^6/mm3',
    '10^6/ul',
  ],
  '10^9/l': ['10^9/l', '109/l', '10e9/l', 'x10^9/l', 'giga/l'],
  '10^12/l': ['10^12/l', '1012/l', '10e12/l', 'x10^12/l', 't/l', 'tera/l'],
};

final Map<String, String> _unitLookup = {
  for (final entry in _unitVariants.entries)
    for (final variant in entry.value) _unitKey(variant): entry.key,
};

String _unitKey(String raw) =>
    raw.toLowerCase().replaceAll(RegExp('[µμ]'), 'u').replaceAll(RegExp(r'^[\s.:;,(\[]+|[\s.:;,)\]]+$'), '');

/// Unité canonique d'un mot lu par l'OCR, `null` si ce n'est pas une unité.
///
/// `mmoi` → `mmol/l`, `jmol` → `µmol/l`, `uit` → `UI/L`, `g/100ml` → `g/dl`.
String? canonicalUnit(String token) {
  final key = _unitKey(token);
  if (key.isEmpty) return null;
  return _unitLookup[key];
}

const Map<String, String> _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', //
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
};

/// Minuscules, sans accents, `-` remplacé par une espace, espaces compactés.
String normalizeLabel(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp('[-_–—]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
