import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:medilink/features/appointment/presentation/controllers/appointment_detail_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/booking_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_agenda_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_search_controller.dart';
import 'package:medilink/features/appointment/presentation/controllers/my_appointments_controller.dart';
import 'package:medilink/features/appointment/presentation/screens/appointment_detail_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/doctor_agenda_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/doctor_booking_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/doctor_search_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/my_appointments_screen.dart';

/// Module RENDEZ-VOUS — Membre 2.
/// Recherche de médecins, disponibilités, réservation, suivi et annulation.
abstract final class AppointmentRoutes {
  static const list = '/rendez-vous';

  /// Détail d'un rendez-vous du patient.
  static String appointment(int appointmentId) => '$list/$appointmentId';

  /// Recherche de médecins.
  static const doctors = '/medecins';

  /// Fiche d'un médecin + prise de rendez-vous.
  static String doctor(int doctorId) => '$doctors/$doctorId';

  /// Agenda du médecin (semaine). Le préfixe /doctor/ le réserve aux médecins.
  static const doctorAgenda = '/doctor/rendez-vous';
}

class AppointmentModule extends FeatureModule {
  const AppointmentModule();

  @override
  String get name => 'Rendez-vous';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      // Repositories
      ..registerLazySingleton(() => DoctorSearchRepository(getIt()))
      ..registerLazySingleton(() => AppointmentRepository(getIt(), getIt(), getIt()))
      // Controllers (une instance par écran)
      ..registerFactory(() => MyAppointmentsController(getIt(), getIt()))
      ..registerFactory(() => DoctorSearchController(getIt()))
      ..registerFactory(() => DoctorAgendaController(getIt(), getIt()))
      ..registerFactoryParam<BookingController, int, void>(
        (doctorId, _) => BookingController(getIt(), getIt(), getIt(), doctorId),
      )
      ..registerFactoryParam<AppointmentDetailController, int, void>(
        (appointmentId, _) => AppointmentDetailController(getIt(), getIt(), getIt(), appointmentId),
      );
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(path: AppointmentRoutes.list, builder: (_, _) => const MyAppointmentsScreen()),
    GoRoute(
      path: '${AppointmentRoutes.list}/:appointmentId',
      builder: (_, state) => AppointmentDetailScreen(appointmentId: int.parse(state.pathParameters['appointmentId']!)),
    ),
    GoRoute(path: AppointmentRoutes.doctorAgenda, builder: (_, _) => const DoctorAgendaScreen()),
    GoRoute(path: AppointmentRoutes.doctors, builder: (_, _) => const DoctorSearchScreen()),
    GoRoute(
      path: '${AppointmentRoutes.doctors}/:doctorId',
      builder: (_, state) => DoctorBookingScreen(doctorId: int.parse(state.pathParameters['doctorId']!)),
    ),
  ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(
      label: 'Rendez-vous',
      icon: Icons.calendar_month_rounded,
      route: AppointmentRoutes.list,
      color: AppColors.moduleAppointment,
      order: 10,
    ),
    ModuleShortcut(
      label: 'Trouver un médecin',
      icon: Icons.person_search_rounded,
      route: AppointmentRoutes.doctors,
      color: AppColors.moduleAppointment,
      order: 11,
    ),
  ];

  @override
  List<ModuleShortcut> get doctorShortcuts => const [
    ModuleShortcut(
      label: 'Mon agenda',
      icon: Icons.calendar_view_week_rounded,
      route: AppointmentRoutes.doctorAgenda,
      color: AppColors.moduleAppointment,
      description: 'Rendez-vous de la semaine',
      order: 10,
    ),
  ];
}
