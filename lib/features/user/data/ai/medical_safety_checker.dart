import 'package:medilink/features/user/data/ai/ai_text.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';

/// Gravité d'une alerte du dossier.
enum AlertLevel {
  critical('Critique'),
  warning('À vérifier'),
  info('Conseil');

  const AlertLevel(this.label);

  final String label;
}

/// Alerte détectée dans le dossier médical (moteur de règles, hors-ligne).
class SafetyAlert {
  const SafetyAlert({required this.level, required this.title, required this.detail, this.evidence = const []});

  final AlertLevel level;
  final String title;
  final String detail;

  /// Termes du dossier qui ont déclenché la règle (explicabilité).
  final List<String> evidence;

  @override
  String toString() => '[${level.name}] $title';
}

/// Famille de médicaments reconnue dans le texte libre du traitement.
class _DrugClass {
  const _DrugClass(this.name, this.keywords);

  final String name;

  /// Molécules et noms commerciaux courants en Tunisie (normalisés).
  final List<String> keywords;
}

const _penicillins = _DrugClass('pénicillines', [
  'amoxicilline', 'ampicilline', 'augmentin', 'clamoxyl', 'penicilline', 'oxacilline', 'cloxacilline',
  'extencilline', 'oracilline', 'amoxil', 'flemoxine',
]);
const _cephalosporins = _DrugClass('céphalosporines', [
  'cefalexine', 'cefadroxil', 'cefuroxime', 'cefixime', 'ceftriaxone', 'cefpodoxime', 'rocephine', 'oroken', 'zinnat',
]);
const _nsaids = _DrugClass('anti-inflammatoires (AINS)', [
  'ibuprofene', 'aspirine', 'acide acetylsalicylique', 'aspegic', 'kardegic', 'diclofenac', 'voltarene', 'ketoprofene',
  'profenid', 'naproxene', 'piroxicam', 'feldene', 'celecoxib', 'celebrex', 'advil', 'brufen', 'nurofen',
  'meloxicam', 'indometacine',
]);
const _sulfonamides = _DrugClass('sulfamides', ['sulfamethoxazole', 'cotrimoxazole', 'bactrim', 'sulfasalazine']);
const _iodine = _DrugClass('produits iodés', ['iode', 'iodee', 'betadine', 'povidone', 'amiodarone', 'cordarone']);
const _opioids = _DrugClass('opiacés', ['codeine', 'tramadol', 'morphine', 'topalgic', 'codoliprane', 'efferalgan codeine']);
const _anticoagulants = _DrugClass('anticoagulants', [
  'warfarine', 'coumadine', 'sintrom', 'acenocoumarol', 'rivaroxaban', 'xarelto', 'apixaban', 'eliquis',
  'dabigatran', 'pradaxa', 'heparine', 'lovenox', 'enoxaparine',
]);
const _betaBlockers = _DrugClass('bêtabloquants', [
  'propranolol', 'avlocardyl', 'atenolol', 'tenormine', 'bisoprolol', 'cardensiel', 'concor', 'metoprolol',
  'nebivolol', 'temerit', 'sotalol', 'carvedilol',
]);
const _corticoids = _DrugClass('corticoïdes', [
  'prednisolone', 'prednisone', 'cortancyl', 'solupred', 'dexamethasone', 'betamethasone', 'celestene',
  'methylprednisolone', 'medrol', 'hydrocortisone',
]);
const _metformin = _DrugClass('metformine', ['metformine', 'glucophage', 'stagid']);
const _antidiabetics = _DrugClass('antidiabétiques', [
  'metformine', 'glucophage', 'insuline', 'lantus', 'novorapid', 'gliclazide', 'diamicron', 'glimepiride',
  'amarel', 'sitagliptine', 'januvia', 'vildagliptine', 'galvus',
]);
const _antihypertensives = _DrugClass('antihypertenseurs', [
  'amlodipine', 'amlor', 'losartan', 'valsartan', 'irbesartan', 'candesartan', 'ramipril', 'triatec',
  'enalapril', 'perindopril', 'coversyl', 'captopril', 'hydrochlorothiazide', 'indapamide', 'fludex',
]);
const _bronchodilators = _DrugClass('traitements de l\'asthme', [
  'salbutamol', 'ventoline', 'seretide', 'symbicort', 'budesonide', 'fluticasone', 'formoterol', 'montelukast',
  'singulair',
]);
const _thyroid = _DrugClass('hormones thyroïdiennes', ['levothyroxine', 'levothyrox', 'euthyrox', 'l-thyroxine']);

