import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/features/appointment/presentation/components/clinic_visit_card.dart';
import 'package:medilab_prokit/features/appointment/presentation/components/confirmation_dialog.dart';
import 'package:medilab_prokit/features/doctor/presentation/components/doctor_list.dart';
import 'package:medilab_prokit/features/patient/presentation/components/patient_selector.dart';
import 'package:medilab_prokit/features/appointment/data/appointment_model.dart';
import 'package:medilab_prokit/features/appointment/data/book_appointment_model.dart';
import 'package:medilab_prokit/features/patient/data/delivered_data_model.dart';
import 'package:medilab_prokit/features/doctor/data/doctor_model.dart';
import 'package:medilab_prokit/features/patient/data/inbox_model.dart';
import 'package:medilab_prokit/features/patient/data/medication_model.dart';
import 'package:medilab_prokit/features/home/data/news_model.dart';
import 'package:medilab_prokit/features/home/data/notification_model.dart';
import 'package:medilab_prokit/features/patient/data/order_success_model.dart';
import 'package:medilab_prokit/features/patient/data/order_track_model.dart';
import 'package:medilab_prokit/features/patient/data/patient_model.dart';
import 'package:medilab_prokit/features/pharmacy/data/payment_model.dart';
import 'package:medilab_prokit/features/patient/data/profile_card_model.dart';
import 'package:medilab_prokit/features/patient/data/lab_scan_model.dart';
import 'package:medilab_prokit/features/patient/data/prescription_model.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/rendez_vous_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/medical_record_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/lab_scan_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/ai_assistant_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/prescription_screen.dart';
import 'package:medilab_prokit/features/home/data/service_model.dart';
import 'package:medilab_prokit/features/doctor/data/specialist_model.dart';
import 'package:medilab_prokit/features/pharmacy/data/voucher_model.dart';
import 'package:medilab_prokit/features/home/data/walkthrough_model.dart';
import 'package:medilab_prokit/features/appointment/presentation/screens/book_appointment_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/online_pharmacy_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/video_consult_screen.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';

List<MLWalkThroughData> mlWalkThroughDataList() {
  List<MLWalkThroughData> list = [];
  list.add(MLWalkThroughData(imagePath: mlIcSlideOne, title: mlSlideOne, subtitle: mlSlideOneSubtitle));
  list.add(MLWalkThroughData(imagePath: mlIcSlideThree, title: mlSlideThree, subtitle: mlSlideThreeSubtitle));
  list.add(MLWalkThroughData(imagePath: mlIcSlideTwo, title: mlSlideTwo, subtitle: mlSlideTwoSubtitle));
  return list;
}

List<MLServicesData> mlServiceDataList() {
  List<MLServicesData> list = [];
  list.add(MLServicesData(title: 'Clinic Visit', icon: Icons.home_work_outlined, image: mlIcDashClinicVisit, widget: MLBookAppointmentScreen(index: 0)));
  list.add(MLServicesData(title: 'Home Visit', icon: Icons.home, image: mlIcDashHomeVisit, widget: MLBookAppointmentScreen(index: 0)));
  list.add(MLServicesData(title: 'Video Consult', icon: Icons.video_call, image: mlIcDashVideoCons, widget: MLVideoConsultScreen()));
  list.add(MLServicesData(title: 'Pharmacy', icon: Icons.local_hospital, image: mlIcDashPharmacy, widget: MLOnlinePharmacyScreen()));
  return list;
}

List<MLBookAppointmentData> mlBookAppointmentDataList() {
  List<MLBookAppointmentData> list = [];
  list.add(MLBookAppointmentData(id: '1', title: 'Select Service', widget: MLClinicVisitComponent(), progress: 0.2));
  list.add(MLBookAppointmentData(id: '2', title: 'Choose Doctor', widget: MLDoctorListComponent(), progress: 0.5));
  list.add(MLBookAppointmentData(id: '3', title: 'Choose Patient', widget: MLPatientComponent(), progress: 0.75));
  list.add(MLBookAppointmentData(id: '4', title: 'Confirm Appointment', widget: MLConfirmAppointmentComponent(), progress: 1.0));
  return list;
}

