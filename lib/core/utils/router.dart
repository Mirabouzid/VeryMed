import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/features/splash/splash_screen.dart';
import 'package:el_asli/features/auth/screens/login_screen.dart';
import 'package:el_asli/features/auth/screens/register_screen.dart';
import 'package:el_asli/features/auth/screens/forgot_password_screen.dart';
import 'package:el_asli/features/home/screens/home_screen.dart';
import 'package:el_asli/features/scan/screens/scan_screen.dart';
import 'package:el_asli/features/results/screens/results_screen.dart';
import 'package:el_asli/features/assistant/screens/assistant_screen.dart';
import 'package:el_asli/features/pharmacy/screens/pharmacy_screen.dart';
import 'package:el_asli/features/history/screens/history_screen.dart';
import 'package:el_asli/features/awareness/screens/awareness_screen.dart';
import 'package:el_asli/features/profile/screens/profile_screen.dart';
import 'package:el_asli/features/shell/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [

    // ── Splash ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (c, s) => _fade(const SplashScreen(), s),
    ),

    // ── Auth (hors shell) ────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (c, s) => _fade(const LoginScreen(), s),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (c, s) => _slide(const RegisterScreen(), s),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      pageBuilder: (c, s) => _slide(const ForgotPasswordScreen(), s),
    ),

    // ── App principale (avec shell + bottom nav) ─────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (c, s) => _fade(const HomeScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.history,
          pageBuilder: (c, s) => _fade(const HistoryScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.pharmacy,
          pageBuilder: (c, s) {
            final product = s.extra as ProductModel?;
            return _fade(PharmacyScreen(product: product), s);
          },
        ),
        GoRoute(
          path: AppRoutes.assistant,
          pageBuilder: (c, s) => _fade(const AssistantScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.awareness,
          pageBuilder: (c, s) => _fade(const AwarenessScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (c, s) => _fade(const ProfileScreen(), s),
        ),
      ],
    ),

    // ── Écrans plein écran (hors shell) ──────────────────────────
    GoRoute(
      path: AppRoutes.scan,
      pageBuilder: (c, s) => _slideUp(const ScanScreen(), s),
    ),
    GoRoute(
      path: AppRoutes.results,
      pageBuilder: (c, s) {
        final result = s.extra as ScanResult;
        return _slideUp(ResultsScreen(scanResult: result), s);
      },
    ),
  ],
);

// ── Transitions ───────────────────────────────────────────────────

CustomTransitionPage<void> _fade(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

CustomTransitionPage<void> _slideUp(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
