import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';

/// Bilans scannés d'un patient, consultés par un médecin depuis le dossier médical.
///
/// Même règle d'accès que le dossier : le patient doit avoir (eu) un rendez-vous
/// avec ce médecin. Lecture seule : ouvrir un bilan ici ne change pas son
/// statut de revue (« Bilans reçus » reste le circuit d'envoi patient → médecin).
class PatientRecordBilansController extends ChangeNotifier {
  PatientRecordBilansController(this._repository, this._access, this._session);

  final BilanRepository _repository;
  final MedicalAccessRepository _access;
  final SessionService _session;

  bool isLoading = false;
  String? error;
  List<BilanSummary> bilans = [];
  ScanBilan? bilan;

  /// Médecin connecté (null si ce n'est pas un médecin).
  int? get doctorId => _session.currentUser?.doctorId;

  Future<void> _checkAccess(int patientId) async {
    final id = doctorId;
    if (id == null || !await _access.canAccess(doctorId: id, patientId: patientId)) {
      throw const AppException('Accès refusé : ce patient n\'a pas de rendez-vous avec vous.', code: 'forbidden');
    }
  }

  /// Liste des bilans validés du patient.
  Future<void> loadList(int patientId) => _run(() async {
    await _checkAccess(patientId);
    bilans = await _repository.confirmedForPatient(patientId);
  });

  /// Un bilan avec ses résultats.
  Future<void> loadOne(int patientId, String bilanId) => _run(() async {
    await _checkAccess(patientId);
    bilan = await _repository.byIdForPatientRecord(bilanId, patientId: patientId);
  });

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
