import 'dart:math';

import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/registration_data.dart';
import 'package:sqflite/sqflite.dart';

/// Code de réinitialisation « envoyé » par SMS.
class ResetCodeDelivery {
  const ResetCodeDelivery({required this.maskedPhone, required this.code});

  /// Numéro masqué affiché à l'utilisateur (ex. « •• ••• 678 »).
  final String maskedPhone;

  /// Code généré. Il n'y a pas de passerelle SMS dans le projet : l'écran
  /// l'affiche en mode démo uniquement.
  final String code;
}

/// Comptes utilisateurs : connexion sécurisée, inscription, mots de passe,
/// suppression de compte.
///
/// Ne gère pas la session : l'appelant utilise ensuite `SessionService.open`.
class AuthRepository {
  AuthRepository(this._database, this._hasher, this._notifications, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final PasswordHasher _hasher;
  final NotificationService _notifications;
  final DateTime Function() _clock;

  /// Échecs de connexion consécutifs avant blocage temporaire.
  static const int maxFailedAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 5);

  /// Durée de validité et nombre d'essais d'un code de réinitialisation.
  static const Duration resetCodeValidity = Duration(minutes: 10);
  static const int maxResetCodeAttempts = 5;

  Database get _db => _database.db;

  // ---------------------------------------------------------------------------
  // Connexion
  // ---------------------------------------------------------------------------

  /// Vérifie l'e-mail, le mot de passe et le statut du compte.
  ///
  /// Après [maxFailedAttempts] échecs, le compte est bloqué [lockDuration].
  /// Le message d'erreur ne révèle pas si l'e-mail existe.
  Future<CurrentUser> login(String email, String password) async {
    final rows = await _db.query(UserTables.users, where: 'email = ?', whereArgs: [email.trim()], limit: 1);
    if (rows.isEmpty) throw _invalidCredentials;
    final u = rows.first;
    final userId = u['id'] as int;
    final now = _clock();

    final lockedUntil = parseSqlDateTime(u['locked_until'] as String?);
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      final minutes = (lockedUntil.difference(now).inSeconds / 60).ceil();
      throw AppException(
        'Trop de tentatives. Réessayez dans $minutes min ou réinitialisez votre mot de passe.',
        code: 'locked',
      );
    }

    if (!_hasher.verify(password, u['password_hash'] as String)) {
      final attempts = (u['failed_attempts'] as int) + 1;
      if (attempts >= maxFailedAttempts) {
        await _db.update(
          UserTables.users,
          {'failed_attempts': 0, 'locked_until': sqlDateTime(now.add(lockDuration))},
          where: 'id = ?',
          whereArgs: [userId],
        );
        throw AppException(
          'Trop de tentatives. Compte bloqué ${lockDuration.inMinutes} minutes par sécurité.',
          code: 'locked',
        );
      }
      await _db.update(UserTables.users, {'failed_attempts': attempts}, where: 'id = ?', whereArgs: [userId]);
      throw _invalidCredentials;
    }

    switch (u['status'] as String) {
      case AccountStatus.pending:
        throw const AppException(
          'Votre compte est en attente de validation par un administrateur. '
          'Vous serez notifié dès qu\'il sera activé.',
          code: 'pending',
        );
      case AccountStatus.rejected:
        final reason = u['rejection_reason'] as String?;
        throw AppException(
          'Votre demande de compte a été refusée${reason == null ? '' : ' : $reason'}.',
          code: 'rejected',
        );
      case AccountStatus.suspended:
        throw const AppException('Votre compte est suspendu. Contactez l\'administrateur.', code: 'suspended');
    }

