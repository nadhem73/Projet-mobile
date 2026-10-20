import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/user/data/models/dependent.dart';
import 'package:medilink/features/user/data/repositories/dependent_repository.dart';

/// État de l'écran « Mes proches ».
class DependentsController extends ChangeNotifier {
  DependentsController(this._repository, this.patientId);

  final DependentRepository _repository;
  final int patientId;

  List<Dependent> dependents = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      dependents = await _repository.forPatient(patientId);
    } catch (e) {
      debugPrint('[DependentsController] $e');
      error = 'Impossible de charger vos proches';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Renvoie null si réussi, sinon le message d'erreur.
  Future<String?> save(Dependent dependent) => _mutate(() => _repository.save(dependent));

  Future<String?> delete(int dependentId) =>
      _mutate(() => _repository.delete(patientId: patientId, dependentId: dependentId));

  Future<String?> _mutate(Future<void> Function() action) async {
    try {
      await action();
      dependents = await _repository.forPatient(patientId);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}
