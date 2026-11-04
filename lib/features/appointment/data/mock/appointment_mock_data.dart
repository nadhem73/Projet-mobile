// Données fictives du module appointment.
// À remplacer progressivement par les données SQLite (repositories du module).
import 'package:medilink/features/appointment/presentation/widgets/clinic_visit_card.dart';
import 'package:medilink/features/appointment/presentation/widgets/confirmation_dialog.dart';
import 'package:medilink/features/appointment/presentation/widgets/doctor_list.dart';
import 'package:medilink/features/user/presentation/widgets/patient_selector.dart';
import 'package:medilink/features/appointment/data/models/appointment_model.dart';
import 'package:medilink/features/appointment/data/models/book_appointment_model.dart';
import 'package:medilink/features/appointment/data/models/doctor_model.dart';
import 'package:medilink/core/utils/app_assets.dart';

List<MLBookAppointmentData> mlBookAppointmentDataList() {
  List<MLBookAppointmentData> list = [];
  list.add(MLBookAppointmentData(id: '1', title: 'Select Service', widget: MLClinicVisitComponent(), progress: 0.2));
  list.add(MLBookAppointmentData(id: '2', title: 'Choose Doctor', widget: MLDoctorListComponent(), progress: 0.5));
  list.add(MLBookAppointmentData(id: '3', title: 'Choose Patient', widget: MLPatientComponent(), progress: 0.75));
  list.add(
    MLBookAppointmentData(
      id: '4',
      title: 'Confirm Appointment',
      widget: MLConfirmAppointmentComponent(),
      progress: 1.0,
    ),
  );
  return list;
}

List<MLDoctorData> mlDoctorListDataList() {
  List<MLDoctorData> list = [];
  list.add(
    MLDoctorData(
      title: 'Dr. Edward Jenner',
      subtitle: 'Endocrinology',
      image: mlIcDoctorImage,
      rating: '4.8',
      fees: '\$450',
    ),
  );
  list.add(
    MLDoctorData(
      title: 'Dr. Edward Jenner',
      subtitle: 'Endocrinology',
      image: mlIcDoctorImage,
      rating: '4.8',
      fees: '\$450',
    ),
  );
  list.add(
    MLDoctorData(
      title: 'Dr. Edward Jenner',
      subtitle: 'Endocrinology',
      image: mlIcDoctorImage,
      rating: '4.8',
      fees: '\$450',
    ),
  );
  list.add(
    MLDoctorData(
      title: 'Dr. Edward Jenner',
      subtitle: 'Endocrinology',
      image: mlIcDoctorImage,
      rating: '4.8',
      fees: '\$450',
    ),
  );
  list.add(
    MLDoctorData(
      title: 'Dr. Edward Jenner',
      subtitle: 'Endocrinology',
      image: mlIcDoctorImage,
      rating: '4.8',
      fees: '\$450',
    ),
  );
  list.add(
    MLDoctorData(
      title: 'Dr. Edward Jenner',
      subtitle: 'Endocrinology',
      image: mlIcDoctorImage,
      rating: '4.8',
      fees: '\$450',
    ),
  );
  return list;
}

List<String?> mlScheduleTimeList() {
  List<String?> list = [];
  list.add('8:00 AM - 9:00 AM');
  list.add('9:00 AM - 10:00 AM');
  list.add('10:00 AM - 11:00 AM');
  list.add('11:00 AM - 12:00 AM');
  list.add('1:00 AM - 2:00 AM');
  list.add('2:00 AM - 3:00 AM');
  list.add('3:00 AM - 4:00 AM');
  list.add('4:00 AM - 5:00 AM');
  return list;
}

List<MLAppointmentData> mlAppointmentDataList() {
  List<MLAppointmentData> list = [];
  list.add(
    MLAppointmentData(
      date: '10',
      month: 'october',
      doctor: 'Dr. Stephen Chew',
      department: 'General Care',
      patient: 'Kaixa Pham',
      service: 'Clinic Visit',
    ),
  );
  list.add(
    MLAppointmentData(
      date: '12',
      month: 'September',
      doctor: 'Dr. Stephen Chew',
      department: 'Pediatric',
      patient: 'Kaixa Pham ',
      service: 'Home Visit',
    ),
  );
  list.add(
    MLAppointmentData(
      date: '10',
      month: 'october',
      doctor: 'Dr. Stephen Chew',
      department: 'General Care',
      patient: 'Kaixa Pham ',
      service: 'Video Consult',
    ),
  );
  list.add(
    MLAppointmentData(
      date: '12',
      month: 'September',
      doctor: 'Dr. Stephen Chew',
      department: 'Pediatric',
      patient: 'Kaixa Pham ',
      service: 'Home Visit',
    ),
  );
  list.add(
    MLAppointmentData(
      date: '10',
      month: 'october',
      doctor: 'Dr. Stephen Chew',
      department: 'General Care',
      patient: 'Kaixa Pham ',
      service: 'Clinic Visit',
    ),
  );
  return list;
}
