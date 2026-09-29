import 'package:medilab_prokit/features/appointment/data/appointment_model.dart';
import 'package:medilab_prokit/features/patient/data/lab_scan_model.dart';
import 'package:medilab_prokit/features/patient/data/prescription_model.dart';

class MLDoctorMedicalRecordData {
  String? patientId;
  String? patientName;
  String? patientAge;
  String? patientGender;
  String? bloodType;
  Map<String, String>? vitals;
  List<String>? medicalHistory;
  List<String>? allergies;
  List<String>? currentMedications;
  List<String>? documents;
  List<MLAppointmentData>? consultationHistory;
  List<MLLabScanData>? labResults;
  List<MLPrescriptionData>? prescriptions;

  MLDoctorMedicalRecordData({
    this.patientId,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.bloodType,
    this.vitals,
    this.medicalHistory,
    this.allergies,
    this.currentMedications,
    this.documents,
    this.consultationHistory,
    this.labResults,
    this.prescriptions,
  });
}