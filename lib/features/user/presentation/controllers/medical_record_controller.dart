import 'package:flutter/foundation.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// État du dossier médical d'un patient (consultation et modification).
class MedicalRecordController extends ChangeNotifier {
  MedicalRecordController(this._repository, this.patientId);

  final MedicalRecordRepository _repository;
  final int patientId;

  MedicalRecord? record;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      record = await _repository.forPatient(patientId);
    } catch (e) {
      debugPrint('[MedicalRecordController] $e');
      error = 'Impossible de charger le dossier médical';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(MedicalRecord updated) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      record = await _repository.save(updated);
      return true;
    } catch (e) {
      debugPrint('[MedicalRecordController] $e');
      error = 'Enregistrement impossible, vérifiez les valeurs saisies';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
