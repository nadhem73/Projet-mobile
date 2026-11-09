import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medilink/core/error/app_exception.dart';
import 'insurance_dossier.dart';

/// Defensive display cleanup in case a model ignores the plain-text instruction.
String cleanInsuranceExplanation(String value) {
  var result = value
      .replaceAll('*', '')
      .replaceAll('__', '')
      .replaceAll('`', '');
  result = result.replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '');
  result = result.replaceAllMapped(
    RegExp(
      r'\b(SUBMITTED|WAITING_DOCUMENTS|REVIEW_COMPLEMENT|WITHDRAWN|APPROVED|REJECTED|PAID|APPEAL_PENDING)\b',
    ),
    (match) => switch (match.group(0)) {
      'SUBMITTED' => 'en cours d’examen',
      'WAITING_DOCUMENTS' => 'pièces attendues',
      'REVIEW_COMPLEMENT' => 'complément à vérifier',
      'APPEAL_PENDING' => 'recours à examiner',
      'WITHDRAWN' => 'retirée',
      'APPROVED' => 'approuvée',
      'REJECTED' => 'refusée',
      'PAID' => 'marquée payée',
      _ => match.group(0)!,
    },
  );
  return result.trim();
}

/// Only status and amounts are sent; never free text, images or identity.
Map<String, Object?> explanationFacts(Map<String, Object?> claim) {
  final state = insuranceClaimState(claim);
  return {
    'status': state,
    'amount_tnd': claim['amount'],
    if (claim['reimbursed_amount'] != null)
      'accepted_amount_tnd': claim['reimbursed_amount'],
  };
}

class InsuranceExplanationService {
  InsuranceExplanationService({http.Client? client, String? url})
    : _client = client ?? http.Client(),
      _url =
          url ??
          const String.fromEnvironment(
            'INSURANCE_ASSISTANT_URL',
            defaultValue: 'http://127.0.0.1:8787/explain',
          );
  final http.Client _client;
  final String _url;

  Future<String> explain(Map<String, Object?> facts) async {
    final uri = Uri.tryParse(_url);
    if (uri == null ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                ['127.0.0.1', 'localhost'].contains(uri.host)))) {
      throw const AppException(
        'Adresse du service invalide. Utilisez HTTPS ou le relais local.',
      );
    }
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(facts),
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        String? code;
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['code'] is String) {
            code = body['code'] as String;
          }
        } on FormatException {
          // Other service implementations may return no JSON error body.
        }
        throw AppException(switch (code) {
          'provider_auth' =>
            'Groq a refusé l’accès. Vérifiez la clé, les droits du modèle et la sécurité réseau.',
          'provider_limit' =>
            'La limite Groq est atteinte. Vérifiez votre quota et réessayez plus tard.',
          'provider_model' =>
            'Le modèle configuré est indisponible pour ce compte Groq.',
          'provider_unreachable' =>
            'Le relais ne peut pas joindre Groq. Vérifiez sa connexion Internet.',
          'invalid_request' =>
            'Le relais a refusé les données du dossier. Vérifiez-les et réessayez.',
          _ =>
            'Le relais ou Groq est indisponible. Vérifiez le relais et réessayez.',
        });
      }
      final body = jsonDecode(response.body);
      final message = body is Map ? body['explanation'] : null;
      if (message is! String ||
          message.trim().isEmpty ||
          message.length > 6000) {
        throw const AppException('Réponse du service invalide. Réessayez.');
      }
      return cleanInsuranceExplanation(message);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'Impossible de joindre le relais local. Vérifiez qu’il est démarré et accessible depuis cet appareil.',
      );
    }
  }

  void dispose() => _client.close();
}
