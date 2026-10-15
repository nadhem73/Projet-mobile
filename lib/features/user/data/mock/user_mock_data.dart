// Données fictives du module user.
// À remplacer progressivement par les données SQLite (repositories du module).
import 'package:flutter/material.dart';
import 'package:medilink/core/theme/colors.dart';
import 'package:medilink/features/user/data/models/patient_model.dart';
import 'package:medilink/features/user/data/models/profile_card_model.dart';
import 'package:medilink/features/appointment/presentation/screens/rendez_vous_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record_screen.dart';
import 'package:medilink/features/ai/presentation/screens/lab_scan_screen.dart';
import 'package:medilink/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/prescription_screen.dart';
import 'package:medilink/core/utils/app_assets.dart';

List<MLPatientData> mlPatientDataList() {
  List<MLPatientData> list = [];
  list.add(MLPatientData(name: 'Kaixa Pham', dob: '21-09-1995', relation: 'label'));
  list.add(MLPatientData(name: 'Stephen Chew', dob: '12-11-1990', relation: 'Brother'));
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
