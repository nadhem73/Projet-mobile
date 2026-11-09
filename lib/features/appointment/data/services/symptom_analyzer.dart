import 'package:medilink/features/appointment/data/models/orientation_result.dart';

/// Un symptôme reconnaissable : les mots à chercher et la spécialité concernée.
class SymptomRule {
  const SymptomRule(this.specialty, this.label, this.keywords, {this.weight = 1, this.soon = false});

  final String specialty;

  /// Libellé affiché dans les raisons (ex. « palpitations »).
  final String label;

  /// Mots ou débuts de mots à chercher, en minuscules SANS accents (ex. 'palpit', 'essouffl').
  final List<String> keywords;

  /// Poids du symptôme dans le choix de la spécialité.
  final double weight;

  /// Ce symptôme justifie à lui seul une consultation rapide.
  final bool soon;
}

/// Signe de gravité : la conduite à tenir est d'appeler le 190, pas de prendre rendez-vous.
class RedFlagRule {
  const RedFlagRule(this.label, this.keywords, {this.specialty});

  final String label;
  final List<String> keywords;

  /// Spécialité concernée, si le signe en indique une (ex. douleur thoracique → Cardiologie).
  final String? specialty;
}

/// Analyse hors ligne des symptômes décrits en français (règles + mots-clés).
///
/// Fonctionne sans internet ni clé d'API. Ce n'est pas un diagnostic : le
/// résultat indique seulement une spécialité et un niveau d'urgence.
class SymptomAnalyzer {
  const SymptomAnalyzer();

  // ---------------------------------------------------------------------------
  // Signes de gravité → urgence (190)
  // ---------------------------------------------------------------------------
  static const redFlags = [
    RedFlagRule('douleur dans la poitrine', [
      'douleur dans la poitrine',
      'douleur a la poitrine',
      'mal a la poitrine',
      'mal dans la poitrine',
      'douleur thoracique',
      'serrement dans la poitrine',
      'oppression thoracique',
      'poitrine qui serre',
    ], specialty: 'Cardiologie'),
    RedFlagRule('difficulté à respirer', [
      'du mal a respirer',
      'difficulte a respirer',
      'difficultes a respirer',
      'n\'arrive pas a respirer',
      'n\'arrive plus a respirer',
      'peux plus respirer',
      'j\'etouffe',
      'je suffoque',
    ], specialty: 'Pneumologie'),
    RedFlagRule('perte de connaissance', ['perte de connaissance', 'perdu connaissance', 'evanoui', 'evanouissement']),
    RedFlagRule('signes d\'AVC (paralysie, visage, parole)', [
      'paralys',
      'visage deforme',
      'bouche de travers',
      'n\'arrive plus a parler',
      'peux plus parler',
      'bras ne repond',
    ], specialty: 'Neurologie'),
    RedFlagRule('convulsions', ['convulsion', 'crise d\'epilepsie']),
    RedFlagRule('saignement important', [
      'hemorragie',
      'beaucoup de sang',
      'saigne beaucoup',
      'vomi du sang',
      'vomit du sang',
      'crache du sang',
    ]),
    RedFlagRule('idées suicidaires', [
      'envie de mourir',
      'me suicider',
      'suicid',
      'me faire du mal',
      'en finir',
    ], specialty: 'Psychiatrie'),
  ];

