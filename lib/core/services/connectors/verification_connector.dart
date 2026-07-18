// ═══════════════════════════════════════════════════════════════════
//  verification_connector.dart
//
//  Interface abstraite (contrat) pour tout backend de vérification.
//  Permet de brancher facilement l'API officielle ANMPS sans toucher
//  au reste de l'application (Open/Closed Principle).
//
//  Backends disponibles :
//    • MongoDbConnector  — base MongoDB Atlas (actuel)
//    • OpenFdaConnector  — api.fda.gov (fallback international)
//    • AnmpsConnector    — futur : API officielle ANMPS Tunisie
//    • LocalConnector    — base JSON embarquée (mode hors-ligne)
// ═══════════════════════════════════════════════════════════════════

import 'package:el_asli/data/models/product_model.dart';

/// Résultat brut retourné par un connecteur
class ConnectorResult {
  final ProductModel? product;
  final ConnectorStatus status;
  final String? errorMessage;
  final String sourceLabel; // ex: "MongoDB ANMPS", "openFDA", "Local"

  const ConnectorResult({
    this.product,
    required this.status,
    this.errorMessage,
    required this.sourceLabel,
  });

  bool get found => status == ConnectorStatus.found;
}

enum ConnectorStatus { found, notFound, error, timeout }

/// Contrat abstrait — tout connecteur doit implémenter ces méthodes
abstract class VerificationConnector {
  /// Nom affiché dans les logs et l'UI
  String get name;

  /// Recherche par code-barres EAN / QR / Datamatrix
  Future<ConnectorResult> findByBarcode(String barcode);

  /// Recherche par nom (OCR)
  Future<ConnectorResult> findByName(String name);

  /// Recherche par numéro de lot (traçabilité)
  Future<ConnectorResult> findByBatchNumber(String batchNumber);

  /// Enregistre un signalement (code suspect)
  Future<bool> submitReport({
    required String barcode,
    required String reportType,
    required String description,
    String? location,
    String? userId,
  });

  /// Vérifie si un numéro de série a déjà été scanné (anti-doublon)
  Future<bool> isSerialNumberDuplicate(String serialNumber);
}