List<MLDoctorData> mlDoctorListDataList() {
  List<MLDoctorData> list = [];
  list.add(MLDoctorData(title: 'Dr. Edward Jenner', subtitle: 'Endocrinology', image: mlIcDoctorImage, rating: '4.8', fees: '\$450'));
  list.add(MLDoctorData(title: 'Dr. Edward Jenner', subtitle: 'Endocrinology', image: mlIcDoctorImage, rating: '4.8', fees: '\$450'));
  list.add(MLDoctorData(title: 'Dr. Edward Jenner', subtitle: 'Endocrinology', image: mlIcDoctorImage, rating: '4.8', fees: '\$450'));
  list.add(MLDoctorData(title: 'Dr. Edward Jenner', subtitle: 'Endocrinology', image: mlIcDoctorImage, rating: '4.8', fees: '\$450'));
  list.add(MLDoctorData(title: 'Dr. Edward Jenner', subtitle: 'Endocrinology', image: mlIcDoctorImage, rating: '4.8', fees: '\$450'));
  list.add(MLDoctorData(title: 'Dr. Edward Jenner', subtitle: 'Endocrinology', image: mlIcDoctorImage, rating: '4.8', fees: '\$450'));
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

List<MLPatientData> mlPatientDataList() {
  List<MLPatientData> list = [];
  list.add(MLPatientData(name: 'Kaixa Pham', dob: '21-09-1995', relation: 'label'));
  list.add(MLPatientData(name: 'Stephen Chew', dob: '12-11-1990', relation: 'Brother'));
  return list;
}

List<MLVoucherData> mlVoucherDataList() {
  List<MLVoucherData> list = [];
  list.add(MLVoucherData(image: mlIcVoucher, title: 'Deal -25% for General Care ', date: 'Exp: 21 April 2022'));
  list.add(MLVoucherData(image: mlIcVoucherTwo, title: 'Deal -10% for Pediatrics ', date: 'Exp: 18 April 2022'));
  return list;
}

List<MLPaymentData> mlPaymentDataList() {
  List<MLPaymentData> list = [];
  list.add(MLPaymentData(image: mlIcBankPaymentOne, title: 'Payment at the clinic'));
  list.add(MLPaymentData(image: mlIcBankPaymentTwo, title: '**** **** **** 2109'));
  list.add(MLPaymentData(image: mlIcBankPaymentThree, title: '**** **** **** 1210'));
  list.add(MLPaymentData(image: mlIcBankPaymentFour, title: 'Kaixa Pham'));
  return list;
}

List<MLMedicationData> mlCategoryMedicineList() {
  List<MLMedicationData> list = [];
  list.add(MLMedicationData(image: mlIcMediIconSix, title: 'Prescription Drug'));
  list.add(MLMedicationData(image: mlIcMediIconFive, title: 'Functional Food'));
  list.add(MLMedicationData(image: mlIcMediIconThree, title: 'Personal Care'));
  list.add(MLMedicationData(image: mlIcMediIconFour, title: 'Family Medicine'));
  list.add(MLMedicationData(image: mlIcMediIconTwo, title: 'Prescription Drug'));
  list.add(MLMedicationData(image: mlIcMediIconOne, title: 'Prescription Drug'));
  return list;
}

List<MLMedicationData> mlPrescriptionMedicineDataList() {
  List<MLMedicationData> list = [];
  list.add(MLMedicationData(image: mlIcMediTwo, title: 'Vitamin C'));
  list.add(MLMedicationData(image: mlIcMediThree, title: 'General Health'));
  list.add(MLMedicationData(image: mlIcMediFour, title: 'Covid-19'));
  list.add(MLMedicationData(image: mlIcMediFive, title: 'Beauty'));
  list.add(MLMedicationData(image: mlIcMediTwo, title: 'Vitamin C'));
  list.add(MLMedicationData(image: mlIcMediThree, title: 'General Health'));
  return list;
}

List<MLDeliveredData> mlDeliveredDataList() {
  List<MLDeliveredData> list = [];
  list.add(MLDeliveredData(imageOne: mlIcMediTwo, imageTwo: mlIcMediTwo, status: 'Pending', medicineOne: 'Apple Cinder Vinegar Goli', medicineTwo: 'High Potency Vitamin'));
  list.add(MLDeliveredData(imageOne: mlIcMediFour, imageTwo: mlIcMediThree, status: 'Processing', medicineOne: 'medicine', medicineTwo: 'medicine'));
  list.add(MLDeliveredData(imageOne: mlIcMediFive, imageTwo: mlIcMediFour, status: 'Pending', medicineOne: 'medicine', medicineTwo: 'medicine'));
  return list;
}

List<MLOrderSuccessData> mlOrderSuccessDataList() {
  List<MLOrderSuccessData> list = [];
  list.add(MLOrderSuccessData(title: 'Code Order', data: '#2995451'));
  list.add(MLOrderSuccessData(title: 'Estimated Time', data: '11:45 AM'));
  list.add(MLOrderSuccessData(title: 'An email confirmation will sent to', data: 'tmrw@gmail.com'));
  list.add(MLOrderSuccessData(title: 'Code Order', data: '#2995451'));
  list.add(MLOrderSuccessData(title: 'Estimated Time', data: '11:45 AM'));
  list.add(MLOrderSuccessData(title: 'An email confirmation will sent to', data: 'tmrw@gmail.com'));
  return list;
}

List<MLSpecialistData> mlSpecialistDataDataList() {
  List<MLSpecialistData> list = [];
  list.add(MLSpecialistData(image: mlIcEyeSpecialist, title: 'Eye Care', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcBoneSpecialist, title: 'Bones', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcCovidSpecialist, title: 'Covid-19', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcHeartSpecialist, title: 'Heart', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcKidneySpecialist, title: 'Kiddney', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcLungsSpecialist, title: 'Lungs', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcToothSpecialist, title: 'Tooth', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcEyeSpecialist, title: 'Eye Care', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcBoneSpecialist, title: 'Bones', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcCovidSpecialist, title: 'Covid-19', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcHeartSpecialist, title: 'Heart', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcKidneySpecialist, title: 'Kiddney', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcLungsSpecialist, title: 'Lungs', subtitle: '647 Disease'));
  list.add(MLSpecialistData(image: mlIcToothSpecialist, title: 'Tooth', subtitle: '647 Disease'));
  return list;
}

List<MLNewsData> mlNewsDataList() {
  List<MLNewsData> list = [];
  list.add(MLNewsData(image: mlIcDoctorImage, title: 'How to prepare before your medical appointment', duration: '18 min ago'));
  list.add(MLNewsData(image: mlIcVideoConsult, title: 'Video consultation: what you need to know', duration: '18 min ago'));
  list.add(MLNewsData(image: mlIcAppointmentBooked, title: 'Five tips to keep your treatment on track', duration: '18 min ago'));
  list.add(MLNewsData(image: mlIcChat, title: 'Chat with your doctor from home', duration: '18 min ago'));
  list.add(MLNewsData(image: mlIcOrderSuccess, title: 'Order your medicine online in a few steps', duration: '18 min ago'));
  return list;
}

List<MLInboxData> mlInboxChatDataList() {
  List<MLInboxData> list = [];
  list.add(MLInboxData(id: 0, message: 'i have already taken medicine'));
  list.add(MLInboxData(id: 1, message: 'Hi Kaixa, have you taken your pills yet?'));
  list.add(MLInboxData(id: 1, message: 'sorry but i can\'t find your home number'));
  list.add(MLInboxData(id: 0, message: 'Please knock on dor'));
  list.add(MLInboxData(id: 0, message: 'I am home waiting for you'));
  list.add(MLInboxData(id: 0, message: 'Hi Miranda'));
  list.add(MLInboxData(id: 1, message: 'I am on my way to your home visit'));
  return list;
}

List<MLInboxData> mlBotChatDataList() {
  List<MLInboxData> list = [];
  list.add(MLInboxData(
      id: 1,
      message: 'These are some of the frequantly asked question whencustomers use our services. Please '
          'choose the question you are intrested in'));
  list.add(MLInboxData(id: 0, message: 'yes'));
  list.add(MLInboxData(
      id: 1,
      message: 'Hi Kaixa, Thank you for using Medilink\'s consulting service.'
          'what are you intrested in our comprehensice checkup package?'));
  list.add(MLInboxData(id: 0, message: 'Get Started'));
  return list;
}

List<MLNotificationData> mlNotificationDataList() {
  List<MLNotificationData> list = [];
  list.add(MLNotificationData(image: mlIcDoctorImage, title: 'an appointment has been scheduled??? in context from reliable sources', time: '3m ago', status: 'Completed', detail: 'Completed'));
  list.add(MLNotificationData(image: mlIcDoctorImage, title: 'Dr. sent you a message', time: '3m ago', status: ''));
  list.add(MLNotificationData(image: mlIcDoctorImage, title: 'Vitamins are essential to human health. Here, l', time: 'Today at 2.20 AM', status: 'Canceled'));
  list.add(MLNotificationData(
      image: mlIcDoctorImage,
      title: 'Hey Dustin,. This email confirms your Service Name appointment on Appointment Date Time Client',
      time: 'Today at 11.20 AM',
      status: 'Delivered',
      detail: 'Succesfully delivered to you'));
  list.add(MLNotificationData(
    image: mlIcDoctorImage,
    title: 'Hey Dustin,. This email confirms your Service Name appointment on Appointment Date Time Client',
    time: '3m ago',
    status: 'Delivered',
  ));
  return list;
}

List<MLAppointmentData> mlAppointmentDataList() {
  List<MLAppointmentData> list = [];
  list.add(MLAppointmentData(date: '10', month: 'october', doctor: 'Dr. Stephen Chew', department: 'General Care', patient: 'Kaixa Pham', service: 'Clinic Visit'));
  list.add(MLAppointmentData(date: '12', month: 'September', doctor: 'Dr. Stephen Chew', department: 'Pediatric', patient: 'Kaixa Pham ', service: 'Home Visit'));
  list.add(MLAppointmentData(date: '10', month: 'october', doctor: 'Dr. Stephen Chew', department: 'General Care', patient: 'Kaixa Pham ', service: 'Video Consult'));
  list.add(MLAppointmentData(date: '12', month: 'September', doctor: 'Dr. Stephen Chew', department: 'Pediatric', patient: 'Kaixa Pham ', service: 'Home Visit'));
  list.add(MLAppointmentData(date: '10', month: 'october', doctor: 'Dr. Stephen Chew', department: 'General Care', patient: 'Kaixa Pham ', service: 'Clinic Visit'));
  return list;
}

List<MLDeliveredData> mlDeliveredStatusDataList() {
  List<MLDeliveredData> list = [];
  list.add(MLDeliveredData(imageOne: mlIcMediTwo, imageTwo: mlIcMediFive, status: 'Pending', medicineOne: 'Apple Cinder Vinegar Goli', medicineTwo: 'High Potency Vitamin'));
  list.add(MLDeliveredData(imageOne: mlIcMediThree, imageTwo: mlIcMediTwo, status: 'Processing', medicineOne: 'Apple Cinder Vinegar Goli', medicineTwo: 'medicine'));
  list.add(MLDeliveredData(imageOne: mlIcMediFour, imageTwo: mlIcMediFour, status: 'Pending', medicineOne: 'Apple Cinder Vinegar Goli', medicineTwo: 'medicine'));
  list.add(MLDeliveredData(imageOne: mlIcMediFive, imageTwo: mlIcMediThree, status: 'Pending', medicineOne: 'Apple Cinder Vinegar Goli', medicineTwo: 'medicine'));
  return list;
}

List<MLMedicationData> mlPillDataList() {
  List<MLMedicationData> list = [];
  list.add(MLMedicationData(image: mlIcMediFive, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediTwo, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediThree, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediFour, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediFive, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediTwo, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediThree, title: 'Probitic, 250mg'));
  list.add(MLMedicationData(image: mlIcMediFour, title: 'Probitic, 250mg'));
  return list;
}

List<MLOrderTrackData> mlOrderTrackDataList() {
  List<MLOrderTrackData> list = [];
  list.add(MLOrderTrackData(date: '27 Sep', time: '09:30 AM', stage: 'Order Placed', message: 'your order #5465422212 is placed', value: true));
  list.add(MLOrderTrackData(date: '27 Sep', time: '16:30 PM', stage: 'Pending', message: 'your order is pending for confirmation,your order is penging for confirmation', value: true));
  list.add(MLOrderTrackData(date: '27 Sep', time: '16:30 PM', stage: 'Confirmed', message: 'your order #5465422212 confirm,your order #5465422212 confirm', value: true));
  list.add(MLOrderTrackData(date: '27 Sep', time: '16:30 PM', stage: 'Processing', message: 'your order #5465422212 Proccesing,your order #5465422212 Proccesing', value: true));
  list.add(MLOrderTrackData(date: 'Today', time: '16:30 PM', stage: 'Delivered', message: 'product delivery to you and marked as deliver', value: false));
  return list;
}

List<MLProfileCardData> mlProfileDataList() {
  List<MLProfileCardData> list = [];
  list.add(MLProfileCardData(img: mlPrescription3, name: 'Rendez-vous', color: medicalTealPrimary, screen: MLRendezVousScreen()));
  list.add(MLProfileCardData(img: mlPrescription2, name: 'Dossier m�dical', color: careCoralPrimary, screen: MLMedicalRecordScreen()));
  list.add(MLProfileCardData(img: mlPrescription1, name: 'Scanner un bilan', color: vitalityGreenPrimary, screen: MLLabScanScreen()));
  list.add(MLProfileCardData(icon: Icons.auto_awesome, name: 'Assistant IA', color: cyanAccentDark, screen: MLAiAssistantScreen()));
  list.add(MLProfileCardData(img: mlPrescription4, name: 'Ordonnances', color: duckBlueMedium, screen: MLPrescriptionScreen()));
  return list;
}

List<MLLabScanData> mlLabScanDataList() {
  List<MLLabScanData> list = [];
  list.add(MLLabScanData(title: 'Bilan sanguin complet', date: '21 Sep 2026', status: 'Analis�'));
  list.add(MLLabScanData(title: 'Glyc�mie � jeun', date: '14 Sep 2026', status: 'Analis�'));
  list.add(MLLabScanData(title: 'Bilan lipidique', date: '02 Sep 2026', status: 'En attente'));
  list.add(MLLabScanData(title: 'NFS - Num�ration formule', date: '25 Aug 2026', status: 'Analis�'));
  return list;
}

List<MLPrescriptionData> mlPrescriptionDataList() {
  List<MLPrescriptionData> list = [];
  list.add(MLPrescriptionData(
    doctor: 'Dr. Stephen Chew',
    specialty: 'M�decine g�n�rale',
    date: '21 Sep 2026',
    status: 'Active',
    medicines: ['Metformine 500 mg - 2x/jour', 'Vitamine B12 - 1x/jour'],
  ));
  list.add(MLPrescriptionData(
    doctor: 'Dr. Edward Jenner',
    specialty: 'Endocrinologie',
    date: '10 Sep 2026',
    status: 'Active',
    medicines: ['Om�prazole 20 mg - matin', 'Parac�tamol 1 g - si douleur'],
  ));
  list.add(MLPrescriptionData(
    doctor: 'Dr. Miranda Kerr',
    specialty: 'P�diatrie',
    date: '12 Aug 2026',
    status: 'Termin�e',
    medicines: ['Amoxicilline 500 mg - 3x/jour pendant 7 jours'],
  ));
  return list;
}

List<LanguageDataModel> languageList() {
  return [
    LanguageDataModel(id: 1, name: 'English', languageCode: 'en', fullLanguageCode: 'en-US', flag: 'assets/images/flag/ic_us.png'),
    LanguageDataModel(id: 2, name: 'Hindi', languageCode: 'hi', fullLanguageCode: 'hi-IN', flag: 'assets/images/flag/ic_hi.png'),
    LanguageDataModel(id: 3, name: 'Arabic', languageCode: 'ar', fullLanguageCode: 'ar-AR', flag: 'assets/images/flag/ic_ar.png'),
    LanguageDataModel(id: 4, name: 'French', languageCode: 'fr', fullLanguageCode: 'fr-FR', flag: 'assets/images/flag/ic_fr.png'),
  ];
}

class MLDoctorAgendaData {
  String? id;
  String? date;
  String? day;
  String? startTime;
  String? endTime;
  String? patientName;
  String? patientId;
  String? type;
  String? status;
  String? notes;

  MLDoctorAgendaData({
    this.id,
    this.date,
    this.day,
    this.startTime,
    this.endTime,
    this.patientName,
    this.patientId,
    this.type,
    this.status,
    this.notes,
  });
}

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

class MLDoctorPrescriptionTemplateData {
  String? id;
  String? name;
  String? category;
  List<String>? medicines;
  String? dosageInstructions;

  MLDoctorPrescriptionTemplateData({
    this.id,
    this.name,
    this.category,
    this.medicines,
    this.dosageInstructions,
  });
}

List<MLDoctorAgendaData> mlDoctorAgendaDataList() {
  List<MLDoctorAgendaData> list = [];
  list.add(MLDoctorAgendaData(
    id: '1',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '08:00',
    endTime: '08:30',
    patientName: 'Kaixa Pham',
    patientId: 'P001',
    type: 'Consultation',
    status: 'Confirmé',
    notes: 'Suivi diabète type 2',
  ));
  list.add(MLDoctorAgendaData(
    id: '2',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '08:30',
    endTime: '09:00',
    patientName: 'Stephen Chew',
    patientId: 'P002',
    type: 'Visite à domicile',
    status: 'En attente',
    notes: 'Contrôle tension',
  ));
  list.add(MLDoctorAgendaData(
    id: '3',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '09:00',
    endTime: '09:30',
    patientName: 'Marie Dubois',
    patientId: 'P003',
    type: 'Vidéo consultation',
    status: 'Confirmé',
    notes: 'Renouvellement ordonnance',
  ));
  list.add(MLDoctorAgendaData(
    id: '4',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '09:30',
    endTime: '10:00',
    patientName: 'Pierre Martin',
    patientId: 'P004',
    type: 'Consultation',
    status: 'Annulé',
    notes: '',
  ));
  list.add(MLDoctorAgendaData(
    id: '5',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '10:00',
    endTime: '10:30',
    patientName: 'Sophie Bernard',
    patientId: 'P005',
    type: 'Consultation',
    status: 'Confirmé',
    notes: 'Bilan annuel',
  ));
  list.add(MLDoctorAgendaData(
    id: '6',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '14:00',
    endTime: '14:30',
    patientName: 'Lucie Moreau',
    patientId: 'P006',
    type: 'Consultation',
    status: 'Confirmé',
    notes: 'Suivi grossesse',
  ));
  list.add(MLDoctorAgendaData(
    id: '7',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '14:30',
    endTime: '15:00',
    patientName: 'Thomas Petit',
    patientId: 'P007',
    type: 'Vidéo consultation',
    status: 'Confirmé',
    notes: 'Résultats analyses',
  ));
  list.add(MLDoctorAgendaData(
    id: '8',
    date: '2026-09-28',
    day: 'Lundi',
    startTime: '15:00',
    endTime: '15:30',
    patientName: 'Emma Roux',
    patientId: 'P008',
    type: 'Consultation',
    status: 'En attente',
    notes: 'Douleurs abdominales',
  ));

  list.add(MLDoctorAgendaData(
    id: '9',
    date: '2026-09-29',
    day: 'Mardi',
    startTime: '08:00',
    endTime: '08:30',
    patientName: 'Julien Blanc',
    patientId: 'P009',
    type: 'Consultation',
    status: 'Confirmé',
    notes: 'Vaccination',
  ));
  list.add(MLDoctorAgendaData(
    id: '10',
    date: '2026-09-29',
    day: 'Mardi',
    startTime: '08:30',
    endTime: '09:00',
    patientName: 'Chloé Garcia',
    patientId: 'P010',
    type: 'Consultation',
    status: 'Confirmé',
    notes: 'Suivi asthme',
  ));

  return list;
}

List<MLDoctorConsultationData> mlDoctorConsultationDataList() {
  List<MLDoctorConsultationData> list = [];
  list.add(MLDoctorConsultationData(
    id: 'C001',
    patientId: 'P001',
    patientName: 'Kaixa Pham',
    patientAge: '29',
    patientGender: 'F',
    date: '2026-09-25',
    time: '09:00',
    type: 'Consultation',
    status: 'Terminé',
    chiefComplaint: 'Fatigue persistante, soif excessive',
    diagnosis: 'Diabète type 2 - déséquilibré',
    notes: 'HbA1c à 8.2%. Augmenter metformine. Contrôle dans 1 mois.',
    prescriptionId: 'RX001',
    vitals: ['TA: 135/85', 'Poids: 72kg', 'Glycémie: 1.85 g/L', 'FC: 78'],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C002',
    patientId: 'P002',
    patientName: 'Stephen Chew',
    patientAge: '34',
    patientGender: 'M',
    date: '2026-09-24',
    time: '14:30',
    type: 'Visite à domicile',
    status: 'Terminé',
    chiefComplaint: 'Céphalées matinales',
    diagnosis: 'Hypertension artérielle stade 1',
    notes: 'TA 145/95 à domicile. Prescrire Amlodipine 5mg. Hygiène de vie.',
    prescriptionId: 'RX002',
    vitals: ['TA: 145/95', 'Poids: 82kg', 'FC: 82'],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C003',
    patientId: 'P003',
    patientName: 'Marie Dubois',
    patientAge: '42',
    patientGender: 'F',
    date: '2026-09-23',
    time: '10:15',
    type: 'Vidéo consultation',
    status: 'Terminé',
    chiefComplaint: 'Renouvellement traitement thyroïde',
    diagnosis: 'Hypothyroïdie stabilisée',
    notes: 'TSH normale à 2.1. Maintenir Lévothyrox 75µg. Prochain bilan dans 6 mois.',
    prescriptionId: 'RX003',
    vitals: ['TA: 120/78', 'Poids: 65kg', 'FC: 70'],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C004',
    patientId: 'P004',
    patientName: 'Pierre Martin',
    patientAge: '56',
    patientGender: 'M',
    date: '2026-09-22',
    time: '11:00',
    type: 'Consultation',
    status: 'Annulé',
    chiefComplaint: '',
    diagnosis: '',
    notes: 'Patient a annulé 2h avant',
    prescriptionId: '',
    vitals: [],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C005',
    patientId: 'P005',
    patientName: 'Sophie Bernard',
    patientAge: '31',
    patientGender: 'F',
    date: '2026-09-20',
    time: '16:00',
    type: 'Consultation',
    status: 'Terminé',
    chiefComplaint: 'Bilan annuel préventif',
    diagnosis: 'RAS - Bon état de santé général',
    notes: 'Examens normaux. Conseil hygiène de vie. Revoir dans 1 an.',
    prescriptionId: '',
    vitals: ['TA: 115/75', 'Poids: 58kg', 'Glycémie: 0.92', 'Cholestérol: 1.85', 'FC: 68'],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C006',
    patientId: 'P006',
    patientName: 'Lucie Moreau',
    patientAge: '28',
    patientGender: 'F',
    date: '2026-09-18',
    time: '09:30',
    type: 'Consultation',
    status: 'En cours',
    chiefComplaint: 'Suivi grossesse - 12 SA',
    diagnosis: 'Grossesse évolutive normale',
    notes: 'Échographie 12 SA normale. Prescrire acide folique. RDV écho 22 SA.',
    prescriptionId: 'RX004',
    vitals: ['TA: 110/70', 'Poids: 62kg', 'FC: 76', 'Température: 36.8'],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C007',
    patientId: 'P007',
    patientName: 'Thomas Petit',
    patientAge: '45',
    patientGender: 'M',
    date: '2026-09-15',
    time: '15:30',
    type: 'Vidéo consultation',
    status: 'Terminé',
    chiefComplaint: 'Résultats bilan lipidique',
    diagnosis: 'Dyslipidémie mixte',
    notes: 'LDL 1.95. Prescrire statine. Régime pauvre en graisses. Contrôle 3 mois.',
    prescriptionId: 'RX005',
    vitals: ['TA: 128/82', 'Poids: 88kg', 'FC: 74'],
  ));
  list.add(MLDoctorConsultationData(
    id: 'C008',
    patientId: 'P008',
    patientName: 'Emma Roux',
    patientAge: '19',
    patientGender: 'F',
    date: '2026-09-28',
    time: '15:00',
    type: 'Consultation',
    status: 'Programmé',
    chiefComplaint: 'Douleurs abdominales basses',
    diagnosis: '',
    notes: '',
    prescriptionId: '',
    vitals: [],
  ));

  return list;
}

List<MLDoctorPatientSummaryData> mlDoctorPatientSummaryDataList() {
  List<MLDoctorPatientSummaryData> list = [];
  list.add(MLDoctorPatientSummaryData(
    id: 'P001',
    name: 'Kaixa Pham',
    dob: '21-09-1995',
    age: '29',
    gender: 'F',
    phone: '06 12 34 56 78',
    email: 'kaixa.pham@email.com',
    lastVisit: '2026-09-25',
    nextAppointment: '2026-10-28',
    conditions: ['Diabète type 2', 'HTA'],
    activeMedications: ['Metformine 500mg', 'Amlodipine 5mg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P002',
    name: 'Stephen Chew',
    dob: '12-11-1990',
    age: '34',
    gender: 'M',
    phone: '06 23 45 67 89',
    email: 'stephen.chew@email.com',
    lastVisit: '2026-09-24',
    nextAppointment: '2026-10-24',
    conditions: ['Hypertension artérielle'],
    activeMedications: ['Amlodipine 5mg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P003',
    name: 'Marie Dubois',
    dob: '08-03-1982',
    age: '42',
    gender: 'F',
    phone: '06 34 56 78 90',
    email: 'marie.dubois@email.com',
    lastVisit: '2026-09-23',
    nextAppointment: '2027-03-23',
    conditions: ['Hypothyroïdie'],
    activeMedications: ['Lévothyrox 75µg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P004',
    name: 'Pierre Martin',
    dob: '25-07-1968',
    age: '56',
    gender: 'M',
    phone: '06 45 67 89 01',
    email: 'pierre.martin@email.com',
    lastVisit: '2026-08-15',
    nextAppointment: '2026-10-15',
    conditions: ['Dyslipidémie', 'Surpoids'],
    activeMedications: ['Atorvastatine 20mg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P005',
    name: 'Sophie Bernard',
    dob: '14-02-1993',
    age: '31',
    gender: 'F',
    phone: '06 56 78 90 12',
    email: 'sophie.bernard@email.com',
    lastVisit: '2026-09-20',
    nextAppointment: '2027-09-20',
    conditions: [],
    activeMedications: [],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P006',
    name: 'Lucie Moreau',
    dob: '30-11-1996',
    age: '28',
    gender: 'F',
    phone: '06 67 89 01 23',
    email: 'lucie.moreau@email.com',
    lastVisit: '2026-09-18',
    nextAppointment: '2026-11-18',
    conditions: ['Grossesse (12 SA)'],
    activeMedications: ['Acide folique 0.4mg', 'Fer 80mg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P007',
    name: 'Thomas Petit',
    dob: '18-09-1979',
    age: '45',
    gender: 'M',
    phone: '06 78 90 12 34',
    email: 'thomas.petit@email.com',
    lastVisit: '2026-09-15',
    nextAppointment: '2026-12-15',
    conditions: ['Dyslipidémie mixte'],
    activeMedications: ['Rosuvastatine 10mg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P008',
    name: 'Emma Roux',
    dob: '22-04-2005',
    age: '19',
    gender: 'F',
    phone: '06 89 01 23 45',
    email: 'emma.roux@email.com',
    lastVisit: '2026-08-10',
    nextAppointment: '2026-09-28',
    conditions: [],
    activeMedications: [],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P009',
    name: 'Julien Blanc',
    dob: '05-06-1988',
    age: '36',
    gender: 'M',
    phone: '06 90 12 34 56',
    email: 'julien.blanc@email.com',
    lastVisit: '2026-07-20',
    nextAppointment: '2026-09-29',
    conditions: [],
    activeMedications: [],
    avatar: 'assets/images/ml_profile_Image.png',
  ));
  list.add(MLDoctorPatientSummaryData(
    id: 'P010',
    name: 'Chloé Garcia',
    dob: '17-12-1992',
    age: '31',
    gender: 'F',
    phone: '06 01 23 45 67',
    email: 'chloe.garcia@email.com',
    lastVisit: '2026-08-05',
    nextAppointment: '2026-09-29',
    conditions: ['Asthme persistant modéré'],
    activeMedications: ['Salbutamol (si besoin)', 'Fluticasone 100µg'],
    avatar: 'assets/images/ml_profile_Image.png',
  ));

  return list;
}

MLDoctorMedicalRecordData mlDoctorMedicalRecordData() {
  return MLDoctorMedicalRecordData(
    patientId: 'P001',
    patientName: 'Kaixa Pham',
    patientAge: '29',
    patientGender: 'F',
    bloodType: 'O+',
    vitals: {
      'Tension artérielle': '120/80 mmHg',
      'Poids': '68 kg',
      'Taille': '165 cm',
      'IMC': '25.0',
      'Glycémie à jeun': '0.92 g/L',
      'HbA1c': '7.2%',
      'Fréquence cardiaque': '72 bpm',
      'Température': '36.8°C',
      'Saturation O2': '98%',
    },
    medicalHistory: [
      'Diabète type 2 (diagnostiqué 2019)',
      'Hypertension artérielle (diagnostiquée 2021)',
      'Appendicectomie (2010)',
      'Accouchement par césarienne (2022)',
    ],
    allergies: [
      'Pénicilline (éruption cutanée)',
      'Arachides (œdème quincke)',
    ],
    currentMedications: [
      'Metformine 500 mg - 2 fois/jour',
      'Amlodipine 5 mg - 1 fois/jour (matin)',
      'Vitamine D 1000 UI - 1 fois/jour',
    ],
    documents: [
      'Compte-rendu hospitalisation 2022',
      'Bilan ophtalmologique 2024',
      'Échographie abdominale 2023',
      'Certificat de vaccination',
    ],
    consultationHistory: mlAppointmentDataList(),
    labResults: mlLabScanDataList(),
    prescriptions: mlPrescriptionDataList(),
  );
}

List<MLDoctorPrescriptionTemplateData> mlDoctorPrescriptionTemplateDataList() {
  List<MLDoctorPrescriptionTemplateData> list = [];
  list.add(MLDoctorPrescriptionTemplateData(
    id: 'TPL001',
    name: 'Diabète type 2 - Première intention',
    category: 'Endocrinologie',
    medicines: ['Metformine 500 mg', 'Metformine 850 mg', 'Metformine 1000 mg'],
    dosageInstructions: 'Augmenter progressivement toutes les 2 semaines selon tolérance et glycémie. Prendre pendant les repas.',
  ));
  list.add(MLDoctorPrescriptionTemplateData(
    id: 'TPL002',
    name: 'Hypertension artérielle - Monothérapie',
    category: 'Cardiologie',
    medicines: ['Amlodipine 5 mg', 'Amlodipine 10 mg', 'Losartan 50 mg', 'Losartan 100 mg'],
    dosageInstructions: '1 comprimé par jour le matin. Contrôler TA à 1 mois.',
  ));
  list.add(MLDoctorPrescriptionTemplateData(
    id: 'TPL003',
    name: 'Infection respiratoire basse - Adulte',
    category: 'Infectiologie',
    medicines: ['Amoxicilline 1g', 'Amoxicilline/Acide clavulanique 1g/125mg', 'Doxycycline 100mg'],
    dosageInstructions: 'Amoxicilline: 1g 3x/jour 7 jours. Si allergie: Doxycycline 100mg 2x/jour 7 jours.',
  ));
  list.add(MLDoctorPrescriptionTemplateData(
    id: 'TPL004',
    name: 'Asthme - Traitement de fond',
    category: 'Pneumologie',
    medicines: ['Fluticasone 100µg', 'Fluticasone 250µg', 'Budesonide/Formotérol 100/6µg', 'Budesonide/Formotérol 200/6µg'],
    dosageInstructions: '2 bouffées matin et soir. Réévaluer à 3 mois. Adapter selon contrôle.',
  ));
  list.add(MLDoctorPrescriptionTemplateData(
    id: 'TPL005',
    name: 'Grossesse - Supplémentation standard',
    category: 'Gynécologie',
    medicines: ['Acide folique 0.4mg', 'Fer 80mg', 'Vitamine D 1000 UI', 'Iode 150µg'],
    dosageInstructions: 'Acide folique: idéalement avant conception. Fer: si ferritine <30. Vitamine D: dose unique 100000 UI au 6ème mois.',
  ));
  list.add(MLDoctorPrescriptionTemplateData(
    id: 'TPL006',
    name: 'Dyslipidémie - Statine',
    category: 'Cardiologie',
    medicines: ['Atorvastatine 10mg', 'Atorvastatine 20mg', 'Rosuvastatine 5mg', 'Rosuvastatine 10mg', 'Simvastatine 20mg'],
    dosageInstructions: '1 comprimé le soir. Contrôle lipidique à 3 mois. Adapter dose selon objectif LDL.',
  ));

  return list;
}
