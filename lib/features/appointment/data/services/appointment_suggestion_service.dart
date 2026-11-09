import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';

/// Un médecin proposé par l'assistant, avec son premier créneau libre.
class DoctorSuggestion {
  const DoctorSuggestion({required this.doctor, required this.firstSlot});

  final DoctorSummary doctor;
  final DateTime firstSlot;
}

/// Médecins proposés suite à une orientation.
class SuggestionResult {
  const SuggestionResult({required this.specialty, required this.suggestions, this.usedFallback = false});

  /// Spécialité réellement utilisée pour la recherche.
  final String specialty;

  /// Du créneau le plus proche au plus lointain.
  final List<DoctorSuggestion> suggestions;

  /// Aucun médecin dans la spécialité conseillée : on propose un généraliste à la place.
  final bool usedFallback;

  static const none = SuggestionResult(specialty: '', suggestions: []);

  bool get isEmpty => suggestions.isEmpty;
  DoctorSuggestion? get best => suggestions.isEmpty ? null : suggestions.first;
}

/// Transforme une orientation (spécialité + urgence) en propositions de rendez-vous concrètes.
class AppointmentSuggestionService {
  AppointmentSuggestionService(this._doctors, this._appointments, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DoctorSearchRepository _doctors;
  final AppointmentRepository _appointments;
  final DateTime Function() _clock;

  /// Fenêtre de recherche d'un créneau selon l'urgence.
  static int daysToSearch(OrientationUrgency urgency) => switch (urgency) {
    OrientationUrgency.soon => 7,
    OrientationUrgency.routine => 30,
    OrientationUrgency.emergency => 0,
  };

  /// Nombre maximum de médecins proposés.
  static const maxSuggestions = 3;

  /// Médecins de la spécialité conseillée avec leur premier créneau libre.
  ///
  /// [city] : si fournie, les médecins de cette ville passent en premier.
  Future<SuggestionResult> suggest(OrientationResult orientation, {String? city}) async {
    if (!orientation.urgency.allowsBooking) return SuggestionResult.none;

    final days = daysToSearch(orientation.urgency);
    var suggestions = await _forSpecialty(orientation.specialty, days, city);
    if (suggestions.isNotEmpty || orientation.specialty == OrientationResult.defaultSpecialty) {
      return SuggestionResult(specialty: orientation.specialty, suggestions: suggestions);
    }

    // Personne dans cette spécialité (ou pas de créneau à temps) : un généraliste peut voir le patient.
    suggestions = await _forSpecialty(OrientationResult.defaultSpecialty, days, city);
    return SuggestionResult(
      specialty: OrientationResult.defaultSpecialty,
      suggestions: suggestions,
      usedFallback: suggestions.isNotEmpty,
    );
  }

  Future<List<DoctorSuggestion>> _forSpecialty(String specialty, int days, String? city) async {
    final doctors = await _doctors.search(specialty: specialty);
    final result = <DoctorSuggestion>[];
    for (final doctor in doctors) {
      final slot = await firstAvailableSlot(doctor.doctorId, days: days);
      if (slot != null) result.add(DoctorSuggestion(doctor: doctor, firstSlot: slot));
    }
    result.sort((a, b) {
      // Même ville d'abord, puis le créneau le plus proche.
      if (city != null) {
        final aHere = a.doctor.city == city;
        final bHere = b.doctor.city == city;
        if (aHere != bHere) return aHere ? -1 : 1;
      }
      return a.firstSlot.compareTo(b.firstSlot);
    });
    return result.take(maxSuggestions).toList();
  }

  /// Premier créneau libre du médecin dans les [days] prochains jours (aujourd'hui compris), ou null.
  ///
  /// [after] : ne garder que les créneaux strictement après cette heure (« un autre créneau »).
  Future<DateTime?> firstAvailableSlot(int doctorId, {required int days, DateTime? after}) async {
    final today = _clock();
    for (var i = 0; i < days; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final slots = await _appointments.availableSlots(doctorId, day);
      for (final slot in slots) {
        if (after == null || slot.isAfter(after)) return slot;
      }
    }
    return null;
  }
}
