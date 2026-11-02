import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medilink/core/config/app_config.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/doctor/data/models/medicament.dart';

/// Recherche dans le dataset des médicaments (PostgreSQL) via l'API
/// intermédiaire du module Pharmacie.
///
/// Contrat attendu : `GET {medicamentsApiUrl}/medicaments?q=<texte>` renvoie
/// une liste JSON de médicaments (colonnes de la table `medicament`).
class MedicamentApi {
  MedicamentApi(this._client, {String? baseUrl}) : _baseUrl = baseUrl ?? AppConfig.medicamentsApiUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 5);

  /// Médicaments dont le nom ou la DCI contient [query] (au moins 2 caractères).
  ///
  /// Lève une [AppException] `offline` si l'API ne répond pas : l'écran
  /// propose alors la saisie libre du nom.
  Future<List<Medicament>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/medicaments').replace(queryParameters: {'q': q}))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw AppException('Recherche de médicaments indisponible.', code: 'offline', cause: response.statusCode);
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final list = body is Map<String, dynamic> ? body['data'] : body;
      return [for (final item in list as List) Medicament.fromJson(item as Map<String, dynamic>)];
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Recherche de médicaments indisponible.', code: 'offline', cause: e);
    }
  }
}
