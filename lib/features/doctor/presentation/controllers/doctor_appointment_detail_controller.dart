import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// Détail d'un rendez-vous vu par le médecin : patient, créneau, motif,
/// résumé santé et consultation éventuellement liée.
class DoctorAppointmentDetailController extends ChangeNotifier {
  DoctorAppointmentDetailController(this._appointments, this._consultations, this._records, this._session);

  final AppointmentRepository _appointments;
  final ConsultationRepository _consultations;
  final MedicalRecordRepository _records;
  final SessionService _session;

  bool isLoading = false;
  bool isStarting = false;
  String? error;

  Appointment? appointment;
  PatientIdentity? patient;
  MedicalRecord? record;

  /// Consultation déjà démarrée pour ce rendez-vous (null sinon).
  Consultation? consultation;

  int get _doctorId => _session.requireUser.doctorId!;

  Future<void> load(int appointmentId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final found = await _appointments.byId(appointmentId);
      // Un médecin ne voit que les rendez-vous pris chez lui.
      if (found == null || found.doctorId != _doctorId) {
        appointment = null;
        error = 'Rendez-vous introuvable';
        return;
      }
      appointment = found;
      final results = await Future.wait([
        _records.identity(found.patientId),
        _records.forPatient(found.patientId),
        _consultations.forAppointment(appointmentId, doctorId: _doctorId),
      ]);
      patient = results[0] as PatientIdentity;
      record = results[1] as MedicalRecord;
      consultation = results[2] as Consultation?;
    } on AppException catch (e) {
      error = e.message;
    } catch (e) {
      debugPrint('[DoctorAppointmentDetailController] $e');
      error = 'Impossible de charger ce rendez-vous';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Démarre (ou retrouve) la consultation du rendez-vous et renvoie son identifiant.
  /// Renvoie null en cas d'erreur (message dans [error]).
  Future<int?> startConsultation() async {
    final a = appointment;
    if (a == null) return null;
    isStarting = true;
    error = null;
    notifyListeners();
    try {
      final c = await _consultations.start(doctorId: _doctorId, patientId: a.patientId, appointmentId: a.id);
      consultation = c;
      return c.id;
    } on AppException catch (e) {
      error = e.message;
      return null;
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }
}
