// ═══════════════════════════════════════════════════════════════════════════
//  barcode_validator.dart — El Asli
//
//  AVERTISSEMENT IMPORTANT :
//  ─────────────────────────
//  Ce module valide UNIQUEMENT le FORMAT d'un code EAN-13 selon la norme GS1.
//  Un checksum VALIDE prouve que le code est bien formé (pas tronqué, pas
//  saisi par erreur) — il ne prouve PAS que le produit est authentique.
//  Un checksum INVALIDE signifie que le code est mal formé (scan raté,
//  code altéré) — cela NE PROUVE PAS que le produit est contrefait.
//
//  La détermination d'authenticité repose sur :
//    1. La correspondance dans une base de données officielle (FDA, locale)
//    2. Des contrôles visuels et physiques de l'emballage
//    3. La traçabilité auprès du fabricant ou autorité sanitaire
//
//  Norme : GS1 EAN-13 / ISO/IEC 15420
//  Référence : https://www.gs1.org/services/verify-gtins
// ═══════════════════════════════════════════════════════════════════════════

/// Résultat détaillé d'une validation EAN-13
class BarcodeValidationResult {
  /// true  → les 13 chiffres forment un EAN-13 bien formé
  /// false → le code est mal formé (longueur, caractères, checksum)
  final bool isWellFormed;

  /// Chiffre de contrôle calculé selon GS1 (null si code non numérique)
  final int? expectedCheckDigit;

  /// Chiffre de contrôle lu dans le code scanné (null si longueur incorrecte)
  final int? scannedCheckDigit;

  /// Message explicatif lisible
  final String reason;

  const BarcodeValidationResult({
    required this.isWellFormed,
    this.expectedCheckDigit,
    this.scannedCheckDigit,
    required this.reason,
  });

  @override
  String toString() =>
      'BarcodeValidationResult(isWellFormed: $isWellFormed, '
      'expected: $expectedCheckDigit, scanned: $scannedCheckDigit, '
      'reason: $reason)';
}

/// Validateur EAN-13 selon la norme GS1 (algorithme Modulo-10 pondéré)
class BarcodeValidator {
  BarcodeValidator._(); // classe utilitaire, pas d'instanciation

  // ────────────────────────────────────────────────────────────────
  //  Algorithme officiel GS1 EAN-13 (Modulo-10 / Luhn adapté)
  //
  //  Entrée  : les 12 PREMIERS chiffres du code (sans le chiffre de contrôle)
  //  Sortie  : le chiffre de contrôle (0 à 9)
  //
  //  Étapes :
  //    Pour i de 0 à 11 (0-indexé) :
  //      poids = 1 si i est PAIR  (positions GS1 impaires : 1,3,5,7,9,11)
  //      poids = 3 si i est IMPAIR (positions GS1 paires  : 2,4,6,8,10,12)
  //    somme = Σ (chiffre[i] × poids[i])
  //    reste = somme % 10
  //    checkDigit = (reste == 0) ? 0 : (10 - reste)
  // ────────────────────────────────────────────────────────────────

  /// Calcule le chiffre de contrôle EAN-13 à partir des 12 premiers chiffres.
  ///
  /// Lance [ArgumentError] si [first12Digits] ne contient pas exactement
  /// 12 chiffres décimaux.
  static int computeCheckDigit(String first12Digits) {
    if (first12Digits.length != 12) {
      throw ArgumentError(
        'computeCheckDigit attend exactement 12 chiffres, '
        'reçu : ${first12Digits.length}',
      );
    }

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final charCode = first12Digits.codeUnitAt(i);
      if (charCode < 0x30 || charCode > 0x39) {
        throw ArgumentError(
          'Caractère non numérique à la position $i : "${first12Digits[i]}"',
        );
      }
      final digit = charCode - 0x30; // '0' = 0x30
      // position 0-indexée paire → poids 1, impaire → poids 3
      final weight = (i % 2 == 0) ? 1 : 3;
      sum += digit * weight;
    }

    final remainder = sum % 10;
    return remainder == 0 ? 0 : (10 - remainder);
  }

  /// Valide un code EAN-13 complet (13 chiffres).
  ///
  /// Retourne `true` si et seulement si :
  ///   - le code fait exactement 13 caractères
  ///   - tous les caractères sont des chiffres décimaux
  ///   - le 13e chiffre correspond au chiffre de contrôle calculé
  ///
  /// ⚠️  Un retour `true` ne garantit PAS l'authenticité du produit.
  /// ⚠️  Un retour `false` ne prouve PAS que le produit est contrefait.
  static bool isValidEan13(String code) {
    return validate(code).isWellFormed;
  }

  /// Validation détaillée avec raison explicite.
  static BarcodeValidationResult validate(String code) {
    // 1. Longueur
    if (code.length != 13) {
      return BarcodeValidationResult(
        isWellFormed: false,
        reason: 'Longueur invalide : ${code.length} chiffres (13 attendus). '
            'Essayez de rescanner.',
      );
    }

    // 2. Caractères numériques uniquement
    for (int i = 0; i < 13; i++) {
      final c = code.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) {
        return BarcodeValidationResult(
          isWellFormed: false,
          reason: 'Caractère non numérique détecté à la position $i : '
              '"${code[i]}". Vérifiez le scan.',
        );
      }
    }

    // 3. Calcul du chiffre de contrôle sur les 12 premiers
    final int expected = computeCheckDigit(code.substring(0, 12));
    final int scanned  = code.codeUnitAt(12) - 0x30;

    if (expected == scanned) {
      return BarcodeValidationResult(
        isWellFormed: true,
        expectedCheckDigit: expected,
        scannedCheckDigit: scanned,
        reason: 'Code EAN-13 bien formé (chiffre de contrôle = $expected).',
      );
    } else {
      return BarcodeValidationResult(
        isWellFormed: false,
        expectedCheckDigit: expected,
        scannedCheckDigit: scanned,
        reason: 'Chiffre de contrôle incorrect : lu $scanned, attendu $expected. '
            'Le code est mal formé — essayez de rescanner ou saisissez-le '
            'manuellement.',
      );
    }
  }
}
