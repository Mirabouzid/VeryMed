import 'package:hive/hive.dart';

part 'product_model.g.dart';

/// Modèle principal d'un produit pharmaceutique
@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String barcode;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String manufacturer;

  @HiveField(4)
  final String composition;

  @HiveField(5)
  final String dosage;

  @HiveField(6)
  final String expiration;

  @HiveField(7)
  final bool requiresPrescription;

  @HiveField(8)
  final List<String> sideEffects;

  @HiveField(9)
  final List<String> alternatives;

  @HiveField(10)
  final bool isAuthentic;

  @HiveField(11)
  final List<String> risks;

  @HiveField(12)
  final String category;

  @HiveField(13)
  final String countryOrigin;

  @HiveField(14)
  final String? imageUrl;

  @HiveField(15)
  final String? registrationNumber;

  @HiveField(16)
  final Map<String, String> localizedNames;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.manufacturer,
    required this.composition,
    required this.dosage,
    required this.expiration,
    required this.requiresPrescription,
    required this.sideEffects,
    required this.alternatives,
    required this.isAuthentic,
    this.risks = const [],
    required this.category,
    required this.countryOrigin,
    this.imageUrl,
    this.registrationNumber,
    this.localizedNames = const {},
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      manufacturer: map['manufacturer']?.toString() ?? '',
      composition: map['composition']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      expiration: map['expiration']?.toString() ?? '',
      requiresPrescription: map['requiresPrescription'] as bool? ?? false,
      sideEffects: List<String>.from(map['sideEffects'] as List? ?? []),
      alternatives: List<String>.from(map['alternatives'] as List? ?? []),
      isAuthentic: map['isAuthentic'] as bool? ?? false,
      risks: List<String>.from(map['risks'] as List? ?? []),
      category: map['category']?.toString() ?? '',
      countryOrigin: map['countryOrigin']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      registrationNumber: map['registrationNumber']?.toString(),
      localizedNames: Map<String, String>.from(map['localizedNames'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'manufacturer': manufacturer,
      'composition': composition,
      'dosage': dosage,
      'expiration': expiration,
      'requiresPrescription': requiresPrescription,
      'sideEffects': sideEffects,
      'alternatives': alternatives,
      'isAuthentic': isAuthentic,
      'risks': risks,
      'category': category,
      'countryOrigin': countryOrigin,
      'imageUrl': imageUrl,
      'registrationNumber': registrationNumber,
      'localizedNames': localizedNames,
    };
  }

  /// Produit inconnu / suspect par défaut
  factory ProductModel.unknown(String barcode) {
    return ProductModel(
      id: 'unknown_$barcode',
      barcode: barcode,
      name: 'Produit non identifié',
      manufacturer: 'Fabricant inconnu',
      composition: 'Composition non vérifiable',
      dosage: 'Non disponible',
      expiration: 'Non disponible',
      requiresPrescription: false,
      sideEffects: [],
      alternatives: [],
      isAuthentic: false,
      risks: [
        'Ce produit n\'est pas répertorié dans notre base de données',
        'Composition potentiellement dangereuse et non contrôlée',
        'Risque de contrefaçon élevé',
        'Ne pas consommer sans avis médical',
      ],
      category: 'INCONNU',
      countryOrigin: 'Inconnu',
    );
  }
}

/// Résultat d'un scan avec métadonnées
@HiveType(typeId: 1)
class ScanResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String scannedCode;

  @HiveField(2)
  final ScanType scanType;

  @HiveField(3)
  final ProductModel? product;

  @HiveField(4)
  final DateTime scannedAt;

  @HiveField(5)
  final bool isAuthentic;

  @HiveField(6)
  final String? location;

  @HiveField(7)
  final bool wasReported;

  ScanResult({
    required this.id,
    required this.scannedCode,
    required this.scanType,
    this.product,
    required this.scannedAt,
    required this.isAuthentic,
    this.location,
    this.wasReported = false,
  });

  ScanResult copyWith({bool? wasReported}) {
    return ScanResult(
      id: id,
      scannedCode: scannedCode,
      scanType: scanType,
      product: product,
      scannedAt: scannedAt,
      isAuthentic: isAuthentic,
      location: location,
      wasReported: wasReported ?? this.wasReported,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scannedCode': scannedCode,
      'scanType': scanType.name,
      'product': product?.toMap(),
      'scannedAt': scannedAt.toIso8601String(),
      'isAuthentic': isAuthentic,
      'location': location,
      'wasReported': wasReported,
    };
  }
}

/// Type de scan effectué
@HiveType(typeId: 2)
enum ScanType {
  @HiveField(0)
  barcode,
  @HiveField(1)
  qrCode,
  @HiveField(2)
  ocr,
  @HiveField(3)
  manual,
}

/// Pharmacie avec disponibilité
class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final bool isOpen;
  final String openHours;
  final double? distance;
  final List<String> availableProducts;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.isOpen,
    required this.openHours,
    this.distance,
    this.availableProducts = const [],
  });

  factory PharmacyModel.fromMap(Map<String, dynamic> map) {
    return PharmacyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      phone: map['phone'] as String,
      isOpen: map['isOpen'] as bool,
      openHours: map['openHours'] as String,
      distance: (map['distance'] as num?)?.toDouble(),
      availableProducts: List<String>.from(map['availableProducts'] as List? ?? []),
    );
  }
}

/// Message du chat assistant
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isVoice;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isVoice = false,
  });
}
