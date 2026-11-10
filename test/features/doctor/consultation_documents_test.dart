import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/consultation_repository.dart';
import 'package:medilink/features/doctor/data/repositories/lab_request_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/pharmacy/data/models/prescription_dispatch.dart';
import 'package:medilink/features/pharmacy/data/repositories/prescription_dispatch_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Documents publiés à la clôture d'une consultation (ordonnances, demandes de
/// bilan) et envoi d'une ordonnance à la pharmacie choisie par le patient.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late ConsultationRepository consultations;
  late PrescriptionRepository prescriptions;
  late LabRequestRepository labRequests;
  late PrescriptionDispatchRepository dispatches;

  late int patientId;
  late CurrentUser patient;
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

  CurrentUser doctor(int doctorId) =>
      CurrentUser(userId: 0, role: UserRole.doctor, nom: 'X', prenom: 'Dr', email: 'd@x.tn', doctorId: doctorId);

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    final notifications = NotificationService(database);
    final records = MedicalRecordRepository(database);
    final access = MedicalAccessRepository(database, records, notifications);
    consultations = ConsultationRepository(database, access, notifications);
    prescriptions = PrescriptionRepository(database, consultations, records, access: access);
    labRequests = LabRequestRepository(database, consultations, access);
    dispatches = PrescriptionDispatchRepository(database, prescriptions);

    final row = await database.db.rawQuery(
      "SELECT p.patient_id, u.id FROM patients p JOIN users u ON u.id = p.user_id WHERE u.email = 'patient@medilink.tn'",
    );
    patientId = row.first['patient_id'] as int;
    patient = CurrentUser(
      userId: row.first['id'] as int,
      role: UserRole.patient,
      nom: 'Ben Salah',
      prenom: 'Amira',
      email: 'patient@medilink.tn',
      patientId: patientId,
    );
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

  Future<Consultation> start() =>
      consultations.start(doctorId: benaliId, patientId: patientId, appointmentId: appointmentId);

  Future<void> close(Consultation c) async {
    await consultations.saveClinical(c.id, doctorId: benaliId, motif: 'Fièvre');
    await consultations.close(c.id, doctorId: benaliId);
  }

  /// Premier médicament du catalogue en stock dans une pharmacie.
  Future<(int medicineId, String name, int pharmacyId)> stockedMedicine() async {
    final rows = await database.db.rawQuery(
      'SELECT m.medicine_id, m.name, ps.pharmacy_id FROM pharmacy_stock ps '
      'JOIN medicines m ON m.medicine_id = ps.medicine_id '
      'WHERE ps.in_stock = 1 AND ps.quantity > 0 ORDER BY ps.pharmacy_id, m.medicine_id LIMIT 1',
    );
    final r = rows.first;
    return (r['medicine_id'] as int, r['name'] as String, r['pharmacy_id'] as int);
  }

  Future<Prescription> publishedPrescription() async {
    final (medicineId, name, _) = await stockedMedicine();
    final c = await start();
    final p = await prescriptions.create(
      consultationId: c.id,
      doctorId: benaliId,
      items: [
        PrescriptionItem(
          medicamentId: medicineId,
          medicamentName: name,
          posologie: '1 par jour',
          dureeTraitement: '5 jours',
        ),
      ],
    );
    await close(c);
    return p;
  }

  group('LabRequestRepository', () {
    test('publiée au patient seulement après la clôture', () async {
      final c = await start();
      final r = await labRequests.create(
        consultationId: c.id,
        doctorId: benaliId,
        tests: ['NFS', ' nfs ', 'Glycémie à jeun', ''],
        note: ' à jeun ',
      );
      expect(r.tests, ['NFS', 'Glycémie à jeun']); // doublons et vides retirés
      expect(r.note, 'à jeun');
      expect(await labRequests.forConsultation(c.id), hasLength(1));
      expect(await labRequests.forPatient(patientId), isEmpty);
      await expectLater(labRequests.viewableBy(r.id, patient), throwsA(isA<AppException>()));

      await close(c);
      expect((await labRequests.forPatient(patientId)).single.id, r.id);
      expect((await labRequests.viewableBy(r.id, patient)).tests, hasLength(2));
    });

    test('refuse une demande vide ou après clôture, suppression tant que la consultation est en cours', () async {
      final c = await start();
      await expectLater(
        labRequests.create(consultationId: c.id, doctorId: benaliId, tests: const ['  ']),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'empty')),
      );
      final r = await labRequests.create(consultationId: c.id, doctorId: benaliId, tests: const ['CRP']);
      await labRequests.delete(r.id, doctorId: benaliId);
      expect(await labRequests.forConsultation(c.id), isEmpty);

      final kept = await labRequests.create(consultationId: c.id, doctorId: benaliId, tests: const ['TSH']);
      await close(c);
      await expectLater(
        labRequests.create(consultationId: c.id, doctorId: benaliId, tests: const ['VS']),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'closed')),
      );
      await expectLater(
        labRequests.delete(kept.id, doctorId: benaliId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'closed')),
      );
    });

    test('un médecin sans accès au dossier ne voit pas la demande', () async {
      final c = await start();
      final r = await labRequests.create(consultationId: c.id, doctorId: benaliId, tests: const ['CRP']);
      final p = await prescriptions.create(
        consultationId: c.id,
        doctorId: benaliId,
        items: const [PrescriptionItem(medicamentName: 'X', posologie: '1/j', dureeTraitement: '3 jours')],
      );
      await close(c);
      expect((await labRequests.viewableBy(r.id, doctor(benaliId))).id, r.id);
      expect((await prescriptions.viewableBy(p.id, doctor(benaliId))).id, p.id);
      await expectLater(labRequests.viewableBy(r.id, doctor(gharbiId)), throwsA(isA<AppException>()));
      await expectLater(prescriptions.viewableBy(p.id, doctor(gharbiId)), throwsA(isA<AppException>()));
    });
  });

  group('PrescriptionDispatchRepository', () {
    test('le patient envoie son ordonnance, le pharmacien la prépare puis la délivre', () async {
      final p = await publishedPrescription();
      final (_, _, stockedPharmacyId) = await stockedMedicine();
      expect(await dispatches.forPrescription(p.id), isNull);

      // Le médicament prescrit est en stock dans au moins cette pharmacie.
      expect((await dispatches.availabilityByPharmacy(p.id))[stockedPharmacyId], 1);

      final pharmacies = await database.db.query('pharmacies', orderBy: 'pharmacy_id', limit: 2);
      final first = pharmacies[0]['pharmacy_id'] as int;
      final second = pharmacies[1]['pharmacy_id'] as int;

      var d = await dispatches.send(prescriptionId: p.id, pharmacyId: first, user: patient);
      expect(d.status, DispatchStatus.sent);
      expect(d.patientName, 'Amira Ben Salah');
      expect(d.itemCount, 1);
      expect(await dispatches.pendingCount(first), 1);

      // Tant qu'elle n'est pas prête, le patient peut changer de pharmacie.
      d = await dispatches.send(prescriptionId: p.id, pharmacyId: second, user: patient);
      expect(d.pharmacyId, second);
      expect(await dispatches.forPharmacy(first), isEmpty);
      expect((await dispatches.forPharmacy(second)).single.prescriptionId, p.id);

      await expectLater(
        dispatches.advance(d.id, pharmacyId: first),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'forbidden')),
      );
      d = await dispatches.advance(d.id, pharmacyId: second);
      expect(d.status, DispatchStatus.ready);
      expect(await dispatches.pendingCount(second), 0);
      await expectLater(
        dispatches.send(prescriptionId: p.id, pharmacyId: first, user: patient),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'locked')),
      );

      d = await dispatches.advance(d.id, pharmacyId: second);
      expect(d.status, DispatchStatus.delivered);
      await expectLater(
        dispatches.advance(d.id, pharmacyId: second),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'delivered')),
      );
    });

    test('impossible d\'envoyer une ordonnance non publiée', () async {
      final (medicineId, name, pharmacyId) = await stockedMedicine();
      final c = await start();
      final p = await prescriptions.create(
        consultationId: c.id,
        doctorId: benaliId,
        items: [
          PrescriptionItem(
            medicamentId: medicineId,
            medicamentName: name,
            posologie: '1/j',
            dureeTraitement: '3 jours',
          ),
        ],
      );
      await expectLater(
        dispatches.send(prescriptionId: p.id, pharmacyId: pharmacyId, user: patient),
        throwsA(isA<AppException>()),
      );
    });
  });
}
