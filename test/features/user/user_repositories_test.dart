import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/models/registration_data.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late AuthRepository auth;
  late ProfileRepository profiles;
  late MedicalRecordRepository records;

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    auth = AuthRepository(database, const PasswordHasher());
    profiles = ProfileRepository(database, auth);
    records = MedicalRecordRepository(database);
  });

  tearDown(() => database.close());

  RegistrationData data(UserRole role, {String email = 'nouveau@medilink.tn'}) => RegistrationData(
    role: role,
    nom: 'Test',
    prenom: 'Compte',
    email: email,
    phone: '22 111 333',
    password: 'Motdepasse1',
    cin: '11223344',
    gender: 'M',
    specialty: 'Pédiatrie',
    city: 'Sousse',
    licenseNumber: 'LIC-${role.name}',
    pharmacyName: 'Pharmacie du Centre',
    company: 'STAR',
    agentCode: 'AG-1',
  );

  group('Connexion', () {
    test('chaque compte de démo ouvre la session de son rôle', () async {
      const accounts = {
        'patient@medilink.tn': UserRole.patient,
        'dr.benali@medilink.tn': UserRole.doctor,
        'pharmacie@medilink.tn': UserRole.pharmacist,
        'assurance@medilink.tn': UserRole.insurer,
      };
      for (final MapEntry(key: email, value: role) in accounts.entries) {
        final user = await auth.login(email, DatabaseSeeder.demoPassword);
        expect(user.role, role, reason: email);
      }
      final doctor = await auth.login('DR.BENALI@medilink.tn', DatabaseSeeder.demoPassword);
      expect(doctor.doctorId, isNotNull);
      expect(doctor.specialty, 'Cardiologie');
      final pharmacist = await auth.login('pharmacie@medilink.tn', DatabaseSeeder.demoPassword);
      expect(pharmacist.organization, 'Pharmacie Ennour');
    });

    test('mauvais mot de passe refusé', () async {
      expect(
        () => auth.login('patient@medilink.tn', 'faux12345'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'invalid_credentials')),
      );
    });
  });

  group('Inscription', () {
    test('crée le compte et la ligne du rôle pour les 4 rôles', () async {
      for (final role in UserRole.values) {
        final user = await auth.register(data(role, email: '${role.name}@test.tn'));
        expect(user.role, role);
        switch (role) {
          case UserRole.patient:
            expect(user.patientId, isNotNull);
            final record = await records.forPatient(user.patientId!);
            expect(record.gender, 'M');
          case UserRole.doctor:
            expect(user.doctorId, isNotNull);
            expect(user.specialty, 'Pédiatrie');
          case UserRole.pharmacist:
            expect(user.pharmacistId, isNotNull);
            expect(user.organization, 'Pharmacie du Centre');
          case UserRole.insurer:
            expect(user.insurerId, isNotNull);
            expect(user.organization, 'STAR');
        }
        expect((await auth.login('${role.name}@test.tn', 'Motdepasse1')).userId, user.userId);
      }
    });

    test('e-mail déjà utilisé refusé', () async {
      expect(
        () => auth.register(data(UserRole.patient, email: 'patient@medilink.tn')),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'email_taken')),
      );
    });

    test('CIN déjà utilisé refusé', () async {
      await auth.register(data(UserRole.patient, email: 'a@test.tn'));
      expect(() => auth.register(data(UserRole.patient, email: 'b@test.tn')), throwsA(isA<AppException>()));
    });
  });

  group('Mots de passe', () {
    test('réinitialisation avec e-mail + téléphone du compte', () async {
      await auth.resetPassword(email: 'patient@medilink.tn', phone: '+21622345678', newPassword: 'Nouveau123');
      expect((await auth.login('patient@medilink.tn', 'Nouveau123')).isPatient, isTrue);
    });

    test('réinitialisation refusée si le téléphone ne correspond pas', () async {
      expect(
        () => auth.resetPassword(email: 'patient@medilink.tn', phone: '99999999', newPassword: 'Nouveau123'),
        throwsA(isA<AppException>()),
      );
    });

    test('changement de mot de passe vérifie l\'ancien', () async {
      final user = await auth.login('patient@medilink.tn', DatabaseSeeder.demoPassword);
      expect(
        () => auth.changePassword(userId: user.userId, current: 'faux', newPassword: 'Autre1234'),
        throwsA(isA<AppException>()),
      );
      await auth.changePassword(userId: user.userId, current: DatabaseSeeder.demoPassword, newPassword: 'Autre1234');
      expect((await auth.login('patient@medilink.tn', 'Autre1234')).userId, user.userId);
    });
  });

  group('Profil', () {
    test('modification du profil médecin (y compris doctor_profiles)', () async {
      final user = await auth.login('dr.gharbi@medilink.tn', DatabaseSeeder.demoPassword);
      final profile = await profiles.load(user);
      expect(profile.licenseNumber, 'TN-MED-1003');
      final updated = await profiles.save(profile.copyWith(prenom: 'Youssef-Ali', fee: 70, specialty: 'Pédiatrie'));
      expect(updated.prenom, 'Youssef-Ali');
      expect(updated.specialty, 'Pédiatrie');
      expect((await profiles.load(updated)).fee, 70);
    });

    test('e-mail d\'un autre compte refusé', () async {
      final user = await auth.login('patient@medilink.tn', DatabaseSeeder.demoPassword);
      final profile = await profiles.load(user);
      expect(() => profiles.save(profile.copyWith(email: 'dr.benali@medilink.tn')), throwsA(isA<AppException>()));
    });
  });

  group('Dossier médical', () {
    test('lecture du dossier de démo, IMC calculé', () async {
      final user = await auth.login('patient@medilink.tn', DatabaseSeeder.demoPassword);
      final record = await records.forPatient(user.patientId!);
      expect(record.bloodGroup, 'O+');
      expect(record.allergyList, ['Pénicilline']);
      expect(record.bmi, closeTo(21.3, 0.1));
    });

    test('enregistrement puis relecture', () async {
      final user = await auth.register(data(UserRole.patient));
      final saved = await records.save(
        MedicalRecord(
          patientId: user.patientId!,
          gender: 'M',
          bloodGroup: 'A+',
          height: 180,
          weight: 75,
          allergies: 'Arachides, Latex',
        ),
      );
      expect(saved.allergyList, ['Arachides', 'Latex']);
      expect(saved.updatedAt, isNotNull);
      expect(saved.completion, greaterThan(0));
    });

    test('groupe sanguin invalide refusé par la base', () async {
      final user = await auth.register(data(UserRole.patient));
      expect(
        () => records.save(MedicalRecord(patientId: user.patientId!, bloodGroup: 'Z+')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
