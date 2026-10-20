import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/user/data/models/dependent.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/models/registration_data.dart';
import 'package:medilink/features/user/data/repositories/admin_repository.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/data/repositories/dependent_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late NotificationService notifications;
  late AuthRepository auth;
  late ProfileRepository profiles;
  late MedicalRecordRepository records;
  late MedicalAccessRepository access;
  late AdminRepository admin;
  late DependentRepository dependents;
  late DateTime now;

  const password = DatabaseSeeder.demoPassword;

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    now = DateTime.now();
    notifications = NotificationService(database);
    auth = AuthRepository(database, const PasswordHasher(), notifications, clock: () => now);
    profiles = ProfileRepository(database, auth);
    records = MedicalRecordRepository(database);
    access = MedicalAccessRepository(database, records, notifications);
    admin = AdminRepository(database, notifications);
    dependents = DependentRepository(database);
  });

  tearDown(() => database.close());

  RegistrationData data(UserRole role, {String email = 'nouveau@medilink.tn', String? cin = '11223344'}) =>
      RegistrationData(
        role: role,
        nom: 'Test',
        prenom: 'Compte',
        email: email,
        phone: '22 111 333',
        password: 'Motdepasse1',
        cin: cin,
        gender: 'M',
        specialty: 'Pédiatrie',
        city: 'Sousse',
        licenseNumber: 'LIC-${role.name}',
        pharmacyName: 'Pharmacie du Centre',
        company: 'STAR',
        agentCode: 'AG-1',
      );

  Future<int> userIdOf(String email) async =>
      (await database.db.query('users', columns: ['id'], where: 'email = ?', whereArgs: [email])).first['id'] as int;

  Matcher appError(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

  group('Connexion', () {
    test('chaque compte de démo actif ouvre la session de son rôle', () async {
      const accounts = {
        'patient@medilink.tn': UserRole.patient,
        'dr.benali@medilink.tn': UserRole.doctor,
        'pharmacie@medilink.tn': UserRole.pharmacist,
        'assurance@medilink.tn': UserRole.insurer,
        'admin@medilink.tn': UserRole.admin,
      };
      for (final MapEntry(key: email, value: role) in accounts.entries) {
        expect((await auth.login(email, password)).role, role, reason: email);
      }
      final doctor = await auth.login('DR.BENALI@medilink.tn', password);
      expect(doctor.specialty, 'Cardiologie');
    });

    test('mauvais mot de passe : message générique', () async {
      expect(() => auth.login('patient@medilink.tn', 'faux12345'), appError('invalid_credentials'));
      expect(() => auth.login('inconnu@medilink.tn', 'faux12345'), appError('invalid_credentials'));
    });

    test('5 échecs bloquent le compte 5 minutes, puis il se débloque', () async {
      for (var i = 0; i < 4; i++) {
        await expectLater(auth.login('patient@medilink.tn', 'faux'), throwsA(isA<AppException>()));
      }
      await expectLater(auth.login('patient@medilink.tn', 'faux'), appError('locked'));
      // Même le bon mot de passe est refusé pendant le blocage.
      await expectLater(auth.login('patient@medilink.tn', password), appError('locked'));
      now = now.add(const Duration(minutes: 6));
      expect((await auth.login('patient@medilink.tn', password)).isPatient, isTrue);
    });

    test('compte en attente de validation refusé', () async {
      expect(() => auth.login('dr.haddad@medilink.tn', password), appError('pending'));
    });
  });

  group('Inscription', () {
    test('patient actif immédiatement, avec dossier et notification de bienvenue', () async {
      final user = await auth.register(data(UserRole.patient));
      expect((await auth.login('nouveau@medilink.tn', 'Motdepasse1')).userId, user.userId);
      expect((await records.forPatient(user.patientId!)).gender, 'M');
      expect((await notifications.forUser(user.userId)).first.title, contains('Bienvenue'));
    });

    test('professionnels en attente puis validés par l\'administrateur', () async {
      final adminId = await userIdOf('admin@medilink.tn');
      final before = await notifications.unreadCount(adminId);
      for (final role in [UserRole.doctor, UserRole.pharmacist, UserRole.insurer]) {
        final email = '${role.name}@test.tn';
        final user = await auth.register(data(role, email: email));
        await expectLater(auth.login(email, 'Motdepasse1'), appError('pending'));
        await admin.approve(user.userId);
        expect((await auth.login(email, 'Motdepasse1')).role, role);
      }
      expect(await notifications.unreadCount(adminId), before + 3);
    });

    test('un administrateur ne peut pas s\'inscrire', () async {
      expect(() => auth.register(data(UserRole.admin)), throwsA(isA<AppException>()));
    });

    test('e-mail et CIN uniques', () async {
      expect(() => auth.register(data(UserRole.patient, email: 'patient@medilink.tn')), appError('email_taken'));
      await auth.register(data(UserRole.patient, email: 'a@test.tn'));
      expect(() => auth.register(data(UserRole.patient, email: 'b@test.tn')), appError('duplicate'));
    });
  });

  group('Mot de passe oublié (code SMS)', () {
    test('code correct : nouveau mot de passe et compte débloqué', () async {
      for (var i = 0; i < 5; i++) {
        await expectLater(auth.login('patient@medilink.tn', 'faux'), throwsA(isA<AppException>()));
      }
      final delivery = await auth.requestPasswordReset(email: 'patient@medilink.tn', phone: '22345678');
      expect(delivery.maskedPhone, '•• ••• 678');
      expect(delivery.code, hasLength(6));
      await expectLater(
        auth.resetPasswordWithCode(email: 'patient@medilink.tn', code: '000000', newPassword: 'Nouveau123'),
        appError('wrong_code'),
      );
      await auth.resetPasswordWithCode(email: 'patient@medilink.tn', code: delivery.code, newPassword: 'Nouveau123');
      expect((await auth.login('patient@medilink.tn', 'Nouveau123')).isPatient, isTrue);
    });

    test('code expiré après 10 minutes', () async {
      final delivery = await auth.requestPasswordReset(email: 'patient@medilink.tn', phone: '+216 22 345 678');
      now = now.add(const Duration(minutes: 11));
      expect(
        () => auth.resetPasswordWithCode(email: 'patient@medilink.tn', code: delivery.code, newPassword: 'Nouveau123'),
        appError('expired_code'),
      );
    });

    test('téléphone incorrect refusé', () async {
      expect(() => auth.requestPasswordReset(email: 'patient@medilink.tn', phone: '99999999'), appError('not_found'));
    });

    test('changement de mot de passe vérifie l\'ancien', () async {
      final user = await auth.login('patient@medilink.tn', password);
      expect(
        () => auth.changePassword(userId: user.userId, current: 'faux', newPassword: 'Autre1234'),
        appError('wrong_password'),
      );
      await auth.changePassword(userId: user.userId, current: password, newPassword: 'Autre1234');
      expect((await auth.login('patient@medilink.tn', 'Autre1234')).userId, user.userId);
    });
  });

  group('Administration', () {
    test('statistiques et comptes en attente', () async {
      final stats = await admin.stats();
      expect(stats.pending, 1);
      expect(stats.byRole[UserRole.doctor], 3);
      final pending = await admin.pendingAccounts();
      expect(pending.single.email, 'dr.haddad@medilink.tn');
      expect(pending.single.license, 'TN-MED-1004');
    });

    test('refus avec motif', () async {
      final id = await userIdOf('dr.haddad@medilink.tn');
      expect(() => admin.reject(id, ''), throwsA(isA<AppException>()));
      await admin.reject(id, 'Numéro d\'Ordre introuvable');
      expect(
        () => auth.login('dr.haddad@medilink.tn', password),
        throwsA(isA<AppException>().having((e) => e.message, 'message', contains('introuvable'))),
      );
    });

    test('suspension et réactivation, session invalidée', () async {
      final adminId = await userIdOf('admin@medilink.tn');
      final user = await auth.login('pharmacie@medilink.tn', password);
      await admin.suspend(user.userId, adminUserId: adminId);
      expect(await auth.refreshSession(user.userId), isNull);
      expect(() => auth.login('pharmacie@medilink.tn', password), appError('suspended'));
      await admin.reactivate(user.userId);
      expect(await auth.refreshSession(user.userId), isNotNull);
      expect(() => admin.suspend(adminId, adminUserId: adminId), throwsA(isA<AppException>()));
    });

    test('recherche par nom et filtre par rôle', () async {
      expect((await admin.accounts(query: 'benali')).single.email, 'dr.benali@medilink.tn');
      expect(await admin.accounts(role: UserRole.doctor), hasLength(4));
    });
  });

  group('Dossier médical', () {
    test('dossier de démo, IMC et complétion', () async {
      final user = await auth.login('patient@medilink.tn', password);
      final record = await records.forPatient(user.patientId!);
      expect(record.allergyList, ['Pénicilline']);
      expect(record.surgicalHistory, contains('Appendicectomie'));
      expect(record.bmi, closeTo(21.3, 0.1));
      expect(record.completion, 100);
    });

    test('groupe sanguin invalide refusé par la base', () async {
      final user = await auth.register(data(UserRole.patient));
      expect(
        () => records.save(MedicalRecord(patientId: user.patientId!, bloodGroup: 'Z+')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('vaccins : ajout, date future refusée, suppression', () async {
      final patientId = (await auth.login('patient@medilink.tn', password)).patientId!;
      expect(await records.vaccinations(patientId), hasLength(3));
      await records.saveVaccination(Vaccination(patientId: patientId, name: 'Grippe', date: DateTime(2025, 11, 2)));
      expect(
        () => records.saveVaccination(
          Vaccination(patientId: patientId, name: 'X', date: DateTime.now().add(const Duration(days: 2))),
        ),
        throwsA(isA<AppException>()),
      );
      final list = await records.vaccinations(patientId);
      expect(list.first.name, 'Grippe');
      await records.deleteVaccination(patientId: patientId, vaccinationId: list.first.id!);
      expect(await records.vaccinations(patientId), hasLength(3));
    });

    test('documents : ajout et suppression', () async {
      final patientId = (await auth.login('patient@medilink.tn', password)).patientId!;
      await records.addDocument(
        patientId: patientId,
        title: 'Bilan sanguin',
        category: DocumentCategory.analysis,
        data: Uint8List.fromList([1, 2, 3]),
      );
      final docs = await records.documents(patientId);
      expect(docs.single.category, DocumentCategory.analysis);
      await records.deleteDocument(patientId: patientId, documentId: docs.single.id!);
      expect(await records.documents(patientId), isEmpty);
    });
  });

  group('Accès des médecins au dossier', () {
    test('médecin avec rendez-vous : accès, trace et notification unique par jour', () async {
      final patient = await auth.login('patient@medilink.tn', password);
      final benali = await auth.login('dr.benali@medilink.tn', password);
      expect((await access.patientsOf(benali.doctorId!)).single.fullName, 'Amira Ben Salah');

      final unreadBefore = await notifications.unreadCount(patient.userId);
      final file = await access.openAsDoctor(doctorId: benali.doctorId!, patientId: patient.patientId!);
      expect(file.record.bloodGroup, 'O+');
      expect(file.vaccinations, hasLength(3));
      await access.openAsDoctor(doctorId: benali.doctorId!, patientId: patient.patientId!);

      final log = await access.accessLog(patient.patientId!);
      expect(log, hasLength(2));
      expect(log.first.doctorName, 'Dr Sami Benali');
      expect(await notifications.unreadCount(patient.userId), unreadBefore + 1);
    });

    test('médecin sans rendez-vous : accès refusé', () async {
      final patient = await auth.login('patient@medilink.tn', password);
      final gharbi = await auth.login('dr.gharbi@medilink.tn', password);
      expect(
        () => access.openAsDoctor(doctorId: gharbi.doctorId!, patientId: patient.patientId!),
        appError('forbidden'),
      );
      expect(await access.patientsOf(gharbi.doctorId!), isEmpty);
    });
  });

  group('Proches', () {
    test('ajout, modification, suppression', () async {
      final patientId = (await auth.login('patient@medilink.tn', password)).patientId!;
      expect((await dependents.forPatient(patientId)).single.prenom, 'Youssef');
      await dependents.save(
        Dependent(patientId: patientId, nom: 'Ben Salah', prenom: 'Lina', relation: DependentRelation.child),
      );
      final lina = (await dependents.forPatient(patientId)).firstWhere((d) => d.prenom == 'Lina');
      await dependents.save(
        Dependent(
          id: lina.id,
          patientId: patientId,
          nom: 'Ben Salah',
          prenom: 'Lina',
          relation: DependentRelation.child,
          bloodGroup: 'A+',
        ),
      );
      expect((await dependents.forPatient(patientId)).firstWhere((d) => d.id == lina.id).bloodGroup, 'A+');
      await dependents.delete(patientId: patientId, dependentId: lina.id!);
      expect(await dependents.forPatient(patientId), hasLength(1));
    });
  });

  group('Profil et compte', () {
    test('modification du profil médecin (y compris doctor_profiles)', () async {
      final user = await auth.login('dr.gharbi@medilink.tn', password);
      final profile = await profiles.load(user);
      expect(profile.licenseNumber, 'TN-MED-1003');
      final updated = await profiles.save(profile.copyWith(prenom: 'Youssef-Ali', fee: 70, specialty: 'Pédiatrie'));
      expect(updated.specialty, 'Pédiatrie');
      expect((await profiles.load(updated)).fee, 70);
    });

    test('photo de profil enregistrée puis supprimée', () async {
      final user = await auth.login('patient@medilink.tn', password);
      await profiles.setAvatar(user.userId, Uint8List.fromList([9, 9, 9]));
      expect(await profiles.avatar(user.userId), [9, 9, 9]);
      await profiles.setAvatar(user.userId, null);
      expect(await profiles.avatar(user.userId), isNull);
    });

    test('suppression du compte patient : toutes ses données sont effacées', () async {
      final user = await auth.register(data(UserRole.patient));
      expect(() => auth.deleteAccount(userId: user.userId, password: 'faux'), appError('wrong_password'));
      await auth.deleteAccount(userId: user.userId, password: 'Motdepasse1');
      expect(await database.db.query('patients', where: 'patient_id = ?', whereArgs: [user.patientId]), isEmpty);
      expect(() => auth.login('nouveau@medilink.tn', 'Motdepasse1'), appError('invalid_credentials'));
    });

    test('le dernier administrateur ne peut pas être supprimé', () async {
      final adminUser = await auth.login('admin@medilink.tn', password);
      expect(() => auth.deleteAccount(userId: adminUser.userId, password: password), throwsA(isA<AppException>()));
    });
  });
}
