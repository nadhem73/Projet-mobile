<div align="center">

# 🏥 Medilink Tunisia

**Application de suivi médical — Flutter UI Kit**

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.7.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material-3-8A2BE2)](https://m3.material.io)
[![Architecture](https://img.shields.io/badge/Architecture-feature--first-0D47A1)](#-architecture)
[![Version](https://img.shields.io/badge/version-1.0.0%2B1-brightgreen)](pubspec.yaml)

*Interface mobile moderne pour la gestion des rendez-vous, du dossier médical,
des ordonnances, de la pharmacie et d'un assistant médical IA.*

</div>

---

## 📋 Sommaire

- [Aperçu](#-aperçu)
- [Captures d'écran](#-captures-décran)
- [Fonctionnalités](#-fonctionnalités)
- [Design system](#-design-system)
- [Stack technique](#-stack-technique)
- [Architecture](#-architecture)
- [Navigation](#-navigation)
- [Démarrage rapide](#-démarrage-rapide)
- [Statut du projet](#-statut-du-projet)
- [Auteur](#-auteur)

---

## 📱 Aperçu

| | |
|---|---|
| **Application** | Medilink Tunisia (`medilab_prokit`) |
| **Type** | Application mobile de santé — **interface complète, données fictives** |
| **Cibles** | Android (primaire), iOS, Web, Windows |
| **Écrans** | 35 écrans • 40 composants réutilisables • 35 routes nommées |
| **Langue UI** | Français / Anglais (chaînes centralisées dans `app_strings.dart`) |

Medilink couvre le parcours patient complet : authentification, tableau de bord,
rendez-vous, dossier médical, résultats de bilans, ordonnances, pharmacie en ligne,
consultation vidéo et assistant médical IA.

---

## 📸 Captures d'écran

<table>
  <tr>
    <td><img src="ScreenShots/1.jpg" width="200"/></td>
    <td><img src="ScreenShots/2.jpg" width="200"/></td>
    <td><img src="ScreenShots/3.jpg" width="200"/></td>
    <td><img src="ScreenShots/4.jpg" width="200"/></td>
    <td><img src="ScreenShots/5.jpg" width="200"/></td>
    <td><img src="ScreenShots/6.jpg" width="200"/></td>
  </tr>
  <tr>
    <td><img src="ScreenShots/7.jpg" width="200"/></td>
    <td><img src="ScreenShots/8.jpg" width="200"/></td>
    <td><img src="ScreenShots/9.jpg" width="200"/></td>
    <td><img src="ScreenShots/10.jpg" width="200"/></td>
    <td><img src="ScreenShots/11.jpg" width="200"/></td>
    <td><img src="ScreenShots/12.jpg" width="200"/></td>
  </tr>
</table>

<details>
<summary>Voir les 27 captures</summary>

<table>
  <tr>
    <td><img src="ScreenShots/13.jpg" width="200"/></td>
    <td><img src="ScreenShots/14.jpg" width="200"/></td>
    <td><img src="ScreenShots/15.jpg" width="200"/></td>
    <td><img src="ScreenShots/16.jpg" width="200"/></td>
    <td><img src="ScreenShots/17.jpg" width="200"/></td>
    <td><img src="ScreenShots/18.jpg" width="200"/></td>
  </tr>
  <tr>
    <td><img src="ScreenShots/19.jpg" width="200"/></td>
    <td><img src="ScreenShots/20.jpg" width="200"/></td>
    <td><img src="ScreenShots/21.jpg" width="200"/></td>
    <td><img src="ScreenShots/22.jpg" width="200"/></td>
    <td><img src="ScreenShots/23.jpg" width="200"/></td>
    <td><img src="ScreenShots/24.jpg" width="200"/></td>
  </tr>
  <tr>
    <td><img src="ScreenShots/25.jpg" width="200"/></td>
    <td><img src="ScreenShots/26.jpg" width="200"/></td>
    <td><img src="ScreenShots/27.jpg" width="200"/></td>
    <td></td><td></td><td></td>
  </tr>
</table>

</details>

---

## ✨ Fonctionnalités

### 🔐 Authentification
Écran de connexion (téléphone + mot de passe), inscription, récupération de mot de passe,
vérification OTP et choix du pays — avec animations d'entrée et dégradé de marque.

### 🏠 Tableau de bord
- Bandeau profil, recherche et panier
- Carte de stats : fréquence cardiaque, poids, tension (données fictives)
- Carrousel des spécialités médicales
- Prochains rendez-vous, médicaments du jour, actualités santé
- **Barre de navigation à 5 onglets** avec bouton *Accueil* central surélevé en gradient
- **FAB assistant IA** toujours accessible

### 📅 Rendez-vous
Prise de rendez-vous guidée (service → médecin → patient → confirmation),
sélection de créneaux horaires, détail et historique des rendez-vous.

### 🩺 Dossier médical
Carte patient, constantes vitales, sections de suivi et historique des consultations.

### 🧪 Bilans & Ordonnances
Liste des bilans (sanguins, glycémie, lipidique…) avec statuts, scan de bilan,
et gestion des ordonnances par médecin/spécialité.

### 💊 Pharmacie en ligne
Catalogue par catégories, détail produit, panier, vouchers, paiement,
suivi de commande et rappels de médicaments.

### 🤖 Assistant IA & Communication
Chat médical IA avec suggestions, messagerie patient-médecin, bot de support,
appels vidéo et notifications.

---

## 🎨 Design system

Direction visuelle **« Bleu canard + Cyan médical »** — professionnelle, moderne et rassurante.

### Palette

| Rôle | Token | Valeur |
|---|---|---|
| Primaire | `duckBluePrimary` | `#0D47A1` |
| Primaire foncé (headers) | `duckBlueDeep` | `#0A2E5C` |
| Accent | `cyanAccentDark` | `#06B6D4` |
| Accent clair | `cyanAccent` | `#22D3EE` |
| Fond d'écran | `medicalAppBackground` | `#F4F7FB` |
| Succès | `healthSuccess` | `#10B981` |
| Alerte | `healthWarning` | `#F59E0B` |
| Erreur | `healthError` | `#EF4444` |

### Principes

- **Typographie** : *Plus Jakarta Sans* (thème Material + styles nb_utils)
- **Élévation** : niveaux 0–5, ombres colorées teintées à la marque
- **Grille** : rayons 12 / 16 / 20 / 28 selon la hiérarchie
- **Effets** : dégradés de marque, glassmorphism, shimmer de chargement, transitions de page animées
- **Mode sombre** : thème complet (surface bleu nuit) commutable depuis le profil
- **Tokens centralisés** : aucune couleur en dur dans les écrans — tout passe par `lib/core/theme/colors.dart`

---

## 🧰 Stack technique

| Catégorie | Choix |
|---|---|
| Framework | Flutter `3.44` • Dart `^3.7.0` • Material 3 |
| Routing | `go_router` `^14.2.0` — 35 routes nommées |
| State management | `mobx` + `flutter_mobx` (thème, préférences) |
| DI | `get_it` `^8.0.0` |
| UI / helpers | `nb_utils`, `google_fonts`, `flutter_vector_icons` |
| Data-viz | `percent_indicator`, `flutter_staggered_grid_view` |
| Images | `cached_network_image` |
| Forms & auth | `country_code_picker`, `otp_text_field` |
| Divers | `intl`, `url_launcher` |
| Lints | `flutter_lints` `^5.0.0` |

---

## 🏗️ Architecture

Organisation **feature-first** : chaque domaine métier est autonome (`data` + `presentation`),
le socle transversal étant isolé dans `core/`.

```
lib/
├── main.dart                     # bootstrap : MobX, get_it, thème, police
├── core/
│   ├── navigation/app_router.dart# 35 routes GoRouter (initial : /splash)
│   ├── state/                    # AppStore MobX + service_locator (get_it)
│   ├── theme/                    # colors.dart • app_theme.dart • medical_theme.dart
│   ├── utils/                    # mock_data • app_strings • app_assets • ui_helpers
│   └── widgets/                  # composants partagés (calendrier, 3D, paywall)
└── features/
    ├── auth/        # connexion, inscription, OTP, mot de passe
    ├── home/        # dashboard, fragments, navbar, splash, walkthrough, bot
    ├── appointment/ # prise de RDV, créneaux, détail
    ├── doctor/      # spécialités, profil médecin, consultation vidéo
    ├── patient/     # dossier médical, bilans, ordonnances, IA, chat, profils
    └── pharmacy/    # catalogue, panier, paiement, commandes, rappels
        ├── data/            # modèles de données
        └── presentation/    # screens/ + components/
```

**Conventions**

- Écrans : `ML*Screen` dans `presentation/screens/`
- Composants réutilisables : `ML*Component` dans `presentation/components/`
- Modèles & données fictives : `*/data/*_model.dart` et `core/utils/mock_data.dart`
- Chaînes localisées : `core/utils/app_strings.dart`

---

## 🧭 Navigation

Route initiale : `/splash` → `/walkthrough` → `/login` → `/dashboard`

<details>
<summary>Table complète des routes</summary>

| Route | Écran |
|---|---|
| `/splash` | `MLSplashScreen` |
| `/walkthrough` | `MLWalkThroughScreen` |
| `/login` | `MLLoginScreen` |
| `/register` | `MLRegistrationScreen` |
| `/forgot-password` | `MLForgetPasswordScreen` |
| `/confirm-phone` | `MLConfirmPhoneNumberScreen` |
| `/auth` | `MLAuthenticationScreen` |
| `/dashboard` | `MLDashboardScreen` |
| `/rendez-vous` | `MLRendezVousScreen` |
| `/book-appointment` | `MLBookAppointmentScreen` |
| `/appointment-detail` | `MLAppointmentDetailScreen` |
| `/medical-record` | `MLMedicalRecordScreen` |
| `/lab-scan` | `MLLabScanScreen` |
| `/prescriptions` | `MLPrescriptionScreen` |
| `/ai-assistant` | `MLAiAssistantScreen` |
| `/medicine` | `MLMedicineScreen` |
| `/chat` | `MLChatScreen` |
| `/bot` | `MLBotScreen` |
| `/profile` | `MLUpdateProfileScreen` |
| `/add-dependent` | `MLAddDependentScreen` |
| `/order-detail` | `MLOrderDetailScreen` |
| `/doctor-detail` | `MLDoctorDetailScreen` |
| `/specialist` | `MLSpecialistScreen` |
| `/video-consult` | `MLVideoConsultScreen` |
| `/pharmacy` | `MLOnlinePharmacyScreen` |
| `/pharmacy-detail` | `MLOnlinePharmacyDetailScreen` |
| `/product-detail` | `MLProductDetailScreen` |
| `/product-more-detail` | `MLProductMoreDetailScreen` |
| `/create-medicine` | `MLCreateNewMedicine` |
| `/add-to-cart` | `MLAddToCartScreen` |
| `/confirm-order` | `MLConfirmOrderScreen` |
| `/add-voucher` | `MLAddVoucherScreen` |
| `/add-payment` | `MLAddPaymentScreen` |
| `/purchase-button` | `PurchaseButton` |
| `/purchase-more` | `PurchaseMoreScreen` |

</details>

---

## 🚀 Démarrage rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `3.44+` (Dart `^3.7.0`)
- Android Studio / Xcode selon la cible
- Un émulateur Android ou un appareil connecté

### Installation

```bash
git clone <url-du-dépôt>
cd "Projet mobile"

flutter pub get        # dépendances
flutter analyze        # vérification statique
flutter run            # lancement sur l'appareil/émulateur ciblé
```

### Commandes utiles

```bash
flutter devices        # liste les appareils disponibles
flutter run -d <id>    # cible un appareil précis
flutter build apk      # build Android
flutter clean          # réinitialiser le build
```

---

## 📌 Statut du projet

| | |
|---|---|
| ✅ | Interface complète (35 écrans) et navigation nommée |
| ✅ | Design system centralisé, clair + sombre |
| ✅ | Données fictives alimentant l'ensemble des écrans (`mock_data.dart`) |
| ⚠️ | **UI-only** : aucun backend, aucune persistance réseau |
| ⚠️ | `test/widget_test.dart` est encore le template par défaut — à remplacer par de vrais tests |

**Pistes suivantes** : connexion d'une API réelle, tests widget/unit, i18n AR/FR/EN,
persistances locale des préférences, publication Play Store / App Store.

---

## ✍️ Auteur

**Medilink Tunisia** — **Medilink Tunisia

> Construit avec Flutter. N'hésitez pas à ouvrir une issue pour toute suggestion d'amélioration.
