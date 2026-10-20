import 'package:medilink/core/session/user_role.dart';

/// Profil complet d'un compte : ligne `users` + ligne de la table du rôle
/// (`patients`, `doctors` + `doctor_profiles`, `pharmacists` ou `insurers`).
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    this.phone,
    this.createdAt,
    this.cin,
    this.dateNaissance,
    this.address,
    this.specialty,
    this.licenseNumber,
    this.biography,
    this.fee,
    this.city,
    this.pharmacyName,
    this.company,
    this.agentCode,
  });

  final int userId;
  final UserRole role;
  final String nom;
  final String prenom;
  final String email;
  final String? phone;
  final DateTime? createdAt;

  // Patient
  final String? cin;
  final DateTime? dateNaissance;

  /// Adresse (patient, médecin ou pharmacie).
  final String? address;

  // Médecin
  final String? specialty;

  /// Numéro d'ordre (médecin) ou d'autorisation (pharmacien).
  final String? licenseNumber;
  final String? biography;
  final double? fee;

  /// Ville (médecin, pharmacien).
  final String? city;

  // Pharmacien
  final String? pharmacyName;

  // Assureur
  final String? company;
  final String? agentCode;

  String get fullName => '$prenom $nom'.trim();

  int? get age {
    final birth = dateNaissance;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
    return years;
  }

  UserProfile copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? phone,
    String? cin,
    DateTime? dateNaissance,
    String? address,
    String? specialty,
    String? biography,
    double? fee,
    String? city,
    String? pharmacyName,
    String? company,
  }) => UserProfile(
    userId: userId,
    role: role,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    createdAt: createdAt,
    cin: cin ?? this.cin,
    dateNaissance: dateNaissance ?? this.dateNaissance,
    address: address ?? this.address,
    specialty: specialty ?? this.specialty,
    licenseNumber: licenseNumber,
    biography: biography ?? this.biography,
    fee: fee ?? this.fee,
    city: city ?? this.city,
    pharmacyName: pharmacyName ?? this.pharmacyName,
    company: company ?? this.company,
    agentCode: agentCode,
  );
}
