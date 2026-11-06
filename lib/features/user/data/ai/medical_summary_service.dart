import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:medilink/features/user/data/ai/medical_safety_checker.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';

/// Configuration de la synthèse IA (aucune clé n'est écrite dans le code).
///
/// ```
/// flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
/// # ou, en production, via un proxy backend qui détient la clé :
/// flutter run --dart-define=AI_SUMMARY_URL=https://api.medilink.tn/ai/summary
/// ```
abstract final class UserAiConfig {
  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const String endpoint = String.fromEnvironment(
    'AI_SUMMARY_URL',
    defaultValue: 'https://api.anthropic.com/v1/messages',
  );
  static const String model = String.fromEnvironment('AI_SUMMARY_MODEL', defaultValue: 'claude-opus-5-5');
  static const Duration timeout = Duration(seconds: 60);

  /// Un proxy (URL personnalisée) n'a pas besoin de clé côté application.
  static bool get isConfigured => apiKey.isNotEmpty || !endpoint.contains('api.anthropic.com');
}

/// Alerte renvoyée par la synthèse.
class SummaryAlert {
  const SummaryAlert(this.level, this.message);

  final AlertLevel level;
  final String message;
}

/// Synthèse clinique d'un dossier, destinée au médecin.
class AiMedicalSummary {
  const AiMedicalSummary({
    required this.summary,
    required this.keyPoints,
    required this.alerts,
    required this.questions,
    required this.missingData,
    required this.source,
    this.fallbackReason,
  });

  final String summary;
  final List<String> keyPoints;
  final List<SummaryAlert> alerts;

  /// Questions à poser au patient pendant la consultation.
  final List<String> questions;

  /// Informations utiles absentes du dossier.
  final List<String> missingData;

  /// « Claude (claude-opus-5-5) » ou « Synthèse locale ».
  final String source;

  /// Renseigné quand le LLM n'a pas pu être utilisé.
  final String? fallbackReason;

  bool get isFromLlm => fallbackReason == null;
}

/// Génère la synthèse IA d'un dossier avec Claude (API Anthropic).
///
/// Confidentialité : seules des données cliniques **anonymisées** sont
/// envoyées (âge, sexe, mesures, antécédents, traitement, vaccins, titres des
/// documents). Ni nom, ni téléphone, ni numéro d'assurance, ni image.
///
/// Sans configuration ou en cas d'erreur réseau, une synthèse locale est
/// construite à partir du moteur de règles : l'écran fonctionne toujours.
class MedicalSummaryService {
  MedicalSummaryService(
    this._client, {
    this.checker = const MedicalSafetyChecker(),
    String? apiKey,
    String? endpoint,
    String? model,
    bool? configured,
  }) : _apiKey = apiKey ?? UserAiConfig.apiKey,
       _endpoint = endpoint ?? UserAiConfig.endpoint,
       _model = model ?? UserAiConfig.model,
       _configured = configured ?? UserAiConfig.isConfigured;

  final http.Client _client;
  final MedicalSafetyChecker checker;
  final String _apiKey;
  final String _endpoint;
  final String _model;
  final bool _configured;

  static const _system =
      'Tu es un assistant d\'aide à la décision clinique intégré à MediLink Tunisia. '
      'Un médecin s\'apprête à recevoir un patient et te transmet son dossier médical anonymisé (JSON). '
      'Rédige en français une synthèse clinique courte et factuelle pour le médecin. '
      'Règles : appuie-toi uniquement sur les données fournies, n\'invente aucune valeur ni aucun diagnostic ; '
      'signale les incohérences (allergie et traitement, interactions, contre-indications liées aux maladies chroniques, '
      'vaccins en retard) ; les « alertes_regles » viennent d\'un moteur de règles, confirme-les ou nuance-les ; '
      'propose des questions concrètes à poser au patient et liste les informations manquantes utiles. '
      'Reste concis : synthèse de 3 à 5 phrases, au plus 5 éléments par liste.';

