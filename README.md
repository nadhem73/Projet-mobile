# MediLink Tunisia

Application mobile multi-utilisateurs (patients et médecins) pour la gestion du parcours médical :
rendez-vous, consultations, dossier médical, ordonnances, assurance, pharmacie, et assistance IA
(OCR des bilans + orientation LLM/RAG).

**Stack :** Flutter / Dart · SQLite (base principale, `sqflite`) · PostgreSQL (dataset médicaments) ·
go_router · get_it · Material 3.

---

## Démarrage rapide

```bash
flutter pub get
flutter run            # émulateur ou téléphone Android
flutter analyze        # doit afficher « No issues found! » avant chaque push
flutter test
```

Au premier lancement, la base SQLite est créée et remplie avec des comptes de démonstration
(mot de passe pour tous : `Medilink123`) :

| Rôle    | E-mail                     |
|---------|----------------------------|
| Patient | `patient@medilink.tn`      |
| Médecin | `dr.benali@medilink.tn` (Cardiologie) |
| Médecin | `dr.trabelsi@medilink.tn` (Médecine générale) |
| Médecin | `dr.gharbi@medilink.tn` (Dermatologie) |
| Pharmacien | `pharmacie@medilink.tn` (Pharmacie Ennour) |
| Assureur | `assurance@medilink.tn` (CNAM) |
| Administrateur | `admin@medilink.tn` |
| Médecin **en attente de validation** | `dr.haddad@medilink.tn` (pour tester la validation par l'admin) |

En mode debug, l'écran de connexion propose des raccourcis pour remplir ces comptes.

Chaque rôle a son propre **panel** après connexion :

| Rôle | Route du panel | Écran | Module |
|---|---|---|---|
| Patient | `/dashboard` | `PatientPanelScreen` | shell |
| Médecin | `/doctor/dashboard` | `MLDoctorDashboardScreen` | doctor |
| Pharmacien | `/pharmacist/dashboard` | `PharmacistDashboardScreen` | pharmacy |
| Assureur | `/insurer/dashboard` | `InsurerDashboardScreen` | insurance |
| Administrateur | `/admin/dashboard` | `AdminDashboardScreen` | user |

Les routes `/doctor/...`, `/pharmacist/...`, `/insurer/...` et `/admin/...` sont réservées au rôle
correspondant (garde d'accès dans `lib/app/app_router.dart`).

Les comptes **médecin, pharmacien et assureur** créés depuis l'application sont « en attente » jusqu'à
leur validation par un administrateur. Le patient de démo a rendez-vous avec Dr Benali et Dr Trabelsi :
eux seuls peuvent consulter son dossier médical.

> La cible principale est **Android**. SQLite (`sqflite`) ne fonctionne pas sur le Web.

---

## Équipe et modules

Chaque membre est responsable d'un dossier `lib/features/<module>/` et de son fichier de schéma
`lib/core/database/schema/<module>_schema.dart`.

| Module | Dossier | Responsable | Périmètre |
|---|---|---|---|
| **User** | `features/user/` + `features/shell/` | Membre 1 | Comptes et sécurité (5 rôles, validation admin), profils, proches, dossier médical, panel patient, notifications |
| **Rendez-vous** | `features/appointment/` | Membre 2 | Recherche de médecins, disponibilités, réservation, annulation |
| **Assurance** | `features/insurance/` | Membre 3 | Contrats (CNAM, mutuelles), prise en charge, remboursements |
| **Pharmacie** | `features/pharmacy/` | Membre 4 | Catalogue médicaments (PostgreSQL), commandes, rappels |
| **Médecin** | `features/doctor/` | Membre 5 | Agenda, consultations, ordonnances (+ vue patient des ordonnances) |
| **IA** | `features/ai/` | Partagé | OCR Tesseract des bilans, assistant LLM/RAG |

> Remplacez « Membre N » par vos noms / comptes GitHub.

---

## Architecture

```
lib/
├── main.dart                 # Initialisation (DI, base, thème)
├── app/                      # Assemblage : liste des modules, routeur, MaterialApp
├── core/                     # Partagé par tous — modifier avec précaution (PR relue)
│   ├── config/               # URLs des API, constantes
│   ├── database/             # AppDatabase (SQLite) + schema/<module>_schema.dart
│   ├── di/                   # get_it
│   ├── modules/              # Contrat FeatureModule
│   ├── navigation/           # Routes globales, garde d'accès
│   ├── security/             # Hachage des mots de passe (PBKDF2)
│   ├── session/              # Utilisateur connecté (SessionService)
│   ├── theme/                # Design system (couleurs, typo, espacements)
│   ├── utils/                # Validateurs, helpers
│   └── widgets/              # Composants UI partagés (MediButton, MediTextField...)
└── features/
    └── <module>/
        ├── <module>_module.dart   # Routes + dépendances + raccourcis d'accueil
        ├── data/                  # models/, repositories/, mock/
        └── presentation/          # screens/, widgets/, controllers/
```

Le guide complet (comment ajouter un écran, une table, un repository...) est dans
**[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**. Les règles Git sont dans
**[CONTRIBUTING.md](CONTRIBUTING.md)**.

---

## Design system

Palette « Vert santé + Menthe » définie dans `lib/core/theme/app_colors.dart` :

| Token | Couleur | Usage |
|---|---|---|
| `AppColors.primary` | `#0F766E` | Boutons, liens, éléments actifs |
| `AppColors.primaryLight` | `#14B8A6` | Accents, dégradés |
| `AppColors.accent` | `#F97316` | Appels à l'action secondaires, badges |
| `AppColors.background` | `#F6FAF9` | Fond des écrans |
| `AppColors.textPrimary` | `#0F1F1C` | Texte principal |

Typographie : **Poppins** (titres) + **Inter** (texte). Mode sombre inclus.

---

## Base de données

- **SQLite** (`lib/core/database/`) : toutes les données de l'application (cahier des charges §9.1).
- **PostgreSQL** (`database/postgres/`) : dataset des médicaments uniquement, accessible via une API
  intermédiaire (cahier des charges §12.2). URL configurable :
  `flutter run --dart-define=MEDICAMENTS_API_URL=http://10.0.2.2:3000`
