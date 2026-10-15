/// Exception métier affichable à l'utilisateur.
///
/// Les repositories lèvent des [AppException] avec un message clair en
/// français ; les écrans l'affichent tel quel (pas de détails techniques ni de
/// données sensibles dans [message]).
class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;

  /// Code optionnel pour traiter un cas précis (ex. 'email_taken').
  final String? code;

  /// Erreur technique d'origine (pour les logs uniquement).
  final Object? cause;

  @override
  String toString() => 'AppException($code): $message';
}
