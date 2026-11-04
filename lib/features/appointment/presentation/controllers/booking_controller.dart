import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';

/// État de la prise de rendez-vous chez un médecin :
/// fiche du médecin → choix du jour → choix de l'heure → motif → réservation.
class BookingController extends ChangeNotifier {
  BookingController(this._doctors, this._appointments, this._session, this.doctorId, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DoctorSearchRepository _doctors;
  final AppointmentRepository _appointments;
  final SessionService _session;
  final DateTime Function() _clock;
  final int doctorId;

  /// Nombre de jours proposés à partir d'aujourd'hui.
  static const daysAhead = 30;

  DoctorSummary? doctor;

  /// Jours où le médecin consulte, sur les [daysAhead] prochains jours.
  List<DateTime> days = [];
  DateTime? selectedDay;

  /// Heures libres du jour choisi.
  List<DateTime> slots = [];
  DateTime? selectedSlot;
  String reason = '';

  bool isLoading = false; // fiche du médecin
  bool isLoadingSlots = false;
  bool isBooking = false;
  String? error;

  bool get canBook => selectedSlot != null && !isBooking;

  /// Charge le médecin, ses jours de consultation, et les heures du premier jour disponible.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      doctor = await _doctors.byId(doctorId);
      if (doctor == null) {
        error = "Ce médecin n'accepte pas de rendez-vous pour le moment";
        return;
      }
      final today = _clock();
      days =
          [
            for (var i = 0; i < daysAhead; i++) DateTime(today.year, today.month, today.day + i),
          ].where(doctor!.workingHours.isOpenOn).toList();
    } catch (e) {
      debugPrint('[BookingController] $e');
      error = 'Impossible de charger ce médecin';
    } finally {
      isLoading = false;
      notifyListeners();
    }
    if (doctor != null && days.isNotEmpty) await selectDay(days.first);
  }

  Future<void> selectDay(DateTime day) async {
    selectedDay = day;
    selectedSlot = null;
    slots = [];
    isLoadingSlots = true;
    notifyListeners();
    try {
      slots = await _appointments.availableSlots(doctorId, day);
    } catch (e) {
      debugPrint('[BookingController] $e');
    } finally {
      isLoadingSlots = false;
      notifyListeners();
    }
  }

  void selectSlot(DateTime slot) {
    selectedSlot = slot;
    notifyListeners();
  }

  void setReason(String value) => reason = value;

  /// Réserve le créneau choisi. Renvoie le rendez-vous créé, ou null (voir [error]).
  ///
  /// Si le créneau a été pris entre-temps, les heures du jour sont rechargées.
  Future<Appointment?> book() async {
    final slot = selectedSlot;
    if (slot == null) {
      error = 'Choisissez une heure';
      notifyListeners();
      return null;
    }
    isBooking = true;
    error = null;
    notifyListeners();
    try {
      final patientId = _session.requireUser.patientId;
      if (patientId == null) throw const AppException('Seul un patient peut prendre rendez-vous.');
      return await _appointments.book(patientId: patientId, doctorId: doctorId, dateTime: slot, reason: reason);
    } on AppException catch (e) {
      error = e.message;
      if (e.code == 'slot_taken' && selectedDay != null) await selectDay(selectedDay!);
      return null;
    } catch (e) {
      debugPrint('[BookingController] $e');
      error = 'La réservation a échoué, réessayez';
      return null;
    } finally {
      isBooking = false;
      notifyListeners();
    }
  }
}
