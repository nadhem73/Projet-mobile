import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/user/data/models/user_profile.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';

/// État de l'écran profil (tous les rôles) et de sa modification.
class ProfileController extends ChangeNotifier {
  ProfileController(this._profiles, this._auth, this._session);

  final ProfileRepository _profiles;
  final AuthRepository _auth;
  final SessionService _session;

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

  /// Renvoie null si réussi, sinon le message d'erreur.
  Future<String?> changePassword(String current, String newPassword) async {
    try {
      await _auth.changePassword(userId: _session.requireUser.userId, current: current, newPassword: newPassword);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() => _session.close();
}
