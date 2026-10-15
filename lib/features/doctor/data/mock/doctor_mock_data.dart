// Données fictives du module doctor.
// À remplacer progressivement par les données SQLite (repositories du module).
import 'package:medilink/features/ai/data/mock/ai_mock_data.dart';
import 'package:medilink/features/appointment/data/mock/appointment_mock_data.dart';
import 'package:medilink/features/appointment/data/models/appointment_model.dart';
import 'package:medilink/features/ai/data/models/lab_scan_model.dart';
import 'package:medilink/features/doctor/data/models/prescription_model.dart';

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
