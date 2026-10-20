import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// État du dossier médical du patient connecté : fiche, vaccins, documents,
/// historique des accès.
class MedicalRecordController extends ChangeNotifier {
  MedicalRecordController(this._repository, this._access, this.patientId);

  final MedicalRecordRepository _repository;
  final MedicalAccessRepository _access;
  final int patientId;

  MedicalRecord? record;
  PatientIdentity? identity;
  List<Vaccination> vaccinations = [];
  List<MedicalDocument> documents = [];
  List<RecordAccess> accessLog = [];

  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      record = await _repository.forPatient(patientId);
      identity = await _repository.identity(patientId);
      vaccinations = await _repository.vaccinations(patientId);
      documents = await _repository.documents(patientId);
      accessLog = await _access.accessLog(patientId);
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

  /// Renvoie null si réussi, sinon le message d'erreur.
  Future<String?> saveVaccination(Vaccination vaccination) => _mutate(() async {
    await _repository.saveVaccination(vaccination);
    vaccinations = await _repository.vaccinations(patientId);
  });

  Future<String?> deleteVaccination(int id) => _mutate(() async {
    await _repository.deleteVaccination(patientId: patientId, vaccinationId: id);
    vaccinations = await _repository.vaccinations(patientId);
  });

  Future<String?> addDocument(String title, DocumentCategory category, Uint8List data) => _mutate(() async {
    await _repository.addDocument(patientId: patientId, title: title, category: category, data: data);
    documents = await _repository.documents(patientId);
  });

  Future<String?> deleteDocument(int id) => _mutate(() async {
    await _repository.deleteDocument(patientId: patientId, documentId: id);
    documents = await _repository.documents(patientId);
  });

  Future<String?> _mutate(Future<void> Function() action) async {
    try {
      await action();
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[MedicalRecordController] $e');
      return 'Opération impossible, réessayez';
    }
  }
}
