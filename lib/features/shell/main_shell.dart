import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/providers/app_providers.dart';


class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.history,
    AppRoutes.pharmacy,
    AppRoutes.assistant,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final safeIdx  = _safeIndex(location);
    final isDark   = ref.watch(themeModeProvider);
    final user     = ref.watch(authUserProvider);

   
    final initial = (user?.fullName.isNotEmpty == true)
        ? user!.fullName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: child,


      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.scan),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded,
            color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: isDark ? AppTheme.cardDark : Colors.white,
        elevation: 8,
        height: 64,
        child: Row(
          children: [
        
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                    isActive: safeIdx == 0,
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    isActive: safeIdx == 1,
                    onTap: () => context.go(AppRoutes.history),
                  ),
                ],
              ),
            ),

            // Espace pour le FAB
            const SizedBox(width: 72),

            
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.local_pharmacy_rounded,
                    label: 'Pharmacies',
                    isActive: safeIdx == 2,
                    onTap: () => context.go(AppRoutes.pharmacy),
                  ),
               
                  _ProfileNavItem(
                    initial: initial,
                    isActive: safeIdx == 4,
                    onTap: () => context.go(AppRoutes.profile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _safeIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }
}


class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? AppTheme.primaryGreen : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? AppTheme.primaryGreen : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavItem extends StatelessWidget {
  final String initial;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.initial,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppTheme.primaryGreen
                    : Colors.grey.shade300,
                border: isActive
                    ? Border.all(color: AppTheme.primaryGreen, width: 2)
                    : null,
                boxShadow: isActive
                    ? [BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 6)]
                    : null,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Profil',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? AppTheme.primaryGreen : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
