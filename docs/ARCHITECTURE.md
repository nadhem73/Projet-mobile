# Guide d'architecture MediLink

Ce guide explique comment développer **votre module** sans casser celui des autres.

## 1. Principe : un module = un dossier autonome

Chaque module implémente `FeatureModule` (`lib/core/modules/feature_module.dart`) dans
`lib/features/<module>/<module>_module.dart` :

```dart
class PharmacyModule extends FeatureModule {
  @override
  String get name => 'Pharmacie';

  // 1. Vos écrans
  @override
  List<RouteBase> get routes => [
    GoRoute(path: PharmacyRoutes.home, builder: (_, _) => const PharmacyHomeScreen()),
  ];

  // 2. Vos repositories / controllers
  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton(() => MedicamentRepository(getIt()));
    getIt.registerFactory(() => PharmacyController(getIt()));
  }

  // 3. Vos tuiles sur l'accueil patient
  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(label: 'Pharmacie', icon: Icons.local_pharmacy_rounded,
        route: PharmacyRoutes.home, color: AppColors.modulePharmacy),
  ];
}
```

`lib/app/app_modules.dart` liste déjà tous les modules : vous n'avez **rien d'autre à brancher**.

## 2. Structure d'un module

```
features/pharmacy/
├── pharmacy_module.dart          # routes, DI, raccourcis
├── data/
│   ├── models/                   # classes de données (fromMap / toMap)
│   ├── repositories/             # accès SQLite / API — toute la logique de données
│   └── mock/                     # données fictives héritées du template (à supprimer à terme)
└── presentation/
    ├── controllers/              # état des écrans (ChangeNotifier)
    ├── screens/                  # un fichier par écran
    └── widgets/                  # composants propres au module
```

Règle : **un écran ne fait jamais de SQL**. Écran → Controller → Repository → Base.

## 3. Les briques partagées (`lib/core/`)

| Besoin | À utiliser |
|---|---|
| Base SQLite | `getIt<AppDatabase>().db` (dans un repository) |
| Utilisateur connecté | `getIt<SessionService>().requireUser` → `role`, `patientId`, `doctorId`, `pharmacistId`, `insurerId`, `organization`... |
| Accueil (panel) d'un rôle | `AppRoutes.homeFor(user.role)` ; profil commun : `context.push(AppRoutes.profile)` |
| Dossier médical d'un patient | `getIt<MedicalRecordRepository>().forPatient(patientId)` + widget `MedicalRecordView` (lecture seule) |
| En-tête et tuiles de panel | `PanelHeader`, `PanelHeaderAction`, `ShortcutTile` |
| Couleurs | `AppColors.primary`, `Theme.of(context).colorScheme` |
| Espacements / arrondis | `AppSpacing.lg`, `AppRadius.card` |
| Boutons, champs, cartes | `MediButton`, `MediTextField`, `MediCard`, `SectionHeader`, `InfoRow`, `StatusBadge`, `MediAvatar` |
| Chargement / vide / erreur | `LoadingView`, `EmptyState`, `EmptyState.error(...)`, `ComingSoonView` |
| Messages | `context.showSuccess('...')`, `context.showError('...')` |
| Validation de formulaire | `Validators.email`, `Validators.phone`, `Validators.cin`, `Validators.required('Le nom')` |
| Erreur métier | `throw AppException('Message clair pour l\'utilisateur')` |
| Hachage de mot de passe | `getIt<PasswordHasher>()` |

Importer tous les widgets d'un coup : `import 'package:medilink/core/widgets/widgets.dart';`

## 4. Exemple complet : repository → controller → écran

### Repository

```dart
class ReminderRepository {
  ReminderRepository(this._database);
  final AppDatabase _database;

  Future<List<Reminder>> forPatient(int patientId) async {
    final rows = await _database.db.query(PharmacyTables.reminders,
        where: 'patient_id = ? AND active = 1', whereArgs: [patientId]);
    return rows.map(Reminder.fromMap).toList();
  }
}
```

### Controller

```dart
class RemindersController extends ChangeNotifier {
  RemindersController(this._repository, this._session);
  final ReminderRepository _repository;
  final SessionService _session;

  bool isLoading = false;
  String? error;
  List<Reminder> reminders = [];

  Future<void> load() async {
    isLoading = true; error = null; notifyListeners();
    try {
      reminders = await _repository.forPatient(_session.requireUser.patientId!);
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false; notifyListeners();
    }
  }
}
```

### Écran

```dart
class RemindersScreen extends StatefulWidget { ... }

class _RemindersScreenState extends State<RemindersScreen> {
  final controller = getIt<RemindersController>()..load();

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes rappels')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) return const LoadingView();
        if (controller.error != null) return EmptyState.error(controller.error!, onRetry: controller.load);
        if (controller.reminders.isEmpty) {
          return const EmptyState(icon: Icons.alarm_off, title: 'Aucun rappel');
        }
        return ListView(children: [for (final r in controller.reminders) Text(r.name)]);
      },
    ),
  );
}
```

Le module **User** (`features/user/`) suit exactement ce modèle : servez-vous-en comme référence.

## 5. Navigation

- Déclarer les chemins dans la classe `<Module>Routes` de votre `<module>_module.dart`.
- Naviguer : `context.push(PharmacyRoutes.home)` (empile) ou `context.go(...)` (remplace).
- Paramètres : `GoRoute(path: '/pharmacy/order/:id', builder: (_, s) => OrderScreen(id: s.pathParameters['id']!))`.
- Garde d'accès automatique (`lib/app/app_router.dart`) : non connecté → `/login` ;
  `/doctor/...` réservé aux médecins.

## 6. Base de données

- Les tables sont créées à partir de `lib/core/database/schema/*.dart` (un fichier par module).
- Noms de tables : utiliser les constantes (`UserTables.patients`, `AppointmentTables.appointments`...).
- Après modification d'un schéma : **incrémenter `AppDatabase.version`**. En développement, la base
  est alors supprimée et recréée avec les données de démo (`database_seeder.dart`).
- Les clés étrangères sont actives (`PRAGMA foreign_keys = ON`).
- Le dataset des médicaments est dans PostgreSQL (`database/postgres/`) : y accéder via une API HTTP
  (`AppConfig.medicamentsApiUrl`), jamais directement depuis l'application.

## 7. Écrans hérités du template

Les écrans préfixés `ML...` viennent du template d'origine : ils affichent des **données fictives**
(`data/mock/`) et utilisent encore `nb_utils`. Ils ont été déplacés dans le bon module et
re-thémés automatiquement (alias de couleurs dans `core/theme/colors.dart`).

Chaque responsable les **remplace progressivement** par des écrans connectés à SQLite, en suivant
le modèle de la section 4 et en utilisant les widgets `core/widgets/`. Une fois un écran remplacé,
supprimez l'ancien fichier et ses données mock.
