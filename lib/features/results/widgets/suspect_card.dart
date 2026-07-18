import 'package:flutter/material.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';

/// Carte d'alerte pour un produit SUSPECT / CONTREFAIT
class SuspectCard extends StatelessWidget {
  final ScanResult result;
  const SuspectCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final product = result.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Alerte principale ─────────────────────────────────────
        _AlertBanner(),
        const SizedBox(height: 12),

        // ── Risques détaillés ──────────────────────────────────────
        if (product != null && product.risks.isNotEmpty)
          _RisksSection(risks: product.risks),
        const SizedBox(height: 12),

        // ── Code scanné ───────────────────────────────────────────
        _InfoSection(
          title: 'Code scanné',
          icon: Icons.qr_code_rounded,
          color: AppTheme.dangerRed,
          children: [
            _InfoRow(label: 'Code', value: result.scannedCode),
            _InfoRow(
              label: 'Type',
              value: _scanTypeName(result.scanType),
            ),
            _InfoRow(
              label: 'Date',
              value: _formatDate(result.scannedAt),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Que faire ? ───────────────────────────────────────────
        _WhatToDoSection(),
        const SizedBox(height: 12),

        // ── Vidéo sensibilisation ─────────────────────────────────
        _AwarenessVideoCard(),
      ],
    );
  }

  String _scanTypeName(ScanType type) {
    switch (type) {
      case ScanType.barcode:
        return 'Code-barres';
      case ScanType.qrCode:
        return 'QR Code';
      case ScanType.ocr:
        return 'Reconnaissance texte (OCR)';
      case ScanType.manual:
        return 'Saisie manuelle';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dangerRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.dangerous_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          const Text(
            '🚨 DANGER — Produit Non Vérifié',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ce produit n\'est pas répertorié dans notre base de données officielle. Il pourrait être contrefait, périmé ou dangereux pour votre santé.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RisksSection extends StatelessWidget {
  final List<String> risks;
  const _RisksSection({required this.risks});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.health_and_safety_rounded,
                    color: AppTheme.dangerRed, size: 18),
                SizedBox(width: 8),
                Text(
                  'Risques identifiés',
                  style: TextStyle(
                    color: AppTheme.dangerRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: risks.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.dangerRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatToDoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Ne pas consommer ce médicament', Icons.block_rounded),
      ('Conserver l\'emballage comme preuve', Icons.inventory_2_rounded),
      ('Retourner à la pharmacie où vous l\'avez acheté', Icons.local_pharmacy_rounded),
      ('Signaler aux autorités sanitaires tunisiennes', Icons.report_rounded),
      ('Consulter un médecin si vous en avez déjà pris', Icons.medical_services_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.checklist_rounded,
                    color: AppTheme.warningOrange, size: 18),
                SizedBox(width: 8),
                Text(
                  'Que faire maintenant ?',
                  style: TextStyle(
                    color: AppTheme.warningOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: steps.map((step) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(step.$2, color: AppTheme.warningOrange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.$1,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AwarenessVideoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Vidéo de sensibilisation'),
            content: const Text(
              'Les contrefaçons de médicaments tuent 100 000 personnes chaque année dans le monde.\n\nEn Tunisie, la DPM (Direction de la Pharmacie et du Médicament) lutte activement contre ce fléau.\n\nAchetez TOUJOURS vos médicaments dans des pharmacies agréées.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icône play
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
            ),
            // Texte
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vidéo sensibilisation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Les dangers des médicaments contrefaits',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '3:45',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Réutilisation depuis authentic_card.dart ─────────────────────────
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B8E87),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
