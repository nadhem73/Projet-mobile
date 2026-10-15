import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/features/ai/ai_module.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/insurance/insurance_module.dart';
import 'package:medilink/features/pharmacy/pharmacy_module.dart';
import 'package:medilink/features/shell/shell_module.dart';
import 'package:medilink/features/user/user_module.dart';

/// Liste des modules de l'application.
///
/// ⚠️ Vous n'avez normalement PAS besoin de modifier ce fichier : ajoutez vos
/// routes et dépendances dans `features/<votre_module>/<votre_module>_module.dart`.
const List<FeatureModule> appModules = [
  ShellModule(),
  UserModule(), // Membre 1
  AppointmentModule(), // Membre 2
  InsuranceModule(), // Membre 3
  PharmacyModule(), // Membre 4
  DoctorModule(), // Membre 5
  AiModule(), // Partagé
];
