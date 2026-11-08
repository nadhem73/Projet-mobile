import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';

/// Historique des consultations du patient connecté (consultations clôturées,
/// tous médecins confondus) et détail d'une consultation avec ses ordonnances.
class PatientConsultationsController extends ChangeNotifier {
  PatientConsultationsController(this._consultations, this._prescriptions, this._session);

  final ConsultationRepository _consultations;
  final PrescriptionRepository _prescriptions;
  final SessionService _session;

  bool isLoading = false;
  String? error;
  List<Consultation> consultations = [];

  /// Consultation ouverte par [loadDetail] et ses ordonnances.
  Consultation? consultation;
  List<Prescription> prescriptions = [];

  int? get _patientId => _session.requireUser.patientId;

  Future<void> load() => _run(() async {
    final patientId = _patientId;
    consultations = patientId == null ? const [] : await _consultations.forPatient(patientId);
  });

  Future<void> loadDetail(int consultationId) => _run(() async {
    final patientId = _patientId;
    if (patientId == null) throw const AppException('Consultation introuvable.', code: 'not_found');
    consultation = await _consultations.forPatientById(consultationId, patientId: patientId);
    prescriptions = await _prescriptions.forConsultation(consultationId);
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
