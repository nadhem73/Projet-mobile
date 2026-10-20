import 'dart:convert';

import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:sqflite/sqflite.dart';

/// Données de démonstration insérées à la création de la base.
///
/// Comptes disponibles (mot de passe identique pour tous : `Medilink123`) :
/// - patient : `patient@medilink.tn`
/// - médecins : `dr.benali@medilink.tn`, `dr.trabelsi@medilink.tn`, `dr.gharbi@medilink.tn`
/// - pharmacien : `pharmacie@medilink.tn`
/// - assureur : `assurance@medilink.tn`
class DatabaseSeeder {
  DatabaseSeeder(this._db, {PasswordHasher hasher = const PasswordHasher()}) : _hasher = hasher;

  final DatabaseExecutor _db;
  final PasswordHasher _hasher;

  static const String demoPassword = 'Medilink123';

  static const _workingHours = {
    'mon': ['08:30-12:30', '14:00-17:00'],
    'tue': ['08:30-12:30', '14:00-17:00'],
    'wed': ['08:30-12:30'],
    'thu': ['08:30-12:30', '14:00-17:00'],
    'fri': ['08:30-12:00'],
    'sat': ['09:00-12:00'],
  };

  Future<void> seed() async {
    final passwordHash = _hasher.hash(demoPassword);

    // ----- Patient de démo -----
    final patientUserId = await _db.insert(UserTables.users, {
      'nom': 'Ben Salah',
      'prenom': 'Amira',
      'email': 'patient@medilink.tn',
      'password_hash': passwordHash,
      'phone': '+216 22 345 678',
      'role': 'PATIENT',
    });
    final patientId = await _db.insert(UserTables.patients, {
      'cin': '09876543',
      'date_naissance': '1998-04-12',
      'adresse': 'Ariana, Tunis',
      'user_id': patientUserId,
    });
    await _db.insert(UserTables.medicalRecords, {
      'patient_id': patientId,
      'gender': 'F',
      'blood_group': 'O+',
      'height': 165,
      'weight': 58,
      'allergies': 'Pénicilline',
      'chronic_diseases': 'Asthme léger',
      'current_treatment': 'Ventoline si besoin',
      'emergency_contact_name': 'Karim Ben Salah',
      'emergency_contact_phone': '+216 98 111 222',
      'insurance_company': 'CNAM',
      'insurance_number': '1234567890',
    });

    // ----- Médecins de démo -----
    const doctors = [
      ('Benali', 'Sami', 'dr.benali@medilink.tn', 'Cardiologie', 'TN-MED-1001', 60.0, 'Tunis'),
      ('Trabelsi', 'Leila', 'dr.trabelsi@medilink.tn', 'Médecine générale', 'TN-MED-1002', 40.0, 'Ariana'),
      ('Gharbi', 'Youssef', 'dr.gharbi@medilink.tn', 'Dermatologie', 'TN-MED-1003', 50.0, 'Sfax'),
    ];
    for (final (nom, prenom, email, specialty, license, fee, city) in doctors) {
      final userId = await _db.insert(UserTables.users, {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password_hash': passwordHash,
        'phone': '+216 71 000 000',
        'role': 'DOCTOR',
      });
      final doctorId = await _db.insert(UserTables.doctors, {
        'license_number': license,
        'specialty': specialty,
        'user_id': userId,
      });
      await _db.insert(UserTables.doctorProfiles, {
        'doctor_id': doctorId,
        'biography': 'Spécialiste en $specialty, plus de 10 ans d\'expérience.',
        'fee': fee,
        'working_hours': jsonEncode(_workingHours),
        'city': city,
        'address': 'Avenue Habib Bourguiba, $city',
      });
    }

    // ----- Pharmacien de démo -----
    final pharmacistUserId = await _db.insert(UserTables.users, {
      'nom': 'Mansouri',
      'prenom': 'Hela',
      'email': 'pharmacie@medilink.tn',
      'password_hash': passwordHash,
      'phone': '+216 71 222 333',
      'role': 'PHARMACIST',
    });
    await _db.insert(UserTables.pharmacists, {
      'pharmacy_name': 'Pharmacie Ennour',
      'license_number': 'TN-PH-2001',
      'address': 'Rue de Marseille',
      'city': 'Tunis',
      'user_id': pharmacistUserId,
    });

    // ----- Assureur de démo -----
    final insurerUserId = await _db.insert(UserTables.users, {
      'nom': 'Jaziri',
      'prenom': 'Mehdi',
      'email': 'assurance@medilink.tn',
      'password_hash': passwordHash,
      'phone': '+216 71 444 555',
      'role': 'INSURER',
    });
    await _db.insert(UserTables.insurers, {
      'company': 'CNAM',
      'agent_code': 'CNAM-AG-301',
      'user_id': insurerUserId,
    });
  }
}
