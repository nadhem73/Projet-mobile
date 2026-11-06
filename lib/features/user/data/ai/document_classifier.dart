import 'package:medilink/features/user/data/ai/ai_text.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';

/// Proposition de l'IA pour un document photographié.
class DocumentSuggestion {
  const DocumentSuggestion({
    required this.category,
    required this.title,
    required this.confidence,
    this.keywords = const [],
  });

  final DocumentCategory category;
  final String title;

  /// Entre 0 et 1.
  final double confidence;

  /// Mots du document qui ont orienté la décision (explicabilité).
  final List<String> keywords;

  int get confidencePercent => (confidence * 100).round();
}

/// Sous-type reconnu dans une catégorie (sert à construire le titre).
class _Subtype {
  const _Subtype(this.title, this.keywords);

  final String title;
  final List<String> keywords;
}

class _CategoryModel {
  const _CategoryModel(this.category, this.defaultTitle, this.weights, {this.subtypes = const []});

  final DocumentCategory category;
  final String defaultTitle;

  /// Mot-clé normalisé → poids (vocabulaire médical français / tunisien).
  final Map<String, double> weights;
  final List<_Subtype> subtypes;
}

const _models = [
  _CategoryModel(
    DocumentCategory.analysis,
    'Analyses médicales',
    {
      'laboratoire': 2, 'biologie': 2, 'analyses': 1.5, 'bilan': 1.5, 'resultat': 1, 'valeurs de reference': 3,
      'normes': 1, 'hemoglobine': 3, 'hematocrite': 3, 'leucocytes': 3, 'plaquettes': 3, 'globules': 2.5,
      'glycemie': 3, 'cholesterol': 3, 'triglycerides': 3, 'creatinine': 3, 'uree': 2, 'tsh': 3, 'hba1c': 3,
      'ferritine': 3, 'crp': 2.5, 'transaminases': 3, 'asat': 2, 'alat': 2, 'g/l': 1.5, 'mmol/l': 2, 'mg/l': 1.5,
      'ui/l': 2, 'prelevement': 2, 'serologie': 3, 'ecbu': 3, 'nfs': 3, 'vitamine d': 2.5,
    },
    subtypes: [
      _Subtype('Numération formule sanguine', ['nfs', 'hemogramme', 'numeration']),
      _Subtype('Bilan lipidique', ['cholesterol', 'triglycerides', 'ldl', 'hdl']),
      _Subtype('Bilan glycémique', ['glycemie', 'hba1c', 'hemoglobine glyquee']),
      _Subtype('Bilan thyroïdien', ['tsh', 't4', 't3']),
      _Subtype('Bilan rénal', ['creatinine', 'uree', 'dfg']),
      _Subtype('Analyse d\'urine', ['ecbu', 'urine']),
      _Subtype('Sérologie', ['serologie']),
    ],
  ),
  _CategoryModel(
    DocumentCategory.imaging,
    'Imagerie médicale',
    {
      'radiologie': 3, 'radiographie': 3, 'radio': 2, 'imagerie': 3, 'echographie': 3, 'echo': 1.5, 'irm': 3,
      'scanner': 3, 'tdm': 3, 'tomodensitometrie': 3, 'mammographie': 3, 'doppler': 3, 'cliche': 2, 'incidence': 2,
      'coupes': 2, 'injection': 1, 'produit de contraste': 2.5, 'conclusion': 0.5, 'thorax': 1, 'abdominale': 1,
    },
    subtypes: [
      _Subtype('IRM', ['irm', 'resonance magnetique']),
      _Subtype('Scanner', ['scanner', 'tdm', 'tomodensitometrie']),
      _Subtype('Échographie', ['echographie', 'doppler']),
      _Subtype('Mammographie', ['mammographie']),
      _Subtype('Radiographie', ['radiographie', 'radio', 'cliche']),
    ],
  ),
  _CategoryModel(DocumentCategory.prescription, 'Ordonnance', {
    'ordonnance': 4, 'prescription': 2.5, 'cp': 1.5, 'comprime': 2, 'comprimes': 2, 'gelule': 2, 'sachet': 1.5,
    'sirop': 2, 'mg': 1, 'fois par jour': 3, 'par jour': 1.5, 'matin': 1, 'soir': 1, 'pendant': 1, 'boite': 2,
    'renouvelable': 3, 'qsp': 3, 'posologie': 2.5, 'cnam': 1, 'pharmacie': 1.5, 'x 3/j': 2, '1/j': 2,
  }),
  _CategoryModel(
    DocumentCategory.report,
    'Compte rendu médical',
    {
      'compte rendu': 4, 'compte-rendu': 4, 'hospitalisation': 3, 'lettre': 2, 'cher confrere': 4, 'confrere': 3,
      'antecedents': 2, 'examen clinique': 3, 'diagnostic': 2, 'sortie': 1.5, 'operatoire': 3, 'intervention': 2,
      'certificat': 3, 'certifie': 3, 'arret de travail': 3, 'histoire de la maladie': 3, 'evolution': 1,
    },
    subtypes: [
      _Subtype('Certificat médical', ['certificat', 'certifie']),
      _Subtype('Compte rendu opératoire', ['operatoire']),
      _Subtype('Compte rendu d\'hospitalisation', ['hospitalisation', 'sortie']),
      _Subtype('Lettre de liaison', ['cher confrere', 'confrere']),
    ],
  ),
];

