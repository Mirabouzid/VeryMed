// ═══════════════════════════════════════════════════════════════════
//  mongodb_connector.dart  —  El Asliفيري ميد
//
//  Connecteur MongoDB Atlas via API REST (Dio).
//  Utilise l'Atlas Data API v1 (HTTPS, sans SDK natif).
//
//  Base : el_asli_db  |  Cluster : pharma.wr49fe4.mongodb.net
//
//  ⚠️  Pour activer :
//    1. Atlas UI → App Services → Create App
//    2. Activez "Atlas Data API"
//    3. Créez une clé API dans Authentication → API Keys
//    4. Remplacez _appId et _apiKey ci-dessous
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:el_asli/core/services/connectors/verification_connector.dart';
import 'package:el_asli/data/models/product_model.dart';

class MongoDbConnector implements VerificationConnector {
  // ── Config Atlas Data API ────────────────────────────────────────
  // Remplacez _appId par l'ID de votre App Service Atlas
  static const String _appId    = 'YOUR_ATLAS_APP_ID';   // ex: data-abcde
  static const String _apiKey   = 'YOUR_ATLAS_API_KEY';  // Créer dans Atlas UI
  static const String _database = 'el_asli_db';
  static const String _dataSource = 'pharma'; // nom du cluster dans Atlas

  static String get _baseUrl =>
      'https://data.mongodb-api.com/app/$_appId/endpoint/data/v1/action';

  late final Dio _dio;

