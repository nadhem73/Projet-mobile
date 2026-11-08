import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Base de démo (database_seeder.dart) : Benali (Cardiologie, Tunis),
// Trabelsi (Médecine générale), Gharbi (Dermatologie, Sfax) sont actifs ;
// Haddad (Pédiatrie, Sousse) est en attente de validation.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late DoctorSearchRepository repository;

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repository = DoctorSearchRepository(database);
  });

  tearDown(() => database.close());

  test('ne propose que les médecins actifs', () async {
    final doctors = await repository.search();
    final names = doctors.map((d) => d.nom).toList();
    expect(names, containsAll(['Benali', 'Trabelsi', 'Gharbi']));
    expect(names, isNot(contains('Haddad')));
  });

  test('les infos du profil sont chargées', () async {
    final benali = (await repository.search(query: 'Benali')).single;
    expect(benali.specialty, 'Cardiologie');
    expect(benali.fee, isNotNull);
    expect(benali.city, isNotNull);
    expect(benali.workingHours.days, isNotEmpty);
  });

  test('recherche par nom ou par spécialité', () async {
    expect((await repository.search(query: 'gharb')).single.nom, 'Gharbi');
    expect((await repository.search(query: 'cardio')).single.nom, 'Benali');
    expect(await repository.search(query: 'introuvable'), isEmpty);
  });

  test('filtres spécialité et ville', () async {
    expect((await repository.search(specialty: 'Dermatologie')).single.nom, 'Gharbi');
    expect((await repository.search(city: 'Sfax')).single.nom, 'Gharbi');
    expect(await repository.search(specialty: 'Pédiatrie'), isEmpty); // médecin en attente
  });

  test('byId', () async {
    final benali = (await repository.search(query: 'Benali')).single;
    expect((await repository.byId(benali.doctorId))?.nom, 'Benali');
    expect(await repository.byId(9999), isNull);
  });

  test('listes de spécialités et de villes sans le médecin en attente', () async {
    final specialties = await repository.specialties();
    expect(specialties, containsAll(['Cardiologie', 'Dermatologie', 'Médecine générale']));
    expect(specialties, isNot(contains('Pédiatrie')));
    expect(await repository.cities(), isNot(contains('Sousse')));
  });
}
