import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/medicament.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/medicament_api.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';

/// Rédaction d'une ordonnance pour une consultation en cours.
class PrescriptionEditorController extends ChangeNotifier {
  PrescriptionEditorController(this._consultations, this._prescriptions, this._medicaments, this._session);

  final ConsultationRepository _consultations;
  final PrescriptionRepository _prescriptions;
  final MedicamentApi _medicaments;
  final SessionService _session;

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  Consultation? consultation;

  /// Lignes de l'ordonnance en cours de rédaction.
  final List<PrescriptionItem> items = [];

  /// Alertes allergies pour les lignes actuelles.
  List<String> warnings = [];

  // Recherche de médicaments
  bool isSearching = false;
  bool apiOffline = false;
  List<Medicament> results = [];
  int _searchId = 0;

  int get _doctorId => _session.requireUser.doctorId!;

  Future<void> load(int consultationId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final c = await _consultations.byId(consultationId, doctorId: _doctorId);
      if (c.isClosed) {
        throw const AppException('La consultation est clôturée : impossible d\'ajouter une ordonnance.');
      }
      consultation = c;
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final id = ++_searchId;
    if (query.trim().length < 2) {
      results = [];
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    try {
      final found = await _medicaments.search(query);
      if (id != _searchId) return; // une recherche plus récente a été lancée
      results = found;
      apiOffline = false;
    } on AppException {
      if (id != _searchId) return;
      results = [];
      apiOffline = true;
    }
    isSearching = false;
    notifyListeners();
  }

  void clearResults() {
    _searchId++;
    results = [];
    isSearching = false;
    notifyListeners();
  }

  Future<void> addItem(PrescriptionItem item) async {
    items.add(item);
    await _refreshWarnings();
  }

  Future<void> replaceItem(int index, PrescriptionItem item) async {
    items[index] = item;
    await _refreshWarnings();
  }

  Future<void> removeItem(int index) async {
    items.removeAt(index);
    await _refreshWarnings();
  }

  /// Enregistre l'ordonnance. Renvoie le message d'erreur, ou null si tout va bien.
  Future<String?> submit({String? note}) async {
    final c = consultation;
    if (c == null) return 'Consultation introuvable.';
    isSaving = true;
    notifyListeners();
    try {
      await _prescriptions.create(consultationId: c.id, doctorId: _doctorId, items: List.of(items), note: note);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _refreshWarnings() async {
    final c = consultation;
    warnings = c == null ? [] : await _prescriptions.allergyWarnings(c.patientId, items);
    notifyListeners();
  }
}
