import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:el_asli/features/auth/widgets/auth_header.dart';
import 'package:el_asli/features/auth/widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _isLoading   = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await ref.read(authServiceProvider).login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ref.read(authUserProvider.notifier).state = result.user;
      context.go(AppRoutes.home);
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 32),

              // ── Header ──────────────────────────────────────────
              const AuthHeader(
                title: 'Bon retour !',
                titleAr: 'مرحباً بعودتك',
                subtitle: 'Connectez-vous pour vérifier vos médicaments',
              ),
              const SizedBox(height: 36),

              // ── Email ────────────────────────────────────────────
              AuthTextField(
                controller: _emailCtrl,
                label: 'Adresse email',
                hint: 'exemple@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Mot de passe ─────────────────────────────────────
              AuthTextField(
                controller: _passCtrl,
                label: 'Mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                  if (v.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // ── Mot de passe oublié ──────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Mot de passe oublié ?',
                      style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),

              // ── Message d'erreur ─────────────────────────────────
              if (_errorMsg != null)
                _ErrorBanner(message: _errorMsg!),
              if (_errorMsg != null) const SizedBox(height: 12),

              // ── Bouton connexion ─────────────────────────────────
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Se connecter'),
                    ),
              const SizedBox(height: 20),

              // ── Divider ──────────────────────────────────────────
              const _Divider(text: 'ou'),
              const SizedBox(height: 16),

              // ── Compte démo ──────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  _emailCtrl.text = 'demo@elasli.tn';
                  _passCtrl.text  = 'Demo1234!';
                  _login();
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Utiliser le compte démo'),
              ),
              const SizedBox(height: 24),

              // ── Inscription ──────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Pas encore de compte ? '),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.register),
                  child: const Text('S\'inscrire',
                      style: TextStyle(color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13))),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  final String text;
  const _Divider({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}
