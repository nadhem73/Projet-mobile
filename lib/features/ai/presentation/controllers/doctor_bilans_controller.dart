import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';

/// Côté médecin : bilans reçus (liste filtrable, scroll infini).
class DoctorBilansController extends ChangeNotifier {
  DoctorBilansController(this._repository, this._session);

  final BilanRepository _repository;
  final SessionService _session;

  final List<BilanSummary> items = [];
  ReviewStatus? filter;
  int _page = 0;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  int? get _doctorId => _session.requireUser.doctorId;

  Future<void> setFilter(ReviewStatus? value) {
    filter = value;
    return refresh();
  }

  Future<void> refresh() async {
    final doctorId = _doctorId;
    if (doctorId == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _repository.forDoctor(doctorId, status: filter);
      items
        ..clear()
        ..addAll(page.content);
      _page = 0;
      hasMore = !page.isLast;
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final doctorId = _doctorId;
    if (doctorId == null || !hasMore || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.forDoctor(doctorId, status: filter, page: _page + 1);
      _page = page.page;
      items.addAll(page.content);
      hasMore = !page.isLast;
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}

/// Côté médecin : lecture d'un bilan reçu, marqué « Lu » à l'ouverture.
class DoctorBilanController extends ChangeNotifier {
  DoctorBilanController(this._repository, this._session);

  final BilanRepository _repository;
  final SessionService _session;

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  ScanBilan? bilan;

  int get _doctorId {
    final id = _session.requireUser.doctorId;
    if (id == null) throw const AppException('Réservé aux médecins.', code: 'forbidden');
    return id;
  }

  Future<void> load(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      bilan = await _repository.markRead(id, doctorId: _doctorId);
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Renvoie un message d'erreur ou `null`.
  Future<String?> markTreated(String? comment) async {
    isSaving = true;
    notifyListeners();
    try {
      bilan = await _repository.markTreated(bilan!.id, doctorId: _doctorId, comment: comment);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
