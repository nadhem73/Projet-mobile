/// Rôles applicatifs. Chaque rôle a son propre panel (espace) dans l'application.
enum UserRole {
  patient('PATIENT', 'Patient', 'Je prends rendez-vous et je suis mon dossier médical'),
  doctor('DOCTOR', 'Médecin', 'Je gère mon agenda, mes consultations et mes ordonnances'),
  pharmacist('PHARMACIST', 'Pharmacien', 'Je traite les ordonnances et les commandes'),
  insurer('INSURER', 'Assureur', 'Je gère les contrats et les remboursements');

  const UserRole(this.dbValue, this.label, this.description);

  /// Valeur stockée dans la colonne `users.role`.
  final String dbValue;
  final String label;

  /// Phrase affichée sur la carte de choix du rôle à l'inscription.
  final String description;

  static UserRole fromDb(String value) =>
      UserRole.values.firstWhere((r) => r.dbValue == value, orElse: () => UserRole.patient);
}
