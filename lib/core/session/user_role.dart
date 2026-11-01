/// Rôles applicatifs. Chaque rôle a son propre panel (espace) dans l'application.
enum UserRole {
  patient('PATIENT', 'Patient', 'Je prends rendez-vous et je suis mon dossier médical'),
  doctor('DOCTOR', 'Médecin', 'Je gère mon agenda, mes consultations et mes ordonnances'),
  pharmacist('PHARMACIST', 'Pharmacien', 'Je traite les ordonnances et les commandes'),
  insurer('INSURER', 'Assureur', 'Je gère les contrats et les remboursements'),
  admin('ADMIN', 'Administrateur', 'Je valide les comptes et je gère la plateforme');

  const UserRole(this.dbValue, this.label, this.description);

  /// Valeur stockée dans la colonne `users.role`.
  final String dbValue;
  final String label;

  /// Phrase affichée sur la carte de choix du rôle à l'inscription.
  final String description;

  /// Rôles proposés à l'inscription (un administrateur ne s'inscrit pas).
  static const List<UserRole> selfRegistrable = [patient, doctor, pharmacist, insurer];

  /// Comptes professionnels : validés par un administrateur avant la première connexion.
  bool get requiresValidation => this == doctor || this == pharmacist || this == insurer;

  static UserRole fromDb(String value) =>
      UserRole.values.firstWhere((r) => r.dbValue == value, orElse: () => UserRole.patient);
}
