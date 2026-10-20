import 'package:medilink/core/session/user_role.dart';

/// Données saisies dans le formulaire d'inscription.
///
/// Les champs communs sont obligatoires ; les champs spécifiques ne sont lus
/// que pour le [role] concerné.
class RegistrationData {
  const RegistrationData({
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.phone,
    required this.password,
    // Patient
    this.cin,
    this.dateNaissance,
    this.gender,
    // Médecin
    this.specialty,
    this.city,
    // Médecin + pharmacien : numéro d'ordre / d'autorisation
    this.licenseNumber,
    // Pharmacien
    this.pharmacyName,
    this.address,
    // Assureur
    this.company,
    this.agentCode,
  });

  final UserRole role;
  final String nom;
  final String prenom;
  final String email;
  final String phone;
  final String password;

  final String? cin;
  final DateTime? dateNaissance;

  /// 'M' ou 'F'.
  final String? gender;

  final String? specialty;
  final String? city;
  final String? licenseNumber;

  final String? pharmacyName;
  final String? address;

  final String? company;
  final String? agentCode;
}