const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Classification automatique des documents du dossier (texte issu de l'OCR).
///
/// Modèle à vocabulaire pondéré : chaque catégorie a un lexique médical,
/// on additionne les poids des termes trouvés et on normalise en probabilité
/// (softmax). Rapide, hors-ligne et explicable (on montre les mots trouvés).
class DocumentClassifier {
  const DocumentClassifier();

  /// En dessous de ce score, le texte n'est pas assez médical pour décider.
  static const double minScore = 3;

  /// Renvoie null si le texte ne permet pas de proposer une catégorie.
  DocumentSuggestion? classify(String rawText, {DateTime? now}) {
    final text = normalizeMedicalText(rawText);
    if (text.length < 10) return null;

    final scores = <DocumentCategory, double>{};
    final matches = <DocumentCategory, List<String>>{};
    for (final model in _models) {
      final found = findKeywords(text, model.weights.keys);
      matches[model.category] = found;
      scores[model.category] = found.fold(0.0, (sum, k) => sum + model.weights[k]!);
    }

    final best = _models.reduce((a, b) => scores[a.category]! >= scores[b.category]! ? a : b);
    final bestScore = scores[best.category]!;
    if (bestScore < minScore) return null;

    // Probabilité « douce » : la catégorie gagnante face aux autres.
    final total = scores.values.fold(0.0, (sum, s) => sum + s);
    final confidence = total == 0 ? 0.0 : (bestScore / total).clamp(0.0, 1.0);

    final subtype = best.subtypes.firstWhere(
      (s) => findKeywords(text, s.keywords).isNotEmpty,
      orElse: () => _Subtype(best.defaultTitle, const []),
    );
    final date = _documentDate(text) ?? now ?? DateTime.now();
    final keywords = matches[best.category]!..sort((a, b) => best.weights[b]!.compareTo(best.weights[a]!));

    return DocumentSuggestion(
      category: best.category,
      title: '${subtype.title} — ${_months[date.month - 1]} ${date.year}',
      confidence: confidence,
      keywords: keywords.take(5).toList(),
    );
  }

  /// Première date plausible du document (jj/mm/aaaa, jj-mm-aaaa, jj.mm.aaaa).
  DateTime? _documentDate(String text) {
    for (final m in RegExp(r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})\b').allMatches(text)) {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      var year = int.parse(m.group(3)!);
      if (year < 100) year += 2000;
      if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1950 || year > DateTime.now().year + 1) continue;
      return DateTime(year, month, day);
    }
    return null;
  }
}
