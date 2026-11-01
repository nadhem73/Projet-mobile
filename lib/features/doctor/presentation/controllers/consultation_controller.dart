import 'package:flutter/foundation.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// Écran d'une consultation : saisie clinique, ordonnances, clôture.
class ConsultationController extends ChangeNotifier {
  ConsultationController(this._consultations, this._prescriptions, this._records, this._session);

  final ConsultationRepository _consultations;
  final PrescriptionRepository _prescriptions;
  final MedicalRecordRepository _records;
  final SessionService _session;

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  Consultation? consultation;
  List<Prescription> prescriptions = [];

  /// Dossier du patient (allergies, traitements) affiché en tête d'écran.
  MedicalRecord? record;

  int get _doctorId => _session.requireUser.doctorId!;

  Future<void> load(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final c = await _consultations.byId(id, doctorId: _doctorId);
      consultation = c;
      prescriptions = await _prescriptions.forConsultation(id);
      record = await _records.forPatient(c.patientId);
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge uniquement les ordonnances (retour de l'éditeur).
  Future<void> refreshPrescriptions() async {
    final c = consultation;
    if (c == null) return;
    prescriptions = await _prescriptions.forConsultation(c.id);
    notifyListeners();
  }

  /// Enregistre la saisie. Renvoie le message d'erreur, ou null si tout va bien.
  Future<String?> save({String? motif, String? diagnostic, String? observation, required VitalSigns vitals}) => _run(
    () => _consultations.saveClinical(
      consultation!.id,
      doctorId: _doctorId,
      motif: motif,
      diagnostic: diagnostic,
      observation: observation,
      vitals: vitals,
    ),
  );

  /// Enregistre la saisie puis clôture la consultation.
  Future<String?> saveAndClose({
    String? motif,
    String? diagnostic,
    String? observation,
    required VitalSigns vitals,
    DateTime? followUpDate,
  }) async {
    final saveError = await save(motif: motif, diagnostic: diagnostic, observation: observation, vitals: vitals);
    if (saveError != null) return saveError;
    return _run(() => _consultations.close(consultation!.id, doctorId: _doctorId, followUpDate: followUpDate));
  }

  Future<String?> deletePrescription(Prescription prescription) async {
    try {
      await _prescriptions.delete(prescription.id, doctorId: _doctorId);
      await refreshPrescriptions();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> _run(Future<Consultation> Function() action) async {
    isSaving = true;
    notifyListeners();
    try {
      consultation = await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
