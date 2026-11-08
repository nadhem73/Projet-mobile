import 'package:medilink/features/appointment/data/models/working_hours.dart';

/// Médecin tel qu'affiché dans la recherche et sur sa fiche.
///
/// Construit à partir d'une jointure `doctors` + `users` + `doctor_profiles`.
/// Colonnes attendues dans la requête : doctor_id, specialty, nom, prenom,
/// et (facultatives, profil) biography, fee, city, address, working_hours.
class DoctorSummary {
  const DoctorSummary({
    required this.doctorId,
    required this.nom,
    required this.prenom,
    required this.specialty,
    this.biography,
    this.fee,
    this.city,
    this.address,
    this.workingHours = WorkingHours.empty,
  });

  final int doctorId;
  final String nom;
  final String prenom;
  final String specialty;
  final String? biography;

  /// Tarif de la consultation, en dinars.
  final double? fee;
  final String? city;
  final String? address;
  final WorkingHours workingHours;

  String get fullName => 'Dr $prenom $nom'.trim();
  String get initials => '${prenom.isEmpty ? '' : prenom[0]}${nom.isEmpty ? '' : nom[0]}'.toUpperCase();

  factory DoctorSummary.fromMap(Map<String, Object?> map) => DoctorSummary(
    doctorId: map['doctor_id'] as int,
    nom: map['nom'] as String,
    prenom: map['prenom'] as String,
    specialty: map['specialty'] as String,
    biography: map['biography'] as String?,
    fee: (map['fee'] as num?)?.toDouble(),
    city: map['city'] as String?,
    address: map['address'] as String?,
    workingHours: WorkingHours.fromJson(map['working_hours'] as String?),
  );
}
