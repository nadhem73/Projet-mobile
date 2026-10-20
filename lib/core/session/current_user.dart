import 'package:medilink/core/session/user_role.dart';

/// Instantané de l'utilisateur connecté, partagé par tous les modules.
///
/// Selon [role], un seul des identifiants métier est renseigné :
/// - [patientId] (table `patients`) pour un patient ;
/// - [doctorId] (table `doctors`) pour un médecin ;
/// - [pharmacistId] (table `pharmacists`) pour un pharmacien ;
/// - [insurerId] (table `insurers`) pour un assureur.
class CurrentUser {
  const CurrentUser({
    required this.userId,
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    this.phone,
    this.patientId,
    this.doctorId,
    this.pharmacistId,
    this.insurerId,
    this.specialty,
    this.organization,
  });

  final int userId;
  final UserRole role;
  final String nom;
  final String prenom;
  final String email;
  final String? phone;
  final int? patientId;
  final int? doctorId;
  final int? pharmacistId;
  final int? insurerId;

  /// Spécialité (médecins uniquement).
  final String? specialty;

  /// Nom de la pharmacie (pharmacien) ou de la compagnie d'assurance (assureur).
  final String? organization;

  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;
  bool get isPharmacist => role == UserRole.pharmacist;
  bool get isInsurer => role == UserRole.insurer;
  bool get isAdmin => role == UserRole.admin;

  String get fullName => '$prenom $nom'.trim();
  String get displayName => isDoctor ? 'Dr $fullName' : fullName;

  /// Ligne affichée sous le nom dans les en-têtes (spécialité, pharmacie...).
  String get subtitle => switch (role) {
    UserRole.patient => 'Patient',
    UserRole.doctor => specialty ?? 'Médecin',
    UserRole.pharmacist => organization ?? 'Pharmacien',
    UserRole.insurer => organization ?? 'Assureur',
    UserRole.admin => 'Administrateur',
  };

  String get initials {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return (p + n).toUpperCase();
  }

  Map<String, Object?> toJson() => {
    'userId': userId,
    'role': role.dbValue,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'phone': phone,
    'patientId': patientId,
    'doctorId': doctorId,
    'pharmacistId': pharmacistId,
    'insurerId': insurerId,
    'specialty': specialty,
    'organization': organization,
  };

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
    userId: json['userId'] as int,
    role: UserRole.fromDb(json['role'] as String),
    nom: json['nom'] as String? ?? '',
    prenom: json['prenom'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String?,
    patientId: json['patientId'] as int?,
    doctorId: json['doctorId'] as int?,
    pharmacistId: json['pharmacistId'] as int?,
    insurerId: json['insurerId'] as int?,
    specialty: json['specialty'] as String?,
    organization: json['organization'] as String?,
  );
}