  // ---------------------------------------------------------------------------
  // Symptômes → spécialité
  // ---------------------------------------------------------------------------
  static const rules = [
    // Cardiologie
    SymptomRule('Cardiologie', 'palpitations', ['palpit', 'coeur qui bat', 'coeur bat vite', 'battements'], weight: 2),
    SymptomRule('Cardiologie', 'essoufflement', ['essouffl', 'souffle court'], weight: 1.5, soon: true),
    SymptomRule('Cardiologie', 'tension artérielle', ['hypertension', 'tension elevee', 'tension haute', 'ma tension']),
    SymptomRule('Cardiologie', 'jambes gonflées', ['jambes gonflees', 'chevilles gonflees', 'pieds gonfles']),
    // Dermatologie
    SymptomRule('Dermatologie', 'boutons', ['bouton', 'acne']),
    SymptomRule('Dermatologie', 'démangeaisons', ['demangeaison', 'ca gratte', 'me gratte', 'urticaire']),
    SymptomRule('Dermatologie', 'problème de peau', [
      'peau',
      'eczema',
      'psoriasis',
      'plaque rouge',
      'plaques rouges',
      'rougeur',
    ], weight: 1.5),
    SymptomRule('Dermatologie', 'grain de beauté', ['grain de beaute', 'verrue', 'tache sur']),
    SymptomRule('Dermatologie', 'chute de cheveux', ['chute de cheveux', 'cheveux tombent', 'perds mes cheveux']),
    // ORL
    SymptomRule('ORL', 'mal d\'oreille', ['oreille', 'otite', 'acouphene', 'sifflement dans']),
    SymptomRule('ORL', 'mal de gorge', ['gorge', 'angine', 'voix enrouee', 'aphone']),
    SymptomRule('ORL', 'sinus / nez', ['sinus', 'nez bouche', 'saigne du nez', 'saignement de nez']),
    // Ophtalmologie
    SymptomRule('Ophtalmologie', 'problème aux yeux', ['oeil', 'yeux', 'conjonctivite', 'paupiere'], weight: 1.5),
    SymptomRule('Ophtalmologie', 'baisse de la vue', ['vision floue', 'vois flou', 'voir flou', 'ma vue', 'lunettes']),
    // Gastro-entérologie
    SymptomRule('Gastro-entérologie', 'mal au ventre', ['mal au ventre', 'douleur au ventre', 'ventre', 'estomac']),
    SymptomRule('Gastro-entérologie', 'troubles digestifs', [
      'diarrhee',
      'constipation',
      'nausee',
      'vomi',
      'mal au coeur',
      'ballonnement',
      'digestion',
    ]),
    SymptomRule('Gastro-entérologie', 'reflux / brûlures', ['reflux', 'brulure d\'estomac', 'brulures d\'estomac']),
    // Pneumologie
    SymptomRule('Pneumologie', 'toux', ['toux', 'tousse', 'crache']),
    SymptomRule('Pneumologie', 'asthme / bronches', ['asthme', 'bronch', 'respiration sifflante'], weight: 1.5),
    // Neurologie
    SymptomRule('Neurologie', 'maux de tête', ['migraine', 'mal de tete', 'maux de tete', 'mal a la tete']),
    SymptomRule('Neurologie', 'vertiges', ['vertige', 'la tete qui tourne', 'tete qui tourne']),
    SymptomRule('Neurologie', 'fourmillements / tremblements', [
      'fourmillement',
      'engourdi',
      'tremblement',
      'je tremble',
    ]),
    SymptomRule('Neurologie', 'troubles de la mémoire', ['memoire', 'oublie tout']),
    // Rhumatologie / Orthopédie
    SymptomRule('Rhumatologie', 'douleurs articulaires', [
      'articulation',
      'arthrose',
      'rhumatisme',
      'genou',
      'epaule',
      'poignet',
    ]),
    SymptomRule('Rhumatologie', 'mal de dos', ['mal au dos', 'mal de dos', 'lombalgie', 'sciatique', 'dos bloque']),
    SymptomRule(
      'Orthopédie',
      'traumatisme (chute, entorse)',
      ['fracture', 'entorse', 'cheville tordue', 'je suis tombe', 'je suis tombee', 'fait une chute'],
      weight: 1.5,
      soon: true,
    ),
    // Gynécologie
    SymptomRule('Gynécologie', 'cycle / règles', ['regles', 'menstru', 'cycle', 'pertes']),
    SymptomRule('Gynécologie', 'grossesse / contraception', ['enceinte', 'grossesse', 'contracepti', 'pilule']),
    // Urologie
    SymptomRule('Urologie', 'troubles urinaires', ['uriner', 'urine', 'pipi', 'brule quand', 'vessie', 'prostate']),
    SymptomRule('Urologie', 'douleur aux reins', ['rein', 'colique nephretique', 'calcul']),
    // Endocrinologie
    SymptomRule('Endocrinologie', 'diabète / glycémie', ['diabete', 'glycemie', 'taux de sucre', 'trop de sucre']),
    SymptomRule('Endocrinologie', 'thyroïde / poids', ['thyroide', 'prise de poids', 'pris du poids', 'kilos']),
    // Psychiatrie
    SymptomRule('Psychiatrie', 'anxiété / stress', ['anxi', 'angoiss', 'stress', 'crise de panique', 'panique']),
    SymptomRule('Psychiatrie', 'humeur déprimée', ['deprim', 'triste', 'plus envie de rien', 'moral']),
    // Médecine dentaire
    SymptomRule('Médecine dentaire', 'mal aux dents', ['dent', 'gencive', 'carie'], weight: 2),
    // Médecine générale
    SymptomRule('Médecine générale', 'fièvre', ['fievre', 'temperature'], soon: true),
    SymptomRule('Médecine générale', 'état grippal', ['grippe', 'rhume', 'courbature', 'mal partout']),
    SymptomRule('Médecine générale', 'fatigue', ['fatigue', 'epuise']),
    SymptomRule('Médecine générale', 'suivi / certificat', ['certificat', 'vaccin', 'bilan', 'controle']),
  ];

