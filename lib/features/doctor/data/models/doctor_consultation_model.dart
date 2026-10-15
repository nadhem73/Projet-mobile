class MLDoctorConsultationData {
  String? id;
  String? patientId;
  String? patientName;
  String? patientAge;
  String? patientGender;
  String? date;
  String? time;
  String? type;
  String? status;
  String? chiefComplaint;
  String? diagnosis;
  String? notes;
  String? prescriptionId;
  List<String>? vitals;

  MLDoctorConsultationData({
    this.id,
    this.patientId,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.date,
    this.time,
    this.type,
    this.status,
    this.chiefComplaint,
    this.diagnosis,
    this.notes,
    this.prescriptionId,
    this.vitals,
  });
}