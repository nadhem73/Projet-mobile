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
  list.add(MLNotificationData(image: mlIcDoctorImage, title: 'an appointment has been scheduled�?� in context from reliable sources', time: '3m ago', status: 'Completed', detail: 'Completed'));
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
  list.add(MLProfileCardData(img: mlPrescription2, name: 'Dossier médical', color: careCoralPrimary, screen: MLMedicalRecordScreen()));
  list.add(MLProfileCardData(img: mlPrescription1, name: 'Scanner un bilan', color: vitalityGreenPrimary, screen: MLLabScanScreen()));
  list.add(MLProfileCardData(icon: Icons.auto_awesome, name: 'Assistant IA', color: cyanAccentDark, screen: MLAiAssistantScreen()));
  list.add(MLProfileCardData(img: mlPrescription4, name: 'Ordonnances', color: duckBlueMedium, screen: MLPrescriptionScreen()));
  return list;
}

List<MLLabScanData> mlLabScanDataList() {
  List<MLLabScanData> list = [];
  list.add(MLLabScanData(title: 'Bilan sanguin complet', date: '21 Sep 2026', status: 'Analisé'));
  list.add(MLLabScanData(title: 'Glycémie à jeun', date: '14 Sep 2026', status: 'Analisé'));
  list.add(MLLabScanData(title: 'Bilan lipidique', date: '02 Sep 2026', status: 'En attente'));
  list.add(MLLabScanData(title: 'NFS - Numération formule', date: '25 Aug 2026', status: 'Analisé'));
  return list;
}

List<MLPrescriptionData> mlPrescriptionDataList() {
  List<MLPrescriptionData> list = [];
  list.add(MLPrescriptionData(
    doctor: 'Dr. Stephen Chew',
    specialty: 'Médecine générale',
    date: '21 Sep 2026',
    status: 'Active',
    medicines: ['Metformine 500 mg - 2x/jour', 'Vitamine B12 - 1x/jour'],
  ));
  list.add(MLPrescriptionData(
    doctor: 'Dr. Edward Jenner',
    specialty: 'Endocrinologie',
    date: '10 Sep 2026',
    status: 'Active',
    medicines: ['Oméprazole 20 mg - matin', 'Paracétamol 1 g - si douleur'],
  ));
  list.add(MLPrescriptionData(
    doctor: 'Dr. Miranda Kerr',
    specialty: 'Pédiatrie',
    date: '12 Aug 2026',
    status: 'Terminée',
    medicines: ['Amoxicilline 500 mg - 3x/jour pendant 7 jours'],
  ));
  return list;
}

List<LanguageDataModel> languageList() {
  return [
    LanguageDataModel(id: 1, name: 'English', languageCode: 'en', fullLanguageCode: 'en-US', flag: 'images/flag/ic_us.png'),
    LanguageDataModel(id: 2, name: 'Hindi', languageCode: 'hi', fullLanguageCode: 'hi-IN', flag: 'images/flag/ic_hi.png'),
    LanguageDataModel(id: 3, name: 'Arabic', languageCode: 'ar', fullLanguageCode: 'ar-AR', flag: 'images/flag/ic_ar.png'),
    LanguageDataModel(id: 4, name: 'French', languageCode: 'fr', fullLanguageCode: 'fr-FR', flag: 'images/flag/ic_fr.png'),
  ];
}