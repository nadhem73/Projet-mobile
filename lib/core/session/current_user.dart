import 'package:medilink/core/session/user_role.dart';

/// Instantané de l'utilisateur connecté, partagé par tous les modules.
///
/// - [patientId] est renseigné si [role] == patient (table `patients`).
/// - [doctorId] est renseigné si [role] == doctor (table `doctors`).
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
  });

  final int userId;
  final UserRole role;
  final String nom;
  final String prenom;
  final String email;
  final String? phone;
  final int? patientId;
  final int? doctorId;

  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;

  String get fullName => '$prenom $nom'.trim();
  String get displayName => isDoctor ? 'Dr $fullName' : fullName;

  String get initials {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return (p + n).toUpperCase();
  }

  CurrentUser copyWith({String? nom, String? prenom, String? email, String? phone}) => CurrentUser(
    userId: userId,
    role: role,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    patientId: patientId,
    doctorId: doctorId,
  );

  Map<String, Object?> toJson() => {
    'userId': userId,
    'role': role.dbValue,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'phone': phone,
    'patientId': patientId,
    'doctorId': doctorId,
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
  );
}
