import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/core/services/auth/auth_service.dart';
import 'package:el_asli/data/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(authUserProvider);
    final isDark  = ref.watch(themeModeProvider);
    final history = ref.watch(scanHistoryProvider);

    final authentic = history.where((s) => s.isAuthentic).length;
    final suspect   = history.where((s) => !s.isAuthentic).length;
    final reported  = history.where((s) => s.wasReported).length;

    final initial = (user?.fullName.isNotEmpty == true)
        ? user!.fullName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          // ── AppBar avec avatar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Colors.white),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).state = !isDark,
                tooltip: isDark ? 'Mode clair' : 'Mode sombre',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                user: user,
                initial: initial,
                totalScans: history.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Stats ───────────────────────────────────────
                  _StatsRow(
                    authentic: authentic,
                    suspect: suspect,
                    reported: reported,
                  ),
                  const SizedBox(height: 20),

                  // ── Infos compte ────────────────────────────────
                  if (user != null) ...[
                    _SectionTitle(title: 'Mon compte'),
                    _InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Nom complet',
                      value: user.fullName,
                    ),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    if (user.phone != null)
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: user.phone!,
                      ),
                    _InfoTile(
                      icon: Icons.language_rounded,
                      label: 'Langue',
                      value: _langLabel(user.language),
                    ),
                    _InfoTile(
                      icon: user.isVerified
                          ? Icons.verified_rounded
                          : Icons.pending_rounded,
                      label: 'Statut',
                      value: user.isVerified ? 'Compte vérifié ✅' : 'En attente de vérification',
                      valueColor: user.isVerified
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Paramètres ──────────────────────────────────
                  _SectionTitle(title: 'Paramètres'),
                  _ActionTile(
                    icon: Icons.history_rounded,
                    label: 'Historique des scans',
                    trailing: Text('${history.length}',
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700)),
                    onTap: () => context.push(AppRoutes.history),
                  ),
                  _ActionTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailing: const _ComingSoonBadge(),
                    onTap: null,
                  ),
                  _ActionTile(
                    icon: Icons.security_rounded,
                    label: 'Changer le mot de passe',
                    onTap: () => context.push(AppRoutes.forgotPassword),
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    label: 'À propos d\'El Asli',
                    onTap: () => _showAboutDialog(context),
                  ),
                  const SizedBox(height: 20),

                  // ── Danger zone ──────────────────────────────────
                  _SectionTitle(title: 'Zone sensible',
                      color: AppTheme.dangerRed),
                  _ActionTile(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Effacer l\'historique',
                    labelColor: AppTheme.warningOrange,
                    onTap: () => _confirmClearHistory(context, ref),
                  ),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Se déconnecter',
                    labelColor: AppTheme.dangerRed,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                  const SizedBox(height: 32),

                  // ── Version ──────────────────────────────────────
                  const Center(
                    child: Text(
                      'El Asliفيري ميد  v1.0.0\nHackathon Automate or Die 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _langLabel(String code) {
    const labels = {
      'fr': '🇫🇷 Français',
      'ar': '🇸🇦 العربية',
      'tn': '🇹🇳 Derja',
      'en': '🇬🇧 English',
    };
    return labels[code] ?? code;
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'El Asli —فيري ميد',
      applicationVersion: '1.0.0',
      applicationLegalese:
          '© 2026 — Hackathon Automate or Die\n'
          'Thème 2 : Lutte contre la contrefaçon\n\n'
          'Base de données : MongoDB Atlas\n'
          'Cartes : OpenStreetMap contributors',
      children: [
        const SizedBox(height: 12),
        const Text(
          'El Asli est une application de vérification '
          'd\'authenticité des médicaments en Tunisie, '
          'développée pour aider les citoyens à se protéger '
          'contre les médicaments contrefaits.',
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.dangerRed),
          SizedBox(width: 8),
          Text('Se déconnecter'),
        ]),
        content: const Text(
            'Voulez-vous vraiment vous déconnecter ?\n'
            'Votre historique local sera conservé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider).logout();
      ref.read(authUserProvider.notifier).state = null;
      context.go(AppRoutes.login);
    }
  }

  Future<void> _confirmClearHistory(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text(
            'Tous vos scans seront supprimés définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningOrange),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(scanHistoryProvider.notifier).clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historique effacé'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  }
}

// ── Header profil ───────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final AuthUser? user;
  final String initial;
  final int totalScans;

  const _ProfileHeader({
    required this.user,
    required this.initial,
    required this.totalScans,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF005C45), Color(0xFF00C896)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Row(
            children: [
              // Avatar cercle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Badge membre
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Membre El Asli',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ligne stats ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int authentic;
  final int suspect;
  final int reported;

  const _StatsRow({
    required this.authentic,
    required this.suspect,
    required this.reported,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _StatItem(
              value: '${authentic + suspect + reported}',
              label: 'Scans total',
              icon: Icons.qr_code_scanner_rounded,
              color: AppTheme.accentBlue),
          _Divider(),
          _StatItem(
              value: '$authentic',
              label: 'Authentiques',
              icon: Icons.check_circle_rounded,
              color: AppTheme.successGreen),
          _Divider(),
          _StatItem(
              value: '$suspect',
              label: 'Suspects',
              icon: Icons.warning_rounded,
              color: AppTheme.dangerRed),
          _Divider(),
          _StatItem(
              value: '$reported',
              label: 'Signalés',
              icon: Icons.report_rounded,
              color: AppTheme.warningOrange),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 40,
      color: Colors.grey.withValues(alpha: 0.2));
}

// ── Titre de section ────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionTitle({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Tile info lecture seule ─────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ]),
        ),
      ]),
    );
  }
}

// ── Tile action ─────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.labelColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (labelColor ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: labelColor ?? AppTheme.primaryGreen, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: labelColor),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Badge "Bientôt" ─────────────────────────────────────────────────
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
      ),
      child: const Text('Bientôt',
          style: TextStyle(
              fontSize: 10,
              color: AppTheme.accentBlue,
              fontWeight: FontWeight.w600)),
    );
  }
}
