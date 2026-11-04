import 'package:flutter/material.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';

/// État de l'agenda du médecin : une semaine (lundi → dimanche), un jour sélectionné,
/// et les rendez-vous de ce jour.
class DoctorAgendaController extends ChangeNotifier {
  DoctorAgendaController(this._repository, this._session, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    selectedDay = DateUtils.dateOnly(_clock());
    weekStart = mondayOf(selectedDay);
    _repository.changes.addListener(_onRepositoryChanged);
  }

  final AppointmentRepository _repository;
  final SessionService _session;
  final DateTime Function() _clock;

  /// Lundi de la semaine affichée.
  late DateTime weekStart;
  late DateTime selectedDay;

  /// Tous les rendez-vous de la semaine affichée.
  List<Appointment> weekAppointments = [];
  bool isLoading = false;
  String? error;

  static DateTime mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  /// Les 7 jours de la semaine affichée.
  List<DateTime> get weekDays => [for (var i = 0; i < 7; i++) DateUtils.addDaysToDate(weekStart, i)];

  DateTime get today => DateUtils.dateOnly(_clock());

  /// Rendez-vous du jour sélectionné.
  List<Appointment> get dayAppointments => appointmentsOn(selectedDay);

  List<Appointment> appointmentsOn(DateTime day) =>
      weekAppointments.where((a) => DateUtils.isSameDay(a.dateTime, day)).toList();

  int countOn(DateTime day) => weekAppointments.where((a) => DateUtils.isSameDay(a.dateTime, day)).length;

  int get _doctorId {
    final id = _session.requireUser.doctorId;
    if (id == null) throw const AppException('Seul un médecin peut consulter cet agenda.');
    return id;
  }

  void _onRepositoryChanged() => load();

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      weekAppointments = await _repository.forDoctorBetween(
        _doctorId,
        weekStart,
        DateUtils.addDaysToDate(weekStart, 7),
      );
    } on AppException catch (e) {
      error = e.message;
    } catch (e) {
      debugPrint('[DoctorAgendaController] $e');
      error = "Impossible de charger l'agenda";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Choisit un jour de la semaine affichée.
  void selectDay(DateTime day) {
    selectedDay = DateUtils.dateOnly(day);
    notifyListeners();
  }

  /// Semaine précédente / suivante : on garde le même jour de la semaine.
  Future<void> previousWeek() => _goTo(DateUtils.addDaysToDate(selectedDay, -7));

  Future<void> nextWeek() => _goTo(DateUtils.addDaysToDate(selectedDay, 7));

  Future<void> goToToday() => _goTo(today);

  Future<void> _goTo(DateTime day) {
    selectedDay = DateUtils.dateOnly(day);
    weekStart = mondayOf(selectedDay);
    return load();
  }

  @override
  void dispose() {
    _repository.changes.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
