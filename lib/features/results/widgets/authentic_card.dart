import 'package:flutter/material.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';

/// Carte détaillée pour un produit AUTHENTIQUE
class AuthenticCard extends StatelessWidget {
  final ScanResult result;
  const AuthenticCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final product = result.product;
    if (product == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Infos principales ──────────────────────────────────────
        _InfoSection(
          title: 'Informations du produit',
          icon: Icons.medication_rounded,
          color: AppTheme.primaryGreen,          children: [
            _InfoRow(label: 'Nom', value: product.name, bold: true),
            _InfoRow(label: 'Fabricant', value: product.manufacturer),
            _InfoRow(label: 'Catégorie', value: product.category),
            _InfoRow(label: 'Pays d\'origine', value: product.countryOrigin),
            if (product.registrationNumber != null)
              _InfoRow(label: 'N° enregistrement', value: product.registrationNumber!),
          ],
        ),
        const SizedBox(height: 12),

        // ── Composition & Dosage ───────────────────────────────────
        _InfoSection(
          title: 'Composition & Dosage',
          icon: Icons.science_rounded,
          color: AppTheme.accentBlue,
          children: [
            _InfoRow(label: 'Composition', value: product.composition),
            _InfoRow(label: 'Dosage recommandé', value: product.dosage),
          ],
        ),
        const SizedBox(height: 12),

        // ── Date d'expiration + Ordonnance ─────────────────────────
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                icon: Icons.calendar_today_rounded,
                label: 'Expiration',
                value: product.expiration,
                color: _expirationColor(product.expiration),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                icon: product.requiresPrescription
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                label: 'Ordonnance',
                value: product.requiresPrescription ? 'Requise' : 'Non requise',
                color: product.requiresPrescription
                    ? AppTheme.warningOrange
                    : AppTheme.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Effets secondaires ──────────────────────────────────────
        if (product.sideEffects.isNotEmpty)
          _InfoSection(
            title: 'Effets secondaires possibles',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.warningOrange,
            children: product.sideEffects
                .map((e) => _BulletItem(text: e, color: AppTheme.warningOrange))
                .toList(),
          ),
        if (product.sideEffects.isNotEmpty) const SizedBox(height: 12),

        // ── Alternatives locales ────────────────────────────────────
        if (product.alternatives.isNotEmpty)
          _InfoSection(
            title: 'Alternatives disponibles',
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF9C27B0),
            children: product.alternatives
                .map((a) => _BulletItem(
                      text: a,
                      color: const Color(0xFF9C27B0),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Color _expirationColor(String expiration) {
    try {
      final parts = expiration.split('-');
      if (parts.length >= 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final expDate = DateTime(year, month);
        final now = DateTime.now();
        final diff = expDate.difference(now).inDays;
        if (diff < 0) return AppTheme.dangerRed;
        if (diff < 90) return AppTheme.warningOrange;
        return AppTheme.successGreen;
      }
    } catch (_) {}
    return AppTheme.successGreen;
  }
}

// ── Widgets partagés ────────────────────────────────────────────────

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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
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
          // Corps
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
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B8E87),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
