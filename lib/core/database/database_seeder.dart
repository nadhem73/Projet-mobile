import 'dart:convert';

import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/database/schema/shared_schema.dart';
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
/// - administrateur : `admin@medilink.tn`
/// - médecin en attente de validation : `dr.haddad@medilink.tn`
///
/// Le patient de démo a un rendez-vous avec Dr Benali et Dr Trabelsi : ces deux
/// médecins peuvent consulter son dossier, Dr Gharbi non.
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

    Future<int> user(String nom, String prenom, String email, String phone, String role, {String status = 'ACTIVE'}) =>
        _db.insert(UserTables.users, {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'password_hash': passwordHash,
          'phone': phone,
          'role': role,
          'status': status,
        });

    // ----- Administrateur -----
    final adminUserId = await user('Kefi', 'Ines', 'admin@medilink.tn', '+216 71 999 000', 'ADMIN');

    // ----- Patient de démo -----
    final patientUserId = await user('Ben Salah', 'Amira', 'patient@medilink.tn', '+216 22 345 678', 'PATIENT');
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
      'surgical_history': 'Appendicectomie (2012)',
      'family_history': 'Diabète de type 2 (père)',
      'emergency_contact_name': 'Karim Ben Salah',
      'emergency_contact_phone': '+216 98 111 222',
      'insurance_company': 'CNAM',
      'insurance_number': '1234567890',
    });
    for (final (name, date, dose) in [
      ('BCG', '1998-05-02', null),
      ('Hépatite B', '1998-06-10', '3 doses'),
      ('Tétanos', '2021-09-14', 'Rappel'),
    ]) {
      await _db.insert(UserTables.vaccinations, {'patient_id': patientId, 'name': name, 'date': date, 'dose': dose});
    }
    await _db.insert(UserTables.dependents, {
      'patient_id': patientId,
      'nom': 'Ben Salah',
      'prenom': 'Youssef',
      'relation': 'CHILD',
      'date_naissance': '2020-02-18',
      'gender': 'M',
      'blood_group': 'O+',
    });

    // ----- Médecins de démo -----
    const doctors = [
      ('Benali', 'Sami', 'dr.benali@medilink.tn', 'Cardiologie', 'TN-MED-1001', 60.0, 'Tunis', 'ACTIVE'),
      ('Trabelsi', 'Leila', 'dr.trabelsi@medilink.tn', 'Médecine générale', 'TN-MED-1002', 40.0, 'Ariana', 'ACTIVE'),
      ('Gharbi', 'Youssef', 'dr.gharbi@medilink.tn', 'Dermatologie', 'TN-MED-1003', 50.0, 'Sfax', 'ACTIVE'),
      ('Haddad', 'Mariem', 'dr.haddad@medilink.tn', 'Pédiatrie', 'TN-MED-1004', 45.0, 'Sousse', 'PENDING'),
    ];
    final doctorIds = <int>[];
    for (final (nom, prenom, email, specialty, license, fee, city, status) in doctors) {
      final userId = await user(nom, prenom, email, '+216 71 000 000', 'DOCTOR', status: status);
      final doctorId = await _db.insert(UserTables.doctors, {
        'license_number': license,
        'specialty': specialty,
        'user_id': userId,
      });
      doctorIds.add(doctorId);
      await _db.insert(UserTables.doctorProfiles, {
        'doctor_id': doctorId,
        'biography': 'Spécialiste en $specialty, plus de 10 ans d\'expérience.',
        'fee': fee,
        'working_hours': jsonEncode(_workingHours),
        'city': city,
        'address': 'Avenue Habib Bourguiba, $city',
      });
    }

    // Rendez-vous du patient de démo (donnent accès à son dossier).
    final now = DateTime.now();
    String at(DateTime d, int hour) => DateTime(d.year, d.month, d.day, hour).toIso8601String().substring(0, 19);
    await _db.insert(AppointmentTables.appointments, {
      'appointment_date_time': at(now.add(const Duration(days: 3)), 10),
      'reason': 'Contrôle cardiologique',
      'status': AppointmentStatus.confirmed,
      'doctor_id': doctorIds[0],
      'patient_id': patientId,
    });
    await _db.insert(AppointmentTables.appointments, {
      'appointment_date_time': at(now.subtract(const Duration(days: 20)), 9),
      'reason': 'Crise d\'asthme',
      'status': AppointmentStatus.completed,
      'doctor_id': doctorIds[1],
      'patient_id': patientId,
    });

    // ----- Pharmacien de démo -----
    final pharmacistUserId = await user('Mansouri', 'Hela', 'pharmacie@medilink.tn', '+216 71 222 333', 'PHARMACIST');
    await _db.insert(UserTables.pharmacists, {
      'pharmacy_name': 'Pharmacie Ennour',
      'license_number': 'TN-PH-2001',
      'address': 'Rue de Marseille',
      'city': 'Tunis',
      'user_id': pharmacistUserId,
    });

    // ----- Assureur de démo -----
    final insurerUserId = await user('Jaziri', 'Mehdi', 'assurance@medilink.tn', '+216 71 444 555', 'INSURER');
    await _db.insert(UserTables.insurers, {'company': 'CNAM', 'agent_code': 'CNAM-AG-301', 'user_id': insurerUserId});

    // ----- Notifications de démo -----
    await _db.insert(SharedTables.notifications, {
      'user_id': patientUserId,
      'type': 'APPOINTMENT',
      'title': 'Rendez-vous confirmé',
      'body': 'Dr Sami Benali vous attend dans 3 jours à 10:00.',
    });
    await _db.insert(SharedTables.notifications, {
      'user_id': adminUserId,
      'type': 'ACCOUNT',
      'title': 'Nouvelle demande de compte',
      'body': 'Dr Mariem Haddad (Pédiatrie) attend la validation de son compte.',
    });
  }
}