/// Allergie déclarée → familles à éviter (et familles à risque croisé).
class _AllergyRule {
  const _AllergyRule(this.allergyKeywords, this.forbidden, {this.crossReactive});

  final List<String> allergyKeywords;
  final _DrugClass forbidden;
  final _DrugClass? crossReactive;
}

const _allergyRules = [
  _AllergyRule(
    ['penicilline', 'amoxicilline', 'beta-lactamine', 'betalactamine', 'augmentin'],
    _penicillins,
    crossReactive: _cephalosporins,
  ),
  _AllergyRule(['cephalosporine', 'ceftriaxone', 'cefixime'], _cephalosporins),
  _AllergyRule(['aspirine', 'ains', 'anti-inflammatoire', 'ibuprofene', 'diclofenac'], _nsaids),
  _AllergyRule(['sulfamide', 'bactrim', 'cotrimoxazole'], _sulfonamides),
  _AllergyRule(['iode', 'iodee', 'produit de contraste', 'betadine'], _iodine),
  _AllergyRule(['codeine', 'morphine', 'opiace', 'tramadol'], _opioids),
];

/// Maladie chronique déclarée → famille de médicaments déconseillée.
class _DiseaseRule {
  const _DiseaseRule(this.diseaseKeywords, this.diseaseLabel, this.drugs, this.level, this.reason);

  final List<String> diseaseKeywords;
  final String diseaseLabel;
  final _DrugClass drugs;
  final AlertLevel level;
  final String reason;
}

const _diseaseRules = [
  _DiseaseRule(
    ['asthme', 'bpco'],
    'asthme',
    _betaBlockers,
    AlertLevel.critical,
    'les bêtabloquants peuvent déclencher un bronchospasme.',
  ),
  _DiseaseRule(['asthme'], 'asthme', _nsaids, AlertLevel.warning, 'les AINS peuvent aggraver certains asthmes.'),
  _DiseaseRule(
    ['ulcere', 'gastrite', 'hemorragie digestive'],
    'ulcère / gastrite',
    _nsaids,
    AlertLevel.warning,
    'les AINS augmentent le risque d\'ulcère et de saignement digestif.',
  ),
  _DiseaseRule(
    ['insuffisance renale', 'maladie renale', 'dialyse'],
    'insuffisance rénale',
    _nsaids,
    AlertLevel.critical,
    'les AINS peuvent aggraver la fonction rénale.',
  ),
  _DiseaseRule(
    ['insuffisance renale', 'maladie renale', 'dialyse'],
    'insuffisance rénale',
    _metformin,
    AlertLevel.warning,
    'la dose de metformine doit être adaptée à la fonction rénale.',
  ),
  _DiseaseRule(
    ['hypertension', 'hta'],
    'hypertension',
    _nsaids,
    AlertLevel.warning,
    'les AINS peuvent élever la tension et réduire l\'effet des antihypertenseurs.',
  ),
  _DiseaseRule(
    ['diabete'],
    'diabète',
    _corticoids,
    AlertLevel.warning,
    'les corticoïdes font monter la glycémie : surveillance renforcée.',
  ),
];

