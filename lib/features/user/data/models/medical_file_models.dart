import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';

/// Vaccin reçu par un patient (table `vaccinations`).
class Vaccination {
  const Vaccination({this.id, required this.patientId, required this.name, required this.date, this.dose, this.notes});

  final int? id;
  final int patientId;
  final String name;
  final DateTime date;
  final String? dose;
  final String? notes;

  /// Vaccins courants proposés à la saisie (calendrier vaccinal tunisien).
  static const suggestions = [
    'BCG',
    'Hépatite B',
    'DTC (diphtérie, tétanos, coqueluche)',
    'Polio',
    'ROR (rougeole, oreillons, rubéole)',
    'Haemophilus influenzae b',
    'Pneumocoque',
    'Tétanos',
    'Grippe saisonnière',
    'COVID-19',
    'HPV',
    'Fièvre typhoïde',
  ];

  factory Vaccination.fromMap(Map<String, Object?> map) => Vaccination(
    id: map['vaccination_id'] as int,
    patientId: map['patient_id'] as int,
    name: map['name'] as String,
    date: DateTime.parse(map['date'] as String),
    dose: map['dose'] as String?,
    notes: map['notes'] as String?,
  );

  Map<String, Object?> toMap() => {
    'patient_id': patientId,
    'name': name.trim(),
    'date': date.toIso8601String().substring(0, 10),
    'dose': _clean(dose),
    'notes': _clean(notes),
  };
}

/// Catégories de documents joints au dossier.
enum DocumentCategory {
  analysis('ANALYSIS', 'Analyse', Icons.biotech_rounded),
  imaging('IMAGING', 'Imagerie', Icons.image_search_rounded),
  prescription('PRESCRIPTION', 'Ordonnance', Icons.receipt_long_rounded),
  report('REPORT', 'Compte rendu', Icons.description_rounded),
  other('OTHER', 'Autre', Icons.folder_rounded);

  const DocumentCategory(this.dbValue, this.label, this.icon);

  final String dbValue;
  final String label;
  final IconData icon;

  static DocumentCategory fromDb(String value) =>
      values.firstWhere((c) => c.dbValue == value, orElse: () => DocumentCategory.other);
}

/// Document (photo) joint au dossier médical (table `medical_documents`).
class MedicalDocument {
  const MedicalDocument({
    this.id,
    required this.patientId,
    required this.title,
    required this.category,
    required this.data,
    this.createdAt,
  });

  final int? id;
  final int patientId;
  final String title;
  final DocumentCategory category;

  /// Image JPEG.
  final Uint8List data;
  final DateTime? createdAt;

  factory MedicalDocument.fromMap(Map<String, Object?> map) => MedicalDocument(
    id: map['document_id'] as int,
    patientId: map['patient_id'] as int,
    title: map['title'] as String,
    category: DocumentCategory.fromDb(map['category'] as String),
    data: map['data'] as Uint8List,
    createdAt: parseSqlDateTime(map['created_at'] as String?),
  );
}

/// Consultation du dossier par un médecin (table `medical_record_access_log`).
class RecordAccess {
  const RecordAccess({required this.doctorName, required this.specialty, required this.accessedAt});

  final String doctorName;
  final String specialty;
  final DateTime accessedAt;
}

/// Identité d'un patient (en-tête du dossier, carte d'urgence).
class PatientIdentity {
  const PatientIdentity({
    required this.patientId,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.phone,
    this.lastAppointment,
  });

  final int patientId;
  final String nom;
  final String prenom;
  final DateTime? dateNaissance;
  final String? phone;

  /// Dernier rendez-vous avec le médecin connecté (liste « mes patients »).
  final DateTime? lastAppointment;

  String get fullName => '$prenom $nom'.trim();
  String get initials => '${prenom.isEmpty ? '' : prenom[0]}${nom.isEmpty ? '' : nom[0]}'.toUpperCase();

  int? get age {
    final birth = dateNaissance;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
    return years;
  }
}

String? _clean(String? value) {
  final v = value?.trim();
  return (v == null || v.isEmpty) ? null : v;
}
