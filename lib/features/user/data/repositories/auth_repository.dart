import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/registration_data.dart';
import 'package:sqflite/sqflite.dart';

/// Comptes utilisateurs : connexion, inscription (4 rôles), mots de passe.
///
/// Ne gère pas la session : l'écran appelle ensuite `SessionService.open`.
class AuthRepository {
  AuthRepository(this._database, this._hasher);

  final AppDatabase _database;
  final PasswordHasher _hasher;

  Database get _db => _database.db;

  /// Vérifie l'e-mail et le mot de passe, renvoie l'utilisateur à mettre en session.
  Future<CurrentUser> login(String email, String password) async {
    final rows = await _db.query(UserTables.users, where: 'email = ?', whereArgs: [email.trim()], limit: 1);
    if (rows.isEmpty || !_hasher.verify(password, rows.first['password_hash'] as String)) {
      throw const AppException('E-mail ou mot de passe incorrect', code: 'invalid_credentials');
    }
    return loadCurrentUser(rows.first['id'] as int);
  }

  /// Crée le compte et la ligne de la table propre au rôle, dans une transaction.
  Future<CurrentUser> register(RegistrationData data) async {
    await _ensureUnique(data);
    try {
      final userId = await _db.transaction((txn) async {
        final userId = await txn.insert(UserTables.users, {
          'nom': data.nom.trim(),
          'prenom': data.prenom.trim(),
          'email': data.email.trim(),
          'password_hash': _hasher.hash(data.password),
          'phone': data.phone.trim(),
          'role': data.role.dbValue,
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
        }
        return userId;
      });
      return await loadCurrentUser(userId);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException('Un compte existe déjà avec ces informations', code: 'duplicate', cause: e);
      }
      throw AppException('Impossible de créer le compte, réessayez', cause: e);
    }
  }

  /// Mot de passe oublié : l'identité est vérifiée par l'e-mail + le téléphone
  /// du compte (pas de serveur d'envoi d'e-mails dans l'application).
  Future<void> resetPassword({required String email, required String phone, required String newPassword}) async {
    final rows = await _db.query(UserTables.users, where: 'email = ?', whereArgs: [email.trim()], limit: 1);
    if (rows.isEmpty || !samePhone(rows.first['phone'] as String?, phone)) {
      throw const AppException('Ces informations ne correspondent à aucun compte', code: 'not_found');
    }
    await _setPassword(rows.first['id'] as int, newPassword);
  }

  Future<void> changePassword({required int userId, required String current, required String newPassword}) async {
    final rows = await _db.query(UserTables.users, columns: ['password_hash'], where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty || !_hasher.verify(current, rows.first['password_hash'] as String)) {
      throw const AppException('Le mot de passe actuel est incorrect', code: 'wrong_password');
    }
    await _setPassword(userId, newPassword);
  }

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

  /// Compare deux numéros en ignorant espaces et préfixe +216 (8 derniers chiffres).
  static bool samePhone(String? a, String? b) {
    String last8(String? v) {
      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
      return digits.length > 8 ? digits.substring(digits.length - 8) : digits;
    }

    final x = last8(a);
    return x.isNotEmpty && x == last8(b);
  }

  Future<void> _setPassword(int userId, String password) => _db.update(
    UserTables.users,
    {'password_hash': _hasher.hash(password), 'updated_at': sqlNow()},
    where: 'id = ?',
    whereArgs: [userId],
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

/// Date courante au format SQLite `datetime('now')` (UTC).
String sqlNow() => DateTime.now().toUtc().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