/// Médicament du traitement → maladie qu'il laisse supposer.
const _impliedDiseases = <(_DrugClass, List<String>, String)>[
  (_antidiabetics, ['diabete'], 'diabète'),
  (_antihypertensives, ['hypertension', 'hta'], 'hypertension'),
  (_bronchodilators, ['asthme', 'bpco'], 'asthme'),
  (_thyroid, ['thyroide', 'hypothyroidie', 'hashimoto'], 'trouble de la thyroïde'),
  (_anticoagulants, ['arythmie', 'fibrillation', 'phlebite', 'thrombose', 'embolie', 'valve'], 'maladie thrombo-embolique'),
];

/// Maladies chroniques qui demandent normalement un traitement de fond.
const _chronicNeedingTreatment = <(List<String>, String)>[
  (['diabete'], 'diabète'),
  (['hypertension', 'hta'], 'hypertension'),
  (['asthme'], 'asthme'),
  (['epilepsie'], 'épilepsie'),
  (['hypothyroidie'], 'hypothyroïdie'),
];

/// Moteur de règles médicales du dossier (« système expert », 100 % hors-ligne).
///
/// Croise allergies, maladies chroniques, traitement en cours, vaccins et IMC
/// pour signaler les incohérences. Chaque alerte cite les termes qui l'ont
/// déclenchée : c'est une aide à la vigilance, pas un diagnostic.
class MedicalSafetyChecker {
  const MedicalSafetyChecker();

