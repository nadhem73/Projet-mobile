import 'package:medilink/features/ai/data/models/bilan_enums.dart';

/// Ligne de l'historique des bilans (`BilanSummary` côté API).
class BilanSummary {
  const BilanSummary({
    required this.id,
    required this.typeBilan,
    required this.dateBilan,
    required this.status,
    required this.resultCount,
    required this.abnormalCount,
    required this.patientId,
    this.reviewStatus,
    this.doctorId,
    this.synced = true,
    this.patientName,
  });

  final String id;
  final String typeBilan;
  final String dateBilan;
  final BilanStatus status;
  final int resultCount;
  final int abnormalCount;
  final ReviewStatus? reviewStatus;
  final int patientId;
  final int? doctorId;

  /// Local uniquement : `false` = analysé hors-ligne.
  final bool synced;

  /// Nom du patient (vue médecin, local uniquement).
  final String? patientName;

  DateTime? get date => DateTime.tryParse(dateBilan);

  factory BilanSummary.fromJson(Map<String, dynamic> json) => BilanSummary(
    id: json['id']?.toString() ?? '',
    typeBilan: json['typeBilan'] as String? ?? 'Bilan',
    dateBilan: json['dateBilan']?.toString() ?? '',
    status: BilanStatus.parse(json['status']),
    resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
    abnormalCount: (json['abnormalCount'] as num?)?.toInt() ?? 0,
    reviewStatus: ReviewStatus.parse(json['reviewStatus']),
    patientId: (json['patientId'] as num?)?.toInt() ?? 0,
    doctorId: (json['doctorId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'typeBilan': typeBilan,
    'dateBilan': dateBilan,
    'status': status.value,
    'resultCount': resultCount,
    'abnormalCount': abnormalCount,
    'reviewStatus': reviewStatus?.value,
    'patientId': patientId,
    'doctorId': doctorId,
  };

  /// Ligne SQL agrégée par `BilanRepository.page`.
  factory BilanSummary.fromMap(Map<String, Object?> map) => BilanSummary(
    id: map['bilan_id'] as String,
    typeBilan: map['type_bilan'] as String? ?? 'Bilan',
    dateBilan: map['date_bilan'] as String? ?? '',
    status: BilanStatus.parse(map['status']),
    resultCount: map['result_count'] as int? ?? 0,
    abnormalCount: map['abnormal_count'] as int? ?? 0,
    reviewStatus: ReviewStatus.parse(map['review_status']),
    patientId: map['patient_id'] as int,
    doctorId: map['doctor_id'] as int?,
    synced: (map['synced'] as int? ?? 1) == 1,
    patientName: map['patient_name'] as String?,
  );
}

/// Page de résultats (équivalent simplifié de la `Page` Spring).
class BilanPage {
  const BilanPage({required this.content, required this.page, required this.totalPages});

  final List<BilanSummary> content;
  final int page;
  final int totalPages;

  bool get isLast => page >= totalPages - 1;

  factory BilanPage.fromJson(Map<String, dynamic> json) => BilanPage(
    content: [for (final e in (json['content'] as List? ?? const [])) BilanSummary.fromJson(e as Map<String, dynamic>)],
    page: (json['number'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
  );
}
