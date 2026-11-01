import 'dart:typed_data';

import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/user_profile.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Lecture et modification du profil de l'utilisateur connecté (tous les rôles).
class ProfileRepository {
  ProfileRepository(this._database, this._auth);

  final AppDatabase _database;
  final AuthRepository _auth;

  Database get _db => _database.db;

  Future<UserProfile> load(CurrentUser user) async {
    final sql = switch (user.role) {
      UserRole.patient =>
        'SELECT u.*, p.cin, p.date_naissance, p.adresse AS address '
            'FROM users u LEFT JOIN patients p ON p.user_id = u.id WHERE u.id = ?',
      UserRole.doctor =>
        'SELECT u.*, d.specialty, d.license_number, dp.biography, dp.fee, dp.city, dp.address '
            'FROM users u LEFT JOIN doctors d ON d.user_id = u.id '
            'LEFT JOIN doctor_profiles dp ON dp.doctor_id = d.doctor_id WHERE u.id = ?',
      UserRole.pharmacist =>
        'SELECT u.*, ph.pharmacy_name, ph.license_number, ph.address, ph.city '
            'FROM users u LEFT JOIN pharmacists ph ON ph.user_id = u.id WHERE u.id = ?',
      UserRole.insurer =>
        'SELECT u.*, i.company, i.agent_code FROM users u LEFT JOIN insurers i ON i.user_id = u.id WHERE u.id = ?',
      UserRole.admin => 'SELECT u.* FROM users u WHERE u.id = ?',
    };
    final rows = await _db.rawQuery(sql, [user.userId]);
    if (rows.isEmpty) throw const AppException('Profil introuvable', code: 'not_found');
    final r = rows.first;
    return UserProfile(
      userId: r['id'] as int,
      role: user.role,
      nom: r['nom'] as String,
      prenom: r['prenom'] as String,
      email: r['email'] as String,
      phone: r['phone'] as String?,
      createdAt: parseSqlDateTime(r['created_at'] as String?),
      cin: r['cin'] as String?,
      dateNaissance: DateTime.tryParse(r['date_naissance'] as String? ?? ''),
      address: r['address'] as String?,
      specialty: r['specialty'] as String?,
      licenseNumber: r['license_number'] as String?,
      biography: r['biography'] as String?,
      fee: (r['fee'] as num?)?.toDouble(),
      city: r['city'] as String?,
      pharmacyName: r['pharmacy_name'] as String?,
      company: r['company'] as String?,
      agentCode: r['agent_code'] as String?,
    );
  }

  /// Enregistre le profil et renvoie l'utilisateur de session mis à jour.
  Future<CurrentUser> save(UserProfile profile) async {
    final clash = await _db.query(
      UserTables.users,
      columns: ['id'],
      where: 'email = ? AND id <> ?',
      whereArgs: [profile.email.trim(), profile.userId],
      limit: 1,
    );
    if (clash.isNotEmpty) {
      throw const AppException('Cette adresse e-mail est déjà utilisée par un autre compte', code: 'email_taken');
    }

    await _db.transaction((txn) async {
      await txn.update(
        UserTables.users,
        {
          'nom': profile.nom.trim(),
          'prenom': profile.prenom.trim(),
          'email': profile.email.trim(),
          'phone': _clean(profile.phone),
          'updated_at': sqlNow(),
        },
        where: 'id = ?',
        whereArgs: [profile.userId],
      );

      final userWhere = 'user_id = ?';
      final userArgs = [profile.userId];
      switch (profile.role) {
        case UserRole.patient:
          await txn.update(
            UserTables.patients,
            {
              'cin': _clean(profile.cin),
              'date_naissance': profile.dateNaissance?.toIso8601String().substring(0, 10),
              'adresse': _clean(profile.address),
            },
            where: userWhere,
            whereArgs: userArgs,
          );
        case UserRole.doctor:
          await txn.update(UserTables.doctors, {'specialty': profile.specialty}, where: userWhere, whereArgs: userArgs);
          final doctor = await txn.query(
            UserTables.doctors,
            columns: ['doctor_id'],
            where: userWhere,
            whereArgs: userArgs,
          );
          final doctorId = doctor.first['doctor_id'] as int;
          final details = {
            'biography': _clean(profile.biography),
            'fee': profile.fee,
            'city': _clean(profile.city),
            'address': _clean(profile.address),
          };
          final updated = await txn.update(
            UserTables.doctorProfiles,
            details,
            where: 'doctor_id = ?',
            whereArgs: [doctorId],
          );
          if (updated == 0) await txn.insert(UserTables.doctorProfiles, {...details, 'doctor_id': doctorId});
        case UserRole.pharmacist:
          await txn.update(
            UserTables.pharmacists,
            {
              'pharmacy_name': profile.pharmacyName?.trim(),
              'address': _clean(profile.address),
              'city': _clean(profile.city),
            },
            where: userWhere,
            whereArgs: userArgs,
          );
        case UserRole.insurer:
          await txn.update(UserTables.insurers, {'company': profile.company}, where: userWhere, whereArgs: userArgs);
        case UserRole.admin:
          break;
      }
    });
    return _auth.loadCurrentUser(profile.userId);
  }

  // ---- Photo de profil ----

  /// Taille maximale de la photo (déjà redimensionnée à la sélection).
  static const int maxAvatarBytes = 1024 * 1024;

  Future<Uint8List?> avatar(int userId) async {
    final rows = await _db.query(UserTables.users, columns: ['avatar'], where: 'id = ?', whereArgs: [userId]);
    return rows.isEmpty ? null : rows.first['avatar'] as Uint8List?;
  }

  /// Enregistre la photo, ou la supprime si [bytes] est null.
  Future<void> setAvatar(int userId, Uint8List? bytes) async {
    if (bytes != null && bytes.length > maxAvatarBytes) throw const AppException('Photo trop lourde (1 Mo maximum)');
    await _db.update(UserTables.users, {'avatar': bytes, 'updated_at': sqlNow()}, where: 'id = ?', whereArgs: [userId]);
  }

  static String? _clean(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