  List<SafetyAlert> check({
    required MedicalRecord record,
    List<Vaccination> vaccinations = const [],
    int? age,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final allergies = normalizeMedicalText(record.allergies);
    final diseases = normalizeMedicalText(record.chronicDiseases);
    final treatment = normalizeMedicalText(record.currentTreatment);
    final alerts = <SafetyAlert>[];

    // 1. Allergie ↔ traitement
    for (final rule in _allergyRules) {
      final allergy = findKeywords(allergies, rule.allergyKeywords);
      if (allergy.isEmpty) continue;
      final drugs = findKeywords(treatment, rule.forbidden.keywords);
      if (drugs.isNotEmpty) {
        alerts.add(
          SafetyAlert(
            level: AlertLevel.critical,
            title: 'Allergie et traitement incompatibles',
            detail:
                'Allergie déclarée (${allergy.join(', ')}) alors que le traitement contient '
                '${drugs.join(', ')} (${rule.forbidden.name}).',
            evidence: [...allergy, ...drugs],
          ),
        );
      }
      final cross = rule.crossReactive;
      if (cross != null) {
        final crossDrugs = findKeywords(treatment, cross.keywords);
        if (crossDrugs.isNotEmpty) {
          alerts.add(
            SafetyAlert(
              level: AlertLevel.warning,
              title: 'Risque d\'allergie croisée',
              detail:
                  'Allergie aux ${rule.forbidden.name} : ${crossDrugs.join(', ')} (${cross.name}) '
                  'peut provoquer une réaction croisée.',
              evidence: [...allergy, ...crossDrugs],
            ),
          );
        }
      }
    }

    // 2. Maladie chronique ↔ traitement
    for (final rule in _diseaseRules) {
      final disease = findKeywords(diseases, rule.diseaseKeywords);
      if (disease.isEmpty) continue;
      final drugs = findKeywords(treatment, rule.drugs.keywords);
      if (drugs.isEmpty) continue;
      alerts.add(
        SafetyAlert(
          level: rule.level,
          title: '${_capitalize(rule.drugs.name)} et ${rule.diseaseLabel}',
          detail: '${drugs.join(', ')} chez un patient avec ${rule.diseaseLabel} : ${rule.reason}',
          evidence: [...disease, ...drugs],
        ),
      );
    }

    // 3. Interaction médicamenteuse majeure : anticoagulant + AINS/aspirine
    final anticoagulant = findKeywords(treatment, _anticoagulants.keywords);
    final nsaid = findKeywords(treatment, _nsaids.keywords);
    if (anticoagulant.isNotEmpty && nsaid.isNotEmpty) {
      alerts.add(
        SafetyAlert(
          level: AlertLevel.critical,
          title: 'Interaction : risque hémorragique',
          detail: '${anticoagulant.join(', ')} associé à ${nsaid.join(', ')} augmente fortement le risque de saignement.',
          evidence: [...anticoagulant, ...nsaid],
        ),
      );
    }

    // 4. Traitement qui suggère une maladie non déclarée
    for (final (drugs, diseaseKeywords, label) in _impliedDiseases) {
      final found = findKeywords(treatment, drugs.keywords);
      if (found.isEmpty || findKeywords(diseases, diseaseKeywords).isNotEmpty) continue;
      alerts.add(
        SafetyAlert(
          level: AlertLevel.info,
          title: 'Maladie chronique peut-être non déclarée',
          detail: 'Le traitement (${found.join(', ')}) laisse supposer : $label. Pensez à compléter le dossier.',
          evidence: found,
        ),
      );
    }

    // 5. Maladie chronique sans traitement renseigné
    if (treatment.isEmpty) {
      for (final (keywords, label) in _chronicNeedingTreatment) {
        final found = findKeywords(diseases, keywords);
        if (found.isEmpty) continue;
        alerts.add(
          SafetyAlert(
            level: AlertLevel.info,
            title: 'Traitement de fond non renseigné',
            detail: '$label déclaré(e) mais aucun traitement en cours n\'est indiqué.',
            evidence: found,
          ),
        );
      }
    }

    // 6. Vaccins
    alerts.addAll(_vaccinationAlerts(vaccinations, diseases, age, today));

    // 7. Corpulence
    final bmi = record.bmi;
    if (bmi != null && (bmi >= 30 || bmi < 18.5)) {
      alerts.add(
        SafetyAlert(
          level: AlertLevel.info,
          title: 'IMC hors norme',
          detail: 'IMC ${bmi.toStringAsFixed(1)} (${record.bmiLabel}) : facteur de risque à prendre en compte.',
          evidence: ['IMC ${bmi.toStringAsFixed(1)}'],
        ),
      );
    }

    alerts.sort((a, b) => a.level.index.compareTo(b.level.index));
    return alerts;
  }

  List<SafetyAlert> _vaccinationAlerts(List<Vaccination> vaccinations, String diseases, int? age, DateTime today) {
    final alerts = <SafetyAlert>[];
    DateTime? lastOf(List<String> keywords) {
      DateTime? last;
      for (final v in vaccinations) {
        if (findKeywords(normalizeMedicalText(v.name), keywords).isEmpty) continue;
        if (last == null || v.date.isAfter(last)) last = v.date;
      }
      return last;
    }

    final isAdult = age == null || age >= 18;
    final tetanus = lastOf(const ['tetanos', 'dtc', 'dtp', 'dtcp']);
    if (isAdult && vaccinations.isNotEmpty) {
      if (tetanus == null) {
        alerts.add(
          const SafetyAlert(
            level: AlertLevel.info,
            title: 'Rappel tétanos non enregistré',
            detail: 'Aucun vaccin contre le tétanos dans le carnet : un rappel est recommandé tous les 10 ans.',
          ),
        );
      } else if (today.difference(tetanus).inDays > 3652) {
        alerts.add(
          SafetyAlert(
            level: AlertLevel.warning,
            title: 'Rappel tétanos dépassé',
            detail: 'Dernier vaccin contre le tétanos en ${tetanus.year} (plus de 10 ans).',
            evidence: ['tétanos ${tetanus.year}'],
          ),
        );
      }
    }

    final atRisk =
        (age != null && age >= 65) ||
        findKeywords(diseases, const ['diabete', 'asthme', 'bpco', 'insuffisance', 'cardiaque']).isNotEmpty;
    final flu = lastOf(const ['grippe']);
    if (atRisk && (flu == null || today.difference(flu).inDays > 365)) {
      alerts.add(
        const SafetyAlert(
          level: AlertLevel.info,
          title: 'Vaccin contre la grippe conseillé',
          detail: 'Patient à risque (âge ou maladie chronique) sans vaccin antigrippal depuis plus d\'un an.',
        ),
      );
    }
    return alerts;
  }

  static String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
