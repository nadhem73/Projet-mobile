import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/ai/data/models/evolution_point.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';

/// Courbe d'un test sur les bilans confirmés.
class BilanEvolutionController extends ChangeNotifier {
  BilanEvolutionController(this._repository, this._session);

  final BilanRepository _repository;
  final SessionService _session;

  bool isLoading = false;
  String? error;
  List<String> tests = const [];
  String? selected;
  List<EvolutionPoint> points = const [];

  int? get _patientId => _session.requireUser.patientId;

  Future<void> load({String? initialTest}) async {
    final patientId = _patientId;
    if (patientId == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      tests = await _repository.trackedTests(patientId);
      selected = tests.contains(initialTest) ? initialTest : (tests.isEmpty ? null : tests.first);
      points = selected == null ? const [] : await _repository.evolution(patientId, selected!);
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> select(String test) async {
    final patientId = _patientId;
    if (patientId == null) return;
    selected = test;
    points = await _repository.evolution(patientId, test);
    notifyListeners();
  }
}
