import 'package:flutter/material.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart' show parseSqlDateTime;

/// Avancement d'une ordonnance envoyée à une pharmacie.
enum DispatchStatus {
  /// Reçue par la pharmacie, en cours de préparation.
  sent('SENT', 'Envoyée', Icons.send_rounded, Color(0xFF1E88E5)),

  /// Médicaments prêts à être retirés.
  ready('READY', 'Prête à retirer', Icons.inventory_2_rounded, Color(0xFFF57C00)),

  /// Remise au patient.
  delivered('DELIVERED', 'Délivrée', Icons.check_circle_rounded, Color(0xFF2E7D32));

  const DispatchStatus(this.code, this.label, this.icon, this.color);

  final String code;
  final String label;
  final IconData icon;
  final Color color;

  /// Étape suivante pour le pharmacien, null si l'ordonnance est délivrée.
  DispatchStatus? get next => switch (this) {
    DispatchStatus.sent => DispatchStatus.ready,
    DispatchStatus.ready => DispatchStatus.delivered,
    DispatchStatus.delivered => null,
  };

  static DispatchStatus fromCode(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => DispatchStatus.sent);
}

/// Ordonnance envoyée par un patient à une pharmacie (table `prescription_dispatches`).
class PrescriptionDispatch {
  const PrescriptionDispatch({
    required this.id,
    required this.prescriptionId,
    required this.pharmacyId,
    required this.patientId,
    required this.status,
    this.sentAt,
    this.updatedAt,
    this.pharmacyName = '',
    this.pharmacyAddress,
    this.pharmacyPhone,
    this.patientName = '',
    this.doctorName = '',
    this.itemCount = 0,
  });

  final int id;
  final int prescriptionId;
  final int pharmacyId;
  final int patientId;
  final DispatchStatus status;
  final DateTime? sentAt;
  final DateTime? updatedAt;

  final String pharmacyName;
  final String? pharmacyAddress;
  final String? pharmacyPhone;
  final String patientName;
  final String doctorName;

  /// Nombre de médicaments sur l'ordonnance.
  final int itemCount;

  /// Le patient peut encore choisir une autre pharmacie.
  bool get canChangePharmacy => status == DispatchStatus.sent;

  factory PrescriptionDispatch.fromMap(Map<String, Object?> map) => PrescriptionDispatch(
    id: map['dispatch_id'] as int,
    prescriptionId: map['prescription_id'] as int,
    pharmacyId: map['pharmacy_id'] as int,
    patientId: map['patient_id'] as int,
    status: DispatchStatus.fromCode(map['status'] as String?),
    sentAt: parseSqlDateTime(map['sent_at'] as String?),
    updatedAt: parseSqlDateTime(map['updated_at'] as String?),
    pharmacyName: map['pharmacy_name'] as String? ?? '',
    pharmacyAddress: map['pharmacy_address'] as String?,
    pharmacyPhone: map['pharmacy_phone'] as String?,
    patientName: '${map['patient_prenom'] ?? ''} ${map['patient_nom'] ?? ''}'.trim(),
    doctorName: 'Dr ${map['doctor_prenom'] ?? ''} ${map['doctor_nom'] ?? ''}'.trim(),
    itemCount: map['item_count'] as int? ?? 0,
  );
}
