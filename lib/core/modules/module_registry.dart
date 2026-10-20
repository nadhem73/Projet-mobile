import 'package:medilink/core/modules/feature_module.dart';

/// Accès en lecture aux modules installés (ex. pour construire les tuiles
/// de l'accueil à partir des `patientShortcuts` de chaque module).
class ModuleRegistry {
  ModuleRegistry(this.modules);

  final List<FeatureModule> modules;

  List<ModuleShortcut> get patientShortcuts => _sorted(modules.expand((m) => m.patientShortcuts));

  List<ModuleShortcut> get doctorShortcuts => _sorted(modules.expand((m) => m.doctorShortcuts));

  static List<ModuleShortcut> _sorted(Iterable<ModuleShortcut> items) =>
      items.toList()..sort((a, b) => a.order.compareTo(b.order));
}
