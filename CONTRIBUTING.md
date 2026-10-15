# Travailler en équipe sur MediLink

## Branches

```
main        ← version stable (démo, soutenance). Jamais de commit direct.
 └─ develop ← intégration. On y fusionne les modules via Pull Request.
     ├─ feature/user
     ├─ feature/appointment
     ├─ feature/insurance
     ├─ feature/pharmacy
     └─ feature/doctor
```

### Démarrer (une seule fois)

```bash
git clone https://github.com/nadhem73/Projet-mobile.git
cd Projet-mobile
git checkout develop
git checkout -b feature/<votre-module>     # ex. feature/pharmacy
git push -u origin feature/<votre-module>
```

### Chaque jour

```bash
# 1. Récupérer le travail des autres
git checkout develop && git pull
git checkout feature/<votre-module>
git merge develop                          # résoudre les conflits s'il y en a

# 2. Travailler, puis vérifier
flutter analyze                            # « No issues found! » obligatoire
flutter test

# 3. Publier
git add .
git commit -m "feat(pharmacy): recherche de médicaments"
git push
```

### Livrer une fonctionnalité

Ouvrir une **Pull Request** `feature/<module>` → `develop` sur GitHub, demander une relecture à au
moins un autre membre, puis fusionner. `develop` → `main` uniquement quand tout fonctionne (démo).

## Règles pour éviter les conflits

1. **Restez dans votre dossier** `lib/features/<votre-module>/` et votre fichier
   `lib/core/database/schema/<votre-module>_schema.dart`.
2. **Nouvelles routes / dépendances** : uniquement dans votre `<module>_module.dart`. Ne touchez pas
   à `lib/app/`.
3. **`lib/core/`** est partagé : toute modification passe par une PR séparée, prévenez le groupe.
4. **Schéma SQLite modifié** → incrémentez `AppDatabase.version` (`lib/core/database/app_database.dart`)
   et prévenez le groupe (la base locale de chacun sera recréée).
5. **Nouveau package** dans `pubspec.yaml` : prévenez le groupe (conflits fréquents sur ce fichier
   et `pubspec.lock`).
6. Pour utiliser les données d'un autre module, passez par son **repository** (ex.
   `getIt<AppointmentRepository>()`), jamais par ses tables directement.

## Messages de commit

Format : `type(module): description` en français.

| Type | Usage |
|---|---|
| `feat` | nouvelle fonctionnalité |
| `fix` | correction de bug |
| `refactor` | réorganisation sans changement de comportement |
| `style` | UI / thème |
| `test` | tests |
| `docs` | documentation |

Exemples : `feat(user): inscription patient`, `fix(appointment): double réservation d'un créneau`.
