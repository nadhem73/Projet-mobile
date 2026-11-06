import 'package:medilink/core/database/schema/appointment_schema.dart';

/// Statut d'un rendez-vous, avec son libellé à l'écran.
///
/// Les valeurs en base sont celles de [AppointmentStatus] (schéma).
enum AppointmentState {
  pending(AppointmentStatus.pending, 'En attente'),
  confirmed(AppointmentStatus.confirmed, 'Confirmé'),
  cancelled(AppointmentStatus.cancelled, 'Annulé'),
  completed(AppointmentStatus.completed, 'Terminé'),
  noShow(AppointmentStatus.noShow, 'Absent');

  const AppointmentState(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static AppointmentState fromDb(String value) =>
      values.firstWhere((s) => s.dbValue == value, orElse: () => AppointmentState.pending);

  /// Rendez-vous encore « vivant » (il bloque le créneau du médecin).
  bool get isActive => this == pending || this == confirmed;
}

/// Rendez-vous (table `appointments`).
///
/// Les champs « affichage » (nom du médecin, spécialité, nom du patient) ne sont
/// remplis que si la requête fait la jointure avec `doctors` / `users` et utilise
/// les alias : doctor_nom, doctor_prenom, specialty, patient_nom, patient_prenom.
class Appointment {
  const Appointment({
    this.id,
    required this.dateTime,
    required this.doctorId,
    required this.patientId,
    this.reason,
    this.status = AppointmentState.pending,
    this.createdAt,
    this.doctorNom,
    this.doctorPrenom,
    this.specialty,
    this.patientNom,
    this.patientPrenom,
  });

  final int? id;

  /// Date et heure du rendez-vous (heure locale).
  final DateTime dateTime;
  final int doctorId;
  final int patientId;
  final String? reason;
  final AppointmentState status;
  final DateTime? createdAt;

  // Champs d'affichage (jointures).
  final String? doctorNom;
  final String? doctorPrenom;
  final String? specialty;
  final String? patientNom;
  final String? patientPrenom;

  String get doctorName => 'Dr ${doctorPrenom ?? ''} ${doctorNom ?? ''}'.trim();
  String get doctorInitials =>
      '${(doctorPrenom ?? '').isEmpty ? '' : doctorPrenom![0]}${(doctorNom ?? '').isEmpty ? '' : doctorNom![0]}'
          .toUpperCase();
  String get patientName => '${patientPrenom ?? ''} ${patientNom ?? ''}'.trim();

  /// À venir : date future et rendez-vous ni annulé ni terminé.
  bool get isUpcoming => status.isActive && dateTime.isAfter(DateTime.now());

  /// Le patient ne peut annuler qu'un rendez-vous à venir.
  bool get canCancel => isUpcoming;

  /// Format stocké en base : 2026-10-20T09:30:00 (sans fuseau, heure locale).
  static String formatDateTime(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute).toIso8601String().substring(0, 19);

  factory Appointment.fromMap(Map<String, Object?> map) => Appointment(
    id: map['appointment_id'] as int,
    dateTime: DateTime.parse(map['appointment_date_time'] as String),
    doctorId: map['doctor_id'] as int,
    patientId: map['patient_id'] as int,
    reason: map['reason'] as String?,
    status: AppointmentState.fromDb(map['status'] as String),
    // created_at vient de datetime('now') de SQLite : heure UTC, sans fuseau.
    createdAt: map['created_at'] == null ? null : DateTime.tryParse('${map['created_at']}Z')?.toLocal(),
    doctorNom: map['doctor_nom'] as String?,
    doctorPrenom: map['doctor_prenom'] as String?,
    specialty: map['specialty'] as String?,
    patientNom: map['patient_nom'] as String?,
    patientPrenom: map['patient_prenom'] as String?,
  );

  /// Colonnes à écrire en base (id et created_at sont gérés par SQLite).
  Map<String, Object?> toMap() => {
    'appointment_date_time': formatDateTime(dateTime),
    'doctor_id': doctorId,
    'patient_id': patientId,
    'reason': (reason == null || reason!.trim().isEmpty) ? null : reason!.trim(),
    'status': status.dbValue,
  };

  Appointment copyWith({AppointmentState? status}) => Appointment(
    id: id,
    dateTime: dateTime,
    doctorId: doctorId,
    patientId: patientId,
    reason: reason,
    status: status ?? this.status,
    createdAt: createdAt,
    doctorNom: doctorNom,
    doctorPrenom: doctorPrenom,
    specialty: specialty,
    patientNom: patientNom,
    patientPrenom: patientPrenom,
  );
}
