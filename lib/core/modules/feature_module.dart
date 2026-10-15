import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Contrat que chaque module fonctionnel (User, Rendez-vous, Assurance,
/// Pharmacie, Médecin...) implémente dans `features/<module>/<module>_module.dart`.
///
/// Grâce à ce contrat, un module ajoute ses écrans, ses dépendances et ses
/// raccourcis d'accueil SANS modifier de fichier partagé : il suffit de
/// compléter son propre fichier `<module>_module.dart`.
abstract class FeatureModule {
  const FeatureModule();

  /// Nom lisible (logs, debug).
  String get name;

  /// Routes go_router exposées par le module.
  List<RouteBase> get routes;

  /// Enregistre repositories / controllers du module dans get_it.
  void registerDependencies(GetIt getIt) {}

  /// Raccourcis affichés sur l'accueil du patient.
  List<ModuleShortcut> get patientShortcuts => const [];

  /// Raccourcis affichés sur l'accueil du médecin.
  List<ModuleShortcut> get doctorShortcuts => const [];
}

/// Tuile de raccourci affichée sur un tableau de bord.
class ModuleShortcut {
  const ModuleShortcut({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
    this.description,
    this.order = 100,
  });

  final String label;
  final IconData icon;

  /// Chemin go_router ouvert au tap (ex. `/insurance`).
  final String route;
  final Color color;
  final String? description;

  /// Position dans la grille (plus petit = plus haut).
  final int order;
}
