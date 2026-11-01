import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/user/data/models/registration_data.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';

/// Résultat d'une inscription réussie.
enum RegistrationOutcome {
  /// Compte patient : la session est ouverte.
  signedIn,

  /// Compte professionnel : en attente de validation par un administrateur.
  pendingValidation,
}

/// État des écrans de connexion, d'inscription et de mot de passe oublié.
class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._session);

  final AuthRepository _repository;
  final SessionService _session;

  bool isLoading = false;
  String? error;

  /// Connecte l'utilisateur. Renvoie l'utilisateur ouvert en session, ou null (voir [error]).
  Future<CurrentUser?> login(String email, String password) => _run(() async {
    final user = await _repository.login(email, password);
    await _session.open(user);
    return user;
  });

  Future<RegistrationOutcome?> register(RegistrationData data) => _run(() async {
    final user = await _repository.register(data);
    if (data.role.requiresValidation) return RegistrationOutcome.pendingValidation;
    await _session.open(user);
    return RegistrationOutcome.signedIn;
  });

  Future<ResetCodeDelivery?> requestResetCode({required String email, required String phone}) =>
      _run(() => _repository.requestPasswordReset(email: email, phone: phone));

  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    final done = await _run(() async {
      await _repository.resetPasswordWithCode(email: email, code: code, newPassword: newPassword);
      return true;
    });
    return done ?? false;
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      return await action();
    } on AppException catch (e) {
      error = e.message;
      return null;
    } catch (e) {
      debugPrint('[AuthController] $e');
      error = 'Une erreur inattendue est survenue, réessayez';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
