import 'package:flutter/foundation.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';

/// État de l'écran « Trouver un médecin » : recherche + filtres spécialité / ville.
class DoctorSearchController extends ChangeNotifier {
  DoctorSearchController(this._repository);

  final DoctorSearchRepository _repository;

  List<DoctorSummary> doctors = [];
  List<String> specialties = [];
  List<String> cities = [];

  String query = '';
  String? specialty;
  String? city;

  bool isLoading = false;
  String? error;

  /// Premier chargement : listes des filtres + tous les médecins.
  /// [specialty] permet d'arriver sur l'écran déjà filtré (ex. depuis une tuile « Cardiologie »).
  Future<void> load({String? specialty}) async {
    this.specialty = specialty;
    await _run(() async {
      specialties = await _repository.specialties();
      cities = await _repository.cities();
      await _search();
    });
  }

  /// Relance la recherche. Les paramètres non fournis gardent leur valeur ;
  /// `clearSpecialty` / `clearCity` retirent le filtre correspondant.
  Future<void> search({
    String? query,
    String? specialty,
    String? city,
    bool clearSpecialty = false,
    bool clearCity = false,
  }) {
    if (query != null) this.query = query;
    if (specialty != null || clearSpecialty) this.specialty = specialty;
    if (city != null || clearCity) this.city = city;
    return _run(_search);
  }

  bool get hasFilters => query.trim().isNotEmpty || specialty != null || city != null;

  Future<void> clearFilters() {
    query = '';
    specialty = null;
    city = null;
    return _run(_search);
  }

  Future<void> _search() async {
    doctors = await _repository.search(query: query, specialty: specialty, city: city);
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      debugPrint('[DoctorSearchController] $e');
      error = 'Impossible de charger les médecins';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
