import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });

  tearDown(() => database.close());

  test('crée toutes les tables et insère les comptes de démo', () async {
    final tables = await database.db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final names = tables.map((t) => t['name']).toSet();
    expect(
      names,
      containsAll([
        'users',
        'patients',
        'doctors',
        'doctor_profiles',
        'medical_records',
        'appointments',
        'consultations',
        'prescriptions',
        'prescription_items',
        'insurance_contracts',
        'insurance_claims',
        'pharmacy_orders',
        'pharmacy_order_items',
        'medication_reminders',
        'notifications',
        'lab_results',
      ]),
    );

    final users = await database.db.query('users');
    expect(users, hasLength(4));
    expect(users.every((u) => !(u['password_hash'] as String).contains('Medilink123')), isTrue);
  });

  test('un créneau ne peut pas être réservé deux fois (sauf si annulé)', () async {
    Map<String, Object?> slot(int patientId, [String status = 'PENDING']) => {
      'appointment_date_time': '2026-10-20T09:30:00',
      'doctor_id': 1,
      'patient_id': patientId,
      'status': status,
    };

    await database.db.insert('appointments', slot(1, 'CANCELLED'));
    await database.db.insert('appointments', slot(1));
    expect(() => database.db.insert('appointments', slot(1)), throwsA(isA<DatabaseException>()));
  });

  test('les clés étrangères sont actives', () async {
    expect(
      () => database.db.insert('patients', {'user_id': 999}),
      throwsA(isA<DatabaseException>()),
    );
  });
}
