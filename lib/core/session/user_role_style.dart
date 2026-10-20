import 'package:flutter/material.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_colors.dart';

/// Icône et couleur associées à chaque rôle (cartes, badges, en-têtes de panel).
extension UserRoleStyle on UserRole {
  IconData get icon => switch (this) {
    UserRole.patient => Icons.person_rounded,
    UserRole.doctor => Icons.medical_services_rounded,
    UserRole.pharmacist => Icons.local_pharmacy_rounded,
    UserRole.insurer => Icons.health_and_safety_rounded,
  };

  Color get color => switch (this) {
    UserRole.patient => AppColors.moduleUser,
    UserRole.doctor => AppColors.moduleAppointment,
    UserRole.pharmacist => AppColors.modulePharmacy,
    UserRole.insurer => AppColors.moduleInsurance,
  };
}
