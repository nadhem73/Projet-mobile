import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/user_profile.dart';
import 'package:medilink/features/user/presentation/controllers/profile_controller.dart';
import 'package:medilink/features/user/presentation/widgets/image_picking.dart';
import 'package:medilink/features/user/presentation/widgets/user_avatar.dart';
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

  Future<void> _changePhoto() async {
    final choice = await pickImage(context, maxWidth: 512, quality: 80, allowRemove: true, title: 'Photo de profil');
    if (choice == null || !mounted) return;
    final error = await _controller.setAvatar(choice is PickedImage ? choice.bytes : null);
    if (!mounted) return;
    error == null ? context.showSuccess('Photo de profil mise à jour') : context.showError(error);
  }

  Future<void> _changePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => _PasswordSheet(
            title: 'Changer le mot de passe',
            withNewPassword: true,
            onSubmit: (current, newPassword) => _controller.changePassword(current, newPassword!),
          ),
    );
    if (changed == true && mounted) context.showSuccess('Mot de passe modifié');
  }

  Future<void> _exportData() async {
    final json = await _controller.exportData();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mes données'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: json));
                  Navigator.pop(context);
                  this.context.showSuccess('Données copiées dans le presse-papiers');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copier'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => _PasswordSheet(
            title: 'Supprimer mon compte',
            warning:
                'Cette action est définitive : votre compte et toutes vos données (dossier médical, '
                'documents, proches) seront effacés.',
            submitLabel: 'Supprimer définitivement',
            destructive: true,
            // La garde du routeur renvoie vers la connexion dès la fermeture de la session.
            onSubmit: (password, _) => _controller.deleteAccount(password),
          ),
    );
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
      appBar: AppBar(title: const Text('Mon profil'), actions: const [NotificationBell()]),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final profile = _controller.profile;
          if (_controller.isLoading && profile == null) return const LoadingView();
          if (profile == null) {
            return EmptyState.error(_controller.error ?? 'Profil indisponible', onRetry: _controller.load);
          }
          final isPatient = profile.role == UserRole.patient;
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ProfileHeader(profile: profile, onChangePhoto: _changePhoto),
                const SizedBox(height: AppSpacing.lg),
                if (isPatient) ...[
                  const SectionHeader(title: 'Mon espace santé'),
                  _ActionsCard(
                    actions: [
                      _Action(Icons.family_restroom_rounded, 'Mes proches', () => context.push(UserRoutes.dependents)),
                      _Action(
                        Icons.qr_code_2_rounded,
                        'Carte d\'urgence',
                        () => context.push(UserRoutes.emergencyCard),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const SectionHeader(title: 'Informations'),
                MediCard(child: Column(children: _infoRows(profile))),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Paramètres'),
                MediCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _tile(Icons.edit_outlined, 'Modifier mon profil', _edit),
                      const Divider(height: 1),
                      _tile(Icons.lock_outline_rounded, 'Changer le mot de passe', _changePassword),
                      const Divider(height: 1),
                      _tile(
                        Icons.notifications_none_rounded,
                        'Notifications',
                        () => context.push(AppRoutes.notifications),
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
                const SectionHeader(title: 'Mes données personnelles'),
                MediCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _tile(Icons.download_outlined, 'Exporter mes données', _exportData),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                        title: const Text('Supprimer mon compte', style: TextStyle(color: AppColors.error)),
                        onTap: _deleteAccount,
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

  Widget _tile(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );

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
        UserRole.admin => const <Widget>[],
      },
      if (p.createdAt != null)
        InfoRow(icon: Icons.event_available_rounded, label: 'Membre depuis', value: date.format(p.createdAt!)),
    ];
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onChangePhoto});

  final UserProfile profile;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = profile.role;
    final initials = '${profile.prenom.isEmpty ? '' : profile.prenom[0]}${profile.nom.isEmpty ? '' : profile.nom[0]}';
    return MediCard(
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(userId: profile.userId, initials: initials.toUpperCase(), size: 72, color: role.color),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onChangePhoto,
                    child: Tooltip(
                      message: 'Changer la photo',
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.photo_camera_rounded, size: 16, color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

class _Action {
  const _Action(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.actions});

  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: ShortcutTile.compactHeight,
              child: ShortcutTile(icon: a.icon, label: a.label, color: AppColors.primary, onTap: a.onTap),
            ),
          ),
        ],
      ],
    );
  }
}

/// Feuille de confirmation par mot de passe (changement de mot de passe,
/// suppression du compte). [onSubmit] renvoie null si réussi, sinon l'erreur.
class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({
    required this.title,
    required this.onSubmit,
    this.withNewPassword = false,
    this.warning,
    this.submitLabel = 'Enregistrer',
    this.destructive = false,
  });

  final String title;
  final Future<String?> Function(String password, String? newPassword) onSubmit;
  final bool withNewPassword;
  final String? warning;
  final String submitLabel;
  final bool destructive;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
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
    final error = await widget.onSubmit(_current.text, widget.withNewPassword ? _password.text : null);
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
    final theme = Theme.of(context);
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
            Text(widget.title, style: theme.textTheme.titleLarge),
            if (widget.warning != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: AppRadius.card),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(widget.warning!, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            MediTextField(
              label: widget.withNewPassword ? 'Mot de passe actuel' : 'Votre mot de passe',
              controller: _current,
              isPassword: true,
              validator: Validators.required('Le mot de passe'),
            ),
            if (widget.withNewPassword) ...[
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
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            widget.destructive
                ? FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: _saving ? null : _submit,
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : const Icon(Icons.delete_forever_rounded),
                  label: Text(widget.submitLabel),
                )
                : MediButton(label: widget.submitLabel, isLoading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