  /// Mots qui indiquent qu'il s'agit d'un enfant → Pédiatrie.
  static const childKeywords = [
    'bebe',
    'nourrisson',
    'mon enfant',
    'mon fils',
    'ma fille',
    'mon petit',
    'ma petite',
    'mon garcon',
  ];

  /// Mots qui rendent la consultation plus pressée.
  static const soonKeywords = [
    'intense',
    'insupportable',
    'tres fort',
    'tres forte',
    's\'aggrave',
    'de plus en plus',
    'empire',
    'enfle',
  ];

  /// Mots qui annulent le symptôme qui suit (« pas de fièvre », « sans douleur »).
  static const _negations = ['pas de ', 'pas d\'', 'sans ', 'aucun ', 'aucune ', 'jamais de '];

  OrientationResult analyze(String text) {
    final t = normalize(text);

    // 1. Signes de gravité.
    final flags = <RedFlagRule>[
      for (final f in redFlags)
        if (_matchesAny(t, f.keywords)) f,
    ];

    // 2. Symptômes → points par spécialité.
    final scores = <String, double>{};
    final reasons = <String, List<String>>{};
    var soon = false;
    for (final rule in rules) {
      if (!_matchesAny(t, rule.keywords)) continue;
      scores[rule.specialty] = (scores[rule.specialty] ?? 0) + rule.weight;
      (reasons[rule.specialty] ??= []).add(rule.label);
      soon = soon || rule.soon;
    }
    soon = soon || _matchesAny(t, soonKeywords);
    final isChild = _matchesAny(t, childKeywords);

    // 3. Spécialité retenue.
    final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final flagSpecialty = flags.map((f) => f.specialty).whereType<String>().firstOrNull;
    String specialty;
    if (flagSpecialty != null) {
      specialty = flagSpecialty;
    } else if (isChild) {
      // Chez l'enfant, le pédiatre est le premier interlocuteur (sauf dents et yeux).
      final top = ranked.firstOrNull?.key;
      specialty = (top == 'Médecine dentaire' || top == 'Ophtalmologie') ? top! : 'Pédiatrie';
    } else {
      specialty = ranked.firstOrNull?.key ?? OrientationResult.defaultSpecialty;
    }

    // 4. Confiance : plus il y a d'indices concordants, plus elle est haute ;
    //    deux spécialités à égalité la font baisser.
    double confidence;
    if (flags.isNotEmpty) {
      confidence = 0.9;
    } else if (ranked.isEmpty) {
      confidence = isChild ? 0.5 : 0.2;
    } else {
      final best = ranked.first.value;
      final second = ranked.length > 1 ? ranked[1].value : 0.0;
      confidence = (0.45 + 0.15 * best - 0.2 * (second / best)).clamp(0.3, 0.95);
    }

    final urgency =
        flags.isNotEmpty
            ? OrientationUrgency.emergency
            : (soon || (isChild && scores.containsKey('Médecine générale')))
            ? OrientationUrgency.soon
            : OrientationUrgency.routine;

    return OrientationResult(
      specialty: specialty,
      urgency: urgency,
      reasons: [...?reasons[specialty], if (specialty == 'Pédiatrie') ...?reasons[ranked.firstOrNull?.key]],
      redFlags: [for (final f in flags) f.label],
      confidence: double.parse(confidence.toStringAsFixed(2)),
      source: OrientationSource.offline,
    );
  }

  /// Minuscules, sans accents, apostrophes et espaces uniformisés.
  static String normalize(String input) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', //
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ç': 'c', 'œ': 'oe', 'æ': 'ae',
      '’': '\'', '‘': '\'', '`': '\'',
    };
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      buffer.write(accents[ch] ?? ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Vrai si un des mots apparaît dans le texte, en ignorant les formes niées.
  static bool _matchesAny(String text, List<String> keywords) {
    for (final k in keywords) {
      var from = 0;
      while (true) {
        final i = text.indexOf(k, from);
        if (i < 0) break;
        // Le mot doit commencer au début d'un mot (« rein » ne doit pas matcher « freiner »).
        final startsWord = i == 0 || !RegExp(r'[a-z0-9]').hasMatch(text[i - 1]);
        if (startsWord && !_isNegated(text, i)) return true;
        from = i + 1;
      }
    }
    return false;
  }

  static bool _isNegated(String text, int index) {
    final before = text.substring(index < 15 ? 0 : index - 15, index);
    return _negations.any(before.endsWith);
  }
}
