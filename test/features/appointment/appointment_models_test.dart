import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/data/models/working_hours.dart';

void main() {
  group('WorkingHours', () {
    const json = '{"mon":["08:30-12:30","14:00-17:00"],"sat":["09:00-12:00"],"xyz":["10:00-11:00"]}';

    test('lit le JSON de doctor_profiles', () {
      final hours = WorkingHours.fromJson(json);
      expect(hours.days.keys, unorderedEquals([DateTime.monday, DateTime.saturday]));
      expect(hours.days[DateTime.monday]!.map((r) => r.toString()), ['08:30-12:30', '14:00-17:00']);
    });

    test('JSON vide ou invalide = horaires vides', () {
      expect(WorkingHours.fromJson(null).days, isEmpty);
      expect(WorkingHours.fromJson('pas du json').days, isEmpty);
    });

    test('découpe une journée en créneaux de 30 min', () {
      final hours = WorkingHours.fromJson(json);
      final saturday = DateTime(2026, 11, 7); // samedi
      final slots = hours.slotsFor(saturday);
      expect(slots.length, 6); // 09:00 → 11:30
      expect(slots.first, DateTime(2026, 11, 7, 9));
      expect(slots.last, DateTime(2026, 11, 7, 11, 30));
      expect(hours.slotsFor(DateTime(2026, 11, 8)), isEmpty); // dimanche fermé
    });

    test('toJson puis fromJson redonne les mêmes horaires', () {
      final hours = WorkingHours.fromJson(json);
      expect(WorkingHours.fromJson(hours.toJson()).toJson(), hours.toJson());
    });
  });

  group('Appointment', () {
    test('fromMap avec jointure, puis toMap', () {
      final a = Appointment.fromMap({
        'appointment_id': 1,
        'appointment_date_time': '2026-10-20T09:30:00',
        'reason': 'Contrôle',
        'status': 'CONFIRMED',
        'created_at': '2026-10-01 08:00:00',
        'doctor_id': 2,
        'patient_id': 3,
        'doctor_nom': 'Benali',
        'doctor_prenom': 'Sami',
        'specialty': 'Cardiologie',
      });
      expect(a.status, AppointmentState.confirmed);
      expect(a.doctorName, 'Dr Sami Benali');
      expect(a.toMap()['appointment_date_time'], '2026-10-20T09:30:00');
      expect(a.toMap()['status'], 'CONFIRMED');
    });

    test('à venir / annulable', () {
      final future = Appointment(dateTime: DateTime.now().add(const Duration(days: 1)), doctorId: 1, patientId: 1);
      expect(future.isUpcoming, isTrue);
      expect(future.copyWith(status: AppointmentState.cancelled).canCancel, isFalse);
      final past = Appointment(dateTime: DateTime(2020), doctorId: 1, patientId: 1);
      expect(past.isUpcoming, isFalse);
    });
  });

  test('DoctorSummary.fromMap', () {
    final d = DoctorSummary.fromMap({
      'doctor_id': 1,
      'nom': 'Benali',
      'prenom': 'Sami',
      'specialty': 'Cardiologie',
      'fee': 60,
      'working_hours': '{"mon":["08:30-12:30"]}',
    });
    expect(d.fullName, 'Dr Sami Benali');
    expect(d.fee, 60.0);
    expect(d.workingHours.days.keys, [DateTime.monday]);
  });
}
