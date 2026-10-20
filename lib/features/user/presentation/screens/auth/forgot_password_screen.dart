import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/repositories/auth_repository.dart';
import 'package:medilink/features/user/presentation/controllers/auth_controller.dart';
import 'package:medilink/features/user/presentation/widgets/auth_scaffold.dart';

/// Mot de passe oublié en deux étapes :
/// 1. e-mail + téléphone du compte → envoi d'un code à 6 chiffres par SMS ;
/// 2. code + nouveau mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _requestKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _controller = getIt<AuthController>();

  ResetCodeDelivery? _delivery;

  @override
  void dispose() {
    for (final c in [_email, _phone, _code, _password, _confirm]) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _back() {
    if (_delivery != null) {
      setState(() => _delivery = null);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    if (_delivery == null && !_requestKey.currentState!.validate()) return;
    final delivery = await _controller.requestResetCode(email: _email.text, phone: _phone.text);
    if (!mounted) return;
    if (delivery == null) {
      context.showError(_controller.error!);
      return;
    }
    _code.clear();
    setState(() => _delivery = delivery);
    context.showInfo('Code envoyé au ${delivery.maskedPhone}');
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (!_resetKey.currentState!.validate()) return;
    final done = await _controller.resetPassword(email: _email.text, code: _code.text, newPassword: _password.text);
    if (!mounted) return;
    if (done) {
      context.showSuccess('Mot de passe modifié, vous pouvez vous connecter');
      context.go(AppRoutes.login);
    } else {
      context.showError(_controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;
    return PopScope(
      canPop: delivery == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _delivery = null);
      },
      child: AuthScaffold(
        title: 'Mot de passe oublié',
        subtitle:
            delivery == null
                ? 'Étape 1 sur 2 — Confirmez votre identité.'
                : 'Étape 2 sur 2 — Saisissez le code reçu par SMS.',
        onBack: _back,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: delivery == null ? _buildRequest() : _buildReset(delivery),
        ),
      ),
    );
  }

  Widget _buildRequest() {
    return Form(
      key: _requestKey,
      child: Column(
        key: const ValueKey('request'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoBox(
            icon: Icons.info_outline_rounded,
            color: AppColors.info,
            text:
                'Saisissez l\'e-mail et le numéro de téléphone de votre compte. '
                'Nous vous enverrons un code de vérification par SMS.',
          ),
          const SizedBox(height: AppSpacing.lg),
          MediTextField(
            label: 'Adresse e-mail',
            controller: _email,
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          MediTextField(
            label: 'Téléphone du compte',
            controller: _phone,
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: Validators.phone,
            onSubmitted: (_) => _requestCode(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ListenableBuilder(
            listenable: _controller,
            builder:
                (context, _) => MediButton(
                  label: 'Recevoir un code',
                  icon: Icons.sms_outlined,
                  isLoading: _controller.isLoading,
                  onPressed: _requestCode,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReset(ResetCodeDelivery delivery) {
    final theme = Theme.of(context);
    return Form(
      key: _resetKey,
      child: Column(
        key: const ValueKey('reset'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBox(
            icon: Icons.sms_outlined,
            color: AppColors.success,
            text:
                'Code envoyé par SMS au ${delivery.maskedPhone}. Il est valable '
                '${AuthRepository.resetCodeValidity.inMinutes} minutes.',
          ),
          // Pas de passerelle SMS dans le projet : le code est affiché en mode démo.
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoBox(
              icon: Icons.developer_mode_rounded,
              color: AppColors.accent,
              text: 'Mode démo (pas d\'envoi réel de SMS) : votre code est ${delivery.code}',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _code,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
            decoration: const InputDecoration(labelText: 'Code à 6 chiffres', counterText: ''),
            validator: (v) => (v == null || v.length != 6) ? 'Le code contient 6 chiffres' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _controller.isLoading ? null : _requestCode,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Renvoyer un code'),
            ),
          ),
          MediTextField(
            label: 'Nouveau mot de passe',
            controller: _password,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            helperText: 'Au moins 8 caractères, une lettre et un chiffre',
            validator: Validators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          MediTextField(
            label: 'Confirmer le mot de passe',
            controller: _confirm,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: Validators.confirmPassword(() => _password.text),
            onSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ListenableBuilder(
            listenable: _controller,
            builder:
                (context, _) => MediButton(
                  label: 'Réinitialiser le mot de passe',
                  icon: Icons.lock_reset_rounded,
                  isLoading: _controller.isLoading,
                  onPressed: _reset,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.card),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
