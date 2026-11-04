/// Médecin pouvant recevoir un bilan (`DoctorDto` côté API).
class DoctorOption {
  const DoctorOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.userId,
    this.email,
    this.phone,
    this.specialty,
    this.hospital,
    this.licenseNumber,
  });

  /// Identifiant médecin (`doctors.doctor_id`).
  final int id;

  /// Compte utilisateur, pour la notification (local uniquement).
  final int? userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? specialty;
  final String? hospital;
  final String? licenseNumber;

  String get displayName => 'Dr $firstName $lastName'.trim();

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory DoctorOption.fromJson(Map<String, dynamic> json) => DoctorOption(
    id: (json['id'] as num?)?.toInt() ?? 0,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    specialty: json['specialty'] as String?,
    hospital: json['hospital'] as String?,
    licenseNumber: json['licenseNumber'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'specialty': specialty,
    'hospital': hospital,
    'licenseNumber': licenseNumber,
  };

  factory DoctorOption.fromMap(Map<String, Object?> map) => DoctorOption(
    id: map['doctor_id'] as int,
    userId: map['user_id'] as int?,
    firstName: map['prenom'] as String? ?? '',
    lastName: map['nom'] as String? ?? '',
    email: map['email'] as String?,
    phone: map['phone'] as String?,
    specialty: map['specialty'] as String?,
    hospital: map['city'] as String?,
    licenseNumber: map['license_number'] as String?,
  );
}
