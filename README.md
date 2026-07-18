# El Asli —فيري ميد

Application mobile Flutter de vérification d'authenticité des médicaments en Tunisie.

**Hackathon Automate or Die 2026 — Thème 2 : Lutte contre la contrefaçon**

---

## 🎯 Objectif

Scanner un médicament → vérifier son authenticité → informer ou alerter l'utilisateur.

---

## 🚀 Fonctionnalités

- 📷 **Scan** : Code-barres EAN-13, QR Code, saisie manuelle
- ✅ **Vérification** : Base locale ANMPS + openFDA + MongoDB Atlas
- 🚨 **Alerte** : Produit suspect → signalement aux autorités
- 🗺️ **Pharmacies** : Carte OpenStreetMap des pharmacies proches
- 🤖 **Assistant IA** : Multilingue (Français, Arabe, Derja, Anglais)
- 🔐 **Auth** : Inscription / Connexion / Mot de passe oublié
- 👤 **Profil** : Historique personnel, statistiques, déconnexion
- 🌙 **Mode sombre** : Interface accessible, adaptée seniors

---

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|-------------|
| Mobile | Flutter 3.35 (Dart) |
| State | Riverpod 2 |
| Navigation | GoRouter |
| Base locale | Hive |
| Cartes | OpenStreetMap (flutter_map) |
| Scan | mobile_scanner |
| Backend | Node.js + Express |
| Base de données | MongoDB Atlas |
| Auth | JWT-like + SHA-256 |

---

## ⚙️ Installation

### Prérequis
- Flutter 3.35+
- Android SDK (minSdk 21)
- Téléphone Android ou émulateur

### Lancer l'app

```bash
flutter pub get
flutter run -d <device_id>
```

### Build APK (optimisé)

```bash
flutter build apk --split-per-abi --target-platform android-arm64
```

L'APK se trouve dans : `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## 🔧 Configuration

### Backend
Voir `../el_asli_backend/README.md`

Modifier l'URL dans `lib/core/services/auth/auth_service.dart` :
```dart
static const String _baseUrl = 'https://votre-backend.onrender.com';
```

### Base de données locale (démo)

10 médicaments tunisiens inclus dans `lib/core/services/connectors/local_connector.dart` :
- Doliprane 1000mg / 500mg
- Amoxicilline Sandoz 500mg
- Augmentin 1g
- Voltarène 50mg
- Ibuprofène Arrow 400mg
- Amlodipine SIPHAT 5mg
- Oméprazole Arrow 20mg
- Cétirizine SIPHAT 10mg
- Vitamine D3 IBSA 1000 UI

### Compte de démonstration
```
Email    : demo@elasli.tn
Password : Demo1234!
```

---

## 📁 Structure du projet

```
lib/
├── core/
│   ├── constants/      # Routes, constantes, données mock
│   ├── services/       # Auth, vérification, TTS, IA
│   │   ├── auth/       # AuthService (MongoDB)
│   │   └── connectors/ # Local, MongoDB, openFDA
│   ├── theme/          # Thème Material 3 (vert/bleu santé)
│   └── utils/          # Router GoRouter, BarcodeValidator
├── data/
│   ├── models/         # ProductModel, ScanResult, AuthUser
│   └── providers/      # Riverpod providers
└── features/
    ├── splash/         # Page de couverture
    ├── auth/           # Login, Register, ForgotPassword
    ├── home/           # Accueil avec stats
    ├── scan/           # Scanner médicament
    ├── results/        # Résultat authentique/suspect
    ├── pharmacy/       # Carte pharmacies (OpenStreetMap)
    ├── assistant/      # Assistant IA multilingue
    ├── history/        # Historique des scans
    ├── awareness/      # Sensibilisation
    ├── profile/        # Profil utilisateur + déconnexion
    └── shell/          # Navigation principale (Bottom Nav)
```

---

## 🔑 Algorithme EAN-13

Validation checksum GS1 implémentée dans `lib/core/utils/barcode_validator.dart`.

Tests unitaires : `test/barcode_validator_test.dart` (27 cas).

```bash
flutter test test/barcode_validator_test.dart
```

---

## 🏥 Contexte réglementaire (Tunisie)

L'autorité compétente est l'**ANMPS** (Agence Nationale du Médicament et des Produits de Santé).
Cette application est conçue pour faciliter l'intégration future avec l'API officielle ANMPS.

---

## 📄 Licence

MIT — Hackathon Automate or Die 2026
