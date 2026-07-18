import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final history = ref.watch(scanHistoryProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderGradient(lang: lang),
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Colors.white),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).state = !isDark;
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),

          // ── Stats rapides ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _StatsRow(history: history),
            ),
          ),

          // ── Bouton scan principal ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MainScanButton(),
            ),
          ),

          // ── Grille de fonctionnalités ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _FeaturesGrid(),
            ),
          ),

          // ── Historique récent ────────────────────────────────────
          if (history.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scans récents',
                        style: Theme.of(context).textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.history),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final scan = history[index];
                  return _RecentScanTile(scan: scan);
                },
                childCount: history.take(3).length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HeaderGradient extends StatelessWidget {
  final String lang;
  const _HeaderGradient({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00C896),
            Color(0xFF00876A),
            Color(0xFF005C4B),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VeryMed  |  دوايا',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Vérifiez vos médicaments',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<ScanResult> history;
  const _StatsRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final authentic = history.where((s) => s.isAuthentic).length;
    final suspect = history.where((s) => !s.isAuthentic).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total scans',
            value: '${history.length}',
            icon: Icons.qr_code_scanner_rounded,
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Authentiques',
            value: '$authentic',
            icon: Icons.check_circle_rounded,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Suspects',
            value: '$suspect',
            icon: Icons.warning_rounded,
            color: AppTheme.dangerRed,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MainScanButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.scan),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanner un médicament',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Code-barres, QR ou emballage',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = [
      _FeatureItem(
        icon: Icons.history_rounded,
        label: 'Historique',
        sublabel: 'Mes scans',
        color: const Color(0xFF9C27B0),
        route: AppRoutes.history,
      ),
      _FeatureItem(
        icon: Icons.local_pharmacy_rounded,
        label: 'Pharmacies',
        sublabel: 'À proximité',
        color: AppTheme.accentBlue,
        route: AppRoutes.pharmacy,
      ),
      _FeatureItem(
        icon: Icons.smart_toy_rounded,
        label: 'Assistant IA',
        sublabel: 'Multilingue',
        color: const Color(0xFFFF6B35),
        route: AppRoutes.assistant,
      ),
      _FeatureItem(
        icon: Icons.school_rounded,
        label: 'Sensibilisation',
        sublabel: 'Conseils & vidéos',
        color: const Color(0xFF00BCD4),
        route: AppRoutes.awareness,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Services', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: features.map((f) => _FeatureCard(feature: f)).toList(),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final String route;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.route,
  });
}

class _FeatureCard extends ConsumerWidget {
  final _FeatureItem feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(feature.route),
      child: Container(
        decoration: BoxDecoration(
          color: feature.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: feature.color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(feature.icon, color: feature.color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: feature.color,
                      fontSize: 14,
                    )),
                Text(feature.sublabel,
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  final ScanResult scan;
  const _RecentScanTile({required this.scan});

  @override
  Widget build(BuildContext context) {
    final isAuth = scan.isAuthentic;
    final color = isAuth ? AppTheme.successGreen : AppTheme.dangerRed;
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAuth ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  df.format(scan.scannedAt),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAuth ? 'Authentique' : 'Suspect',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
