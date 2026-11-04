import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/data/repositories/bilan_api.dart';
import 'package:medilink/features/ai/data/repositories/bilan_image_store.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';

/// Historique paginé des bilans + renvoi au serveur des bilans analysés hors-ligne.
class BilanHistoryController extends ChangeNotifier {
  BilanHistoryController(this._repository, this._api, this._images, this._session, {Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final BilanRepository _repository;
  final BilanApi _api;
  final BilanImageStore _images;
  final SessionService _session;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final List<BilanSummary> items = [];
  int _page = 0;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  /// Bilans analysés hors-ligne en attente d'envoi.
  int pendingSync = 0;
  bool isOnline = false;
  bool isSyncing = false;

  /// Le bandeau « Renvoyer au serveur » n'a de sens que si le scan serveur est configuré.
  bool get canSync => _api.isEnabled && isOnline && pendingSync > 0;

  int? get _patientId => _session.requireUser.patientId;

  /// Premier chargement + écoute du retour du réseau.
  Future<void> start() async {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
    final current = await _connectivity.checkConnectivity();
    isOnline = current.any((r) => r != ConnectivityResult.none);
    await refresh();
  }

  Future<void> refresh() async {
    final patientId = _patientId;
    if (patientId == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _repository.page(patientId);
      items
        ..clear()
        ..addAll(page.content);
      _page = 0;
      hasMore = !page.isLast;
      pendingSync = (await _repository.unsynced(patientId)).length;
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Scroll infini : charge la page suivante.
  Future<void> loadMore() async {
    final patientId = _patientId;
    if (patientId == null || !hasMore || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.page(patientId, page: _page + 1);
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

  /// Supprime un bilan. Renvoie un message d'erreur ou `null`.
  Future<String?> delete(String id) async {
    final patientId = _patientId;
    if (patientId == null) return 'Bilan introuvable.';
    try {
      final bilan = await _repository.byId(id, patientId: patientId);
      await _repository.delete(id, patientId: patientId);
      await _images.remove(bilan.imagePath);
      items.removeWhere((b) => b.id == id);
      if (!bilan.synced) pendingSync--;
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  /// Renvoie à `/api/bilans/scan` les photos des bilans analysés hors-ligne.
  /// Renvoie le nombre de bilans synchronisés.
  Future<int> syncPending() async {
    final patientId = _patientId;
    if (patientId == null || !canSync) return 0;
    isSyncing = true;
    notifyListeners();
    var done = 0;
    try {
      for (final local in await _repository.unsynced(patientId)) {
        final image = local.imagePath;
        if (image == null || !File(image).existsSync()) continue;
        try {
          final server = await _api.scan(image);
          await _repository.replaceWithServer(
            local.id,
            server.copyWith(patientId: patientId, imagePath: image),
            patientId: patientId,
          );
          done++;
        } on AppException catch (e) {
          if (e.code == 'offline' || e.code == 'timeout') break;
        }
      }
    } finally {
      isSyncing = false;
    }
    await refresh();
    return done;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
