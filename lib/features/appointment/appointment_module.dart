import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/appointment/presentation/screens/appointment_detail_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/book_appointment_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/doctor_detail_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/rendez_vous_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/specialist_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/video_consult_screen.dart';

/// Module RENDEZ-VOUS — Membre 2.
/// Recherche de médecins, disponibilités, réservation, suivi et annulation.
abstract final class AppointmentRoutes {
  static const list = '/rendez-vous';
  static const book = '/book-appointment';
  static const detail = '/appointment-detail';
  static const doctorDetail = '/doctor-detail';
  static const specialists = '/specialist';
  static const videoConsult = '/video-consult';
}

class AppointmentModule extends FeatureModule {
  const AppointmentModule();

  @override
  String get name => 'Rendez-vous';

  @override
  void registerDependencies(GetIt getIt) {
    // TODO(appointment): enregistrer AppointmentRepository, DoctorSearchRepository...
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(path: AppointmentRoutes.list, builder: (_, _) => const MLRendezVousScreen()),
    GoRoute(path: AppointmentRoutes.book, builder: (_, _) => const MLBookAppointmentScreen()),
    GoRoute(path: AppointmentRoutes.detail, builder: (_, _) => const MLAppointmentDetailScreen()),
    GoRoute(path: AppointmentRoutes.doctorDetail, builder: (_, _) => const MLDoctorDetailScreen()),
    GoRoute(path: AppointmentRoutes.specialists, builder: (_, _) => const MLSpecialistScreen()),
    GoRoute(path: AppointmentRoutes.videoConsult, builder: (_, _) => const MLVideoConsultScreen()),
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
      route: AppointmentRoutes.specialists,
      color: AppColors.moduleAppointment,
      order: 11,
    ),
  ];
}
