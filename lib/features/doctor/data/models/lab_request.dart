import 'dart:convert';

import 'package:medilink/features/user/data/repositories/auth_repository.dart' show parseSqlDateTime;

/// Demande de bilan (table `lab_requests`) : analyses que le patient doit
/// faire réaliser au laboratoire.
class LabRequest {
  const LabRequest({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.tests,
    this.consultationId,
    this.note,
    this.createdAt,
    this.doctorName = '',
    this.doctorSpecialty,
    this.patientName = '',
  });

  final int id;
  final int? consultationId;
  final int doctorId;
  final int patientId;

  /// Analyses demandées, ex. « NFS », « Glycémie à jeun ».
  final List<String> tests;
  final String? note;
  final DateTime? createdAt;

  final String doctorName;
  final String? doctorSpecialty;
  final String patientName;

  /// Analyses proposées en un geste dans l'écran de consultation.
  static const List<String> commonTests = [
    'NFS (numération formule sanguine)',
    'Glycémie à jeun',
    'HbA1c',
    'Bilan lipidique',
    'Créatinine',
    'Urée',
    'Transaminases (ASAT/ALAT)',
    'CRP',
    'VS',
    'TSH',
    'Ionogramme sanguin',
    'Ferritine',
    'Vitamine D',
    'ECBU',
  ];

  /// Ligne issue de la requête de `LabRequestRepository` (jointures users).
  factory LabRequest.fromMap(Map<String, Object?> map) => LabRequest(
    id: map['lab_request_id'] as int,
    consultationId: map['consultation_id'] as int?,
    doctorId: map['doctor_id'] as int,
    patientId: map['patient_id'] as int,
    tests: decodeTests(map['tests'] as String?),
    note: map['note'] as String?,
    createdAt: parseSqlDateTime(map['created_at'] as String?),
    doctorName: 'Dr ${map['doctor_prenom'] ?? ''} ${map['doctor_nom'] ?? ''}'.trim(),
    doctorSpecialty: map['specialty'] as String?,
    patientName: '${map['patient_prenom'] ?? ''} ${map['patient_nom'] ?? ''}'.trim(),
  );

  static String encodeTests(List<String> tests) => jsonEncode(tests);

  static List<String> decodeTests(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [for (final t in jsonDecode(raw) as List) t.toString()];
    } on FormatException {
      return const [];
    }
  }
}
