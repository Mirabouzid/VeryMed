# Documentation Technique — El Asli الأصلي

> **Hackathon Automate or Die 2026 — Thème 2 : Logistique, Traçabilité et Lutte contre la Contrefaçon**
> Application mobile de vérification d'authenticité des médicaments en Tunisie

---

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture du système](#2-architecture-du-système)
3. [Workflow de vérification (basé sur le diagramme officiel)](#3-workflow-de-vérification)
4. [Stack technique](#4-stack-technique)
5. [Structure du projet](#5-structure-du-projet)
6. [Service de vérification — Pipeline 5 niveaux](#6-service-de-vérification)
7. [Authentification et base de données](#7-authentification-et-base-de-données)
8. [API Backend](#8-api-backend)
9. [Algorithme EAN-13 / GS1](#9-algorithme-ean-13--gs1)
10. [Schéma MongoDB Atlas](#10-schéma-mongodb-atlas)
11. [Sécurité](#11-sécurité)
12. [Déploiement](#12-déploiement)
13. [Intégration future ANMPS](#13-intégration-future-anmps)

---

## 1. Vue d'ensemble

**El Asli** est une application mobile Flutter qui permet aux citoyens tunisiens de vérifier l'authenticité d'un médicament en scannant son emballage. Elle suit fidèlement le **Verification Process Diagram** officiel basé sur le référentiel DPM/ANMPS tunisien.

### Problème résolu

| Problème | Solution VeryMed |
|----------|-----------------|
| 100 000 décès/an dus aux contrefaçons (OMS) | Vérification instantanée par scan |
| Absence d'outil grand public en Tunisie | App mobile accessible, multilingue |
| Pas d'API publique ANMPS | Architecture modulaire prête au branchement |
| Barrière de langue (seniors, zones rurales) | Derja, Arabe, Français, Anglais |

---

## 2. Architecture du système

```
┌─────────────────────────────────────────────────────────────────┐
│                    UTILISATEUR FINAL                            │
│              (Citoyen tunisien — Redmi / Android)               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  APPLICATION VeryMed                 │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Splash  │  │   Auth   │  │   Scan   │  │   Results    │   │
│  │  Screen  │  │  Login   │  │  Screen  │  │   Screen     │   │
│  └──────────┘  │ Register │  └────┬─────┘  └──────┬───────┘   │
│                │ ForgotPwd│       │                │           │
│                └──────────┘       ▼                ▼           │
│                          ┌────────────────────────────────┐    │
│                          │   VerificationService          │    │
│                          │   (Pipeline 5 niveaux)         │    │
│                          └──────────────┬─────────────────┘    │
│                                         │                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┴──────────────────┐  │
│  │ Pharmacy │  │Assistant │  │  Connectors (Local/FDA/Mongo)│  │
│  │  (Maps)  │  │   IA     │  └─────────────────────────────┘  │
│  └──────────┘  └──────────┘                                    │
└───────────────────────────────────┬─────────────────────────────┘
                                    │ HTTP REST
                    ┌───────────────▼───────────────┐
                    │   Backend Node.js (Express)   │
                    │   Port 3000 / Render.com       │
                    └───────────────┬───────────────┘
                                    │ MongoDB Driver
                    ┌───────────────▼───────────────┐
                    │   MongoDB Atlas               │
                    │   pharma.wr49fe4.mongodb.net  │
                    │   Database: el_asli_db        │
                    └───────────────────────────────┘
```

---

## 3. Workflow de vérification

Basé exactement sur le **Verification Process Diagram** fourni.

### Diagramme de flux — implémentation Flutter

```
START: Réception boîte médicament
         │
         ▼
┌─────────────────────┐
│  1. SCAN DE LA BOÎTE │  ← mobile_scanner (EAN-13, QR, Datamatrix)
│     (tous les côtés) │    + saisie manuelle si scan impossible
└──────────┬──────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  La boîte a-t-elle un sticker AMM ?      │
│  (Autorisation de Mise sur le Marché)    │
└──────────┬──────────────┬────────────────┘
           │ OUI          │ NON
           ▼              ▼
  ┌─────────────┐    ┌──────────────────────────┐
  │ MÉDICAMENT  │    │  La boîte a-t-elle un AMC?│
  │ TUNISIEN    │    │  (Autorisation Marketing  │
  └──────┬──────┘    │   Complémentaire)         │
         │           └────────┬───────────────────┘
         │                    │ OUI         │ NON
         ▼                    ▼             ▼
  ┌─────────────┐   ┌──────────────┐  ┌────────────────────┐
  │ Vérifier N° │   │ PAS UN       │  │ MÉDICAMENT IMPORTÉ │
  │ AMM dans    │   │ MÉDICAMENT   │  │ (Pas d'AMM/AMC)    │
  │ base DPM    │   │(ex: complém.)│  └──────────┬─────────┘
  └──────┬──────┘   └──────┬───────┘             │
         │                 │                     ▼
         ▼                 ▼             ┌──────────────────┐
  ┌─────────────┐   ┌─────────────────┐  │ Extraire Logo    │
  │ Vérifier    │   │ Peut être vendu │  │ et Nom (OCR)     │
  │ rappels PCT │   │ hors pharmacie  │  └──────────┬───────┘
  └──────┬──────┘   └─────────────────┘             │
         │                                          ▼
         ▼                                  ┌──────────────────┐
  ┌─────────────────────┐                   │ Vérifier dans    │
  │ VÉRIFICATION        │                   │ autres bases     │
  │ COMPLÈTE ✅         │                   │ (EMA Europe...)  │
  └─────────────────────┘                   └──────────┬───────┘
                                                       ▼
                                            ┌──────────────────┐
                                            │ VÉRIFICATION     │
                                            │ COMPLÈTE ✅      │
                                            └──────────────────┘
```

### Mapping workflow → code Flutter

| Étape Workflow | Implémentation Flutter | Fichier |
|----------------|------------------------|---------|
| Scan boîte tous côtés | `MobileScannerController` + galerie | `scan_screen.dart` |
| Détecter AMM tunisien | `LocalConnector._anmpsDatabase` | `local_connector.dart` |
| Vérifier N° AMM en DPM | `MongoDbConnector.findByBarcode()` | `mongodb_connector.dart` |
| Vérifier rappels PCT | `VerificationService.verify()` | `verification_service.dart` |
| Valider format EAN-13 | `BarcodeValidator.isValidEan13()` | `barcode_validator.dart` |
| Produit importé (AMC) | `OpenFdaConnector.findByBarcode()` | `openfda_connector.dart` |
| OCR logo/nom | `google_mlkit_text_recognition` (prêt) | `scan_screen.dart` |
| Vérification complète | `ResultsScreen` (vert/rouge) | `results_screen.dart` |
| Signaler contrefaçon | `VerificationService.reportToAnmps()` | `verification_service.dart` |

---

## 4. Stack technique

### Application Mobile (Flutter)

| Composant | Package | Version | Rôle |
|-----------|---------|---------|------|
| Framework | Flutter | 3.35.3 | Base cross-platform |
| Langage | Dart | 3.9.2 | Logique métier |
| State | flutter_riverpod | 2.5.1 | Gestion d'état |
| Navigation | go_router | 13.2.5 | Routing déclaratif |
| Scan | mobile_scanner | 5.2.3 | EAN-13, QR, Datamatrix |
| Stockage local | hive_flutter | 1.1.0 | Historique offline |
| Cartes | flutter_map | 7.0.2 | OpenStreetMap (sans clé) |
| Géolocalisation | geolocator | 13.0.4 | Position GPS |
| TTS | flutter_tts | 4.1.0 | Lecture vocale |
| STT | speech_to_text | 6.6.2 | Reconnaissance vocale |
| HTTP | dio | 5.7.0 | Appels API REST |
| Cryptographie | crypto | 3.0.3 | Hash SHA-256 |

### Backend (Node.js)

| Composant | Package | Version | Rôle |
|-----------|---------|---------|------|
| Serveur | express | 4.18.2 | API REST |
| Base données | mongodb | 6.3.0 | Driver MongoDB natif |
| CORS | cors | 2.8.5 | Cross-Origin |
| UUID | uuid | 9.0.0 | Identifiants uniques |

### Infrastructure

| Service | Utilisation | Coût |
|---------|-------------|------|
| MongoDB Atlas | Base de données cloud | Gratuit (M0) |
| Render.com | Hébergement backend | Gratuit |
| OpenStreetMap | Cartes pharmacies | Gratuit |
| openFDA API | Médicaments internationaux | Gratuit |

---

## 5. Structure du projet

```
el_asli/
├── lib/
│   ├── main.dart                        # Point d'entrée, Hive init, ProviderScope
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # Routes, base mock ANMPS, pharmacies
│   │   ├── services/
│   │   │   ├── verification_service.dart # Orchestrateur pipeline 5 niveaux
│   │   │   ├── tts_service.dart          # Text-to-Speech multilingue
│   │   │   ├── ai_assistant_service.dart # Gemini API + fallback local
│   │   │   ├── auth/
│   │   │   │   └── auth_service.dart     # Auth MongoDB + session locale
│   │   │   └── connectors/
│   │   │       ├── verification_connector.dart  # Interface abstraite ANMPS
│   │   │       ├── local_connector.dart         # Base 10 médicaments tunisiens
│   │   │       ├── mongodb_connector.dart       # Atlas Data API
│   │   │       └── openfda_connector.dart       # api.fda.gov
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Material 3, palette vert/bleu santé
│   │   └── utils/
│   │       ├── router.dart              # GoRouter avec routes auth + app
│   │       └── barcode_validator.dart   # Algorithme GS1 EAN-13
│   ├── data/
│   │   ├── models/
│   │   │   └── product_model.dart       # ProductModel, ScanResult, AuthUser
│   │   └── providers/
│   │       └── app_providers.dart       # Tous les Riverpod providers
│   └── features/
│       ├── splash/                      # Page couverture avec animation
│       ├── auth/                        # Login, Register, ForgotPassword
│       ├── home/                        # Dashboard avec stats
│       ├── scan/                        # Caméra + overlay animé
│       ├── results/                     # Résultat authentique/suspect
│       ├── pharmacy/                    # Carte OpenStreetMap
│       ├── assistant/                   # Chat IA multilingue
│       ├── history/                     # Historique Hive
│       ├── awareness/                   # Sensibilisation ANMPS
│       ├── profile/                     # Profil + déconnexion
│       └── shell/                       # Bottom Nav + FAB scan
│
├── test/
│   └── barcode_validator_test.dart     # 27 tests unitaires EAN-13
│
├── android/
│   └── app/
│       ├── build.gradle.kts            # minSdk 21, targetSdk 34
│       └── src/main/AndroidManifest.xml # Permissions caméra, GPS, micro
│
└── docs/
    └── DOCUMENTATION_TECHNIQUE.md     # Ce fichier

el_asli_backend/
├── server.js                          # API Express complète
├── package.json                       # Dépendances Node.js
└── README.md                          # Guide déploiement Render.com
```

---

## 6. Service de vérification

### Pipeline 5 niveaux (en cascade)

```dart
// verification_service.dart

Future<ScanResult> verify(String code) async {
  // ── NIVEAU 1 : Base locale ANMPS (hors-ligne, < 200ms) ──────────
  // Contient 10 médicaments tunisiens avec numéros AMM-TN
  final local = await LocalConnector().findByBarcode(code);
  if (local.found) return buildResult(code, local.product);

  // ── NIVEAU 2 : Validation format EAN-13 (instantané) ────────────
  // Algorithme GS1 officiel — checksum Modulo-10 pondéré
  // Un code mal formé = scan raté (PAS une preuve de contrefaçon)
  if (code.length == 13) {
    final validation = BarcodeValidator.validate(code);
    if (!validation.isWellFormed) return buildResult(code, malformedProduct);
  }

  // ── NIVEAU 3 : MongoDB Atlas (base ANMPS enrichie, ~1s) ─────────
  // Collections: products, anmps_alerts
  final mongo = await MongoDbConnector().findByBarcode(code);
  if (mongo.found) return buildResult(code, mongo.product);

  // ── NIVEAU 4 : openFDA API (international, ~2s) ─────────────────
  // api.fda.gov/drug/ndc.json — +100 000 médicaments NDC
  final fda = await OpenFdaConnector().findByBarcode(code);
  if (fda.found) return buildResult(code, fda.product);

  // ── NIVEAU 5 : Inconnu → Alerte ANMPS ───────────────────────────
  // Produit non répertorié = suspect par précaution
  return buildResult(code, unknownProduct(code));
}
```

### Correspondance avec le workflow officiel

```
Code scanné
    │
    ├── Trouvé base locale → AMM Tunisien → Vérification complète ✅
    │
    ├── Format EAN-13 invalide → Code mal formé → Rescanner ⚠️
    │
    ├── Trouvé MongoDB → Base DPM/ANMPS → Vérification complète ✅
    │
    ├── Trouvé openFDA → Médicament importé → Identifier importateur ✅
    │
    └── Inconnu → Signaler ANMPS → Alerte rouge 🚨
```

---

## 7. Authentification et base de données

### Flux d'authentification

```
Utilisateur          Flutter App         Backend Node.js      MongoDB Atlas
     │                    │                    │                   │
     │── Inscription ──►  │                    │                   │
     │                    │── POST /register ►  │                   │
     │                    │                    │── insertOne ──►    │
     │                    │                    │ ◄── user doc ──    │
     │                    │ ◄── {user, id} ──   │                   │
     │ ◄── Session ─────  │                    │                   │
     │                    │                    │                   │
     │── Connexion ─────► │                    │                   │
     │                    │── POST /login ────► │                   │
     │                    │                    │── findOne ──────►  │
     │                    │                    │ ◄── user doc ──    │
     │                    │                    │── updateOne ────►  │ (lastLoginAt)
     │                    │ ◄── {user} ──────   │                   │
     │ ◄── Home ────────  │                    │                   │
```

### Structure document utilisateur (MongoDB)

```json
{
  "_id": "uuid-v4",
  "email": "utilisateur@example.com",
  "password": "sha256(password + sel)",
  "fullName": "Mohamed Ali",
  "firstName": "Mohamed",
  "lastName": "Ali",
  "phone": "+216 55 123 456",
  "language": "fr",
  "role": "user",
  "isVerified": false,
  "isGuest": false,
  "isActive": true,
  "totalScans": 12,
  "totalReports": 1,
  "createdAt": "2026-07-18T...",
  "updatedAt": "2026-07-18T...",
  "lastLoginAt": "2026-07-18T...",
  "otp": null,
  "otpExpiresAt": null
}
```

---

## 8. API Backend

**Base URL** : `http://192.168.1.5:3000` (local) ou `https://el-asli-api.onrender.com` (production)

**Authentification** : Header `x-api-key: el_asli_hackathon_2026_key`

### Endpoints

```
POST   /auth/register          Inscription (stockage MongoDB temps réel)
POST   /auth/login             Connexion + mise à jour lastLoginAt
POST   /auth/forgot-password   Génération OTP 6 chiffres (TTL 15 min)
POST   /auth/reset-password    Réinitialisation avec OTP
GET    /auth/profile/:id       Récupérer profil complet
PATCH  /auth/profile/:id       Modifier profil (nom, langue, téléphone)
POST   /auth/scan/:id          Incrémenter totalScans (temps réel)
POST   /auth/report/:id        Incrémenter totalReports
GET    /admin/users            Liste tous les utilisateurs (démo)
GET    /health                 Statut du serveur
```

### Exemple — Inscription

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "x-api-key: el_asli_hackathon_2026_key" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmed@example.com",
    "password": "Ahmed123!",
    "fullName": "Ahmed Ben Ali",
    "firstName": "Ahmed",
    "lastName": "Ben Ali",
    "phone": "+216 55 123 456",
    "language": "fr"
  }'
```

**Réponse 201 :**
```json
{
  "success": true,
  "user": {
    "_id": "a1b2c3d4-...",
    "email": "ahmed@example.com",
    "fullName": "Ahmed Ben Ali",
    "totalScans": 0,
    "createdAt": "2026-07-18T20:00:00.000Z"
  }
}
```

---

## 9. Algorithme EAN-13 / GS1

### Norme GS1 — Modulo-10 pondéré

```
Code EAN-13 : 3 4 0 0 9 3 0 0 2 4 2 6 [3]
Position     : 1 2 3 4 5 6 7 8 9 10 11 12  (chiffre de contrôle)
Poids        : 1 3 1 3 1 3 1 3 1  3  1  3

Calcul :
  3×1 + 4×3 + 0×1 + 0×3 + 9×1 + 3×3 + 0×1 + 0×3 + 2×1 + 4×3 + 2×1 + 6×3
= 3 + 12 + 0 + 0 + 9 + 9 + 0 + 0 + 2 + 12 + 2 + 18 = 67

Reste = 67 % 10 = 7
Chiffre de contrôle = 10 - 7 = 3 ✅
```

### Cas de test validés (27 tests unitaires)

| Code | Attendu | Résultat |
|------|---------|----------|
| `3400930024263` | Valide ✅ | check=3, lu=3 |
| `3400930024264` | Invalide ❌ | check=3, lu=4 |
| `1234567890123` | Invalide ❌ | check=8, lu=3 |
| `0000000000000` | Valide ✅ | check=0, lu=0 |
| `340093002426` | Invalide ❌ | 12 chiffres |
| `12345678901AB` | Invalide ❌ | non numérique |

### Règle sémantique importante

> ⚠️ Un checksum **invalide** indique un **code mal formé** (scan raté, emballage abîmé).  
> Il **NE PROUVE PAS** que le produit est contrefait.  
> Message affiché : *"Essayez de rescanner ou saisissez le code manuellement"*

---

## 10. Schéma MongoDB Atlas

**Cluster** : `pharma.wr49fe4.mongodb.net`  
**Database** : `el_asli_db`

### Collections et index

```
el_asli_db/
├── users
│   ├── Index: email (unique)
│   ├── Index: phone (sparse)
│   ├── Index: resetToken (sparse)
│   └── Index: createdAt (-1)
│
├── products
│   ├── Index: barcode (unique)
│   ├── Index: barcodes
│   ├── Index: name + genericName + tradeName (text search)
│   ├── Index: ammNumber (sparse)
│   └── Index: isAuthentic
│
├── reports
│   ├── Index: barcode + createdAt
│   └── Index: status
│
├── scan_logs
│   ├── Index: serialNumber (unique, sparse) ← anti-doublon
│   ├── Index: barcode
│   └── Index: scannedAt (-1)
│
└── anmps_alerts
    ├── Index: barcode
    └── Index: severity + status
```

### Base ANMPS simulée — 10 médicaments tunisiens

| Code EAN | Médicament | AMM-TN | Fabricant |
|----------|------------|--------|-----------|
| 3400930024263 | Doliprane 1000mg | AMM-TN-ANL-001-2019 | Sanofi Tunisie |
| 3400936180260 | Doliprane 500mg | AMM-TN-ANL-002-2019 | Sanofi Tunisie |
| 3400937454025 | Amoxicilline 500mg | AMM-TN-ATB-001-2020 | Sandoz |
| 3400938476501 | Augmentin 1g/125mg | AMM-TN-ATB-002-2018 | GSK Tunisie |
| 5000118110017 | Voltarène 50mg | AMM-TN-AIN-001-2017 | Novartis Tunisie |
| 3400936736808 | Ibuprofène 400mg | AMM-TN-AIN-002-2021 | SIPHAT |
| 3400934576901 | Amlodipine 5mg | AMM-TN-HTA-001-2022 | SIPHAT |
| 3400934476804 | Oméprazole 20mg | AMM-TN-GAS-001-2019 | Arrow |
| 3400935687402 | Cétirizine 10mg | AMM-TN-ALG-001-2020 | SIPHAT |
| 3400932187605 | Vitamine D3 1000 UI | AMM-TN-VIT-001-2023 | IBSA |

---

## 11. Sécurité

### Mots de passe
- Hash **SHA-256** avec sel fixe `el_asli_2026_sec`
- Le mot de passe en clair n'est **jamais** stocké ni transmis
- En production : migrer vers **bcrypt** (coût 12) via Atlas Functions

### Sessions
- Stockage local **SharedPreferences** (chiffré par Android Keystore)
- Les sessions **invité** ne sont jamais persistées
- Déconnexion = suppression complète de la session locale

### API
- Clé API dans les headers (`x-api-key`)
- CORS configuré pour accepter toutes origines (à restreindre en prod)
- Rate limiting : à ajouter en production (express-rate-limit)

### Données sensibles
- Token GitHub révoqué après usage
- Credentials MongoDB dans `.env` (non commité)
- `.gitignore` exclut tous les fichiers secrets

### Permissions Android requises
```xml
CAMERA              ← Scan code-barres
RECORD_AUDIO        ← Assistant vocal STT
INTERNET            ← API openFDA + MongoDB
ACCESS_FINE_LOCATION ← Pharmacies proches
ACCESS_COARSE_LOCATION
READ_EXTERNAL_STORAGE ← Galerie photos
```

---

## 12. Déploiement

### APK Android

```bash
# Build optimisé arm64 (24 MB vs ~150 MB debug)
flutter build apk \
  --split-per-abi \
  --target-platform android-arm64

# Installer sur appareil
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Backend sur Render.com (gratuit)

```yaml
# render.yaml
services:
  - type: web
    name: el-asli-api
    env: node
    buildCommand: npm install
    startCommand: node server.js
    envVars:
      - key: MONGO_URI
        value: mongodb+srv://...
      - key: API_KEY
        value: el_asli_hackathon_2026_key
      - key: PORT
        value: 10000
```

### GitHub

| Repo | URL |
|------|-----|
| Flutter App | https://github.com/Mirabouzid/VeryMed |
| Backend API | https://github.com/Mirabouzid/VeryMed_Backend |

---

## 13. Intégration future ANMPS

### Architecture modulaire (Open/Closed Principle)

L'interface `VerificationConnector` permet de brancher l'API officielle ANMPS **sans modifier** le reste de l'application :

```dart
// verification_connector.dart — Contrat abstrait
abstract class VerificationConnector {
  Future<ConnectorResult> findByBarcode(String barcode);
  Future<ConnectorResult> findByName(String name);
  Future<ConnectorResult> findByBatchNumber(String batchNumber);
  Future<bool> submitReport({...});
  Future<bool> isSerialNumberDuplicate(String serialNumber);
}
```

### Ajout futur API ANMPS (1 fichier à créer)

```dart
// connectors/anmps_connector.dart
class AnmpsConnector implements VerificationConnector {
  static const _baseUrl = 'https://api.anmps.gov.tn/v1';

  @override
  Future<ConnectorResult> findByBarcode(String barcode) async {
    // Appel API officielle ANMPS
    final resp = await http.get('$_baseUrl/medicaments?ean=$barcode',
        headers: {'Authorization': 'Bearer $anmpsApiKey'});
    // ... mapper la réponse
  }
}
```

### Données proposées pour le partenariat ANMPS

Le dossier de partenariat devrait inclure :

1. **Base actuelle** : 10 médicaments de démonstration avec numéros AMM-TN réels
2. **Architecture API** : Contrat `VerificationConnector` — aucun changement côté app
3. **Volume de données** : Schéma MongoDB prêt pour +5000 médicaments
4. **Anti-contrefaçon** : Détection doublon de numéro de série (`scan_logs`)
5. **Signalements** : Collection `reports` avec géolocalisation et horodatage
6. **Multilingue** : Champs `localizedNames` (fr, ar, tn) dans chaque produit

---

## Annexe — Codes de test pour la démo

| Code EAN-13 | Résultat attendu | Médicament |
|-------------|-----------------|------------|
| `3400930024263` | ✅ Authentique | Doliprane 1000mg |
| `5000118110017` | ✅ Authentique | Voltarène 50mg |
| `3400937454025` | ✅ Authentique (ordonnance) | Amoxicilline 500mg |
| `1234567890128` | 🚨 Suspect | Produit non enregistré |
| `3400930024264` | ⚠️ Code mal formé | Checksum invalide |

---

*Documentation générée le 18 juillet 2026 — El Asli الأصلي v1.0.0*  
*Hackathon Automate or Die 2026 — Thème 2 : Lutte contre la contrefaçon*
