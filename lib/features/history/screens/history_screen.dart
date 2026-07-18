import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des scans'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _confirmClear(context, ref),
              tooltip: 'Effacer tout',
            ),
        ],
      ),
      body: history.isEmpty
          ? _EmptyState()
          : Column(
              children: [
                // ── Stats résumé ──────────────────────────────────
                _HistorySummary(history: history),

                // ── Liste ─────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return _HistoryTile(
                        scan: history[index],
                        onTap: () => context.push(
                          AppRoutes.results,
                          extra: history[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text(
            'Voulez-vous supprimer tous vos scans ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(scanHistoryProvider.notifier).clearHistory();
    }
  }
}

class _HistorySummary extends StatelessWidget {
  final List<ScanResult> history;
  const _HistorySummary({required this.history});

  @override
  Widget build(BuildContext context) {
    final authentic = history.where((s) => s.isAuthentic).length;
    final suspect = history.length - authentic;
    final reported = history.where((s) => s.wasReported).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Total', value: '${history.length}',
              icon: Icons.qr_code_scanner_rounded),
          _SummaryItem(label: 'Authentiques', value: '$authentic',
              icon: Icons.check_circle_rounded),
          _SummaryItem(label: 'Suspects', value: '$suspect',
              icon: Icons.warning_rounded),
          _SummaryItem(label: 'Signalés', value: '$reported',
              icon: Icons.report_rounded),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onTap;

  const _HistoryTile({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAuth = scan.isAuthentic;
    final color = isAuth ? AppTheme.successGreen : AppTheme.dangerRed;
    final df = DateFormat('dd/MM/yyyy  HH:mm');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Icône statut
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuth ? Icons.check_circle_rounded : Icons.dangerous_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.product?.name ?? scan.scannedCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scan.product?.manufacturer ?? 'Code: ${scan.scannedCode}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(df.format(scan.scannedAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            // Badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAuth ? '✅ Authentique' : '🚨 Suspect',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (scan.wasReported) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '📋 Signalé',
                      style: TextStyle(
                          color: AppTheme.warningOrange,
                          fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80,
              color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('Aucun scan effectué',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Scannez votre premier médicament\npour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