  static const _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['synthese', 'points_cles', 'alertes', 'questions_a_poser', 'donnees_manquantes'],
    'properties': {
      'synthese': {'type': 'string'},
      'points_cles': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'alertes': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['niveau', 'message'],
          'properties': {
            'niveau': {
              'type': 'string',
              'enum': ['critique', 'attention', 'info'],
            },
            'message': {'type': 'string'},
          },
        },
      },
      'questions_a_poser': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'donnees_manquantes': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  };

  /// Données réellement envoyées au LLM (affichables pour la transparence).
  Map<String, Object?> anonymizedPayload(PatientMedicalFile file, List<SafetyAlert> ruleAlerts) {
    final r = file.record;
    return {
      'age': file.patient.age,
      'sexe': r.genderLabel,
      'groupe_sanguin': r.bloodGroup,
      'taille_cm': r.height,
      'poids_kg': r.weight,
      'imc': r.bmi == null ? null : double.parse(r.bmi!.toStringAsFixed(1)),
      'allergies': r.allergyList,
      'maladies_chroniques': r.chronicDiseaseList,
      'traitement_en_cours': r.currentTreatment,
      'antecedents_chirurgicaux': r.surgicalHistory,
      'antecedents_familiaux': r.familyHistory,
      'vaccins': [
        for (final v in file.vaccinations) {'nom': v.name, 'annee': v.date.year, if (v.dose != null) 'dose': v.dose},
      ],
      'documents': [for (final d in file.documents) '${d.category.label} : ${d.title}'],
      'alertes_regles': [for (final a in ruleAlerts) '${a.level.label} — ${a.title} : ${a.detail}'],
    };
  }

  Future<AiMedicalSummary> summarize(PatientMedicalFile file) async {
    final ruleAlerts = checker.check(
      record: file.record,
      vaccinations: file.vaccinations,
      age: file.patient.age,
    );
    if (!_configured) {
      return localSummary(file, ruleAlerts, reason: 'IA en ligne non configurée (clé API absente)');
    }
    try {
      return await _callClaude(anonymizedPayload(file, ruleAlerts));
    } catch (e) {
      debugPrint('[MedicalSummaryService] $e');
      return localSummary(file, ruleAlerts, reason: 'Service IA indisponible, synthèse locale affichée');
    }
  }

  Future<AiMedicalSummary> _callClaude(Map<String, Object?> payload) async {
    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: {
            'content-type': 'application/json',
            'anthropic-version': '2026-10-21',
            // Si Claude décline (filtre de sécurité), l'API relance sur un modèle de repli.
            'anthropic-beta': 'server-side-fallback-2026-07-01',
            if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
            // Démo dans Chrome : appel direct depuis le navigateur.
            if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: jsonEncode({
            'model': _model,
            'max_tokens': 16000,
            'fallbacks': 'default',
            'system': _system,
            'output_config': {
              'effort': 'low',
              'format': {'type': 'json_schema', 'schema': _schema},
            },
            'messages': [
              {
                'role': 'user',
                'content': 'Dossier du patient :\n${const JsonEncoder.withIndent('  ').convert(payload)}',
              },
            ],
          }),
        )
        .timeout(UserAiConfig.timeout);

    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}: ${response.body}');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
    final stopReason = body['stop_reason'];
    if (stopReason == 'refusal') throw StateError('Requête déclinée par le modèle');
    if (stopReason == 'max_tokens') throw StateError('Réponse tronquée');

    final text = (body['content'] as List)
        .cast<Map<String, Object?>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    final json = jsonDecode(text) as Map<String, Object?>;
    List<String> strings(String key) => (json[key] as List? ?? const []).cast<String>();

    return AiMedicalSummary(
      summary: json['synthese'] as String,
      keyPoints: strings('points_cles'),
      alerts: [
        for (final a in (json['alertes'] as List? ?? const []).cast<Map<String, Object?>>())
          SummaryAlert(switch (a['niveau']) {
            'critique' => AlertLevel.critical,
            'attention' => AlertLevel.warning,
            _ => AlertLevel.info,
          }, a['message'] as String),
      ],
      questions: strings('questions_a_poser'),
      missingData: strings('donnees_manquantes'),
      source: 'Claude (${body['model'] ?? _model})',
    );
  }

  /// Synthèse construite sans LLM, à partir du dossier et du moteur de règles.
  AiMedicalSummary localSummary(PatientMedicalFile file, List<SafetyAlert> ruleAlerts, {required String reason}) {
    final r = file.record;
    final identity = [
      if (r.genderLabel != null) r.genderLabel,
      if (file.patient.age != null) '${file.patient.age} ans',
    ].join(', ');
    final sentences = <String>[
      identity.isEmpty ? 'Patient(e) sans données d\'identité clinique.' : 'Patient(e) : $identity.',
      r.chronicDiseaseList.isEmpty
          ? 'Aucune maladie chronique déclarée.'
          : 'Maladies chroniques : ${r.chronicDiseaseList.join(', ')}.',
      r.allergyList.isEmpty ? 'Aucune allergie connue.' : 'Allergies : ${r.allergyList.join(', ')}.',
      r.currentTreatment == null ? 'Pas de traitement en cours renseigné.' : 'Traitement : ${r.currentTreatment}.',
    ];

    final missing = <String>[
      if (r.bloodGroup == null) 'Groupe sanguin',
      if (r.height == null || r.weight == null) 'Taille / poids',
      if (r.emergencyContactName == null) 'Contact d\'urgence',
      if (file.vaccinations.isEmpty) 'Carnet de vaccination',
    ];

    return AiMedicalSummary(
      summary: sentences.join(' '),
      keyPoints: [
        if (r.bmi != null) 'IMC ${r.bmi!.toStringAsFixed(1)} (${r.bmiLabel})',
        if (r.bloodGroup != null) 'Groupe sanguin ${r.bloodGroup}',
        if (r.surgicalHistory != null) 'Antécédents chirurgicaux : ${r.surgicalHistory}',
        if (r.familyHistory != null) 'Antécédents familiaux : ${r.familyHistory}',
        '${file.vaccinations.length} vaccin(s), ${file.documents.length} document(s) au dossier',
      ],
      alerts: [for (final a in ruleAlerts) SummaryAlert(a.level, '${a.title} : ${a.detail}')],
      questions: [
        if (r.currentTreatment != null) 'Le traitement actuel est-il bien suivi et toléré ?',
        if (r.allergyList.isNotEmpty) 'Quel type de réaction allergique a été observé ?',
        'Y a-t-il eu des changements depuis la dernière consultation ?',
      ],
      missingData: missing,
      source: 'Synthèse locale (moteur de règles)',
      fallbackReason: reason,
    );
  }
}
