import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/account_summary.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';

/// Gestion des comptes par l'administrateur : validation des professionnels,
/// suspension, statistiques.
class AdminRepository {
  AdminRepository(this._database, this._notifications);

  final AppDatabase _database;
  final NotificationService _notifications;

  static const _select = '''
    SELECT u.id, u.role, u.nom, u.prenom, u.email, u.phone, u.status, u.rejection_reason, u.created_at,
           COALESCE(d.specialty, ph.pharmacy_name, i.company) AS detail,
           COALESCE(d.license_number, ph.license_number, i.agent_code, p.cin) AS license
    FROM users u
    LEFT JOIN doctors d ON d.user_id = u.id
    LEFT JOIN pharmacists ph ON ph.user_id = u.id
    LEFT JOIN insurers i ON i.user_id = u.id
    LEFT JOIN patients p ON p.user_id = u.id
  ''';

  Future<PlatformStats> stats() async {
    final rows = await _database.db.rawQuery(
      'SELECT role, status, COUNT(*) AS c FROM ${UserTables.users} GROUP BY role, status',
    );
    final byRole = {for (final r in UserRole.values) r: 0};
    var pending = 0, suspended = 0;
    for (final row in rows) {
      final count = row['c'] as int;
      final status = row['status'] as String;
      if (status == AccountStatus.active) byRole.update(UserRole.fromDb(row['role'] as String), (v) => v + count);
      if (status == AccountStatus.pending) pending += count;
      if (status == AccountStatus.suspended) suspended += count;
    }
    return PlatformStats(byRole: byRole, pending: pending, suspended: suspended);
  }

  /// Comptes professionnels en attente, du plus ancien au plus récent.
  Future<List<AccountSummary>> pendingAccounts() async {
    final rows = await _database.db.rawQuery('$_select WHERE u.status = ? ORDER BY u.created_at, u.id', [
      AccountStatus.pending,
    ]);
    return rows.map(AccountSummary.fromMap).toList();
  }

  /// Recherche de comptes (nom, prénom, e-mail), filtrable par rôle et statut.
  Future<List<AccountSummary>> accounts({String query = '', UserRole? role, String? status}) async {
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add("(u.nom LIKE ? OR u.prenom LIKE ? OR u.email LIKE ? OR (u.prenom || ' ' || u.nom) LIKE ?)");
      args.addAll(List.filled(4, '%$q%'));
    }
    if (role != null) {
      where.add('u.role = ?');
      args.add(role.dbValue);
    }
    if (status != null) {
      where.add('u.status = ?');
      args.add(status);
    }
    final rows = await _database.db.rawQuery(
      '$_select ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY u.nom, u.prenom',
      args,
    );
    return rows.map(AccountSummary.fromMap).toList();
  }

  Future<void> approve(int userId) async {
    await _setStatus(userId, AccountStatus.active, expected: [AccountStatus.pending, AccountStatus.rejected]);
    await _notifications.notify(
      userId: userId,
      type: NotificationTypes.account,
      title: 'Compte validé',
      body: 'Bienvenue sur MediLink ! Votre compte professionnel est maintenant actif.',
    );
  }

  Future<void> reject(int userId, String reason) async {
    if (reason.trim().isEmpty) throw const AppException('Indiquez le motif du refus');
    await _setStatus(userId, AccountStatus.rejected, expected: [AccountStatus.pending], reason: reason.trim());
  }

  Future<void> suspend(int userId, {required int adminUserId}) async {
    if (userId == adminUserId) throw const AppException('Vous ne pouvez pas suspendre votre propre compte');
    await _setStatus(userId, AccountStatus.suspended, expected: [AccountStatus.active]);
  }

  Future<void> reactivate(int userId) async {
    await _setStatus(userId, AccountStatus.active, expected: [AccountStatus.suspended]);
    await _notifications.notify(
      userId: userId,
      type: NotificationTypes.account,
      title: 'Compte réactivé',
      body: 'Votre compte MediLink est de nouveau actif.',
    );
  }

  Future<void> _setStatus(int userId, String status, {required List<String> expected, String? reason}) async {
    final updated = await _database.db.update(
      UserTables.users,
      {
        'status': status,
        'rejection_reason': reason,
        'failed_attempts': 0,
        'locked_until': null,
        'updated_at': sqlNow(),
      },
      where: 'id = ? AND status IN (${List.filled(expected.length, '?').join(', ')})',
      whereArgs: [userId, ...expected],
    );
    if (updated == 0) throw const AppException('Ce compte a déjà été traité, actualisez la liste');
  }
}
