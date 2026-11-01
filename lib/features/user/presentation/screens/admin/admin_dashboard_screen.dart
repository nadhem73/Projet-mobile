import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/account_summary.dart';
import 'package:medilink/features/user/presentation/controllers/admin_controller.dart';
import 'package:medilink/features/user/presentation/screens/admin/admin_widgets.dart';
import 'package:medilink/features/user/presentation/widgets/user_avatar.dart';
import 'package:medilink/features/user/user_module.dart';

/// Panel de l'administrateur : chiffres clés et comptes professionnels à valider.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _controller = getIt<AdminController>()..loadDashboard();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _quickApprove(AccountSummary a) async {
    final error = await _controller.approve(a.userId);
    if (!mounted) return;
    error == null ? context.showSuccess('Compte de ${a.fullName} validé') : context.showError(error);
  }

  Future<void> _quickReject(AccountSummary a) async {
    final reason = await askRejectionReason(context);
    if (reason == null) return;
    final error = await _controller.reject(a.userId, reason);
    if (!mounted) return;
    error == null ? context.showSuccess('Demande refusée') : context.showError(error);
  }

  @override
  Widget build(BuildContext context) {
    final user = getIt<SessionService>().currentUser;
    final theme = Theme.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final stats = _controller.stats;
          return RefreshIndicator(
            onRefresh: _controller.loadDashboard,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PanelHeader(
                    greeting: 'Espace administrateur',
                    title: user?.fullName ?? '',
                    subtitle: 'Gestion de la plateforme MediLink',
                    initials: user?.initials ?? '',
                    avatar:
                        user == null
                            ? null
                            : UserAvatar(userId: user.userId, initials: user.initials, size: 52, onDark: true),
                    color: UserRole.admin.color,
                    onAvatarTap: () => context.push(AppRoutes.profile),
                    actions: [
                      const NotificationBell(onDark: true),
                      PanelHeaderAction(
                        icon: Icons.person_outline_rounded,
                        tooltip: 'Mon profil',
                        onPressed: () => context.push(AppRoutes.profile),
                      ),
                    ],
                  ),
                ),
                if (stats == null)
                  const SliverFillRemaining(child: LoadingView())
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'Comptes actifs'),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final role in UserRole.values)
                                _StatChip(
                                  icon: role.icon,
                                  color: role.color,
                                  value: stats.byRole[role] ?? 0,
                                  label: role.label,
                                  onTap: () => context.push(UserRoutes.adminUsers, extra: role),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: _AlertCard(
                                  icon: Icons.hourglass_top_rounded,
                                  color: AppColors.warning,
                                  value: stats.pending,
                                  label: 'en attente',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _AlertCard(
                                  icon: Icons.pause_circle_outline_rounded,
                                  color: AppColors.textMuted,
                                  value: stats.suspended,
                                  label: 'suspendu(s)',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MediButton.outlined(
                            label: 'Gérer tous les comptes',
                            icon: Icons.manage_accounts_outlined,
                            onPressed: () async {
                              await context.push(UserRoutes.adminUsers);
                              _controller.loadDashboard();
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(title: 'Demandes à valider (${_controller.pending.length})'),
                        ],
                      ),
                    ),
                  ),
                  if (_controller.pending.isEmpty)
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.task_alt_rounded,
                        title: 'Tout est à jour',
                        message: 'Aucun compte professionnel en attente de validation.',
                        color: AppColors.success,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      sliver: SliverList.separated(
                        itemCount: _controller.pending.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final a = _controller.pending[i];
                          return AccountTile(
                            account: a,
                            onTap: () => showAccountSheet(context, a, _controller),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Refuser',
                                  onPressed: () => _quickReject(a),
                                  icon: const Icon(Icons.close_rounded, color: AppColors.error),
                                ),
                                IconButton.filledTonal(
                                  tooltip: 'Valider',
                                  onPressed: () => _quickApprove(a),
                                  icon: const Icon(Icons.check_rounded),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      child: Text(
                        'Avant de valider, vérifiez le numéro d\'inscription à l\'Ordre, l\'autorisation '
                        'd\'exercice ou le matricule auprès de l\'organisme concerné.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('$value', style: theme.textTheme.titleMedium?.copyWith(color: color)),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text('$value', style: theme.textTheme.headlineSmall?.copyWith(color: color)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
