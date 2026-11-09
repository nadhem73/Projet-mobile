import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:medilink/features/appointment/data/services/appointment_suggestion_service.dart';
import 'package:medilink/features/appointment/data/services/symptom_analyzer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Base de démo : Benali (Cardiologie, Tunis), Trabelsi (Médecine générale),
// Gharbi (Dermatologie, Sfax) actifs ; Haddad (Pédiatrie) en attente de validation.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late AppointmentRepository appointments;
  late AppointmentSuggestionService service;
  late int patientId;
  const analyzer = SymptomAnalyzer();

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    final doctors = DoctorSearchRepository(database);
    appointments = AppointmentRepository(database, doctors, NotificationService(database));
    service = AppointmentSuggestionService(doctors, appointments);
    patientId =
        (await database.db.rawQuery(
              "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
            )).first['patient_id']
            as int;
  });

  tearDown(() => database.close());

  test('palpitations → Dr Benali avec un créneau dans la semaine', () async {
    final orientation = analyzer.analyze("J'ai des palpitations et un essoufflement à l'effort");
    final result = await service.suggest(orientation);

    expect(result.specialty, 'Cardiologie');
    expect(result.usedFallback, isFalse);
    expect(result.best!.doctor.nom, 'Benali');
    final now = DateTime.now();
    expect(result.best!.firstSlot.isAfter(now), isTrue);
    expect(result.best!.firstSlot.isBefore(now.add(const Duration(days: 8))), isTrue);
  });

  test('aucun pédiatre validé → un généraliste est proposé à la place', () async {
    final orientation = analyzer.analyze('Mon fils a de la fièvre et tousse');
    expect(orientation.specialty, 'Pédiatrie');

    final result = await service.suggest(orientation);
    expect(result.usedFallback, isTrue);
    expect(result.specialty, OrientationResult.defaultSpecialty);
    expect(result.best!.doctor.nom, 'Trabelsi');
  });

  test('urgence → aucune proposition de rendez-vous', () async {
    final orientation = analyzer.analyze("J'ai une forte douleur dans la poitrine");
    final result = await service.suggest(orientation);
    expect(result.isEmpty, isTrue);
  });

  test('le premier créneau proposé n\'est jamais un créneau déjà réservé', () async {
    final orientation = analyzer.analyze("J'ai des boutons et ça me gratte");
    final first = (await service.suggest(orientation)).best!;
    await appointments.book(patientId: patientId, doctorId: first.doctor.doctorId, dateTime: first.firstSlot);

    final next = (await service.suggest(orientation)).best!;
    expect(next.doctor.doctorId, first.doctor.doctorId);
    expect(next.firstSlot, isNot(first.firstSlot));
    expect(next.firstSlot.isAfter(first.firstSlot), isTrue);
  });

  test('avec une ville : les médecins de cette ville passent en premier', () async {
    // Deuxième cardiologue, à Sfax.
    final userId = await database.db.insert('users', {
      'nom': 'Mansour',
      'prenom': 'Leila',
      'email': 'dr.mansour@medilink.tn',
      'password_hash': 'x',
      'role': 'DOCTOR',
    });
    final doctorId = await database.db.insert('doctors', {
      'license_number': 'TN-MED-9999',
      'specialty': 'Cardiologie',
      'user_id': userId,
    });
    await database.db.insert('doctor_profiles', {
      'doctor_id': doctorId,
      'city': 'Sfax',
      'fee': 55.0,
      'working_hours': jsonEncode({
        for (final d in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat']) d: ['08:00-18:00'],
      }),
    });

    final orientation = analyzer.analyze("J'ai des palpitations");
    final inSfax = await service.suggest(orientation, city: 'Sfax');
    expect(inSfax.suggestions, hasLength(2));
    expect(inSfax.best!.doctor.nom, 'Mansour');

    final inTunis = await service.suggest(orientation, city: 'Tunis');
    expect(inTunis.best!.doctor.nom, 'Benali');
  });
}
