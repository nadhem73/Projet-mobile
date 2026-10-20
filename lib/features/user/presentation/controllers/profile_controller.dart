import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/user/data/models/user_profile.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/dependent_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';
import 'package:medilink/features/user/presentation/controllers/user_avatar_store.dart';

/// État de l'écran profil (tous les rôles) et de sa modification.
class ProfileController extends ChangeNotifier {
  ProfileController(this._profiles, this._auth, this._session, this._records, this._dependents, this._avatars);

  final ProfileRepository _profiles;
  final AuthRepository _auth;
  final SessionService _session;
  final MedicalRecordRepository _records;
  final DependentRepository _dependents;
  final UserAvatarStore _avatars;

  UserProfile? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _profiles.load(_session.requireUser);
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre le profil et met à jour la session. Renvoie true si réussi.
  Future<bool> save(UserProfile updated) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final user = await _profiles.save(updated);
      await _session.update(user);
      profile = updated;
      return true;
    } on AppException catch (e) {
      error = e.message;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Photo de profil (null = supprimer). Renvoie null si réussi, sinon le message d'erreur.
  Future<String?> setAvatar(Uint8List? bytes) async {
    try {
      await _avatars.set(_session.requireUser.userId, bytes);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  /// Renvoie null si réussi, sinon le message d'erreur.
  Future<String?> changePassword(String current, String newPassword) => _guard(
    () => _auth.changePassword(userId: _session.requireUser.userId, current: current, newPassword: newPassword),
  );

  /// Supprime définitivement le compte puis ferme la session.
  Future<String?> deleteAccount(String password) async {
    final error = await _guard(() => _auth.deleteAccount(userId: _session.requireUser.userId, password: password));
    if (error == null) await _session.close();
    return error;
  }

  /// Export de toutes les données personnelles au format JSON (droit d'accès).
  Future<String> exportData() async {
    final user = _session.requireUser;
    final p = profile ?? await _profiles.load(user);
    final data = <String, Object?>{
      'exporte_le': DateTime.now().toIso8601String(),
      'compte': {
        'role': p.role.label,
        'prenom': p.prenom,
        'nom': p.nom,
        'email': p.email,
        'telephone': p.phone,
        'cin': p.cin,
        'date_naissance': p.dateNaissance?.toIso8601String().substring(0, 10),
        'adresse': p.address,
        'specialite': p.specialty,
        'numero_professionnel': p.licenseNumber ?? p.agentCode,
        'organisme': p.pharmacyName ?? p.company,
      }..removeWhere((_, v) => v == null),
    };
    final patientId = user.patientId;
    if (patientId != null) {
      final record = await _records.forPatient(patientId);
      data['dossier_medical'] = record.toMap()..remove('patient_id');
      data['vaccins'] = [
        for (final v in await _records.vaccinations(patientId))
          {'nom': v.name, 'date': v.date.toIso8601String().substring(0, 10), 'dose': v.dose},
      ];
      data['documents'] = [
        for (final d in await _records.documents(patientId)) {'titre': d.title, 'categorie': d.category.label},
      ];
      data['proches'] = [
        for (final d in await _dependents.forPatient(patientId))
          {'prenom': d.prenom, 'nom': d.nom, 'lien': d.relation.label},
      ];
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> logout() => _session.close();

  Future<String?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}
