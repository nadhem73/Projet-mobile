import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Base de démo : le patient a un rendez-vous à venir avec Dr Benali (dans 3 jours)
// et un rendez-vous passé avec Dr Trabelsi. Les médecins travaillent le lundi
// 08:30-12:30 et 14:00-17:00.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late NotificationService notifications;
  late AppointmentRepository repository;
  late int patientId;
  late int benaliId;
  late int benaliUserId;
  late DateTime monday; // un lundi à au moins une semaine d'ici

  Future<int> idOf(String sql, List<Object?> args) async =>
      (await database.db.rawQuery(sql, args)).first.values.first as int;

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    notifications = NotificationService(database);
    repository = AppointmentRepository(database, DoctorSearchRepository(database), notifications);

    patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
      [],
    );
    benaliUserId = await idOf("SELECT id FROM users WHERE email = 'dr.benali@medilink.tn'", []);
    benaliId = await idOf('SELECT doctor_id FROM doctors WHERE user_id = ?', [benaliUserId]);

    final start = DateTime.now().add(const Duration(days: 8));
    final d = start.add(Duration(days: (DateTime.monday - start.weekday) % 7));
    monday = DateTime(d.year, d.month, d.day);
  });

  tearDown(() => database.close());

  group('lecture', () {
    test('rendez-vous à venir et passés du patient de démo', () async {
      final upcoming = await repository.upcomingForPatient(patientId);
      final past = await repository.pastForPatient(patientId);
      expect(upcoming.single.doctorName, 'Dr Sami Benali');
      expect(upcoming.single.specialty, 'Cardiologie');
      expect(upcoming.single.status, AppointmentState.confirmed);
      expect(past.single.status, AppointmentState.completed);
    });
  });

  group('créneaux libres', () {
    test('lundi : horaires découpés en 30 min', () async {
      final slots = await repository.availableSlots(benaliId, monday);
      // 08:30-12:30 → 8 créneaux, 14:00-17:00 → 6 créneaux
      expect(slots.length, 14);
      expect(slots.first, monday.add(const Duration(hours: 8, minutes: 30)));
    });

    test('dimanche : aucun créneau', () async {
      expect(await repository.availableSlots(benaliId, monday.subtract(const Duration(days: 1))), isEmpty);
    });

    test('un créneau réservé disparaît, et réapparaît après annulation', () async {
      final nine = monday.add(const Duration(hours: 9));
      final booked = await repository.book(patientId: patientId, doctorId: benaliId, dateTime: nine);
      expect(await repository.availableSlots(benaliId, monday), isNot(contains(nine)));

      await repository.cancel(appointmentId: booked.id!, patientId: patientId);
      expect(await repository.availableSlots(benaliId, monday), contains(nine));
    });
  });

  group('réservation', () {
    test('réserve, apparaît dans « à venir » et prévient le médecin', () async {
      final at = monday.add(const Duration(hours: 10));
      final a = await repository.book(
        patientId: patientId,
        doctorId: benaliId,
        dateTime: at,
        reason: 'Douleur thoracique',
      );

      expect(a.id, isNotNull);
      expect(a.dateTime, at);
      expect(a.status, AppointmentRepository.initialStatus);
      expect(a.patientName, isNotEmpty);
      expect((await repository.upcomingForPatient(patientId)).map((e) => e.id), contains(a.id));

      final notes = await notifications.forUser(benaliUserId);
      expect(notes.first.title, 'Nouveau rendez-vous');
    });

    test('refuse un créneau déjà pris', () async {
      final at = monday.add(const Duration(hours: 11));
      await repository.book(patientId: patientId, doctorId: benaliId, dateTime: at);

      final otherPatient = await database.db.insert('patients', {
        'user_id': await database.db.insert('users', {
          'nom': 'Autre',
          'prenom': 'Patient',
          'email': 'autre@medilink.tn',
          'password_hash': 'x',
          'role': 'PATIENT',
        }),
      });
      await expectLater(
        repository.book(patientId: otherPatient, doctorId: benaliId, dateTime: at),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'slot_taken')),
      );
    });

    test('refuse un créneau hors horaires, passé ou chez un médecin non validé', () async {
      await expectLater(
        repository.book(patientId: patientId, doctorId: benaliId, dateTime: monday.add(const Duration(hours: 13))),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'slot_closed')),
      );
      await expectLater(
        repository.book(patientId: patientId, doctorId: benaliId, dateTime: DateTime(2020, 1, 6, 9)),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'slot_past')),
      );
      final haddadId = await idOf(
        "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.haddad@medilink.tn'",
        [],
      );
      await expectLater(
        repository.book(patientId: patientId, doctorId: haddadId, dateTime: monday.add(const Duration(hours: 9))),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'doctor_unavailable')),
      );
    });
  });

  group('annulation', () {
    test('annule, passe dans l\'historique et prévient le médecin', () async {
      final a = await repository.book(
        patientId: patientId,
        doctorId: benaliId,
        dateTime: monday.add(const Duration(hours: 9)),
      );
      await repository.cancel(appointmentId: a.id!, patientId: patientId);

      expect((await repository.byId(a.id!))!.status, AppointmentState.cancelled);
      expect((await repository.pastForPatient(patientId)).map((e) => e.id), contains(a.id));
      expect((await notifications.forUser(benaliUserId)).first.title, 'Rendez-vous annulé');
    });

    test('un patient ne peut pas annuler le rendez-vous d\'un autre', () async {
      final a = await repository.book(
        patientId: patientId,
        doctorId: benaliId,
        dateTime: monday.add(const Duration(hours: 9)),
      );
      await expectLater(
        repository.cancel(appointmentId: a.id!, patientId: patientId + 999),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'not_found')),
      );
    });

    test('un rendez-vous passé ou déjà annulé ne peut pas être annulé', () async {
      final past = (await repository.pastForPatient(patientId)).single;
      await expectLater(
        repository.cancel(appointmentId: past.id!, patientId: patientId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'not_cancellable')),
      );
    });
  });

  test('agenda du médecin pour une journée', () async {
    await repository.book(patientId: patientId, doctorId: benaliId, dateTime: monday.add(const Duration(hours: 9)));
    final agenda = await repository.forDoctorOnDay(benaliId, monday);
    expect(agenda.single.patientName, isNotEmpty);
  });

  test('agenda du médecin sur une semaine (sans les annulés)', () async {
    final a = await repository.book(
      patientId: patientId,
      doctorId: benaliId,
      dateTime: monday.add(const Duration(hours: 9)),
    );
    final b = await repository.book(
      patientId: patientId,
      doctorId: benaliId,
      dateTime: monday.add(const Duration(days: 1, hours: 10)),
    );
    await repository.cancel(appointmentId: b.id!, patientId: patientId);
    // Lundi suivant : hors de la semaine.
    await repository.book(
      patientId: patientId,
      doctorId: benaliId,
      dateTime: monday.add(const Duration(days: 7, hours: 9)),
    );

    final week = await repository.forDoctorBetween(benaliId, monday, monday.add(const Duration(days: 7)));
    expect(week.map((e) => e.id), [a.id]);
  });
}