  MongoDbConnector() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
        'api-key': _apiKey,
      },
    ));
  }

  @override
  String get name => 'MongoDB Atlas (ANMPS)';

  // ── Vérifier si le connecteur est configuré ──────────────────────
  bool get isConfigured =>
      _appId != 'YOUR_ATLAS_APP_ID' && _apiKey != 'YOUR_ATLAS_API_KEY';

  // ── Recherche par code-barres ────────────────────────────────────
  @override
  Future<ConnectorResult> findByBarcode(String barcode) async {
    if (!isConfigured) {
      return ConnectorResult(
          status: ConnectorStatus.error,
          errorMessage: 'Atlas Data API non configurée',
          sourceLabel: name);
    }
    return _findOne('products', {
      r'$or': [
        {'barcode': barcode},
        {'barcodes': barcode},
        {'ean13': barcode},
      ]
    });
  }

  // ── Recherche par nom (OCR) ──────────────────────────────────────
  @override
  Future<ConnectorResult> findByName(String productName) async {
    if (!isConfigured) {
      return ConnectorResult(
          status: ConnectorStatus.error,
          errorMessage: 'Atlas Data API non configurée',
          sourceLabel: name);
    }
    return _findOne('products', {
      r'$or': [
        {'name':        {r'$regex': productName, r'$options': 'i'}},
        {'genericName': {r'$regex': productName, r'$options': 'i'}},
        {'tradeName':   {r'$regex': productName, r'$options': 'i'}},
      ]
    });
  }

  // ── Recherche par numéro de lot ──────────────────────────────────
  @override
  Future<ConnectorResult> findByBatchNumber(String batchNumber) async {
    if (!isConfigured) {
      return ConnectorResult(
          status: ConnectorStatus.notFound, sourceLabel: name);
    }
    return _findOne('products', {'batchNumbers': batchNumber});
  }

  // ── Signalement ANMPS ────────────────────────────────────────────
  @override
  Future<bool> submitReport({
    required String barcode,
    required String reportType,
    required String description,
    String? location,
    String? userId,
  }) async {
    if (!isConfigured) return false;
    try {
      await _dio.post('$_baseUrl/insertOne', data: jsonEncode({
        'dataSource': _dataSource,
        'database': _database,
        'collection': 'reports',
        'document': {
          'barcode': barcode,
          'reportType': reportType,
          'description': description,
          'location': location,
          'userId': userId ?? 'anonymous',
          'status': 'pending',
          'createdAt': {r'$date': DateTime.now().toUtc().toIso8601String()},
          'country': 'TN',
          'source': 'el_asli_app_v1',
        },
      }));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Détection doublon (anti-contrefaçon) ─────────────────────────
  @override
  Future<bool> isSerialNumberDuplicate(String serialNumber) async {
    if (!isConfigured) return false;
    try {
      final response = await _dio.post('$_baseUrl/findOne', data: jsonEncode({
        'dataSource': _dataSource,
        'database': _database,
        'collection': 'scan_logs',
        'filter': {'serialNumber': serialNumber},
      }));
      final body = response.data as Map<String, dynamic>;
      return body['document'] != null;
    } catch (_) {
      return false;
    }
  }

  // ── Enregistrer un scan dans scan_logs ───────────────────────────
  Future<void> logScan(String barcode, {String? serialNumber, String? userId}) async {
    if (!isConfigured) return;
    try {
      await _dio.post('$_baseUrl/insertOne', data: jsonEncode({
        'dataSource': _dataSource,
        'database': _database,
        'collection': 'scan_logs',
        'document': {
          'barcode': barcode,
          'serialNumber': serialNumber,
          'userId': userId ?? 'anonymous',
          'scannedAt': {r'$date': DateTime.now().toUtc().toIso8601String()},
          'source': 'el_asli_app',
        },
      }));
    } catch (_) {}
  }

  // ── Récupérer les alertes ANMPS actives ──────────────────────────
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    if (!isConfigured) return [];
    try {
      final response = await _dio.post('$_baseUrl/find', data: jsonEncode({
        'dataSource': _dataSource,
        'database': _database,
        'collection': 'anmps_alerts',
        'filter': {'status': 'active'},
        'sort': {'publishedAt': -1},
        'limit': 10,
      }));
      final body = response.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(body['documents'] as List? ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── findOne générique ────────────────────────────────────────────
  Future<ConnectorResult> _findOne(
    String collection,
    Map<String, dynamic> filter,
  ) async {
    try {
      final response = await _dio.post('$_baseUrl/findOne', data: jsonEncode({
        'dataSource': _dataSource,
        'database': _database,
        'collection': collection,
        'filter': filter,
      }));

      final body = response.data as Map<String, dynamic>;
      final doc  = body['document'];

      if (doc == null) {
        return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: name);
      }

      return ConnectorResult(
        product: _mapToProduct(doc as Map<String, dynamic>),
        status: ConnectorStatus.found,
        sourceLabel: name,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ConnectorResult(
          status: ConnectorStatus.timeout,
          errorMessage: 'Délai dépassé — vérifiez votre connexion internet',
          sourceLabel: name,
        );
      }
      return ConnectorResult(
        status: ConnectorStatus.error,
        errorMessage: e.message,
        sourceLabel: name,
      );
    }
  }

  // ── Mapping document Mongo → ProductModel ────────────────────────
  ProductModel _mapToProduct(Map<String, dynamic> d) {
    return ProductModel(
      id: d['_id']?.toString() ?? d['ammNumber']?.toString() ?? '',
      barcode: d['barcode']?.toString() ?? '',
      name: d['name']?.toString() ?? d['tradeName']?.toString() ?? '',
      manufacturer: d['manufacturer']?.toString() ?? d['labeler']?.toString() ?? '',
      composition: _composition(d),
      dosage: d['dosage']?.toString() ?? '',
      expiration: d['expiration']?.toString() ?? '',
      requiresPrescription: d['requiresPrescription'] as bool? ?? false,
      sideEffects: _list(d['sideEffects']),
      alternatives: _list(d['alternatives']),
      isAuthentic: d['isAuthentic'] as bool? ?? d['isVerified'] as bool? ?? true,
      risks: _list(d['risks']),
      category: d['category']?.toString() ?? d['therapeuticClass']?.toString() ?? '',
      countryOrigin: d['countryOrigin']?.toString() ?? '',
      registrationNumber: d['ammNumber']?.toString() ?? d['registrationNumber']?.toString(),
      localizedNames: Map<String, String>.from(
        (d['localizedNames'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      ),
    );
  }

  String _composition(Map<String, dynamic> d) {
    if (d['composition'] != null) return d['composition'].toString();
    if (d['activeIngredients'] is List) {
      return (d['activeIngredients'] as List)
          .map((i) => i is Map ? '${i['name']} ${i['strength']}' : i.toString())
          .join(', ');
    }
    return '';
  }

  List<String> _list(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
