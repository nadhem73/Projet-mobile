import 'package:flutter/foundation.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';

/// Liste des consultations du médecin connecté : rendez-vous à démarrer,
/// consultations en cours et terminées.
class ConsultationsController extends ChangeNotifier {
  ConsultationsController(this._repository, this._session);

  final ConsultationRepository _repository;
  final SessionService _session;

  bool isLoading = false;
  bool isStarting = false;
  String? error;
  List<AppointmentToStart> toStart = [];
  List<Consultation> inProgress = [];
  List<Consultation> closed = [];

  int get _doctorId => _session.requireUser.doctorId!;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_repository.appointmentsToStart(_doctorId), _repository.forDoctor(_doctorId)]);
      toStart = results[0] as List<AppointmentToStart>;
      final all = results[1] as List<Consultation>;
      inProgress = all.where((c) => c.status == ConsultationStatus.inProgress).toList();
      closed = all.where((c) => c.status == ConsultationStatus.closed).toList();
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Démarre la consultation d'un rendez-vous et renvoie son identifiant
  /// (null en cas d'erreur, message dans [error]).
  Future<int?> start(AppointmentToStart appointment) async {
    isStarting = true;
    error = null;
    notifyListeners();
    try {
      final consultation = await _repository.start(
        doctorId: _doctorId,
        patientId: appointment.patientId,
        appointmentId: appointment.appointmentId,
      );
      return consultation.id;
    } on AppException catch (e) {
      error = e.message;
      return null;
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }
}
