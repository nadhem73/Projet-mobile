import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart' show parseSqlDateTime;

/// Constantes relevées pendant une consultation.
class VitalSigns {
  const VitalSigns({this.bloodPressure, this.temperature, this.height, this.weight});

  /// Tension artérielle au format « 12/8 » (cmHg) ou « 120/80 » (mmHg).
  final String? bloodPressure;

  /// Température en °C.
  final double? temperature;

  /// Taille en cm.
  final double? height;

  /// Poids en kg.
  final double? weight;

  static final RegExp _bloodPressurePattern = RegExp(r'^\d{1,3}/\d{1,3}$');

  bool get isEmpty => bloodPressure == null && temperature == null && height == null && weight == null;

  /// Indice de masse corporelle, arrondi à 0,1 (null si taille ou poids manquant).
  double? get bmi {
    final h = height, w = weight;
    if (h == null || w == null || h <= 0) return null;
    final meters = h / 100;
    return (w / (meters * meters) * 10).roundToDouble() / 10;
  }

  /// Message d'erreur si une valeur est hors des bornes physiologiques, sinon null.
  String? validate() {
    final bp = bloodPressure;
    if (bp != null && !_bloodPressurePattern.hasMatch(bp)) {
      return 'Tension invalide : utilisez le format 12/8.';
    }
    final t = temperature;
    if (t != null && (t < 30 || t > 45)) return 'Température invalide (entre 30 et 45 °C).';
    final h = height;
    if (h != null && (h < 30 || h > 250)) return 'Taille invalide (entre 30 et 250 cm).';
    final w = weight;
    if (w != null && (w < 1 || w > 350)) return 'Poids invalide (entre 1 et 350 kg).';
    return null;
  }

  Map<String, Object?> toMap() => {
    'blood_pressure': bloodPressure,
    'temperature': temperature,
    'height': height,
    'weight': weight,
    'bmi': bmi,
  };

  factory VitalSigns.fromMap(Map<String, Object?> map) => VitalSigns(
    bloodPressure: map['blood_pressure'] as String?,
    temperature: (map['temperature'] as num?)?.toDouble(),
    height: (map['height'] as num?)?.toDouble(),
    weight: (map['weight'] as num?)?.toDouble(),
  );
}

/// Rendez-vous d'un médecin pour lequel aucune consultation n'a encore été démarrée.
class AppointmentToStart {
  const AppointmentToStart({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.status,
    this.reason,
  });

  final int appointmentId;
  final int patientId;
  final String patientName;
  final DateTime dateTime;
  final String status;
  final String? reason;

  factory AppointmentToStart.fromMap(Map<String, Object?> map) => AppointmentToStart(
    appointmentId: map['appointment_id'] as int,
    patientId: map['patient_id'] as int,
    patientName: '${map['prenom'] ?? ''} ${map['nom'] ?? ''}'.trim(),
    dateTime: DateTime.parse(map['appointment_date_time'] as String),
    status: map['status'] as String,
    reason: map['reason'] as String?,
  );
}

/// Consultation médicale (table `consultations`), avec les noms du patient et
/// du médecin pour l'affichage.
class Consultation {
  const Consultation({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.status,
    this.appointmentId,
    this.patientName = '',
    this.doctorName = '',
    this.doctorSpecialty,
    this.patientBirthDate,
    this.motif,
    this.diagnostic,
    this.observation,
    this.vitals = const VitalSigns(),
    this.startTime,
    this.endTime,
    this.followUpDate,
  });

  final int id;
  final int? appointmentId;
  final int doctorId;
  final int patientId;
  final String status;

  final String patientName;
  final String doctorName;
  final String? doctorSpecialty;
  final DateTime? patientBirthDate;

  final String? motif;
  final String? diagnostic;
  final String? observation;
  final VitalSigns vitals;

  final DateTime? startTime;
  final DateTime? endTime;

  /// Date du rendez-vous de contrôle conseillé (jour uniquement).
  final DateTime? followUpDate;

  bool get isInProgress => status == ConsultationStatus.inProgress;
  bool get isClosed => status == ConsultationStatus.closed;

  /// Âge du patient en années (null si date de naissance inconnue).
  int? ageAt(DateTime date) {
    final birth = patientBirthDate;
    if (birth == null) return null;
    var age = date.year - birth.year;
    if (date.month < birth.month || (date.month == birth.month && date.day < birth.day)) age--;
    return age;
  }

  /// Ligne issue de la requête de [ConsultationRepository] (jointures users).
  factory Consultation.fromMap(Map<String, Object?> map) => Consultation(
    id: map['consultation_id'] as int,
    appointmentId: map['appointment_id'] as int?,
    doctorId: map['doctor_id'] as int,
    patientId: map['patient_id'] as int,
    status: map['status'] as String,
    patientName: '${map['patient_prenom'] ?? ''} ${map['patient_nom'] ?? ''}'.trim(),
    doctorName: 'Dr ${map['doctor_prenom'] ?? ''} ${map['doctor_nom'] ?? ''}'.trim(),
    doctorSpecialty: map['specialty'] as String?,
    patientBirthDate: DateTime.tryParse(map['date_naissance'] as String? ?? ''),
    motif: map['motif'] as String?,
    diagnostic: map['diagnostic'] as String?,
    observation: map['observation'] as String?,
    vitals: VitalSigns.fromMap(map),
    startTime: parseSqlDateTime(map['start_time'] as String?),
    endTime: parseSqlDateTime(map['end_time'] as String?),
    followUpDate: DateTime.tryParse(map['follow_up_date'] as String? ?? ''),
  );
}
