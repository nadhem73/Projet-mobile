// Données fictives du module pharmacy.
// À remplacer progressivement par les données SQLite (repositories du module).
import 'package:medilink/features/pharmacy/data/models/delivered_data_model.dart';
import 'package:medilink/features/pharmacy/data/models/medication_model.dart';
import 'package:medilink/features/pharmacy/data/models/order_success_model.dart';
import 'package:medilink/features/pharmacy/data/models/order_track_model.dart';
import 'package:medilink/features/pharmacy/data/models/payment_model.dart';
import 'package:medilink/features/pharmacy/data/models/voucher_model.dart';
import 'package:medilink/core/utils/app_assets.dart';

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
