// ═══════════════════════════════════════════════════════════════════
//  local_connector.dart  —  El Asli
//
//  Base locale embarquée — fonctionne 100% hors-ligne.
//  Contient la simulation "base ANMPS Tunisie" avec médicaments réels.
//  C'est le premier niveau de vérification (le plus rapide).
// ═══════════════════════════════════════════════════════════════════

import 'package:el_asli/core/services/connectors/verification_connector.dart';
import 'package:el_asli/data/models/product_model.dart';

class LocalConnector implements VerificationConnector {
  @override
  String get name => 'Base locale ANMPS (démo)';

  @override
  Future<ConnectorResult> findByBarcode(String barcode) async {
    // Simulation délai réseau minimal
    await Future.delayed(const Duration(milliseconds: 150));
    final product = _anmpsDatabase[barcode];
    if (product != null) {
      return ConnectorResult(
        product: product,
        status: ConnectorStatus.found,
        sourceLabel: name,
      );
    }
    return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: name);
  }

  @override
  Future<ConnectorResult> findByName(String name) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final q = name.toLowerCase().trim();
    for (final p in _anmpsDatabase.values) {
      if (p.name.toLowerCase().contains(q) ||
          q.contains(p.name.toLowerCase().split(' ').first)) {
        return ConnectorResult(
          product: p,
          status: ConnectorStatus.found,
          sourceLabel: this.name,
        );
      }
    }
    return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: this.name);
  }

  @override
  Future<ConnectorResult> findByBatchNumber(String batchNumber) async {
    return ConnectorResult(status: ConnectorStatus.notFound, sourceLabel: name);
  }

  @override
  Future<bool> submitReport({
    required String barcode,
    required String reportType,
    required String description,
    String? location,
    String? userId,
  }) async => false; // Géré par MongoDB

  @override
  Future<bool> isSerialNumberDuplicate(String serialNumber) async => false;

  // ══════════════════════════════════════════════════════════════════
  //  BASE ANMPS SIMULÉE — Médicaments tunisiens réels (démo hackathon)
  //  Source : répertoire ANMPS / PCT (Pharmacie Centrale de Tunisie)
  //  ⚠️  Données de démonstration uniquement
  // ══════════════════════════════════════════════════════════════════
  static final Map<String, ProductModel> _anmpsDatabase = {

    // ── Analgésiques ────────────────────────────────────────────────
    '3400930024263': ProductModel(
      id: 'TN-AMM-001', barcode: '3400930024263',
      name: 'Doliprane 1000mg',
      manufacturer: 'Sanofi Tunisie / Sanofi France',
      composition: 'Paracétamol 1000mg',
      dosage: '1 cp toutes les 6h, max 4 cp/jour. Ne pas dépasser 3g/j si insuffisance hépatique.',
      expiration: '2027-06',
      requiresPrescription: false,
      sideEffects: ['Réactions allergiques cutanées rares', 'Atteinte hépatique en cas de surdosage'],
      alternatives: ['Panadol 1000mg', 'Efferalgan 1000mg', 'Dafalgan 1000mg', 'Acétaminophène générique'],
      isAuthentic: true,
      risks: [],
      category: 'Analgésique / Antipyrétique',
      countryOrigin: 'France',
      registrationNumber: 'AMM-TN-ANL-001-2019',
      localizedNames: {'ar': 'دوليبران 1000 ملغ', 'fr': 'Doliprane 1000mg', 'tn': 'دوليبران'},
    ),

    '3400936180260': ProductModel(
      id: 'TN-AMM-002', barcode: '3400936180260',
      name: 'Doliprane 500mg',
      manufacturer: 'Sanofi Tunisie',
      composition: 'Paracétamol 500mg',
      dosage: '1 à 2 cp toutes les 6h, max 8 cp/jour',
      expiration: '2026-12',
      requiresPrescription: false,
      sideEffects: ['Réactions allergiques rares'],
      alternatives: ['Panadol 500mg', 'Efferalgan 500mg'],
      isAuthentic: true, risks: [],
      category: 'Analgésique / Antipyrétique',
      countryOrigin: 'France',
      registrationNumber: 'AMM-TN-ANL-002-2019',
      localizedNames: {'ar': 'دوليبران 500 ملغ', 'tn': 'دوليبران نص'},
    ),

    // ── Antibiotiques ───────────────────────────────────────────────
    '3400937454025': ProductModel(
      id: 'TN-AMM-003', barcode: '3400937454025',
      name: 'Amoxicilline Sandoz 500mg',
      manufacturer: 'Sandoz / Hexal Tunisie',
      composition: 'Amoxicilline trihydrate 500mg',
      dosage: '1 gélule 3x/jour pendant 7 jours, à heures fixes',
      expiration: '2026-09',
      requiresPrescription: true,
      sideEffects: ['Diarrhée', 'Nausées', 'Réactions allergiques', 'Candidose buccale'],
      alternatives: ['Clamoxyl 500mg', 'Augmentin 500mg', 'Amoxil 500mg'],
      isAuthentic: true, risks: [],
      category: 'Antibiotique — Pénicilline',
      countryOrigin: 'Allemagne',
      registrationNumber: 'AMM-TN-ATB-001-2020',
      localizedNames: {'ar': 'أموكسيسيلين 500 ملغ', 'tn': 'الأموكسيسيلين'},
    ),

    '3400938476501': ProductModel(
      id: 'TN-AMM-004', barcode: '3400938476501',
      name: 'Augmentin 1g/125mg',
      manufacturer: 'GSK Tunisie / GlaxoSmithKline',
      composition: 'Amoxicilline 1g + Acide clavulanique 125mg',
      dosage: '1 cp 2x/jour (matin/soir) pendant 7 à 10 jours',
      expiration: '2027-03',
      requiresPrescription: true,
      sideEffects: ['Diarrhée', 'Hépatotoxicité rare', 'Candidose'],
      alternatives: ['Co-amoxiclav 1g/125mg générique'],
      isAuthentic: true, risks: [],
      category: 'Antibiotique — Pénicilline + Inhibiteur',
      countryOrigin: 'Belgique',
      registrationNumber: 'AMM-TN-ATB-002-2018',
      localizedNames: {'ar': 'أوغمنتين 1 غرام', 'tn': 'الأوغمنتان'},
    ),

    // ── Anti-inflammatoires ─────────────────────────────────────────
    '5000118110017': ProductModel(
      id: 'TN-AMM-005', barcode: '5000118110017',
      name: 'Voltarène 50mg',
      manufacturer: 'Novartis Pharma Tunisie',
      composition: 'Diclofénac sodique 50mg',
      dosage: '1 cp 2-3x/jour avec les repas, max 150mg/jour',
      expiration: '2027-05',
      requiresPrescription: false,
      sideEffects: ['Troubles gastro-intestinaux', 'Maux de tête', 'Vertiges', 'Rétention d\'eau'],
      alternatives: ['Diclofénac Mylan 50mg', 'Diclofen 50mg'],
      isAuthentic: true, risks: [],
      category: 'Anti-inflammatoire AINS',
      countryOrigin: 'Suisse',
      registrationNumber: 'AMM-TN-AIN-001-2017',
      localizedNames: {'ar': 'فولتارين 50 ملغ', 'tn': 'الفولتارين'},
    ),

    '3400936736808': ProductModel(
      id: 'TN-AMM-006', barcode: '3400936736808',
      name: 'Ibuprofène Arrow 400mg',
      manufacturer: 'Arrow Génériques / SIPHAT Tunisie',
      composition: 'Ibuprofène 400mg',
      dosage: '1 cp 3x/jour pendant les repas, max 1200mg/jour',
      expiration: '2026-06',
      requiresPrescription: false,
      sideEffects: ['Douleurs gastriques', 'Nausées', 'Risque cardiovasculaire prolongé'],
      alternatives: ['Advil 400mg', 'Nurofen 400mg', 'Brufen 400mg'],
      isAuthentic: true, risks: [],
      category: 'Anti-inflammatoire AINS',
      countryOrigin: 'France',
      registrationNumber: 'AMM-TN-AIN-002-2021',
      localizedNames: {'ar': 'إيبوبروفين 400 ملغ', 'tn': 'الإيبوبروفين'},
    ),

    // ── Antihypertenseurs ────────────────────────────────────────────
    '3400934576901': ProductModel(
      id: 'TN-AMM-007', barcode: '3400934576901',
      name: 'Amlodipine SIPHAT 5mg',
      manufacturer: 'SIPHAT (Tunisie)',
      composition: 'Amlodipine bésylate 5mg',
      dosage: '1 cp/jour, de préférence le matin',
      expiration: '2027-01',
      requiresPrescription: true,
      sideEffects: ['Œdèmes des chevilles', 'Bouffées de chaleur', 'Céphalées', 'Palpitations'],
      alternatives: ['Amlor 5mg', 'Norvasc 5mg'],
      isAuthentic: true, risks: [],
      category: 'Antihypertenseur — Inhibiteur calcique',
      countryOrigin: 'Tunisie',
      registrationNumber: 'AMM-TN-HTA-001-2022',
      localizedNames: {'ar': 'أملوديبين 5 ملغ', 'tn': 'الأملوديبين'},
    ),

    // ── Gastro-entérologie ──────────────────────────────────────────
    '3400934476804': ProductModel(
      id: 'TN-AMM-008', barcode: '3400934476804',
      name: 'Oméprazole Arrow 20mg',
      manufacturer: 'Arrow Génériques',
      composition: 'Oméprazole 20mg',
      dosage: '1 gélule/jour le matin à jeun, 4 semaines',
      expiration: '2026-04',
      requiresPrescription: false,
      sideEffects: ['Maux de tête', 'Diarrhée', 'Flatulences', 'Hypomagnesémie prolongée'],
      alternatives: ['Mopral 20mg', 'Losec 20mg', 'Inexium 20mg'],
      isAuthentic: true, risks: [],
      category: 'Inhibiteur de la pompe à protons',
      countryOrigin: 'France',
      registrationNumber: 'AMM-TN-GAS-001-2019',
      localizedNames: {'ar': 'أوميبرازول 20 ملغ', 'tn': 'الأوميبرازول'},
    ),

    // ── Antihistaminiques ────────────────────────────────────────────
    '3400935687402': ProductModel(
      id: 'TN-AMM-009', barcode: '3400935687402',
      name: 'Cétirizine SIPHAT 10mg',
      manufacturer: 'SIPHAT (Tunisie)',
      composition: 'Chlorhydrate de cétirizine 10mg',
      dosage: '1 cp/jour le soir, au moment des repas',
      expiration: '2026-08',
      requiresPrescription: false,
      sideEffects: ['Somnolence légère', 'Sécheresse buccale', 'Céphalées'],
      alternatives: ['Zyrtec 10mg', 'Virlix 10mg', 'Reactine 10mg'],
      isAuthentic: true, risks: [],
      category: 'Antihistaminique H1',
      countryOrigin: 'Tunisie',
      registrationNumber: 'AMM-TN-ALG-001-2020',
      localizedNames: {'ar': 'سيتيريزين 10 ملغ', 'tn': 'السيتيريزين'},
    ),

    // ── Vitamines / Compléments ─────────────────────────────────────
    '3400932187605': ProductModel(
      id: 'TN-AMM-010', barcode: '3400932187605',
      name: 'Vitamine D3 IBSA 1000 UI',
      manufacturer: 'IBSA Pharma Tunisie',
      composition: 'Cholécalciférol 1000 UI (25 µg)',
      dosage: '1 cp/jour, de préférence avec un repas contenant des graisses',
      expiration: '2027-09',
      requiresPrescription: false,
      sideEffects: ['Hypercalcémie en surdosage', 'Nausées'],
      alternatives: ['Zymad 1000 UI', 'Uvedose 100 000 UI (trimestriel)'],
      isAuthentic: true, risks: [],
      category: 'Vitamine / Complément',
      countryOrigin: 'Suisse',
      registrationNumber: 'AMM-TN-VIT-001-2023',
      localizedNames: {'ar': 'فيتامين د3 1000 وحدة', 'tn': 'فيتامين الدي'},
    ),

    // ── PRODUIT SUSPECT (démo contrefaçon) ─────────────────────────
    '1234567890128': ProductModel(
      id: 'SUSPECT-001', barcode: '1234567890128',
      name: 'PRODUIT NON ENREGISTRÉ',
      manufacturer: 'Fabricant inconnu',
      composition: 'Composition non vérifiable',
      dosage: 'Non disponible',
      expiration: 'Non disponible',
      requiresPrescription: false,
      sideEffects: [],
      alternatives: [],
      isAuthentic: false,
      risks: [
        '🚨 Ce code-barres n\'est pas enregistré auprès de l\'ANMPS',
        'La composition de ce produit est totalement inconnue',
        'Risque élevé de substances toxiques ou de dosage incorrect',
        'Peut être une contrefaçon d\'un médicament populaire',
        'Ne jamais consommer sans avis d\'un professionnel de santé',
      ],
      category: 'NON VÉRIFIÉ',
      countryOrigin: 'Inconnu',
      registrationNumber: null,
      localizedNames: {'ar': 'منتج غير مسجل', 'tn': 'منتج مش موثوق'},
    ),
  };
}
