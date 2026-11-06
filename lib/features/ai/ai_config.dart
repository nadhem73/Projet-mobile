/// Configuration du module IA (bilans).
///
/// Le scan serveur (Gemini Vision puis Tesseract côté backend) est DÉSACTIVÉ
/// par défaut : l'application analyse alors les bilans sur le téléphone.
/// Pour l'activer, passer l'URL de la gateway MediLink Tunisia et un jeton
/// au lancement (aucune clé n'est écrite dans le code) :
///
/// ```
/// flutter run --dart-define=BILAN_API_URL=http://10.0.2.2:8080 --dart-define=BILAN_API_TOKEN=<jwt>
/// ```
abstract final class AiConfig {
  /// Gateway exposant `/api/bilans/**` (vide = scan serveur désactivé).
  static const String bilanApiUrl = String.fromEnvironment('BILAN_API_URL');

  /// Jeton Bearer du backend bilan-service.
  static const String bilanApiToken = String.fromEnvironment('BILAN_API_TOKEN');

  /// Délai max d'un scan serveur (upload + OCR Gemini/Tesseract).
  static const Duration scanTimeout = Duration(seconds: 90);

  /// Préférence « OCR hors-ligne forcé » (SharedPreferences).
  static const String offlineOcrKey = 'ai.offline_ocr';
}
