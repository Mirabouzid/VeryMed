// ═══════════════════════════════════════════════════════════════════
//  openfda_connector.dart  —  El Asli
//  Connecteur openFDA — fallback international (gratuit, sans clé)
//  Couvre +100 000 médicaments NDC américains
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:el_asli/core/services/connectors/verification_connector.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:uuid/uuid.dart';

class OpenFdaConnector implements VerificationConnector {
  static const String _base = 'https://api.fda.gov/drug/ndc.json';
  static const _uuid = Uuid();

  @override
  String get name => 'openFDA (USA/International)';

  @override
  Future<ConnectorResult> findByBarcode(String barcode) async {
    // EAN-13 → NDC : retirer le chiffre de préfixe pays (premier chiffre)
    final ndc = barcode.length == 13 ? barcode.substring(1) : barcode;
    return _query('product_ndc:"$ndc"');
  }

  @override
  Future<ConnectorResult> findByName(String name) async {
    final encoded = Uri.encodeComponent(name);
    return _query('brand_name:"$encoded"');
  }

  @override
  Future<ConnectorResult> findByBatchNumber(String batchNumber) async {
    return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: name);
  }

  @override
  Future<bool> submitReport({
    required String barcode, required String reportType,
    required String description, String? location, String? userId,
  }) async => false;

  @override
  Future<bool> isSerialNumberDuplicate(String serialNumber) async => false;

  Future<ConnectorResult> _query(String search) async {
    try {
      final uri = Uri.parse('$_base?search=$search&limit=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: name);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: name);
      }
      final product = _parse(results.first as Map<String, dynamic>);
      return ConnectorResult(product: product, status: ConnectorStatus.found, sourceLabel: name);
    } catch (_) {
      return ConnectorResult(status: ConnectorStatus.error,
          errorMessage: 'openFDA indisponible', sourceLabel: name);
    }
  }

  ProductModel _parse(Map<String, dynamic> d) {
    final ingredients = (d['active_ingredients'] as List?)
        ?.map((i) => '${i['name']} ${i['strength']}').join(', ') ?? '';

    return ProductModel(
      id: d['product_ndc']?.toString() ?? _uuid.v4(),
      barcode: d['product_ndc']?.toString() ?? '',
      name: d['brand_name']?.toString() ?? d['generic_name']?.toString() ?? '',
      manufacturer: d['labeler_name']?.toString() ?? '',
      composition: ingredients.isNotEmpty ? ingredients : 'Voir notice',
      dosage: '${d['dosage_form'] ?? ''} — ${(d['route'] as List?)?.join(', ') ?? ''}',
      expiration: 'Vérifier emballage',
      requiresPrescription: false,
      sideEffects: ['Consulter la notice officielle'],
      alternatives: [],
      isAuthentic: true,
      risks: [],
      category: d['marketing_category']?.toString() ?? 'Médicament',
      countryOrigin: 'USA / International',
      registrationNumber: d['product_ndc']?.toString(),
      localizedNames: {},
    );
  }
}
