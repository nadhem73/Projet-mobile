import 'dart:io';

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
    expect(users, hasLength(8));
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

  test('mise à jour du schéma : suppression de toutes les tables dans une transaction', () async {
    // Reproduit onUpgrade (transaction, clés étrangères actives) sur une base remplie.
    await database.db.transaction((txn) => AppDatabase.dropAll(txn));
    final left = await database.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    expect(left, isEmpty);
  });

  test("mise à jour du schéma : une base d'ancienne version est recréée", () async {
    final path = '${Directory.systemTemp.createTempSync('medilink').path}/upgrade.db';
    final old = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(version: 1));
    await old.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT)');
    await old.execute('CREATE TABLE patients (patient_id INTEGER PRIMARY KEY, user_id INTEGER REFERENCES users(id))');
    await old.execute(
      'CREATE TABLE medical_records (id INTEGER PRIMARY KEY, patient_id INTEGER REFERENCES patients(patient_id))',
    );
    await old.insert('users', {'id': 1, 'email': 'a@b.tn'});
    await old.insert('patients', {'patient_id': 1, 'user_id': 1});
    await old.insert('medical_records', {'patient_id': 1});
    await old.close();

    final upgraded = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    expect(await upgraded.db.query('users'), hasLength(8));
    await upgraded.close();
  });

  test('les clés étrangères sont actives', () async {
    expect(() => database.db.insert('patients', {'user_id': 999}), throwsA(isA<DatabaseException>()));
  });
}
