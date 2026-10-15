/// Rôles applicatifs (cahier des charges §14 : un utilisateur est patient OU médecin).
enum UserRole {
  patient('PATIENT', 'Patient'),
  doctor('DOCTOR', 'Médecin');

  const UserRole(this.dbValue, this.label);

  /// Valeur stockée dans la colonne `users.role`.
  final String dbValue;
  final String label;

  static UserRole fromDb(String value) =>
      UserRole.values.firstWhere((r) => r.dbValue == value, orElse: () => UserRole.patient);
}
