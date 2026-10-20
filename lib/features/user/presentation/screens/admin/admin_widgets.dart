import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/account_summary.dart';
import 'package:medilink/features/user/presentation/controllers/admin_controller.dart';

Color accountStatusColor(String status) => switch (status) {
  'ACTIVE' => AppColors.success,
  'PENDING' => AppColors.warning,
  'REJECTED' => AppColors.error,
  _ => AppColors.textMuted,
};

/// Ligne de compte (listes de l'administrateur).
class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.account, required this.onTap, this.trailing});

  final AccountSummary account;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = account;
    return MediCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MediAvatar(initials: a.initials, size: 44, color: a.role.color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.fullName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [a.role.label, if (a.detail != null) a.detail!].join(' · '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(label: AccountSummary.statusLabel(a.status), color: accountStatusColor(a.status)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Fiche détaillée d'un compte avec les actions possibles selon son statut.
Future<void> showAccountSheet(BuildContext context, AccountSummary account, AdminController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AccountSheet(account: account, controller: controller, parentContext: context),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.account, required this.controller, required this.parentContext});

  final AccountSummary account;
  final AdminController controller;
  final BuildContext parentContext;

  Future<void> _run(BuildContext context, Future<String?> Function() action, String success) async {
    Navigator.pop(context);
    final error = await action();
    if (!parentContext.mounted) return;
    error == null ? parentContext.showSuccess(success) : parentContext.showError(error);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = account;
    final date = DateFormat('d MMMM yyyy', 'fr');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MediAvatar(initials: a.initials, size: 56, color: a.role.color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.fullName, style: theme.textTheme.titleLarge),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          StatusBadge(label: a.role.label, color: a.role.color, icon: a.role.icon),
                          StatusBadge(label: AccountSummary.statusLabel(a.status), color: accountStatusColor(a.status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InfoRow(icon: Icons.alternate_email_rounded, label: 'E-mail', value: a.email),
            InfoRow(icon: Icons.phone_rounded, label: 'Téléphone', value: a.phone),
            if (a.detail != null) InfoRow(icon: Icons.work_outline_rounded, label: 'Activité', value: a.detail),
            if (a.license != null)
              InfoRow(
                icon: Icons.verified_outlined,
                label: 'N° à vérifier (Ordre, autorisation, CIN...)',
                value: a.license,
              ),
            if (a.createdAt != null)
              InfoRow(icon: Icons.event_outlined, label: 'Inscrit le', value: date.format(a.createdAt!)),
            if (a.rejectionReason != null)
              InfoRow(
                icon: Icons.block_rounded,
                label: 'Motif du refus',
                value: a.rejectionReason,
                color: AppColors.error,
              ),
            const SizedBox(height: AppSpacing.lg),
            if (a.isPending) ...[
              MediButton(
                label: 'Valider le compte',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => _run(context, () => controller.approve(a.userId), 'Compte de ${a.fullName} validé'),
              ),
              const SizedBox(height: AppSpacing.sm),
              MediButton.outlined(
                label: 'Refuser',
                icon: Icons.block_rounded,
                onPressed: () async {
                  final reason = await askRejectionReason(context);
                  if (reason == null || !context.mounted) return;
                  await _run(context, () => controller.reject(a.userId, reason), 'Demande refusée');
                },
              ),
            ],
            if (a.isRejected)
              MediButton(
                label: 'Valider finalement le compte',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => _run(context, () => controller.approve(a.userId), 'Compte de ${a.fullName} validé'),
              ),
            if (a.isActive && a.role != UserRole.admin)
              MediButton.outlined(
                label: 'Suspendre le compte',
                icon: Icons.pause_circle_outline_rounded,
                onPressed: () => _run(context, () => controller.suspend(a.userId), 'Compte suspendu'),
              ),
            if (a.isSuspended)
              MediButton(
                label: 'Réactiver le compte',
                icon: Icons.play_circle_outline_rounded,
                onPressed: () => _run(context, () => controller.reactivate(a.userId), 'Compte réactivé'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Demande le motif d'un refus (obligatoire, envoyé à l'utilisateur à sa connexion).
Future<String?> askRejectionReason(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Motif du refus'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Ex. numéro d\'inscription à l\'Ordre introuvable'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isNotEmpty) Navigator.pop(context, reason);
              },
              child: const Text('Refuser'),
            ),
          ],
        ),
  ).whenComplete(controller.dispose);
}
