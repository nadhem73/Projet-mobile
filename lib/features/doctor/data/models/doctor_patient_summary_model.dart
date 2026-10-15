class MLDoctorPatientSummaryData {
  String? id;
  String? name;
  String? dob;
  String? age;
  String? gender;
  String? phone;
  String? email;
  String? lastVisit;
  String? nextAppointment;
  List<String>? conditions;
  List<String>? activeMedications;
  String? avatar;

  MLDoctorPatientSummaryData({
    this.id,
    this.name,
    this.dob,
    this.age,
    this.gender,
    this.phone,
    this.email,
    this.lastVisit,
    this.nextAppointment,
    this.conditions,
    this.activeMedications,
    this.avatar,
  });
}