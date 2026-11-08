import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';

/// État de l'écran « Mes rendez-vous » (onglets À venir / Passés).
///
/// Se recharge tout seul quand un rendez-vous est pris ou annulé ailleurs
/// dans l'application (ex. réservation lancée depuis l'accueil).
class MyAppointmentsController extends ChangeNotifier {
  MyAppointmentsController(this._repository, this._session) {
    _repository.changes.addListener(_onRepositoryChanged);
  }

  final AppointmentRepository _repository;
  final SessionService _session;

  List<Appointment> upcoming = [];
  List<Appointment> past = [];
  bool isLoading = false;
  String? error;

  Future<void>? _loading;

  int get _patientId {
    final id = _session.requireUser.patientId;
    if (id == null) throw const AppException('Seul un patient peut consulter ses rendez-vous.');
    return id;
  }

  void _onRepositoryChanged() => load();

  /// Charge les deux listes. Un appel pendant un chargement en cours réutilise ce chargement.
  Future<void> load() => _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final patientId = _patientId;
      upcoming = await _repository.upcomingForPatient(patientId);
      past = await _repository.pastForPatient(patientId);
    } on AppException catch (e) {
      error = e.message;
    } catch (e) {
      debugPrint('[MyAppointmentsController] $e');
      error = 'Impossible de charger vos rendez-vous';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Annule puis recharge les listes. Renvoie null si réussi, sinon le message d'erreur.
  Future<String?> cancel(int appointmentId) async {
    try {
      await _repository.cancel(appointmentId: appointmentId, patientId: _patientId);
      await load();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  @override
  void dispose() {
    _repository.changes.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
