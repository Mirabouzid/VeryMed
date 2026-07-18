import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:el_asli/features/results/widgets/authentic_card.dart';
import 'package:el_asli/features/results/widgets/suspect_card.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final ScanResult scanResult;
  const ResultsScreen({super.key, required this.scanResult});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _speakResult();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _speakResult() async {
    final tts = ref.read(ttsServiceProvider);
    final product = widget.scanResult.product;
    if (product == null) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (widget.scanResult.isAuthentic) {
      await tts.speakAuthentic(product.name);
    } else {
      await tts.speakSuspect(product.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.scanResult;
    final isAuthentic = result.isAuthentic;
    final bgColor = isAuthentic
        ? AppTheme.successGreenLight
        : AppTheme.dangerRedLight;
    final headerColor = isAuthentic
        ? AppTheme.primaryGreen
        : AppTheme.dangerRed;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: headerColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                    onPressed: _speakResult,
                    tooltip: 'Lire à voix haute',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: () => _shareResult(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ResultHeader(
                    isAuthentic: isAuthentic,
                    product: result.product,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isAuthentic
                      ? AuthenticCard(result: result)
                      : SuspectCard(result: result),
                ),
              ),

       
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _ActionButtons(
                    result: result,
                    isAuthentic: isAuthentic,
                  ),
                ),
              ),

            
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push(AppRoutes.scan);
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scanner un autre médicament'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: headerColor,
                      side: BorderSide(color: headerColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareResult(BuildContext context) {
    final p = widget.scanResult.product;
    if (p == null) return;
    final text = widget.scanResult.isAuthentic
        ? '✅ VeryMed: ${p.name} (${p.manufacturer}) est AUTHENTIQUE. Fabriqué en ${p.countryOrigin}.'
        : '🚨 VeryMed: ${p.name} est SUSPECT. Ne pas consommer. Signalez aux autorités.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partage : $text'), duration: const Duration(seconds: 3)),
    );
  }
}


class _ResultHeader extends StatelessWidget {
  final bool isAuthentic;
  final ProductModel? product;

  const _ResultHeader({required this.isAuthentic, this.product});

  @override
  Widget build(BuildContext context) {
    // color variable removed — gradient uses inline colors

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAuthentic
              ? [const Color(0xFF00C896), const Color(0xFF00796B)]
              : [const Color(0xFFE53935), const Color(0xFFB71C1C)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Badge principal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAuthentic
                          ? Icons.verified_rounded
                          : Icons.dangerous_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAuthentic
                          ? 'Produit Authentique & Approuvé'
                          : 'Produit Potentiellement Contrefait !',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product?.name ?? 'Produit inconnu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (product?.manufacturer != null)
                Text(
                  product!.manufacturer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ActionButtons extends ConsumerWidget {
  final ScanResult result;
  final bool isAuthentic;

  const _ActionButtons({required this.result, required this.isAuthentic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Trouver en pharmacie (toujours visible)
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.pharmacy, extra: result.product),
          icon: const Icon(Icons.local_pharmacy_rounded),
          label: Text(isAuthentic
              ? 'Trouver en pharmacie'
              : 'Trouver une alternative en pharmacie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isAuthentic ? AppTheme.primaryGreen : AppTheme.accentBlue,
          ),
        ),
        const SizedBox(height: 12),

        // Demander à l'assistant
        OutlinedButton.icon(
          onPressed: () {
            ref.read(aiAssistantServiceProvider).setContext(result.product);
            context.push(AppRoutes.assistant);
          },
          icon: const Icon(Icons.smart_toy_rounded),
          label: const Text('Demander à l\'assistant IA'),
        ),

        // Bouton signalement si suspect
        if (!isAuthentic) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _reportProduct(context, ref),
            icon: const Icon(Icons.report_rounded),
            label: const Text('Signaler aux autorités'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _reportProduct(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_rounded, color: AppTheme.dangerRed),
            SizedBox(width: 8),
            Text('Signaler ce produit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous allez signaler "${result.product?.name ?? result.scannedCode}" comme produit suspect aux autorités sanitaires tunisiennes.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Cette action sera transmise à :\n• Direction de la Pharmacie et du Médicament (DPM)\n• Ministère de la Santé Tunisie',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Confirmer le signalement'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Marquer comme signalé
      await ref.read(scanHistoryProvider.notifier).markAsReported(result.id);
      // Re-check mounted after await
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Signalement envoyé aux autorités. Merci !'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