    if ((u['failed_attempts'] as int) > 0 || u['locked_until'] != null) {
      await _db.update(
        UserTables.users,
        {'failed_attempts': 0, 'locked_until': null},
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
    return loadCurrentUser(userId);
  }

  static const _invalidCredentials = AppException('E-mail ou mot de passe incorrect', code: 'invalid_credentials');

  /// Revalide une session restaurée au démarrage : null si le compte a été
  /// supprimé, suspendu, ou n'est plus actif.
  Future<CurrentUser?> refreshSession(int userId) async {
    final rows = await _db.query(UserTables.users, columns: ['status'], where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty || rows.first['status'] != AccountStatus.active) return null;
    return loadCurrentUser(userId);
  }

  // ---------------------------------------------------------------------------
  // Inscription
  // ---------------------------------------------------------------------------

  /// Crée le compte et la ligne de la table propre au rôle, dans une transaction.
  ///
  /// Patient : compte actif immédiatement. Médecin, pharmacien, assureur :
  /// compte « en attente », validé par un administrateur.
  Future<CurrentUser> register(RegistrationData data) async {
    if (!UserRole.selfRegistrable.contains(data.role)) {
      throw const AppException('Ce type de compte ne peut pas être créé depuis l\'application');
    }
    await _ensureUnique(data);
    final pending = data.role.requiresValidation;
    final int userId;
    try {
      userId = await _db.transaction((txn) async {
        final userId = await txn.insert(UserTables.users, {
          'nom': data.nom.trim(),
          'prenom': data.prenom.trim(),
          'email': data.email.trim(),
          'password_hash': _hasher.hash(data.password),
          'phone': data.phone.trim(),
          'role': data.role.dbValue,
          'status': pending ? AccountStatus.pending : AccountStatus.active,
        });

        switch (data.role) {
          case UserRole.patient:
            final patientId = await txn.insert(UserTables.patients, {
              'cin': _clean(data.cin),
              'date_naissance': data.dateNaissance?.toIso8601String().substring(0, 10),
              'adresse': _clean(data.address),
              'user_id': userId,
            });
            // Dossier médical créé vide : le patient le complète ensuite.
            await txn.insert(UserTables.medicalRecords, {'patient_id': patientId, 'gender': data.gender});
          case UserRole.doctor:
            final doctorId = await txn.insert(UserTables.doctors, {
              'license_number': data.licenseNumber!.trim(),
              'specialty': data.specialty!,
              'user_id': userId,
            });
            await txn.insert(UserTables.doctorProfiles, {'doctor_id': doctorId, 'city': _clean(data.city)});
          case UserRole.pharmacist:
            await txn.insert(UserTables.pharmacists, {
              'pharmacy_name': data.pharmacyName!.trim(),
              'license_number': data.licenseNumber!.trim(),
              'address': _clean(data.address),
              'city': _clean(data.city),
              'user_id': userId,
            });
          case UserRole.insurer:
            await txn.insert(UserTables.insurers, {
              'company': data.company!,
              'agent_code': data.agentCode!.trim(),
              'user_id': userId,
            });
          case UserRole.admin:
            break;
        }
        return userId;
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException('Un compte existe déjà avec ces informations', code: 'duplicate', cause: e);
      }
      throw AppException('Impossible de créer le compte, réessayez', cause: e);
    }

    final fullName = '${data.prenom.trim()} ${data.nom.trim()}';
    if (pending) {
      await _notifications.notifyRole(
        roleDbValue: UserRole.admin.dbValue,
        type: NotificationTypes.account,
        title: 'Nouvelle demande de compte',
        body: '$fullName demande un compte ${data.role.label.toLowerCase()}.',
        payload: {'userId': userId},
      );
    } else {
      await _notifications.notify(
        userId: userId,
        type: NotificationTypes.system,
        title: 'Bienvenue sur MediLink !',
        body: 'Pensez à compléter votre dossier médical : il aide vos médecins à mieux vous soigner.',
      );
    }
    return loadCurrentUser(userId);
  }

  // ---------------------------------------------------------------------------
  // Mots de passe
  // ---------------------------------------------------------------------------

  /// Étape 1 du mot de passe oublié : vérifie l'e-mail + le téléphone du compte
  /// et génère un code à 6 chiffres valable [resetCodeValidity].
  Future<ResetCodeDelivery> requestPasswordReset({required String email, required String phone}) async {
    final rows = await _db.query(UserTables.users, where: 'email = ?', whereArgs: [email.trim()], limit: 1);
    if (rows.isEmpty || !samePhone(rows.first['phone'] as String?, phone)) {
      throw const AppException('Ces informations ne correspondent à aucun compte', code: 'not_found');
    }
    final userId = rows.first['id'] as int;
    final code = (Random.secure().nextInt(900000) + 100000).toString();

    // Un seul code valable à la fois.
    await _db.update(
      UserTables.passwordResetCodes,
      {'used': 1},
      where: 'user_id = ? AND used = 0',
      whereArgs: [userId],
    );
    await _db.insert(UserTables.passwordResetCodes, {
      'user_id': userId,
      'code_hash': _hasher.hash(code),
      'expires_at': sqlDateTime(_clock().add(resetCodeValidity)),
    });
    return ResetCodeDelivery(maskedPhone: maskPhone(rows.first['phone'] as String?), code: code);
  }

  /// Étape 2 : vérifie le code et enregistre le nouveau mot de passe.
  /// Débloque aussi le compte s'il était bloqué après trop d'échecs.
  Future<void> resetPasswordWithCode({required String email, required String code, required String newPassword}) async {
    final users = await _db.query(UserTables.users, columns: ['id'], where: 'email = ?', whereArgs: [email.trim()]);
    if (users.isEmpty) throw const AppException('Code invalide ou expiré', code: 'invalid_code');
    final userId = users.first['id'] as int;

    final codes = await _db.query(
      UserTables.passwordResetCodes,
      where: 'user_id = ? AND used = 0',
      whereArgs: [userId],
      orderBy: 'code_id DESC',
      limit: 1,
    );
    if (codes.isEmpty) throw const AppException('Code invalide ou expiré', code: 'invalid_code');
    final c = codes.first;
    final codeId = c['code_id'] as int;
    final expiresAt = parseSqlDateTime(c['expires_at'] as String)!;

    if (expiresAt.isBefore(_clock())) {
      throw const AppException('Ce code a expiré, demandez-en un nouveau', code: 'expired_code');
    }
    if ((c['attempts'] as int) >= maxResetCodeAttempts) {
      throw const AppException('Trop d\'essais, demandez un nouveau code', code: 'too_many_attempts');
    }
    if (!_hasher.verify(code.trim(), c['code_hash'] as String)) {
      await _db.rawUpdate('UPDATE ${UserTables.passwordResetCodes} SET attempts = attempts + 1 WHERE code_id = ?', [
        codeId,
      ]);
      throw const AppException('Code incorrect', code: 'wrong_code');
    }

    await _db.transaction((txn) async {
      await txn.update(UserTables.passwordResetCodes, {'used': 1}, where: 'code_id = ?', whereArgs: [codeId]);
      await txn.update(
        UserTables.users,
        {
          'password_hash': _hasher.hash(newPassword),
          'failed_attempts': 0,
          'locked_until': null,
          'updated_at': sqlNow(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    });
    await _notifySecurity(userId, 'Votre mot de passe a été réinitialisé.');
  }

  Future<void> changePassword({required int userId, required String current, required String newPassword}) async {
    await _verifyPassword(userId, current);
    await _db.update(
      UserTables.users,
      {'password_hash': _hasher.hash(newPassword), 'updated_at': sqlNow()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    await _notifySecurity(userId, 'Votre mot de passe a été modifié.');
  }

  // ---------------------------------------------------------------------------
  // Suppression du compte (droit à l'effacement)
  // ---------------------------------------------------------------------------

  /// Supprime le compte et toutes ses données (dossier, proches, documents...).
  Future<void> deleteAccount({required int userId, required String password}) async {
    final role = await _verifyPassword(userId, password);
    if (role == UserRole.admin.dbValue) {
      final admins = await _db.rawQuery(
        "SELECT COUNT(*) AS c FROM ${UserTables.users} WHERE role = 'ADMIN' AND status = 'ACTIVE'",
      );
      if ((admins.first['c'] as int) <= 1) {
        throw const AppException('Impossible de supprimer le dernier compte administrateur');
      }
    }
    try {
      await _db.delete(UserTables.users, where: 'id = ?', whereArgs: [userId]);
    } on DatabaseException catch (e) {
      throw AppException(
        'Ce compte est lié à un historique médical (consultations, ordonnances) et ne peut pas être '
        'supprimé directement. Contactez l\'administrateur.',
        code: 'has_history',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Utilisateur de session
  // ---------------------------------------------------------------------------

  /// Construit l'utilisateur de session à partir de `users` + table du rôle.
  Future<CurrentUser> loadCurrentUser(int userId) async {
    final users = await _db.query(UserTables.users, where: 'id = ?', whereArgs: [userId], limit: 1);
    if (users.isEmpty) throw const AppException('Compte introuvable', code: 'not_found');
    final u = users.first;
    final role = UserRole.fromDb(u['role'] as String);

    Future<Map<String, Object?>> roleRow(String table) async {
      final rows = await _db.query(table, where: 'user_id = ?', whereArgs: [userId], limit: 1);
      return rows.isEmpty ? const {} : rows.first;
    }

    final row = switch (role) {
      UserRole.patient => await roleRow(UserTables.patients),
      UserRole.doctor => await roleRow(UserTables.doctors),
      UserRole.pharmacist => await roleRow(UserTables.pharmacists),
      UserRole.insurer => await roleRow(UserTables.insurers),
      UserRole.admin => const <String, Object?>{},
    };

    return CurrentUser(
      userId: userId,
      role: role,
      nom: u['nom'] as String,
      prenom: u['prenom'] as String,
      email: u['email'] as String,
      phone: u['phone'] as String?,
      patientId: row['patient_id'] as int?,
      doctorId: row['doctor_id'] as int?,
      pharmacistId: row['pharmacist_id'] as int?,
      insurerId: row['insurer_id'] as int?,
      specialty: row['specialty'] as String?,
      organization: (row['pharmacy_name'] ?? row['company']) as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Utilitaires
  // ---------------------------------------------------------------------------

  /// Compare deux numéros en ignorant espaces et préfixe +216 (8 derniers chiffres).
  static bool samePhone(String? a, String? b) {
    final x = _last8(a);
    return x.isNotEmpty && x == _last8(b);
  }

  /// « +216 22 345 678 » → « •• ••• 678 ».
  static String maskPhone(String? phone) {
    final digits = _last8(phone);
    if (digits.length < 3) return '••••••••';
    return '•• ••• ${digits.substring(digits.length - 3)}';
  }

  static String _last8(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length > 8 ? digits.substring(digits.length - 8) : digits;
  }

  /// Vérifie le mot de passe actuel et renvoie le rôle (valeur SQL) du compte.
  Future<String> _verifyPassword(int userId, String password) async {
    final rows = await _db.query(
      UserTables.users,
      columns: ['password_hash', 'role'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty || !_hasher.verify(password, rows.first['password_hash'] as String)) {
      throw const AppException('Le mot de passe actuel est incorrect', code: 'wrong_password');
    }
    return rows.first['role'] as String;
  }

  Future<void> _notifySecurity(int userId, String body) => _notifications.notify(
    userId: userId,
    type: NotificationTypes.security,
    title: 'Sécurité du compte',
    body: '$body Si ce n\'est pas vous, contactez immédiatement l\'administrateur.',
  );

  Future<void> _ensureUnique(RegistrationData data) async {
    Future<bool> exists(String table, String column, String? value) async {
      if (value == null || value.trim().isEmpty) return false;
      final rows = await _db.query(table, columns: [column], where: '$column = ?', whereArgs: [value.trim()], limit: 1);
      return rows.isNotEmpty;
    }

    if (await exists(UserTables.users, 'email', data.email)) {
      throw const AppException('Un compte existe déjà avec cette adresse e-mail', code: 'email_taken');
    }
    final duplicate = switch (data.role) {
      UserRole.patient when await exists(UserTables.patients, 'cin', data.cin) => 'Ce numéro de CIN est déjà utilisé',
      UserRole.doctor when await exists(UserTables.doctors, 'license_number', data.licenseNumber) =>
        'Ce numéro d\'inscription à l\'Ordre est déjà utilisé',
      UserRole.pharmacist when await exists(UserTables.pharmacists, 'license_number', data.licenseNumber) =>
        'Ce numéro d\'autorisation est déjà utilisé',
      UserRole.insurer when await exists(UserTables.insurers, 'agent_code', data.agentCode) =>
        'Ce matricule d\'agent est déjà utilisé',
      _ => null,
    };
    if (duplicate != null) throw AppException(duplicate, code: 'duplicate');
  }

  static String? _clean(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}

/// Date au format SQLite `datetime('now')` (UTC, « AAAA-MM-JJ HH:MM:SS »).
String sqlDateTime(DateTime date) => date.toUtc().toIso8601String().substring(0, 19).replaceFirst('T', ' ');

/// Date courante au format SQLite (UTC).
String sqlNow() => sqlDateTime(DateTime.now());

/// Lit une date stockée par SQLite (UTC) et la convertit en heure locale.
DateTime? parseSqlDateTime(String? value) =>
    value == null ? null : DateTime.tryParse('${value.replaceFirst(' ', 'T')}Z')?.toLocal();
