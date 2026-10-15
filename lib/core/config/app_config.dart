/// Configuration globale de l'application.
///
/// Les URL des services distants (API médicaments PostgreSQL, OCR, LLM/RAG)
/// peuvent être surchargées au lancement :
/// `flutter run --dart-define=MEDICAMENTS_API_URL=http://10.0.2.2:3000`
abstract final class AppConfig {
  static const String appName = 'MediLink Tunisia';

  /// Nom du fichier SQLite local.
  static const String databaseName = 'medilink.db';

  /// API intermédiaire vers le dataset PostgreSQL des médicaments (module Pharmacie).
  /// 10.0.2.2 = machine hôte vue depuis l'émulateur Android.
  static const String medicamentsApiUrl = String.fromEnvironment(
    'MEDICAMENTS_API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Service IA (OCR + LLM/RAG).
  static const String aiApiUrl = String.fromEnvironment('AI_API_URL', defaultValue: 'http://10.0.2.2:8000');

  /// Délai max des appels réseau.
  static const Duration networkTimeout = Duration(seconds: 20);
}
