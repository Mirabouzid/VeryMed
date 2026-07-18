import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:el_asli/features/auth/widgets/auth_header.dart';
import 'package:el_asli/features/auth/widgets/auth_text_field.dart';

/// Écran mot de passe oublié — 3 étapes :
///  Étape 1 : saisir l'email
///  Étape 2 : saisir l'OTP reçu (affiché en démo)
///  Étape 3 : choisir le nouveau mot de passe
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 1; // 1 = email, 2 = OTP, 3 = nouveau MDP

  final _emailCtrl   = TextEditingController();
  final _otpCtrl     = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confCtrl    = TextEditingController();

  bool _isLoading    = false;
  bool _obscurePass  = true;
  bool _obscureConf  = true;
  String? _errorMsg;
  String? _infoMsg;
  String? _demoOtp; // Affiché uniquement en mode démo

  @override
  void dispose() {
    for (final c in [_emailCtrl, _otpCtrl, _passCtrl, _confCtrl]) { c.dispose(); }
    super.dispose();
  }

  // ── Étape 1 : Envoyer OTP ────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Veuillez saisir votre email');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; _infoMsg = null; });

    final result = await ref.read(authServiceProvider)
        .sendPasswordReset(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Extraire OTP démo (préfixé par OTP_CODE:)
      if (result.error?.startsWith('OTP_CODE:') == true) {
        _demoOtp = result.error!.replaceFirst('OTP_CODE:', '');
        _infoMsg = '📱 Mode démo — Votre code OTP : $_demoOtp\n(En production, reçu par SMS/Email)';
      } else {
        _infoMsg = 'Un code de vérification a été envoyé à ${_emailCtrl.text}';
      }
      setState(() => _step = 2);
    } else {
      setState(() => _errorMsg = result.error ?? 'Erreur inattendue');
    }
  }

  // ── Étape 2 : Vérifier OTP ───────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _errorMsg = 'Le code OTP doit contenir 6 chiffres');
      return;
    }
    // En mode démo, accepter l'OTP affiché
    if (_demoOtp != null && _otpCtrl.text.trim() == _demoOtp) {
      setState(() { _step = 3; _errorMsg = null; _infoMsg = null; });
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    // OTP incorrect en démo
    setState(() { _isLoading = false; _errorMsg = 'Code OTP incorrect. Réessayez.'; });
  }

  // ── Étape 3 : Réinitialiser MDP ──────────────────────────────────
  Future<void> _resetPassword() async {
    if (_passCtrl.text.length < 6) {
      setState(() => _errorMsg = 'Mot de passe trop court (min 6 caractères)');
      return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      setState(() => _errorMsg = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await ref.read(authServiceProvider).resetPasswordWithOtp(
      email: _emailCtrl.text.trim(),
      otp: _otpCtrl.text.trim(),
      newPassword: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mot de passe réinitialisé avec succès !'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      context.go(AppRoutes.login);
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
          onPressed: () => _step > 1
              ? setState(() { _step--; _errorMsg = null; _infoMsg = null; })
              : context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 16),

            // ── Indicateur d'étapes ──────────────────────────────
            _StepIndicator(currentStep: _step),
            const SizedBox(height: 28),

            // ── Header dynamique ─────────────────────────────────
            AuthHeader(
              title: _step == 1 ? 'Mot de passe oublié'
                   : _step == 2 ? 'Code de vérification'
                   : 'Nouveau mot de passe',
              titleAr: _step == 1 ? 'نسيت كلمة المرور'
                     : _step == 2 ? 'رمز التحقق'
                     : 'كلمة مرور جديدة',
              subtitle: _step == 1
                  ? 'Saisissez votre email pour recevoir un code de vérification'
                  : _step == 2
                  ? 'Entrez le code à 6 chiffres envoyé à ${_emailCtrl.text}'
                  : 'Choisissez un nouveau mot de passe sécurisé',
            ),
            const SizedBox(height: 28),

            // ── Message info ─────────────────────────────────────
            if (_infoMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_infoMsg!,
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // ── Étape 1 : Email ──────────────────────────────────
            if (_step == 1) ...[
              AuthTextField(
                controller: _emailCtrl,
                label: 'Adresse email',
                hint: 'votre@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              if (_errorMsg != null) ...[
                _ErrorBanner(message: _errorMsg!),
                const SizedBox(height: 12),
              ],
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : ElevatedButton.icon(
                      onPressed: _sendOtp,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Envoyer le code'),
                    ),
            ],

            // ── Étape 2 : OTP ────────────────────────────────────
            if (_step == 2) ...[
              AuthTextField(
                controller: _otpCtrl,
                label: 'Code OTP',
                hint: '000000',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: const Text('Renvoyer le code',
                    style: TextStyle(color: AppTheme.primaryGreen)),
              ),
              const SizedBox(height: 12),
              if (_errorMsg != null) ...[
                _ErrorBanner(message: _errorMsg!),
                const SizedBox(height: 12),
              ],
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : ElevatedButton.icon(
                      onPressed: _verifyOtp,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Vérifier le code'),
                    ),
            ],

            // ── Étape 3 : Nouveau MDP ────────────────────────────
            if (_step == 3) ...[
              AuthTextField(
                controller: _passCtrl,
                label: 'Nouveau mot de passe',
                hint: 'Minimum 6 caractères',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 14),
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
              ),
              const SizedBox(height: 24),
              if (_errorMsg != null) ...[
                _ErrorBanner(message: _errorMsg!),
                const SizedBox(height: 12),
              ],
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : ElevatedButton.icon(
                      onPressed: _resetPassword,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Enregistrer le mot de passe'),
                    ),
            ],

            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    final steps = ['Email', 'Code OTP', 'Nouveau MDP'];
    return Row(children: List.generate(steps.length * 2 - 1, (i) {
      if (i.isOdd) {
        final idx = i ~/ 2;
        return Expanded(child: Container(height: 2,
            color: idx < currentStep - 1
                ? AppTheme.primaryGreen
                : Colors.grey.shade300));
      }
      final idx = i ~/ 2;
      final done = idx < currentStep - 1;
      final active = idx == currentStep - 1;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: done || active ? AppTheme.primaryGreen : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppTheme.primaryGreen : Colors.transparent, width: 2),
          ),
          child: Center(child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Text('${idx + 1}', style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w700, fontSize: 13))),
        ),
        const SizedBox(height: 4),
        Text(steps[idx], style: TextStyle(
            fontSize: 10,
            color: active ? AppTheme.primaryGreen : Colors.grey,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ]);
    }));
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
