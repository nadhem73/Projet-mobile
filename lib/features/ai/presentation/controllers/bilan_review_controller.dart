import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/ai/data/models/doctor_option.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/data/ocr/lab_test_dictionary.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';
import 'package:medilink/features/ai/data/repositories/doctor_directory.dart';

/// Revue / détail d'un bilan : correction des valeurs, validation, envoi à un médecin.
class BilanReviewController extends ChangeNotifier {
  BilanReviewController(this._repository, this._doctors, this._session);

  final BilanRepository _repository;
  final DoctorDirectory _doctors;
  final SessionService _session;

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  ScanBilan? bilan;

  List<DoctorOption> _allDoctors = const [];
  String doctorQuery = '';
  bool isLoadingDoctors = false;

  bool get isReadOnly => bilan?.isConfirmed ?? true;

  int get _patientId {
    final id = _session.requireUser.patientId;
    if (id == null) throw const AppException('Réservé aux patients.', code: 'forbidden');
    return id;
  }

  String get _patientName => _session.requireUser.fullName;

  Future<void> load(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      bilan = await _repository.byId(id, patientId: _patientId);
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Corrige une valeur. Renvoie un message d'erreur, ou `null` si c'est enregistré.
  Future<String?> editResult(int resultId, {required String valeur, String? valeurAncienne}) {
    if (valeur.trim().isEmpty) return Future.value('La valeur est obligatoire.');
    return _save(
      () => _repository.updateResult(
        bilan!.id,
        resultId,
        patientId: _patientId,
        valeur: valeur,
        valeurAncienne: valeurAncienne,
      ),
    );
  }

  Future<String?> confirm() => _save(() => _repository.confirm(bilan!.id, patientId: _patientId));

  /// Valide les valeurs corrigées puis envoie le bilan au médecin choisi.
  Future<String?> confirmAndSend(DoctorOption doctor) => _save(() async {
    final current = bilan!;
    if (!current.isConfirmed) await _repository.confirm(current.id, patientId: _patientId);
    return _repository.assignDoctor(current.id, patientId: _patientId, doctor: doctor, patientName: _patientName);
  });

  Future<String?> assign(DoctorOption doctor) => _save(
    () => _repository.assignDoctor(bilan!.id, patientId: _patientId, doctor: doctor, patientName: _patientName),
  );

  Future<String?> _save(Future<ScanBilan> Function() action) async {
    isSaving = true;
    notifyListeners();
    try {
      bilan = await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Médecins
  // ---------------------------------------------------------------------------

  Future<void> loadDoctors() async {
    if (_allDoctors.isNotEmpty) return;
    isLoadingDoctors = true;
    notifyListeners();
    try {
      _allDoctors = await _doctors.all();
    } finally {
      isLoadingDoctors = false;
      notifyListeners();
    }
  }

  void filterDoctors(String query) {
    doctorQuery = query;
    notifyListeners();
  }

  /// Médecins dont le nom ou la spécialité contient la recherche (sans accents).
  List<DoctorOption> get doctors {
    final q = normalizeLabel(doctorQuery);
    if (q.isEmpty) return _allDoctors;
    return _allDoctors
        .where((d) => normalizeLabel('${d.firstName} ${d.lastName} ${d.specialty ?? ''}').contains(q))
        .toList();
  }
}
