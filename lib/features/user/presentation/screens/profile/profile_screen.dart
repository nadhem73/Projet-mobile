import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/user_profile.dart';
import 'package:medilink/features/user/presentation/controllers/profile_controller.dart';
import 'package:medilink/features/user/user_module.dart';

/// Profil de l'utilisateur connecté, quel que soit son rôle.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = getIt<ProfileController>()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final saved = await context.push<bool>(UserRoutes.editProfile);
    if (saved == true) {
      await _controller.load();
      if (mounted) context.showSuccess('Profil mis à jour');
    }
  }

  Future<void> _changePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangePasswordSheet(controller: _controller),
    );
    if (changed == true && mounted) context.showSuccess('Mot de passe modifié');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Se déconnecter ?'),
            content: const Text('Vous devrez saisir à nouveau votre e-mail et votre mot de passe.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se déconnecter')),
            ],
          ),
    );
    // La garde du routeur redirige vers la connexion dès la fermeture de la session.
    if (confirm == true) await _controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final profile = _controller.profile;
          if (_controller.isLoading && profile == null) return const LoadingView();
          if (profile == null) {
            return EmptyState.error(_controller.error ?? 'Profil indisponible', onRetry: _controller.load);
          }
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Informations'),
                MediCard(child: Column(children: _infoRows(profile))),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Paramètres'),
                MediCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Modifier mon profil'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _edit,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Changer le mot de passe'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _changePassword,
                      ),
                      const Divider(height: 1),
                      Observer(
                        builder: (_) {
                          final appStore = getIt<AppStore>();
                          return SwitchListTile(
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Mode sombre'),
                            value: appStore.isDarkModeOn,
                            onChanged: (v) => appStore.toggleDarkMode(value: v),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                MediButton.outlined(label: 'Se déconnecter', icon: Icons.logout_rounded, onPressed: _logout),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _infoRows(UserProfile p) {
    final date = DateFormat('d MMMM yyyy', 'fr');
    return [
      InfoRow(icon: Icons.alternate_email_rounded, label: 'E-mail', value: p.email),
      InfoRow(icon: Icons.phone_rounded, label: 'Téléphone', value: p.phone),
      ...switch (p.role) {
        UserRole.patient => [
          InfoRow(icon: Icons.badge_outlined, label: 'CIN', value: p.cin),
          InfoRow(
            icon: Icons.cake_outlined,
            label: 'Date de naissance',
            value: p.dateNaissance == null ? null : '${date.format(p.dateNaissance!)} (${p.age} ans)',
          ),
          InfoRow(icon: Icons.place_outlined, label: 'Adresse', value: p.address),
        ],
        UserRole.doctor => [
          InfoRow(icon: Icons.medical_information_outlined, label: 'Spécialité', value: p.specialty),
          InfoRow(icon: Icons.verified_outlined, label: 'N° Ordre des médecins', value: p.licenseNumber),
          InfoRow(icon: Icons.location_city_rounded, label: 'Ville', value: p.city),
          InfoRow(icon: Icons.place_outlined, label: 'Adresse du cabinet', value: p.address),
          InfoRow(
            icon: Icons.payments_outlined,
            label: 'Tarif de consultation',
            value: p.fee == null ? null : '${p.fee!.toStringAsFixed(0)} TND',
          ),
          InfoRow(icon: Icons.notes_rounded, label: 'Présentation', value: p.biography),
        ],
        UserRole.pharmacist => [
          InfoRow(icon: Icons.storefront_outlined, label: 'Pharmacie', value: p.pharmacyName),
          InfoRow(icon: Icons.verified_outlined, label: 'N° d\'autorisation', value: p.licenseNumber),
          InfoRow(icon: Icons.place_outlined, label: 'Adresse', value: p.address),
          InfoRow(icon: Icons.location_city_rounded, label: 'Ville', value: p.city),
        ],
        UserRole.insurer => [
          InfoRow(icon: Icons.business_rounded, label: 'Organisme', value: p.company),
          InfoRow(icon: Icons.badge_outlined, label: 'Matricule agent', value: p.agentCode),
        ],
      },
      if (p.createdAt != null)
        InfoRow(icon: Icons.event_available_rounded, label: 'Membre depuis', value: date.format(p.createdAt!)),
    ];
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = profile.role;
    final initials = '${profile.prenom.isEmpty ? '' : profile.prenom[0]}${profile.nom.isEmpty ? '' : profile.nom[0]}';
    return MediCard(
      child: Row(
        children: [
          MediAvatar(initials: initials.toUpperCase(), size: 64, color: role.color),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == UserRole.doctor ? 'Dr ${profile.fullName}' : profile.fullName,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(label: role.label, color: role.color, icon: role.icon),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.controller});

  final ProfileController controller;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.controller.changePassword(_current.text, _password.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Changer le mot de passe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            MediTextField(
              label: 'Mot de passe actuel',
              controller: _current,
              isPassword: true,
              validator: Validators.required('Le mot de passe actuel'),
            ),
            const SizedBox(height: AppSpacing.md),
            MediTextField(
              label: 'Nouveau mot de passe',
              controller: _password,
              isPassword: true,
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            MediTextField(
              label: 'Confirmer le nouveau mot de passe',
              controller: _confirm,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _password.text),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            MediButton(label: 'Enregistrer', isLoading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
