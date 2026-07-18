/// Constantes globales de l'application VeryMed
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'VeryMed';
  static const String appTagline = 'دوايا - Vérifiez l\'authenticité';
  static const String appVersion = '1.0.0';

  // API Keys (à remplacer par vos clés réelles)
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String openFdaBaseUrl = 'https://api.fda.gov/drug';
  static const String drugsApiBaseUrl = 'https://www.drugs.com/api';

  // Firebase Collections
  static const String scansCollection = 'scans';
  static const String reportsCollection = 'reports';
  static const String pharmaciesCollection = 'pharmacies';
  static const String productsCollection = 'products';

  // Hive Boxes
  static const String scanHistoryBox = 'scan_history';
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';

  // Timeouts
  static const int apiTimeoutSeconds = 15;
  static const int scanDebounceMs = 500;

  // Pharmacies simulées Tunisie (Tunis)
  static const List<Map<String, dynamic>> mockPharmacies = [
    {
      'id': 'ph001',
      'name': 'Pharmacie Centrale Tunis',
      'address': 'Avenue Habib Bourguiba, Tunis',
      'lat': 36.8190,
      'lng': 10.1657,
      'phone': '+216 71 000 001',
      'isOpen': true,
      'openHours': '08:00 - 22:00',
    },
    {
      'id': 'ph002',
      'name': 'Pharmacie El Menzah',
      'address': 'El Menzah 6, Ariana',
      'lat': 36.8630,
      'lng': 10.1960,
      'phone': '+216 71 000 002',
      'isOpen': true,
      'openHours': '24h/24',
    },
    {
      'id': 'ph003',
      'name': 'Pharmacie La Marsa',
      'address': 'Avenue Taieb Mhiri, La Marsa',
      'lat': 36.8876,
      'lng': 10.3236,
      'phone': '+216 71 000 003',
      'isOpen': false,
      'openHours': '08:00 - 20:00',
    },
    {
      'id': 'ph004',
      'name': 'Pharmacie Sfax Centre',
      'address': 'Avenue Habib Bourguiba, Sfax',
      'lat': 34.7424,
      'lng': 10.7605,
      'phone': '+216 74 000 004',
      'isOpen': true,
      'openHours': '08:00 - 21:00',
    },
    {
      'id': 'ph005',
      'name': 'Pharmacie Sousse',
      'address': 'Boulevard de la Corniche, Sousse',
      'lat': 35.8245,
      'lng': 10.6346,
      'phone': '+216 73 000 005',
      'isOpen': true,
      'openHours': '07:00 - 23:00',
    },
  ];

  // Produits simulés pour démo
  static const List<Map<String, dynamic>> mockProducts = [
    {
      'barcode': '3400930024264',
      'name': 'Doliprane 1000mg',
      'manufacturer': 'Sanofi',
      'composition': 'Paracétamol 1000mg',
      'dosage': '1 comprimé toutes les 6h, max 4/jour',
      'expiration': '2026-12',
      'requiresPrescription': false,
      'sideEffects': ['Réactions allergiques rares', 'Atteinte hépatique en surdosage'],
      'alternatives': ['Panadol 1000mg', 'Efferalgan 1000mg', 'Dafalgan 1000mg'],
      'isAuthentic': true,
      'category': 'Analgésique / Antipyrétique',
      'countryOrigin': 'France',
    },
    {
      'barcode': '3400937454025',
      'name': 'Amoxicilline 500mg',
      'manufacturer': 'Sandoz',
      'composition': 'Amoxicilline trihydrate 500mg',
      'dosage': '1 gélule 3x/jour pendant 7 jours',
      'expiration': '2025-08',
      'requiresPrescription': true,
      'sideEffects': ['Diarrhée', 'Nausées', 'Réactions allergiques'],
      'alternatives': ['Clamoxyl 500mg', 'Augmentin 500mg'],
      'isAuthentic': true,
      'category': 'Antibiotique',
      'countryOrigin': 'Allemagne',
    },
    {
      'barcode': '1234567890123',
      'name': 'MÉDICAMENT INCONNU',
      'manufacturer': 'Inconnu',
      'composition': 'Non vérifié',
      'dosage': 'Non disponible',
      'expiration': 'Non disponible',
      'requiresPrescription': false,
      'sideEffects': [],
      'alternatives': [],
      'isAuthentic': false,
      'risks': [
        'Composition inconnue et potentiellement dangereuse',
        'Peut contenir des substances toxiques',
        'Dosage non contrôlé - risque de surdosage',
        'Peut manquer de principe actif - traitement inefficace',
      ],
      'category': 'SUSPECT',
      'countryOrigin': 'Inconnu',
    },
    {
      'barcode': '5000118110017',
      'name': 'Voltarène 50mg',
      'manufacturer': 'Novartis',
      'composition': 'Diclofénac sodique 50mg',
      'dosage': '1 comprimé 2-3x/jour avec repas',
      'expiration': '2027-03',
      'requiresPrescription': false,
      'sideEffects': ['Troubles gastro-intestinaux', 'Maux de tête', 'Vertiges'],
      'alternatives': ['Diclofénac Mylan 50mg', 'Voltarol 50mg'],
      'isAuthentic': true,
      'category': 'Anti-inflammatoire',
      'countryOrigin': 'Suisse',
    },
  ];
}

/// Clés de navigation
class AppRoutes {
  AppRoutes._();
  static const String splash         = '/';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home           = '/home';
  static const String scan           = '/scan';
  static const String results        = '/results';
  static const String assistant      = '/assistant';
  static const String pharmacy       = '/pharmacy';
  static const String history        = '/history';
  static const String awareness      = '/awareness';
  static const String profile        = '/profile';
  static const String settings       = '/settings';
  static const String report         = '/report';
}
