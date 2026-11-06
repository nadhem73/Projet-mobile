import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';

/// Bilan complet (`ScanBilanResponse` côté API).
///
/// Produit soit par le serveur (`POST /api/bilans/scan`), soit par l'OCR local
/// (id préfixé par [localPrefix], [synced] à `false`).
class ScanBilan {
  const ScanBilan({
    required this.id,
    required this.typeBilan,
    required this.format,
    required this.dateBilan,
    required this.laboratoire,
    required this.status,
    required this.patientId,
    required this.resultats,
    this.reviewStatus,
    this.doctorId,
    this.doctorName,
    this.patientName,
    this.doctorComment,
    this.synced = true,
    this.imagePath,
    this.createdAt,
  });

  static const localPrefix = 'local-';

  final String id;
  final String typeBilan;
  final BilanFormat format;

  /// Date telle que lue sur le bilan (ISO `yyyy-MM-dd` si reconnue).
  final String dateBilan;
  final String laboratoire;
  final BilanStatus status;
  final ReviewStatus? reviewStatus;
  final int patientId;
  final int? doctorId;
  final List<BilanResult> resultats;

  // ---- Champs locaux (non renvoyés par l'API) ----

  /// Nom du médecin destinataire (jointure locale).
  final String? doctorName;

  /// Nom du patient (vue médecin).
  final String? patientName;

  /// Retour du médecin au patient.
  final String? doctorComment;

  /// `false` = analysé hors-ligne, pas encore envoyé au serveur.
  final bool synced;

  /// Photo d'origine, pour un renvoi ultérieur au serveur.
  final String? imagePath;
  final DateTime? createdAt;

  bool get isLocal => id.startsWith(localPrefix);
  bool get isConfirmed => status == BilanStatus.confirmed;
  int get abnormalCount => resultats.where((r) => r.status.isOutOfRange).length;
  DateTime? get date => DateTime.tryParse(dateBilan);

  ScanBilan copyWith({
    String? id,
    int? patientId,
    String? typeBilan,
    String? dateBilan,
    String? laboratoire,
    BilanStatus? status,
    ReviewStatus? reviewStatus,
    int? doctorId,
    String? doctorName,
    List<BilanResult>? resultats,
    bool? synced,
    String? imagePath,
  }) => ScanBilan(
    id: id ?? this.id,
    typeBilan: typeBilan ?? this.typeBilan,
    format: format,
    dateBilan: dateBilan ?? this.dateBilan,
    laboratoire: laboratoire ?? this.laboratoire,
    status: status ?? this.status,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    patientId: patientId ?? this.patientId,
    doctorId: doctorId ?? this.doctorId,
    doctorName: doctorName ?? this.doctorName,
    patientName: patientName,
    doctorComment: doctorComment,
    resultats: resultats ?? this.resultats,
    synced: synced ?? this.synced,
    imagePath: imagePath ?? this.imagePath,
    createdAt: createdAt,
  );

  // ---------------------------------------------------------------------------
  // JSON (API)
  // ---------------------------------------------------------------------------

  factory ScanBilan.fromJson(Map<String, dynamic> json) => ScanBilan(
    id: json['id']?.toString() ?? '',
    typeBilan: json['typeBilan'] as String? ?? 'Bilan',
    format: BilanFormat.parse(json['format']),
    dateBilan: json['dateBilan']?.toString() ?? '',
    laboratoire: json['laboratoire'] as String? ?? '',
    status: BilanStatus.parse(json['status']),
    reviewStatus: ReviewStatus.parse(json['reviewStatus']),
    patientId: (json['patientId'] as num?)?.toInt() ?? 0,
    doctorId: (json['doctorId'] as num?)?.toInt(),
    resultats: [
      for (final r in (json['resultats'] as List? ?? const [])) BilanResult.fromJson(r as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'typeBilan': typeBilan,
    'format': format.value,
    'dateBilan': dateBilan,
    'laboratoire': laboratoire,
    'status': status.value,
    'reviewStatus': reviewStatus?.value,
    'patientId': patientId,
    'doctorId': doctorId,
    'resultats': [for (final r in resultats) r.toJson()],
  };

  // ---------------------------------------------------------------------------
  // SQLite (table bilans ; résultats chargés à part)
  // ---------------------------------------------------------------------------

  factory ScanBilan.fromMap(Map<String, Object?> map, List<BilanResult> resultats) => ScanBilan(
    id: map['bilan_id'] as String,
    typeBilan: map['type_bilan'] as String? ?? 'Bilan',
    format: BilanFormat.parse(map['format']),
    dateBilan: map['date_bilan'] as String? ?? '',
    laboratoire: map['laboratoire'] as String? ?? '',
    status: BilanStatus.parse(map['status']),
    reviewStatus: ReviewStatus.parse(map['review_status']),
    patientId: map['patient_id'] as int,
    doctorId: map['doctor_id'] as int?,
    doctorName: map['doctor_name'] as String?,
    patientName: map['patient_name'] as String?,
    doctorComment: map['doctor_comment'] as String?,
    resultats: resultats,
    synced: (map['synced'] as int? ?? 1) == 1,
    imagePath: map['image_path'] as String?,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
  );

  Map<String, Object?> toMap({String? rawText}) => {
    'bilan_id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'type_bilan': typeBilan,
    'format': format.value,
    'date_bilan': dateBilan,
    'laboratoire': laboratoire,
    'status': status.value,
    'review_status': reviewStatus?.value,
    'image_path': imagePath,
    'doctor_comment': doctorComment,
    'raw_text': rawText,
    'synced': synced ? 1 : 0,
  };
}
