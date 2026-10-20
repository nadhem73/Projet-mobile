import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/presentation/controllers/auth_controller.dart';
import 'package:medilink/features/user/presentation/widgets/auth_scaffold.dart';

/// Réinitialisation du mot de passe après vérification de l'e-mail et du
/// téléphone associés au compte.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _controller = getIt<AuthController>();

  @override
  void dispose() {
    for (final c in [_email, _phone, _password, _confirm]) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(AppRoutes.login);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final done = await _controller.resetPassword(email: _email.text, phone: _phone.text, newPassword: _password.text);
    if (!mounted) return;
    if (done) {
      context.showSuccess('Mot de passe modifié, vous pouvez vous connecter');
      _back();
    } else {
      context.showError(_controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle: 'Confirmez votre identité puis choisissez un nouveau mot de passe.',
      onBack: _back,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: AppRadius.card),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Saisissez l\'e-mail et le numéro de téléphone utilisés lors de votre inscription.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
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
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.md),
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
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            ListenableBuilder(
              listenable: _controller,
              builder:
                  (context, _) => MediButton(
                    label: 'Réinitialiser le mot de passe',
                    icon: Icons.lock_reset_rounded,
                    isLoading: _controller.isLoading,
                    onPressed: _submit,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
