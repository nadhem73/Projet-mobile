import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/account_summary.dart';
import 'package:medilink/features/user/data/repositories/admin_repository.dart';

/// État de l'espace administrateur.
class AdminController extends ChangeNotifier {
  AdminController(this._repository, this._session);

  final AdminRepository _repository;
  final SessionService _session;

  PlatformStats? stats;
  List<AccountSummary> pending = [];
  List<AccountSummary> accounts = [];

  String query = '';
  UserRole? roleFilter;
  String? statusFilter;

  bool isLoading = false;
  String? error;

  /// Tableau de bord : chiffres clés + comptes en attente.
  Future<void> loadDashboard() => _load(() async {
    stats = await _repository.stats();
    pending = await _repository.pendingAccounts();
  });

  /// Liste de tous les comptes avec les filtres courants.
  Future<void> search({
    String? query,
    UserRole? role,
    String? status,
    bool clearRole = false,
    bool clearStatus = false,
  }) {
    if (query != null) this.query = query;
    if (role != null || clearRole) roleFilter = role;
    if (status != null || clearStatus) statusFilter = status;
    return _load(() async {
      accounts = await _repository.accounts(query: this.query, role: roleFilter, status: statusFilter);
    });
  }

  Future<String?> approve(int userId) => _act(() => _repository.approve(userId));

  Future<String?> reject(int userId, String reason) => _act(() => _repository.reject(userId, reason));

  Future<String?> suspend(int userId) =>
      _act(() => _repository.suspend(userId, adminUserId: _session.requireUser.userId));

  Future<String?> reactivate(int userId) => _act(() => _repository.reactivate(userId));

  Future<void> _load(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      debugPrint('[AdminController] $e');
      error = 'Chargement impossible';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Exécute une action puis recharge les données. Renvoie null si réussi.
  Future<String?> _act(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      stats = await _repository.stats();
      pending = await _repository.pendingAccounts();
      accounts = await _repository.accounts(query: query, role: roleFilter, status: statusFilter);
      notifyListeners();
    }
  }
}
