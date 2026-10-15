import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session de l'utilisateur connecté.
///
/// Source de vérité unique pour savoir QUI est connecté. Tous les modules
/// lisent `getIt<SessionService>().currentUser` (ex. pour filtrer les
/// rendez-vous du patient courant). Seul le module User appelle [open] et
/// [close].
///
/// C'est un [ChangeNotifier] : le routeur l'écoute pour rediriger
/// automatiquement vers la connexion après une déconnexion.
class SessionService extends ChangeNotifier {
  SessionService(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'medilink.session';
  static const String _onboardingKey = 'medilink.onboarding_done';

  CurrentUser? _currentUser;

  CurrentUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Le patient/médecin connecté. À n'utiliser que sur des écrans protégés.
  CurrentUser get requireUser {
    final user = _currentUser;
    if (user == null) throw StateError('Aucun utilisateur connecté');
    return user;
  }

  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> markOnboardingDone() => _prefs.setBool(_onboardingKey, true);

  /// Restaure la session au démarrage de l'application.
  void restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      _currentUser = CurrentUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _prefs.remove(_key);
    }
  }

  Future<void> open(CurrentUser user) async {
    _currentUser = user;
    await _prefs.setString(_key, jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// Met à jour les infos affichées (après modification du profil).
  Future<void> update(CurrentUser user) => open(user);

  Future<void> close() async {
    _currentUser = null;
    await _prefs.remove(_key);
    notifyListeners();
  }
}
