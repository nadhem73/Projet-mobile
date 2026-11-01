import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';

/// Ligne de compte affichée dans l'espace administrateur.
class AccountSummary {
  const AccountSummary({
    required this.userId,
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    this.phone,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.detail,
    this.license,
  });

  final int userId;
  final UserRole role;
  final String nom;
  final String prenom;
  final String email;
  final String? phone;

  /// Voir [AccountStatus].
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;

  /// Spécialité, nom de la pharmacie ou organisme.
  final String? detail;

  /// N° d'Ordre, d'autorisation ou matricule — à vérifier avant validation.
  final String? license;

  String get fullName => '$prenom $nom'.trim();
  String get initials => '${prenom.isEmpty ? '' : prenom[0]}${nom.isEmpty ? '' : nom[0]}'.toUpperCase();

  bool get isPending => status == AccountStatus.pending;
  bool get isActive => status == AccountStatus.active;
  bool get isSuspended => status == AccountStatus.suspended;
  bool get isRejected => status == AccountStatus.rejected;

  static String statusLabel(String status) => switch (status) {
    AccountStatus.active => 'Actif',
    AccountStatus.pending => 'En attente',
    AccountStatus.rejected => 'Refusé',
    AccountStatus.suspended => 'Suspendu',
    _ => status,
  };

  factory AccountSummary.fromMap(Map<String, Object?> map) => AccountSummary(
    userId: map['id'] as int,
    role: UserRole.fromDb(map['role'] as String),
    nom: map['nom'] as String,
    prenom: map['prenom'] as String,
    email: map['email'] as String,
    phone: map['phone'] as String?,
    status: map['status'] as String,
    rejectionReason: map['rejection_reason'] as String?,
    createdAt: parseSqlDateTime(map['created_at'] as String?),
    detail: map['detail'] as String?,
    license: map['license'] as String?,
  );
}

/// Chiffres clés de la plateforme.
class PlatformStats {
  const PlatformStats({required this.byRole, required this.pending, required this.suspended});

  final Map<UserRole, int> byRole;
  final int pending;
  final int suspended;

  int get total => byRole.values.fold(0, (a, b) => a + b);
}
