import 'package:flutter/material.dart';
import 'package:el_asli/core/theme/app_theme.dart';

/// Header commun à tous les écrans d'authentification
class AuthHeader extends StatelessWidget {
  final String title;
  final String titleAr;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.titleAr,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mini logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),

        // Titre français
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Titre arabe
        Text(
          titleAr,
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Sous-titre
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
