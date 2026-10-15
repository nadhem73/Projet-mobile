// Données fictives du module shell.
// À remplacer progressivement par les données SQLite (repositories du module).
import 'package:flutter/material.dart';
import 'package:medilink/features/shell/data/models/inbox_model.dart';
import 'package:medilink/features/shell/data/models/news_model.dart';
import 'package:medilink/features/shell/data/models/notification_model.dart';
import 'package:medilink/features/shell/data/models/service_model.dart';
import 'package:medilink/features/appointment/presentation/screens/book_appointment_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/online_pharmacy_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/video_consult_screen.dart';
import 'package:medilink/core/utils/app_assets.dart';

List<MLServicesData> mlServiceDataList() {
  List<MLServicesData> list = [];
  list.add(MLServicesData(title: 'Clinic Visit', icon: Icons.home_work_outlined, image: mlIcDashClinicVisit, widget: MLBookAppointmentScreen(index: 0)));
  list.add(MLServicesData(title: 'Home Visit', icon: Icons.home, image: mlIcDashHomeVisit, widget: MLBookAppointmentScreen(index: 0)));
  list.add(MLServicesData(title: 'Video Consult', icon: Icons.video_call, image: mlIcDashVideoCons, widget: MLVideoConsultScreen()));
  list.add(MLServicesData(title: 'Pharmacy', icon: Icons.local_hospital, image: mlIcDashPharmacy, widget: MLOnlinePharmacyScreen()));
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
