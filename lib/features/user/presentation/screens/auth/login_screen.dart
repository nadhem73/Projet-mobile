import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/presentation/controllers/auth_controller.dart';
import 'package:medilink/features/user/presentation/widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _controller = getIt<AuthController>();

  /// Comptes de démonstration (affichés uniquement en mode debug).
  static const _demoAccounts = {
    UserRole.patient: 'patient@medilink.tn',
    UserRole.doctor: 'dr.benali@medilink.tn',
    UserRole.pharmacist: 'pharmacie@medilink.tn',
    UserRole.insurer: 'assurance@medilink.tn',
    UserRole.admin: 'admin@medilink.tn',
  };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final user = await _controller.login(_email.text, _password.text);
    if (!mounted) return;
    if (user == null) {
      context.showError(_controller.error!);
    } else {
      context.go(AppRoutes.homeFor(user.role));
    }
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = DatabaseSeeder.demoPassword;
  }

  Future<void> _showPharmacyPicker() async {
    List<Pharmacy> pharmacies = [];
    try {
      pharmacies = await getIt<PharmacyRepository>().getAll();
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF0D9488), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Choisir une pharmacie (${pharmacies.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sélectionnez une officine pour tester son inventaire et ses prix spécifiques',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: pharmacies.isEmpty
                      ? const Center(child: Text('Aucune pharmacie trouvée'))
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: pharmacies.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = pharmacies[i];
                            final isNight = p.isNightPharmacy;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isNight
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                    : const Color(0xFF0D9488).withValues(alpha: 0.15),
                                child: Icon(
                                  isNight ? Icons.nightlight_round : Icons.local_pharmacy,
                                  color: isNight ? const Color(0xFF6366F1) : const Color(0xFF0D9488),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${p.address} • ${p.phone ?? ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Chip(
                                label: Text(
                                  isNight ? 'Nuit' : 'Jour',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isNight ? const Color(0xFF6366F1) : const Color(0xFF0D9488),
                                  ),
                                ),
                                backgroundColor: isNight
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                                    : const Color(0xFF0D9488).withValues(alpha: 0.1),
                                padding: EdgeInsets.zero,
                              ),
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                if (p.email != null && p.email!.isNotEmpty) {
                                  _fillDemo(p.email!);
                                } else {
                                  _fillDemo('pharmacie@medilink.tn');
                                }
                                _submit();
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      title: 'Bon retour !',
      subtitle: 'Connectez-vous pour accéder à votre espace.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MediTextField(
                label: 'Adresse e-mail',
                controller: _email,
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              MediTextField(
                label: 'Mot de passe',
                controller: _password,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.required('Le mot de passe'),
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListenableBuilder(
                listenable: _controller,
                builder:
                    (context, _) => MediButton(
                      label: 'Se connecter',
                      icon: Icons.login_rounded,
                      isLoading: _controller.isLoading,
                      onPressed: _submit,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Pas encore de compte ?', style: theme.textTheme.bodyMedium),
                  TextButton(onPressed: () => context.push(AppRoutes.register), child: const Text('Créer un compte')),
                ],
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Comptes de démonstration', textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final MapEntry(key: role, value: email) in _demoAccounts.entries)
                      ActionChip(
                        avatar: Icon(role.icon, size: 18, color: role.color),
                        label: Text(role == UserRole.pharmacist ? 'Pharmacien (33)' : role.label),
                        onPressed: () {
                          if (role == UserRole.pharmacist) {
                            _showPharmacyPicker();
                          } else {
                            _fillDemo(email);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
