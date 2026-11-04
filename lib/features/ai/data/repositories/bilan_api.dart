import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/ai/ai_config.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';

/// Scan d'un bilan par le backend MediLink Tunisia (`POST /api/bilans/scan`) :
/// Gemini Vision puis Tesseract côté serveur.
///
/// Désactivé tant que `BILAN_API_URL` n'est pas défini (voir [AiConfig]) ;
/// l'application utilise alors l'OCR local.
class BilanApi {
  BilanApi(this._client, {String? baseUrl, String? token})
    : _baseUrl = baseUrl ?? AiConfig.bilanApiUrl,
      _token = token ?? AiConfig.bilanApiToken;

  final http.Client _client;
  final String _baseUrl;
  final String _token;

  bool get isEnabled => _baseUrl.isNotEmpty;

  /// Envoie la photo (champ multipart `image`) ; [onProgress] reçoit 0..1.
  ///
  /// Erreurs : [AppException] `offline` (réseau), `timeout` (> 90 s),
  /// `rejected` (image refusée par le serveur, 4xx), `server` (5xx).
  Future<ScanBilan> scan(String imagePath, {void Function(double progress)? onProgress}) async {
    if (!isEnabled) throw const AppException('Scan serveur non configuré.', code: 'disabled');
    try {
      final multipart = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/bilans/scan'))
        ..files.add(await http.MultipartFile.fromPath('image', imagePath, filename: 'bilan.jpg'));
      final body = multipart.finalize();

      // Requête « streamée » pour suivre la progression de l'envoi.
      final request =
          http.StreamedRequest('POST', multipart.url)
            ..headers.addAll(multipart.headers)
            ..contentLength = multipart.contentLength;
      if (_token.isNotEmpty) request.headers['Authorization'] = 'Bearer $_token';

      final total = multipart.contentLength;
      var sent = 0;
      body.listen(
        (chunk) {
          sent += chunk.length;
          if (total > 0) onProgress?.call(sent / total);
          request.sink.add(chunk);
        },
        onDone: request.sink.close,
        onError: request.sink.addError,
        cancelOnError: true,
      );

      final response = await _client.send(request).then(http.Response.fromStream).timeout(AiConfig.scanTimeout);
      final decoded = response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) return ScanBilan.fromJson(decoded);

      final message = decoded is Map ? (decoded['error'] ?? decoded['message'])?.toString() : null;
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AppException(
          'Accès au serveur refusé (session expirée).',
          code: 'unauthorized',
          cause: response.statusCode,
        );
      }
      if (response.statusCode >= 400 && response.statusCode < 500) {
        throw AppException(message ?? 'Image refusée par le serveur.', code: 'rejected', cause: response.statusCode);
      }
      throw AppException(
        message ?? 'Le serveur n\'a pas pu analyser le bilan.',
        code: 'server',
        cause: response.statusCode,
      );
    } on AppException {
      rethrow;
    } on TimeoutException catch (e) {
      throw AppException('Le serveur met trop de temps à répondre.', code: 'timeout', cause: e);
    } on SocketException catch (e) {
      throw AppException('Serveur injoignable.', code: 'offline', cause: e);
    } on http.ClientException catch (e) {
      throw AppException('Serveur injoignable.', code: 'offline', cause: e);
    }
  }
}
