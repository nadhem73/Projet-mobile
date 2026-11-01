import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late ConsultationRepository consultations;
  late PrescriptionRepository prescriptions;
  late MedicalRecordRepository records;

  // Données de démo (DatabaseSeeder).
  late int patientId;
  late int patientUserId;
  late int benaliId; // RDV confirmé avec le patient
  late int gharbiId; // aucun RDV avec le patient
  late int appointmentId;

  Future<int> doctorIdOf(String email) async {
    final rows = await database.db.rawQuery(
      'SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = ?',
      [email],
    );
    return rows.first['doctor_id'] as int;
  }

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    final notifications = NotificationService(database);
    records = MedicalRecordRepository(database);
    final access = MedicalAccessRepository(database, records, notifications);
    consultations = ConsultationRepository(database, access, notifications);
    prescriptions = PrescriptionRepository(database, consultations, records);

    final patient = await database.db.rawQuery(
      "SELECT p.patient_id, u.id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    patientId = patient.first['patient_id'] as int;
    patientUserId = patient.first['id'] as int;
    benaliId = await doctorIdOf('dr.benali@medilink.tn');
    gharbiId = await doctorIdOf('dr.gharbi@medilink.tn');
    final appointment = await database.db.query(
      AppointmentTables.appointments,
      where: 'doctor_id = ? AND patient_id = ? AND status = ?',
      whereArgs: [benaliId, patientId, AppointmentStatus.confirmed],
    );
    appointmentId = appointment.first['appointment_id'] as int;
  });

  tearDown(() => database.close());

  Future<Consultation> startFromAppointment() =>
      consultations.start(doctorId: benaliId, patientId: patientId, appointmentId: appointmentId);

  const amoxicilline = PrescriptionItem(
    medicamentName: 'Amoxicilline',
    dosage: '1 g',
    forme: 'comprimé',
    posologie: '1 comprimé matin et soir',
    dureeTraitement: '7 jours',
  );

  group('VitalSigns', () {
    test('calcule l\'IMC arrondi', () {
      expect(const VitalSigns(height: 175, weight: 70).bmi, 22.9);
      expect(const VitalSigns(weight: 70).bmi, isNull);
    });

    test('rejette les valeurs hors bornes', () {
      expect(const VitalSigns(bloodPressure: '12/8', temperature: 37.2).validate(), isNull);
      expect(const VitalSigns(bloodPressure: '12-8').validate(), isNotNull);
      expect(const VitalSigns(temperature: 50).validate(), isNotNull);
      expect(const VitalSigns(weight: 0).validate(), isNotNull);
    });
  });

  group('ConsultationRepository', () {
    test('démarre une consultation depuis un rendez-vous, sans doublon', () async {
      final c = await startFromAppointment();
      expect(c.isInProgress, isTrue);
      expect(c.patientName, isNotEmpty);
      expect(c.doctorName, startsWith('Dr '));
      expect(c.startTime, isNotNull);

      final again = await startFromAppointment();
      expect(again.id, c.id);
    });

    test('refuse un médecin sans rendez-vous avec le patient', () async {
      await expectLater(
        consultations.start(doctorId: gharbiId, patientId: patientId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'forbidden')),
      );
      await expectLater(
        consultations.start(doctorId: gharbiId, patientId: patientId, appointmentId: appointmentId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'forbidden')),
      );
    });

    test('un autre médecin ne peut pas lire ni modifier la consultation', () async {
      final c = await startFromAppointment();
      await expectLater(consultations.byId(c.id, doctorId: gharbiId), throwsA(isA<AppException>()));
      await expectLater(consultations.saveClinical(c.id, doctorId: gharbiId, motif: 'x'), throwsA(isA<AppException>()));
    });

    test('enregistre la saisie clinique et l\'IMC', () async {
      final c = await startFromAppointment();
      final saved = await consultations.saveClinical(
        c.id,
        doctorId: benaliId,
        motif: '  Douleur thoracique ',
        diagnostic: 'Angor stable',
        vitals: const VitalSigns(bloodPressure: '14/9', temperature: 37, height: 180, weight: 81),
      );
      expect(saved.motif, 'Douleur thoracique');
      expect(saved.diagnostic, 'Angor stable');
      expect(saved.vitals.bloodPressure, '14/9');
      final row = await database.db.query(DoctorTables.consultations, where: 'consultation_id = ?', whereArgs: [c.id]);
      expect(row.first['bmi'], 25.0);
    });

    test('refuse des constantes invalides', () async {
      final c = await startFromAppointment();
      await expectLater(
        consultations.saveClinical(c.id, doctorId: benaliId, vitals: const VitalSigns(temperature: 60)),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'invalid_vitals')),
      );
    });

    test('refuse de clôturer une consultation vide', () async {
      final c = await startFromAppointment();
      await expectLater(
        consultations.close(c.id, doctorId: benaliId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'empty')),
      );
    });

    test('la clôture termine le rendez-vous, notifie le patient et verrouille la consultation', () async {
      final c = await startFromAppointment();
      await consultations.saveClinical(c.id, doctorId: benaliId, motif: 'Contrôle');
      await prescriptions.create(consultationId: c.id, doctorId: benaliId, items: [amoxicilline]);
      final followUp = DateTime.now().add(const Duration(days: 30));

      final closed = await consultations.close(c.id, doctorId: benaliId, followUpDate: followUp);
      expect(closed.isClosed, isTrue);
      expect(closed.endTime, isNotNull);
      expect(closed.followUpDate?.day, followUp.day);

      final appointment = await database.db.query(
        AppointmentTables.appointments,
        where: 'appointment_id = ?',
        whereArgs: [appointmentId],
      );
      expect(appointment.first['status'], AppointmentStatus.completed);

      final notification = await database.db.query(
        'notifications',
        where: 'user_id = ? AND type = ?',
        whereArgs: [patientUserId, NotificationTypes.prescription],
      );
      expect(notification, hasLength(1));

      await expectLater(
        consultations.saveClinical(c.id, doctorId: benaliId, motif: 'modifié'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'closed')),
      );
      expect(await consultations.forPatient(patientId), hasLength(1));
      expect(await consultations.forDoctor(benaliId, status: ConsultationStatus.inProgress), isEmpty);
    });

    test('refuse une date de contrôle passée', () async {
      final c = await startFromAppointment();
      await consultations.saveClinical(c.id, doctorId: benaliId, motif: 'Contrôle');
      await expectLater(
        consultations.close(c.id, doctorId: benaliId, followUpDate: DateTime(2020)),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'invalid_date')),
      );
    });
  });

  group('PrescriptionRepository', () {
    test('crée une ordonnance avec ses lignes', () async {
      final c = await startFromAppointment();
      final p = await prescriptions.create(
        consultationId: c.id,
        doctorId: benaliId,
        note: ' À renouveler si besoin ',
        items: [
          amoxicilline,
          const PrescriptionItem(
            medicamentId: 12,
            medicamentName: 'Doliprane',
            posologie: '1 g si fièvre',
            dureeTraitement: '5 jours',
          ),
        ],
      );
      expect(p.patientId, patientId);
      expect(p.note, 'À renouveler si besoin');
      expect(p.items.map((i) => i.medicamentName), ['Amoxicilline', 'Doliprane']);
      expect(p.items[1].medicamentId, 12);
      expect(await prescriptions.forConsultation(c.id), hasLength(1));
    });

    test('refuse une ordonnance vide ou incomplète', () async {
      final c = await startFromAppointment();
      await expectLater(
        prescriptions.create(consultationId: c.id, doctorId: benaliId, items: []),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'empty')),
      );
      await expectLater(
        prescriptions.create(
          consultationId: c.id,
          doctorId: benaliId,
          items: [const PrescriptionItem(medicamentName: 'Doliprane')],
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'invalid_item')),
      );
    });

    test('le patient ne voit l\'ordonnance qu\'après la clôture', () async {
      final c = await startFromAppointment();
      await consultations.saveClinical(c.id, doctorId: benaliId, motif: 'Contrôle');
      await prescriptions.create(consultationId: c.id, doctorId: benaliId, items: [amoxicilline]);
      expect(await prescriptions.forPatient(patientId), isEmpty);

      await consultations.close(c.id, doctorId: benaliId);
      final list = await prescriptions.forPatient(patientId);
      expect(list, hasLength(1));
      expect(list.first.doctorName, startsWith('Dr '));
    });

    test('suppression possible seulement avant la clôture', () async {
      final c = await startFromAppointment();
      await consultations.saveClinical(c.id, doctorId: benaliId, motif: 'Contrôle');
      final draft = await prescriptions.create(consultationId: c.id, doctorId: benaliId, items: [amoxicilline]);
      await prescriptions.delete(draft.id, doctorId: benaliId);
      expect(await prescriptions.forConsultation(c.id), isEmpty);

      final kept = await prescriptions.create(consultationId: c.id, doctorId: benaliId, items: [amoxicilline]);
      await consultations.close(c.id, doctorId: benaliId);
      await expectLater(
        prescriptions.delete(kept.id, doctorId: benaliId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'closed')),
      );
      await expectLater(
        prescriptions.create(consultationId: c.id, doctorId: benaliId, items: [amoxicilline]),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'closed')),
      );
    });

    test('signale les allergies du dossier médical', () async {
      await records.save(MedicalRecord(patientId: patientId, allergies: 'Pénicilline, Amoxicilline'));
      final warnings = await prescriptions.allergyWarnings(patientId, [
        amoxicilline,
        const PrescriptionItem(medicamentName: 'Doliprane'),
      ]);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('Amoxicilline'));
    });
  });
}
