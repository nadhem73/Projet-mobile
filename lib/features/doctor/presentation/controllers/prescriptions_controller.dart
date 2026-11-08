import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';

/// Liste des ordonnances de l'utilisateur connecté : celles reçues (patient)
/// ou rédigées (médecin).
class PrescriptionsController extends ChangeNotifier {
  PrescriptionsController(this._repository, this._session);

  final PrescriptionRepository _repository;
  final SessionService _session;

  bool isLoading = false;
  String? error;
  List<Prescription> prescriptions = [];

  bool get isDoctor => _session.requireUser.isDoctor;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final user = _session.requireUser;
      prescriptions = switch ((user.patientId, user.doctorId)) {
        (final int patientId, _) => await _repository.forPatient(patientId),
        (_, final int doctorId) => await _repository.forDoctor(doctorId),
        _ => const [],
      };
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
