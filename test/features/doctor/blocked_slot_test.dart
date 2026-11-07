import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:medilink/features/doctor/data/models/blocked_slot.dart';
import 'package:medilink/features/doctor/data/repositories/blocked_slot_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Indisponibilités du médecin : enregistrement (module Médecin) et effet sur la
// réservation des patients (module Rendez-vous). Dr Benali travaille le lundi
// 08:30-12:30 et 14:00-17:00.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late BlockedSlotRepository blocks;
  late AppointmentRepository appointments;
  late int patientId;
  late int benaliId;
  late DateTime monday; // un lundi à au moins une semaine d'ici

  Future<int> idOf(String sql) async => (await database.db.rawQuery(sql)).first.values.first as int;
  DateTime at(int hour, [int minute = 0]) => monday.add(Duration(hours: hour, minutes: minute));
  BlockedSlot slot(DateTime start, DateTime end, {String title = 'Réunion'}) =>
      BlockedSlot(doctorId: benaliId, title: title, start: start, end: end);

  setUpAll(() => initializeDateFormatting('fr'));

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    blocks = BlockedSlotRepository(database);
    appointments = AppointmentRepository(database, DoctorSearchRepository(database), NotificationService(database));
    patientId = await idOf(
      "SELECT p.patient_id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    benaliId = await idOf(
      "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
    );
    final start = DateTime.now().add(const Duration(days: 8));
    final d = start.add(Duration(days: (DateTime.monday - start.weekday) % 7));
    monday = DateTime(d.year, d.month, d.day);
  });

  tearDown(() => database.close());

  group('enregistrement', () {
    test('une indisponibilité est enregistrée puis relue sur la semaine', () async {
      final saved = await blocks.create(slot(at(9), at(10)).copyWithNote('Salle 2'));
      expect(saved.id, isNotNull);
      final week = await blocks.forDoctorBetween(benaliId, monday, monday.add(const Duration(days: 7)));
      expect(week.single.title, 'Réunion');
      expect(week.single.note, 'Salle 2');
      expect(week.single.start, at(9));
      expect(week.single.end, at(10));
    });

    test('refus : titre vide, fin avant début, plage passée', () async {
      expect(() => blocks.create(slot(at(9), at(10), title: '  ')), throwsA(isA<AppException>()));
      expect(() => blocks.create(slot(at(10), at(9))), throwsA(isA<AppException>()));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        () => blocks.create(slot(yesterday, yesterday.add(const Duration(hours: 1)))),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'past')),
      );
    });

    test('refus : chevauche une autre indisponibilité', () async {
      await blocks.create(slot(at(9), at(10)));
      expect(
        () => blocks.create(slot(at(9, 30), at(11), title: 'Formation')),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'overlap')),
      );
      // Bout à bout : accepté.
      await blocks.create(slot(at(10), at(11), title: 'Formation'));
    });

    test('refus : un patient a déjà réservé dans la plage', () async {
      await appointments.book(patientId: patientId, doctorId: benaliId, dateTime: at(9, 30));
      expect(
        () => blocks.create(slot(at(9), at(10))),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'appointment')
              .having((e) => e.message, 'message', contains('09:30')),
        ),
      );
      // Le rendez-vous de 09:30 finit à 10:00 : bloquer à partir de 10:00 reste possible.
      await blocks.create(slot(at(10), at(11)));
    });

    test('suppression : seulement par le médecin concerné', () async {
      final saved = await blocks.create(slot(at(9), at(10)));
      expect(() => blocks.delete(saved.id!, doctorId: benaliId + 1000), throwsA(isA<AppException>()));
      await blocks.delete(saved.id!, doctorId: benaliId);
      expect(await blocks.forDoctorBetween(benaliId, monday, monday.add(const Duration(days: 1))), isEmpty);
    });
  });

  group('effet sur la réservation des patients', () {
    test('les créneaux bloqués ne sont plus proposés, puis reviennent après suppression', () async {
      expect(await appointments.availableSlots(benaliId, monday), hasLength(14));

      // 09:00-10:00 → 09:00 et 09:30 disparaissent.
      final saved = await blocks.create(slot(at(9), at(10)));
      final slots = await appointments.availableSlots(benaliId, monday);
      expect(slots, hasLength(12));
      expect(slots, isNot(contains(at(9))));
      expect(slots, isNot(contains(at(9, 30))));
      expect(slots, contains(at(8, 30)));
      expect(slots, contains(at(10)));

      await blocks.delete(saved.id!, doctorId: benaliId);
      expect(await appointments.availableSlots(benaliId, monday), hasLength(14));
    });

    test('une plage qui ne tombe pas sur une demi-heure bloque les créneaux touchés', () async {
      // 09:15-09:45 touche 09:00-09:30 et 09:30-10:00.
      await blocks.create(slot(at(9, 15), at(9, 45)));
      final slots = await appointments.availableSlots(benaliId, monday);
      expect(slots, isNot(contains(at(9))));
      expect(slots, isNot(contains(at(9, 30))));
      expect(slots, contains(at(10)));
    });

    test('réserver sur un créneau bloqué est refusé', () async {
      await blocks.create(slot(at(9), at(10)));
      expect(
        () => appointments.book(patientId: patientId, doctorId: benaliId, dateTime: at(9, 30)),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'slot_blocked')),
      );
      // Juste après la plage : accepté.
      final ok = await appointments.book(patientId: patientId, doctorId: benaliId, dateTime: at(10));
      expect(ok.id, isNotNull);
    });

    test('l\'indisponibilité d\'un médecin ne gêne pas les autres', () async {
      await blocks.create(slot(at(9), at(10)));
      final other = await idOf(
        "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.gharbi@medilink.tn'",
      );
      expect(await appointments.availableSlots(other, monday), contains(at(9)));
    });
  });
}

extension on BlockedSlot {
  BlockedSlot copyWithNote(String note) =>
      BlockedSlot(id: id, doctorId: doctorId, title: title, start: start, end: end, note: note);
}
