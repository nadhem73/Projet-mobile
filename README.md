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

> La cible principale est **Android**. La démo Web utilise SQLite via WebAssembly.

## Module assurance

Depuis le tableau de bord patient, ouvrez **Assurance** pour enregistrer un contrat
(organisme, numéro et taux déclaré). Le **simulateur de reste à charge** prépare le
budget sans créer de demande : montant des soins × taux déclaré, arrondi au millime.
Il ne tient pas compte des plafonds ou exclusions et ne garantit pas la couverture.

Une demande peut comporter une date de soins, des photos de justificatifs et un lien
vers une consultation ou une ordonnance appartenant au patient. **Mon dossier médical**
permet de joindre une copie d'un document existant : sa suppression ultérieure dans le
dossier médical ne supprime pas la pièce déjà déposée dans la demande.

**Lire la facture** analyse la première image avec Tesseract, localement, puis propose
le total et la date. Le patient doit les vérifier avant validation. La saisie manuelle
reste disponible si la lecture échoue. JPEG, PNG et WebP : 3 Mo par image, 5 images et
6 Mo maximum par dossier. Aucun document n'est transmis à un service d'OCR externe.

Depuis le compte assureur, le tableau de bord affiche les contrats dont le nom de
l'organisme correspond à celui de l'assureur et les demandes associées. Recherche par
adhérent, numéro de contrat ou dossier, filtres par statut, et actualisation sont disponibles.
**Ouvrir le dossier** donne accès aux pièces agrandissables, à l'historique et à la prochaine étape.
L'assureur peut demander des pièces, approuver avec un montant retenu, refuser avec un
motif obligatoire, puis confirmer un paiement effectué hors de MediLink. Un écart
entre montant retenu et estimation nécessite un motif. Un complément en attente bloque
l'approbation jusqu'à la réponse du patient. Aucun paiement n'est exécuté par l'application.

Le patient peut compléter une demande encore en attente. Chaque soumission, complément,
demande de pièces et décision produit une notification destinée aux comptes concernés,
avec un lien vers le dossier. Les contrôles d'accès du repository s'appliquent également
aux liens directs : patient propriétaire ou assureur de l'organisme uniquement. Les
notes cliniques des consultations ne sont pas exposées à l'assureur.

Pour essayer le parcours sur une même installation, créez un contrat **CNAM** avec
`patient@medilink.tn`, ajoutez une demande, puis connectez-vous avec
`assurance@medilink.tn` (mot de passe de démo `Medilink123`). Les données sont
stockées localement dans SQLite : elles ne sont pas partagées entre appareils ni
transmises à un organisme externe. La vérification réelle des contrats, les accords
préalables officiels et les paiements réels nécessitent un service distant.

**Aucune migration :** tables, colonnes, index et `AppDatabase.version` (3) inchangés.
Le champ TEXT existant `insurance_claims.document_path` contient désormais un dossier
JSON préfixé `medilink-dossier:v1:` : images en base64, date, consignes et événements.
Les anciens chemins simples sont conservés et signalés dans le détail ; une nouvelle
copie de l'image est nécessaire pour les afficher sur toutes les plateformes. Les
notifications utilisent la table existante et sont écrites dans la même transaction que
la décision. Un dossier illisible n'est jamais écrasé silencieusement. Cette convention
locale devra être prise en compte si un backend ou un export est ajouté ultérieurement.

OCR : `flutter_tesseract_ocr` pour Android/iOS, Tesseract.js 6.0.1 + core 6.0.0 pour le
Web. Les moteurs Web et modèles linguistiques sont livrés avec l'application, avec
leurs licences dans `web/ocr/` et `assets/tessdata/`. La référence Xcode `tessdata` inclut
les modèles dans le bundle iOS. L'OCR ajoute environ 23 Mo de fichiers sources ; le Web
charge uniquement le moteur nécessaire à la première lecture. La configuration native
doit être validée sur un appareil Android/iOS avant livraison.

Validation : `flutter test test/features/insurance`, `flutter analyze`, `flutter build web`.
Le test navigateur optionnel `node tool/verify_insurance_ocr.cjs` utilise Chrome et un
paquet `playwright-core` installé séparément (`PLAYWRIGHT_CORE_PATH` peut désigner son
dossier). Il lit une facture synthétique et vérifie qu'aucune requête OCR externe n'est faite.

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
