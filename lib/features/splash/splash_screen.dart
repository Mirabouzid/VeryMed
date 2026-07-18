import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/providers/app_providers.dart';

/// ─────────────────────────────────────────────────────────────
///  Page de couverture El Asli
///
///  Comportement :
///  1. Animation d'entrée (logo + tagline)
///  2. Après animation → afficher boutons "Commencer" / "Se connecter"
///  3. L'utilisateur CLIQUE pour avancer — jamais automatique
///  4. Seule exception : session valide trouvée en base → home direct
/// ─────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>  _fadeAnim;
  late Animation<double>  _scaleAnim;
  late Animation<Offset>  _slideAnim;
  late Animation<double>  _btnFadeAnim;

  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));

    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.65, curve: Curves.elasticOut)));

    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.2, 0.75, curve: Curves.easeOut)));

    _btnFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.65, 1.0, curve: Curves.easeIn)));

    _ctrl.forward().then((_) {
      if (mounted) setState(() => _showButtons = true);
    });

    // Vérifier session en arrière-plan SANS naviguer automatiquement
    _checkExistingSession();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Vérifie si l'utilisateur est déjà connecté
  /// → Seulement si session RÉELLE trouvée, on navigue directement
  Future<void> _checkExistingSession() async {
    final authService = ref.read(authServiceProvider);
    final user = await authService.restoreSession();
    if (!mounted) return;
    // Session valide → naviguer directement vers home
    if (user != null && !user.isGuest) {
      ref.read(authUserProvider.notifier).state = user;
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) context.go(AppRoutes.home);
    }
    // Sinon : l'utilisateur choisit depuis les boutons
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF002B20),
              Color(0xFF004D38),
              Color(0xFF007A5C),
              Color(0xFF00C896),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo animé ─────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(children: [
                    // Cercle logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: CustomPaint(painter: _LogoPainter()),
                      ),
                    ),
                    const SizedBox(height: 28),

                    //فيري ميد
                    const Text(
                      'الأصلي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        shadows: [
                          Shadow(color: Colors.black38,
                              blurRadius: 10, offset: Offset(0, 3))
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'E L  A S L I',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 8,
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              // ── Tagline ────────────────────────────────────────
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Vérifiez l\'authenticité\nde vos médicaments',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'تحقق من أصالة أدويتك وحمِ عائلتك',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ]),
                ),
              ),

              const Spacer(flex: 2),

              // ── Boutons d'action ───────────────────────────────
              FadeTransition(
                opacity: _btnFadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(children: [

                    // Features highlights
                    if (_showButtons) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeatureBadge(icon: Icons.qr_code_scanner_rounded,
                              label: 'Scanner'),
                          const SizedBox(width: 12),
                          _FeatureBadge(icon: Icons.verified_rounded,
                              label: 'Vérifier'),
                          const SizedBox(width: 12),
                          _FeatureBadge(icon: Icons.local_pharmacy_rounded,
                              label: 'Pharmacies'),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Bouton principal : S'inscrire
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: AppTheme.primaryGreen, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Créer un compte',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bouton secondaire : Se connecter
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.login),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'J\'ai déjà un compte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lien compte démo
                    GestureDetector(
                      onTap: () => _loginAsGuest(context),
                      child: Text(
                        'Continuer sans compte (démo)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Footer ─────────────────────────────────────────
              FadeTransition(
                opacity: _btnFadeAnim,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(children: [
                    const Divider(color: Colors.white24, indent: 80, endIndent: 80),
                    const SizedBox(height: 8),
                    Text(
                      'Hackathon Automate or Die 2026  •  Thème 2',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Connexion invité démo — sans inscription
  Future<void> _loginAsGuest(BuildContext context) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.login(
      email: 'demo@elasli.tn',
      password: 'Demo1234!',
    );
    if (!mounted) return;
    if (result.success) {
      ref.read(authUserProvider.notifier).state = result.user;
      context.go(AppRoutes.home);
    } else {
      // Créer guest local si démo non dispo
      final guestResult = await authService.loginAsGuest();
      if (mounted && guestResult.success) {
        ref.read(authUserProvider.notifier).state = guestResult.user;
        context.go(AppRoutes.home);
      }
    }
  }
}

/// Badge fonctionnalité
class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    ]);
  }
}

/// Logo custom peint en Canvas
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fond pill (comprimé)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.28, w, h * 0.44),
        Radius.circular(h * 0.22),
      ),
      bgPaint,
    );

    // Croix médicale blanche
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.5, h * 0.92), linePaint);
    canvas.drawLine(Offset(w * 0.08, h * 0.5), Offset(w * 0.92, h * 0.5), linePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
