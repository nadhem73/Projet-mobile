import 'package:flutter/foundation.dart';
import 'package:medilink/core/database/seeders/medicine_seeder.dart';
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

    // ----- Pharmacien de démo (Pharmacie Ennour) -----
    final pharmacistUserId = await user('Mansouri', 'Hela', 'pharmacie@medilink.tn', '+216 71 222 333', 'PHARMACIST');
    await _db.insert(UserTables.pharmacists, {
      'pharmacy_name': 'Pharmacie Ennour',
      'license_number': 'TN-PH-2001',
      'address': 'Rue de Marseille',
      'city': 'Tunis',
      'user_id': pharmacistUserId,
    });
    await _db.insert('pharmacies', {
      'name': 'Pharmacie Ennour',
      'address': 'Rue de Marseille, Tunis',
      'phone': '+216 71 222 333',
      'email': 'pharmacie@medilink.tn',
      'latitude': 36.8000,
      'longitude': 10.1800,
      'pharmacien_user_id': pharmacistUserId,
      'opening_hours': jsonEncode({'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'}),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // ----- 33 Pharmacies OSM Vérifiées (Tunis, Ariana, Manouba) -----
    final pharmaciesData = [
      // -----------------------------------------------------------------------
      // GOUVERNORAT DE TUNIS (13 Pharmacies Vérifiées OSM)
      // -----------------------------------------------------------------------
      {
        'nom': 'Karray',
        'prenom': 'Slim',
        'email': 'dr.slim.karray@medilink.tn',
        'phone': '+216 71 243 520',
        'pharmacy_name': 'Pharmacie de Nuit Dr. Slim Karray',
        'address': '20 Avenue de la Liberté, Bab Bhar, Tunis 1002',
        'lat': 36.8113322,
        'lon': 10.1768947,
        'hours': {'monday': '19:30-08:30', 'tuesday': '19:30-08:30', 'wednesday': '19:30-08:30', 'thursday': '19:30-08:30', 'friday': '19:30-08:30', 'saturday': '19:30-08:30', 'sunday': '19:30-08:30'},
      },
      {
        'nom': 'Guiga',
        'prenom': 'Maher',
        'email': 'dr.maher.guiga@medilink.tn',
        'phone': '+216 71 222 284',
        'pharmacy_name': 'Pharmacie de Nuit Dr. Maher Guiga',
        'address': '24 Avenue Habib Bourguiba, Le Bardo, Tunis 2000',
        'lat': 36.8093066,
        'lon': 10.1370490,
        'hours': {'monday': '19:00-08:00', 'tuesday': '19:00-08:00', 'wednesday': '19:00-08:00', 'thursday': '19:00-08:00', 'friday': '19:00-08:00', 'saturday': '19:00-08:00', 'sunday': '19:00-08:00'},
      },
      {
        'nom': 'Houissa',
        'prenom': 'Officine',
        'email': 'pharmacie.nuit.houissa@medilink.tn',
        'phone': '+216 71 731 220',
        'pharmacy_name': 'Pharmacie de Nuit Houissa',
        'address': 'Avenue Habib Bourguiba, Carthage / Marsa 2016',
        'lat': 36.8693081,
        'lon': 10.3429057,
        'hours': {'monday': '19:30-08:30', 'tuesday': '19:30-08:30', 'wednesday': '19:30-08:30', 'thursday': '19:30-08:30', 'friday': '19:30-08:30', 'saturday': '19:30-08:30', 'sunday': '19:30-08:30'},
      },
      {
        'nom': 'Sidi Hassine',
        'prenom': 'Garde',
        'email': 'pharmacie.nuit.sidihassine@medilink.tn',
        'phone': '+216 71 590 100',
        'pharmacy_name': 'Pharmacie de Nuit Sidi Hassine',
        'address': 'Rue 4853, Sidi Hassine, Tunis 1095',
        'lat': 36.7684776,
        'lon': 10.1136669,
        'hours': {'monday': '19:30-08:30', 'tuesday': '19:30-08:30', 'wednesday': '19:30-08:30', 'thursday': '19:30-08:30', 'friday': '19:30-08:30', 'saturday': '19:30-08:30', 'sunday': '19:30-08:30'},
      },
      {
        'nom': 'Bourguiba',
        'prenom': 'Centrale',
        'email': 'pharmacie.centrale.tunis@medilink.tn',
        'phone': '+216 71 252 535',
        'pharmacy_name': 'Pharmacie Centrale',
        'address': 'Avenue Habib Bourguiba, Tunis 1000',
        'lat': 36.8028513,
        'lon': 10.1827555,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:30', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Faiza',
        'prenom': 'Dr',
        'email': 'pharmacie.faiza@medilink.tn',
        'phone': '+216 71 254 110',
        'pharmacy_name': 'Pharmacie Faïza',
        'address': 'Rue de Rome / Av. Habib Bourguiba, Tunis 1000',
        'lat': 36.8039956,
        'lon': 10.1805642,
        'hours': {'monday': '08:30-19:30', 'tuesday': '08:30-19:30', 'wednesday': '08:30-19:30', 'thursday': '08:30-19:30', 'friday': '08:30-19:30', 'saturday': '08:30-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Chaouch',
        'prenom': 'Taher',
        'email': 'dr.taher.chaouch@medilink.tn',
        'phone': '+216 71 784 210',
        'pharmacy_name': 'Pharmacie Taher Chaouch',
        'address': 'Avenue Hédi Chaker, Tunis 1002',
        'lat': 36.8165748,
        'lon': 10.1808556,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Bab',
        'prenom': 'El Assal',
        'email': 'pharmacie.babalassal@medilink.tn',
        'phone': '+216 71 570 120',
        'pharmacy_name': 'Pharmacie Bab El Assal',
        'address': 'Avenue El Béchir Sfar, Bab El Assal, Tunis 1005',
        'lat': 36.8127465,
        'lon': 10.1699778,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Du Parc',
        'prenom': 'Officine',
        'email': 'pharmacie.duparc@medilink.tn',
        'phone': '+216 71 340 550',
        'pharmacy_name': 'Pharmacie du Parc',
        'address': 'Avenue Habib Thameur (Le Passage), Tunis 1000',
        'lat': 36.8058989,
        'lon': 10.1773572,
        'hours': {'monday': '08:00-20:00', 'tuesday': '08:00-20:00', 'wednesday': '08:00-20:00', 'thursday': '08:00-20:00', 'friday': '08:00-20:00', 'saturday': '08:00-15:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Mendès',
        'prenom': 'France',
        'email': 'pharmacie.mendesfrance@medilink.tn',
        'phone': '+216 71 848 213',
        'pharmacy_name': 'Pharmacie Pierre Mendès France',
        'address': 'Rue Pierre Mendès France, Mutuelleville, Tunis 1082',
        'lat': 36.8311843,
        'lon': 10.1726005,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Ben Hamza',
        'prenom': 'Hedia',
        'email': 'dr.benhamza.lac@medilink.tn',
        'phone': '+216 71 964 634',
        'pharmacy_name': 'Pharmacie Ben Hamza Hedia',
        'address': 'Rue du Lac Inari, Les Berges du Lac 1, Tunis 1053',
        'lat': 36.8318637,
        'lon': 10.2314980,
        'hours': {'monday': '08:30-20:00', 'tuesday': '08:30-20:00', 'wednesday': '08:30-20:00', 'thursday': '08:30-20:00', 'friday': '08:30-20:00', 'saturday': '08:30-16:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'De La Bourse',
        'prenom': 'Lac 2',
        'email': 'pharmacie.bourse.lac2@medilink.tn',
        'phone': '+216 71 190 007',
        'pharmacy_name': 'Pharmacie de la Bourse',
        'address': 'Avenue de la Bourse, Les Berges du Lac 2, Tunis 1053',
        'lat': 36.8481732,
        'lon': 10.2710158,
        'hours': {'monday': '08:30-20:00', 'tuesday': '08:30-20:00', 'wednesday': '08:30-20:00', 'thursday': '08:30-20:00', 'friday': '08:30-20:00', 'saturday': '08:30-16:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Belkhodja',
        'prenom': 'Laouiti',
        'email': 'pharmacie.marsa.13aout@medilink.tn',
        'phone': '+216 71 740 775',
        'pharmacy_name': 'Pharmacie Belkhodja Laouiti',
        'address': 'Rue du 13 Août 1956, La Marsa Ville, Tunis 2070',
        'lat': 36.8821144,
        'lon': 10.3278397,
        'hours': {'monday': '08:00-20:30', 'tuesday': '08:00-20:30', 'wednesday': '08:00-20:30', 'thursday': '08:00-20:30', 'friday': '08:00-20:30', 'saturday': '08:00-16:00', 'sunday': '09:00-14:00'},
      },

      // -----------------------------------------------------------------------
      // GOUVERNORAT DE L'ARIANA (12 Pharmacies Vérifiées OSM)
      // -----------------------------------------------------------------------
      {
        'nom': 'Jellouli',
        'prenom': 'Hedia',
        'email': 'dr.hedia.jellouli@medilink.tn',
        'phone': '+216 71 829 250',
        'pharmacy_name': 'Pharmacie de Nuit Hedia Jellouli',
        'address': 'Avenue Hédi Nouira, Cité Ennasr 2, Ariana 2037',
        'lat': 36.8559456,
        'lon': 10.1559505,
        'hours': {'monday': '19:30-08:30', 'tuesday': '19:30-08:30', 'wednesday': '19:30-08:30', 'thursday': '19:30-08:30', 'friday': '19:30-08:30', 'saturday': '19:30-08:30', 'sunday': '19:30-08:30'},
      },
      {
        'nom': 'Intilaka',
        'prenom': 'Nuit',
        'email': 'pharmacie.nuit.intilaka@medilink.tn',
        'phone': '+216 71 546 273',
        'pharmacy_name': 'Pharmacie de Nuit Cité Intilaka',
        'address': 'Avenue Mongi Slim, Cité Intilaka / Mnihla, Ariana 1064',
        'lat': 36.8402748,
        'lon': 10.1165802,
        'hours': {'monday': '19:00-08:00', 'tuesday': '19:00-08:00', 'wednesday': '19:00-08:00', 'thursday': '19:00-08:00', 'friday': '19:00-08:00', 'saturday': '19:00-08:00', 'sunday': '19:00-08:00'},
      },
      {
        'nom': 'Zouhir',
        'prenom': 'Fethi',
        'email': 'pharmacie.nuit.ghazela@medilink.tn',
        'phone': '+216 71 858 000',
        'pharmacy_name': 'Pharmacie de Nuit Cité El Ghazala',
        'address': 'Rue Fathi Zouhir, Cité El Ghazala, Ariana 2088',
        'lat': 36.8779911,
        'lon': 10.1857929,
        'hours': {'monday': '19:30-08:30', 'tuesday': '19:30-08:30', 'wednesday': '19:30-08:30', 'thursday': '19:30-08:30', 'friday': '19:30-08:30', 'saturday': '19:30-08:30', 'sunday': '19:30-08:30'},
      },
      {
        'nom': 'Menzah 6',
        'prenom': 'Nuit',
        'email': 'pharmacie.nuit.menzah6@medilink.tn',
        'phone': '+216 71 230 890',
        'pharmacy_name': 'Pharmacie de Nuit El Menzah 6',
        'address': 'Avenue Othman Ibn Affane, El Menzah 6, Ariana 2091',
        'lat': 36.8424613,
        'lon': 10.1659011,
        'hours': {'monday': '19:00-08:00', 'tuesday': '19:00-08:00', 'wednesday': '19:00-08:00', 'thursday': '19:00-08:00', 'friday': '19:00-08:00', 'saturday': '19:00-08:00', 'sunday': '19:00-08:00'},
      },
      {
        'nom': 'Khabthani',
        'prenom': 'Fayez',
        'email': 'dr.fayez.khabthani@medilink.tn',
        'phone': '+216 70 830 550',
        'pharmacy_name': 'Pharmacie Fayez Khabthani',
        'address': 'Avenue Hédi Nouira, Cité Ennasr 2, Ariana 2037',
        'lat': 36.8585794,
        'lon': 10.1620726,
        'hours': {'monday': '08:30-20:00', 'tuesday': '08:30-20:00', 'wednesday': '08:30-20:00', 'thursday': '08:30-20:00', 'friday': '08:30-20:00', 'saturday': '08:30-18:00', 'sunday': '09:00-15:00'},
      },
      {
        'nom': 'Cheikh-Rouhou',
        'prenom': 'Jaouida',
        'email': 'dr.cheikhrouhou@medilink.tn',
        'phone': '+216 70 832 100',
        'pharmacy_name': 'Pharmacie Jaouida Cheikh-Rouhou',
        "address": "Avenue de l'Ère Nouvelle, Cité Ennasr 1, Ariana 2037",
        'lat': 36.8567493,
        'lon': 10.1607476,
        'hours': {'monday': '08:00-20:00', 'tuesday': '08:00-20:00', 'wednesday': '08:00-20:00', 'thursday': '08:00-20:00', 'friday': '08:00-20:00', 'saturday': '08:00-15:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Ghezaiel',
        'prenom': 'Moncef',
        'email': 'dr.moncef.ghezaiel@medilink.tn',
        'phone': '+216 71 719 448',
        'pharmacy_name': 'Pharmacie Moncef Ghezaiel',
        'address': 'Rue de Carthage, Ariana Ville 2080',
        'lat': 36.8590746,
        'lon': 10.1919532,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Ghroubi',
        'prenom': 'Sana',
        'email': 'dr.sana.ghroubi@medilink.tn',
        'phone': '+216 71 702 330',
        'pharmacy_name': 'Pharmacie Sana Ghroubi',
        'address': 'Avenue Abderrahman Khabthani, Ariana 2080',
        'lat': 36.8553111,
        'lon': 10.1779669,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Ben Hfaiedh',
        'prenom': 'Hassen',
        'email': 'dr.benhfaiedh@medilink.tn',
        'phone': '+216 71 710 400',
        'pharmacy_name': 'Pharmacie Hassen Ben Hfaiedh',
        'address': 'Rue Abderrahmen Mami, Ariana 2080',
        'lat': 36.8659170,
        'lon': 10.2000907,
        'hours': {'monday': '08:00-20:00', 'tuesday': '08:00-20:00', 'wednesday': '08:00-20:00', 'thursday': '08:00-20:00', 'friday': '08:00-20:00', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Meddeb',
        'prenom': 'Rofaida',
        'email': 'dr.rofaida.meddeb@medilink.tn',
        'phone': '+216 71 754 731',
        'pharmacy_name': 'Pharmacie Rofaida Meddeb',
        'address': 'Avenue Ammar Ibn Yasser, El Menzah 6, Ariana 2091',
        'lat': 36.8498600,
        'lon': 10.1651163,
        'hours': {'monday': '08:00-20:00', 'tuesday': '08:00-20:00', 'wednesday': '08:00-20:00', 'thursday': '08:00-20:00', 'friday': '08:00-20:00', 'saturday': '08:00-15:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Mnif',
        'prenom': 'Fatma',
        'email': 'dr.fatma.mnif@medilink.tn',
        'phone': '+216 71 858 000',
        'pharmacy_name': 'Pharmacie Fatma Mnif',
        'address': 'Avenue Habib Bourguiba, Cité El Ghazala, Ariana 2088',
        'lat': 36.8912796,
        'lon': 10.1714301,
        'hours': {'monday': '08:00-20:00', 'tuesday': '08:00-20:00', 'wednesday': '08:00-20:00', 'thursday': '08:00-20:00', 'friday': '08:00-20:00', 'saturday': '08:00-15:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Hamdoun',
        'prenom': 'Larguech',
        'email': 'dr.hamdoun.larguech@medilink.tn',
        'phone': '+216 70 688 220',
        'pharmacy_name': 'Pharmacie Hamdoun Larguech',
        "address": "Avenue de l'Union du Maghreb Arabe (UMA), La Soukra, Ariana 2036",
        'lat': 36.8749797,
        'lon': 10.2443516,
        'hours': {'monday': '08:30-20:00', 'tuesday': '08:30-20:00', 'wednesday': '08:30-20:00', 'thursday': '08:30-20:00', 'friday': '08:30-20:00', 'saturday': '08:30-16:00', 'sunday': 'Fermé'},
      },

      // -----------------------------------------------------------------------
      // GOUVERNORAT DE LA MANOUBA (8 Pharmacies Vérifiées OSM)
      // -----------------------------------------------------------------------
      {
        'nom': 'Douar',
        'prenom': 'Hicher',
        'email': 'pharmacie.nuit.douarhicher@medilink.tn',
        'phone': '+216 71 641 220',
        'pharmacy_name': 'Pharmacie de Nuit Douar Hicher',
        'address': 'Avenue des Martyrs, Douar Hicher, Manouba 2086',
        'lat': 36.8213541,
        'lon': 10.0896295,
        'hours': {'monday': '19:00-08:00', 'tuesday': '19:00-08:00', 'wednesday': '19:00-08:00', 'thursday': '19:00-08:00', 'friday': '19:00-08:00', 'saturday': '19:00-08:00', 'sunday': '19:00-08:00'},
      },
      {
        'nom': 'Oued',
        'prenom': 'Ellil',
        'email': 'pharmacie.nuit.ouedellil@medilink.tn',
        'phone': '+216 71 625 110',
        'pharmacy_name': 'Pharmacie de Nuit Oued Ellil',
        "address": "Avenue de l'Indépendance, Oued Ellil, Manouba 2021",
        'lat': 36.8256460,
        'lon': 10.0965013,
        'hours': {'monday': '19:00-08:00', 'tuesday': '19:00-08:00', 'wednesday': '19:00-08:00', 'thursday': '19:00-08:00', 'friday': '19:00-08:00', 'saturday': '19:00-08:00', 'sunday': '19:00-08:00'},
      },
      {
        'nom': 'Manouba',
        'prenom': 'Nuit',
        'email': 'pharmacie.nuit.manouba@medilink.tn',
        'phone': '+216 71 600 320',
        'pharmacy_name': 'Pharmacie de Nuit Manouba Hôpital',
        'address': 'Avenue Habib Bourguiba (Face Hôpital Razi), Manouba 2010',
        'lat': 36.8144495,
        'lon': 10.1011402,
        'hours': {'monday': '19:30-08:30', 'tuesday': '19:30-08:30', 'wednesday': '19:30-08:30', 'thursday': '19:30-08:30', 'friday': '19:30-08:30', 'saturday': '19:30-08:30', 'sunday': '19:30-08:30'},
      },
      {
        'nom': 'Tebourba',
        'prenom': 'Nuit',
        'email': 'pharmacie.nuit.tebourba@medilink.tn',
        'phone': '+216 71 660 210',
        'pharmacy_name': 'Pharmacie de Nuit Tebourba - Djedaida',
        'address': 'Route Principale, Tebourba / Djedaida, Manouba 1124',
        'lat': 36.8482850,
        'lon': 9.9355791,
        'hours': {'monday': '19:00-08:00', 'tuesday': '19:00-08:00', 'wednesday': '19:00-08:00', 'thursday': '19:00-08:00', 'friday': '19:00-08:00', 'saturday': '19:00-08:00', 'sunday': '19:00-08:00'},
      },
      {
        'nom': 'Travailleurs',
        'prenom': 'Manouba',
        'email': 'pharmacie.interne.manouba@medilink.tn',
        'phone': '+216 71 608 444',
        'pharmacy_name': 'Pharmacie des Travailleurs',
        'address': 'Rue des Travailleurs, Manouba 2010',
        'lat': 36.8144734,
        'lon': 10.1017352,
        'hours': {'monday': '08:00-19:00', 'tuesday': '08:00-19:00', 'wednesday': '08:00-19:00', 'thursday': '08:00-19:00', 'friday': '08:00-19:00', 'saturday': '08:00-13:30', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Amira',
        'prenom': 'Naoufel',
        'email': 'dr.naoufel.amira@medilink.tn',
        'phone': '+216 71 640 880',
        'pharmacy_name': 'Pharmacie Naoufel Amira',
        'address': 'Avenue Khaled Ibn El Walid, Douar Hicher, Manouba 2086',
        'lat': 36.8195680,
        'lon': 10.0949753,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'Boumaiza',
        'prenom': 'Dr',
        'email': 'pharmacie.boumaiza@medilink.tn',
        'phone': '+216 71 650 340',
        'pharmacy_name': 'Pharmacie Boumaïza',
        'address': 'Avenue Habib Bourguiba, Mornaguia, Manouba 1110',
        'lat': 36.7592016,
        'lon': 10.0211302,
        'hours': {'monday': '08:00-19:30', 'tuesday': '08:00-19:30', 'wednesday': '08:00-19:30', 'thursday': '08:00-19:30', 'friday': '08:00-19:30', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
      {
        'nom': 'El Amri',
        'prenom': 'Dr',
        'email': 'pharmacie.elamri@medilink.tn',
        'phone': '+216 71 651 020',
        'pharmacy_name': 'Pharmacie El Amri',
        'address': 'Route Principale GP5, Mornaguia, Manouba 1110',
        'lat': 36.7587987,
        'lon': 10.0190716,
        'hours': {'monday': '08:00-19:00', 'tuesday': '08:00-19:00', 'wednesday': '08:00-19:00', 'thursday': '08:00-19:00', 'friday': '08:00-19:00', 'saturday': '08:00-14:00', 'sunday': 'Fermé'},
      },
    ];

    for (int i = 0; i < pharmaciesData.length; i++) {
      final p = pharmaciesData[i];
      final uId = await user(
        p['nom'] as String,
        p['prenom'] as String,
        p['email'] as String,
        p['phone'] as String,
        'PHARMACIST',
      );
      final address = p['address'] as String;
      final city = address.contains('Ariana') ? 'Ariana' : (address.contains('Manouba') ? 'Manouba' : 'Tunis');
      await _db.insert(UserTables.pharmacists, {
        'pharmacy_name': p['pharmacy_name'],
        'license_number': 'TN-PH-${2002 + i}',
        'address': address,
        'city': city,
        'user_id': uId,
      });
      await _db.insert('pharmacies', {
        'name': p['pharmacy_name'],
        'address': address,
        'phone': p['phone'],
        'email': p['email'],
        'latitude': p['lat'],
        'longitude': p['lon'],
        'pharmacien_user_id': uId,
        'opening_hours': jsonEncode(p['hours']),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    // ----- Médicaments et stocks (import CSV & génération) -----
    try {
      if (_db is Database) {
        final medicineSeeder = MedicineSeeder(_db);
        await medicineSeeder.seed();
      }
    } catch (e) {
      debugPrint('[DatabaseSeeder] Medicine seeder warning: $e');
    }

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
