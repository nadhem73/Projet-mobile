import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';

/// État de l'écran « Détail d'un rendez-vous » (avec bouton Annuler).
class AppointmentDetailController extends ChangeNotifier {
  AppointmentDetailController(this._repository, this._doctors, this._session, this.appointmentId);

  final AppointmentRepository _repository;
  final DoctorSearchRepository _doctors;
  final SessionService _session;
  final int appointmentId;

  Appointment? appointment;

  /// Fiche du médecin (adresse, tarif). Peut être null si son compte n'est plus actif.
  DoctorSummary? doctor;
  bool isLoading = false;
  bool isCancelling = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final found = await _repository.byId(appointmentId);
      // Un patient ne voit que ses propres rendez-vous.
      if (found == null || found.patientId != _session.requireUser.patientId) {
        appointment = null;
        error = 'Rendez-vous introuvable';
      } else {
        appointment = found;
        doctor = await _doctors.byId(found.doctorId);
      }
    } catch (e) {
      debugPrint('[AppointmentDetailController] $e');
      error = 'Impossible de charger ce rendez-vous';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Renvoie null si l'annulation a réussi, sinon le message d'erreur.
  Future<String?> cancel() async {
    final patientId = _session.requireUser.patientId;
    if (patientId == null) return 'Seul un patient peut annuler un rendez-vous.';
    isCancelling = true;
    notifyListeners();
    try {
      await _repository.cancel(appointmentId: appointmentId, patientId: patientId);
      appointment = await _repository.byId(appointmentId);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isCancelling = false;
      notifyListeners();
    }
  }
}
