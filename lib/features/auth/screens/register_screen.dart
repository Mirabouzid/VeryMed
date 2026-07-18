import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:el_asli/features/auth/widgets/auth_header.dart';
import 'package:el_asli/features/auth/widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();

  bool _isLoading    = false;
  bool _obscurePass  = true;
  bool _obscureConf  = true;
  bool _acceptTerms  = false;
  String _lang       = 'fr';
  String? _errorMsg;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confCtrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _errorMsg = 'Veuillez accepter les conditions d\'utilisation');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await ref.read(authServiceProvider).register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      language: _lang,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ref.read(authUserProvider.notifier).state = result.user;
      // Afficher message de bienvenue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenue, ${result.user?.fullName} ! 🎉'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      context.go(AppRoutes.home);
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              const AuthHeader(
                title: 'Créer un compte',
                titleAr: 'إنشاء حساب',
                subtitle: 'Rejoignez El Asli pour protéger votre santé',
              ),
              const SizedBox(height: 28),

              // ── Nom complet ──────────────────────────────────────
              AuthTextField(
                controller: _nameCtrl,
                label: 'Nom complet',
                hint: 'Votre prénom et nom',
                icon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nom requis';
                  if (v.trim().length < 3) return 'Nom trop court';
                  return null;
                },
              ),
              const SizedBox(height: 14),

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
              const SizedBox(height: 14),

              // ── Téléphone ────────────────────────────────────────
              AuthTextField(
                controller: _phoneCtrl,
                label: 'Téléphone (optionnel)',
                hint: '+216 XX XXX XXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // ── Mot de passe ─────────────────────────────────────
              AuthTextField(
                controller: _passCtrl,
                label: 'Mot de passe',
                hint: 'Minimum 6 caractères',
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
              const SizedBox(height: 14),

              // ── Confirmation ─────────────────────────────────────
              AuthTextField(
                controller: _confCtrl,
                label: 'Confirmer le mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConf,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConf = !_obscureConf),
                ),
                validator: (v) {
                  if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Langue préférée ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDE7E5)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _lang,
                    icon: const Icon(Icons.language_rounded, color: AppTheme.primaryGreen),
                    items: const [
                      DropdownMenuItem(value: 'fr', child: Text('🇫🇷  Français')),
                      DropdownMenuItem(value: 'ar', child: Text('🇸🇦  العربية')),
                      DropdownMenuItem(value: 'tn', child: Text('🇹🇳  Derja')),
                      DropdownMenuItem(value: 'en', child: Text('🇬🇧  English')),
                    ],
                    onChanged: (v) => setState(() => _lang = v ?? 'fr'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── CGU ──────────────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  activeColor: AppTheme.primaryGreen,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'J\'accepte les '),
                          TextSpan(text: 'Conditions d\'utilisation',
                              style: TextStyle(color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600)),
                          TextSpan(text: ' et la '),
                          TextSpan(text: 'Politique de confidentialité',
                              style: TextStyle(color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600)),
                        ]),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Erreur ───────────────────────────────────────────
              if (_errorMsg != null) ...[
                _ErrorBanner(message: _errorMsg!),
                const SizedBox(height: 12),
              ],

              // ── Bouton inscription ───────────────────────────────
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : ElevatedButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Créer mon compte'),
                    ),
              const SizedBox(height: 20),

              // ── Déjà un compte ───────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Déjà un compte ? '),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Se connecter',
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
  Widget build(BuildContext context) => Container(
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
