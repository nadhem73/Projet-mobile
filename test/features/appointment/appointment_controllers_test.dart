import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:medilink/features/appointment/presentation/controllers/appointment_detail_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/booking_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_agenda_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_search_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/my_appointments_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late SessionService session;
  late DoctorSearchRepository doctors;
  late AppointmentRepository appointments;
  late int benaliId;

  Future<Map<String, Object?>> row(String sql) async => (await database.db.rawQuery(sql)).first;

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    doctors = DoctorSearchRepository(database);
    appointments = AppointmentRepository(database, doctors, NotificationService(database));
    benaliId =
        (await row(
              "SELECT d.doctor_id FROM doctors d JOIN users u ON u.id = d.user_id WHERE u.email = 'dr.benali@medilink.tn'",
            ))['doctor_id']
            as int;

    // Patient de démo connecté.
    final patient = await row(
      "SELECT u.id, u.nom, u.prenom, p.patient_id FROM users u JOIN patients p ON p.user_id = u.id "
      "WHERE u.email = 'patient@medilink.tn'",
    );
    SharedPreferences.setMockInitialValues({});
    session = SessionService(await SharedPreferences.getInstance());
    await session.open(
      CurrentUser(
        userId: patient['id'] as int,
        role: UserRole.patient,
        nom: patient['nom'] as String,
        prenom: patient['prenom'] as String,
        email: 'patient@medilink.tn',
        patientId: patient['patient_id'] as int,
      ),
    );
  });

  tearDown(() => database.close());

  test('MyAppointmentsController charge les rendez-vous du patient connecté', () async {
    final c = MyAppointmentsController(appointments, session);
    await c.load();
    expect(c.error, isNull);
    expect(c.upcoming.single.doctorName, 'Dr Sami Benali');
    expect(c.past, hasLength(1));

    expect(await c.cancel(c.upcoming.single.id!), isNull);
    expect(c.upcoming, isEmpty);
    expect(c.past.first.status, AppointmentState.cancelled);
  });

  test('DoctorSearchController : filtres puis remise à zéro', () async {
    final c = DoctorSearchController(doctors);
    await c.load();
    expect(c.doctors, hasLength(3));
    expect(c.specialties, contains('Cardiologie'));

    await c.search(specialty: 'Dermatologie');
    expect(c.doctors.single.nom, 'Gharbi');
    expect(c.hasFilters, isTrue);

    await c.clearFilters();
    expect(c.doctors, hasLength(3));
  });

  test('BookingController : jour, heure, motif puis réservation', () async {
    final c = BookingController(doctors, appointments, session, benaliId);
    await c.load();
    expect(c.doctor?.nom, 'Benali');
    expect(c.days, isNotEmpty);
    expect(c.days.every((d) => d.weekday != DateTime.sunday), isTrue);

    // Un lundi dans le futur (les heures du jour même peuvent être déjà passées).
    final monday = c.days.lastWhere((d) => d.weekday == DateTime.monday);
    await c.selectDay(monday);
    expect(c.slots, isNotEmpty);
    expect(c.canBook, isFalse);

    final slot = c.slots.first;
    c.selectSlot(slot);
    c.setReason('Palpitations');
    final booked = await c.book();
    expect(booked, isNotNull);
    expect(booked!.reason, 'Palpitations');

    // Le même créneau n'est plus proposé.
    await c.selectDay(monday);
    expect(c.slots, isNot(contains(slot)));
  });

  test('BookingController : réserver sans heure donne une erreur', () async {
    final c = BookingController(doctors, appointments, session, benaliId);
    await c.load();
    expect(await c.book(), isNull);
    expect(c.error, 'Choisissez une heure');
  });

  test('AppointmentDetailController : détail puis annulation', () async {
    final id = (await appointments.upcomingForPatient(session.requireUser.patientId!)).single.id!;
    final c = AppointmentDetailController(appointments, doctors, session, id);
    await c.load();
    expect(c.appointment?.canCancel, isTrue);

    expect(await c.cancel(), isNull);
    expect(c.appointment?.status, AppointmentState.cancelled);
    expect(await c.cancel(), isNotNull); // déjà annulé
  });

  test('DoctorAgendaController : semaine, jour sélectionné, navigation', () async {
    // Le médecin Benali se connecte.
    final benaliUser = await row("SELECT id, nom, prenom FROM users WHERE email = 'dr.benali@medilink.tn'");
    await session.open(
      CurrentUser(
        userId: benaliUser['id'] as int,
        role: UserRole.doctor,
        nom: benaliUser['nom'] as String,
        prenom: benaliUser['prenom'] as String,
        email: 'dr.benali@medilink.tn',
        doctorId: benaliId,
      ),
    );

    // Rendez-vous de démo : dans 3 jours à 10h.
    final demoDay = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 3)));
    final c = DoctorAgendaController(appointments, session);
    await c.load();

    expect(c.selectedDay, DateUtils.dateOnly(DateTime.now()));
    expect(c.weekDays.first.weekday, DateTime.monday);
    expect(c.weekDays, hasLength(7));

    // Aller à la semaine du rendez-vous de démo, puis sélectionner ce jour.
    while (!c.weekDays.contains(demoDay)) {
      await c.nextWeek();
    }
    c.selectDay(demoDay);
    expect(c.countOn(demoDay), 1);
    expect(c.dayAppointments.single.reason, 'Contrôle cardiologique');
    expect(c.dayAppointments.single.patientName, isNotEmpty);

    await c.previousWeek();
    expect(c.selectedDay, DateUtils.addDaysToDate(demoDay, -7));
    await c.goToToday();
    expect(c.selectedDay, DateUtils.dateOnly(DateTime.now()));
    c.dispose();
  });
}
