import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';

/// Panel de l'assureur (point d'entrée de l'espace INSURER).
///
/// Module Assurance (Membre 3) : remplacer les tuiles « Bientôt » par les
/// vrais écrans au fur et à mesure (contrats, remboursements...).
class InsurerDashboardScreen extends StatelessWidget {
  const InsurerDashboardScreen({super.key});

  static const _features = [
    (Icons.description_rounded, 'Contrats', 'Contrats et adhérents'),
    (Icons.request_quote_rounded, 'Remboursements', 'Demandes à traiter'),
    (Icons.fact_check_rounded, 'Prises en charge', 'Accords préalables'),
    (Icons.insights_rounded, 'Statistiques', 'Suivi des dépenses de santé'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = getIt<SessionService>().currentUser;
    final color = UserRole.insurer.color;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PanelHeader(
              greeting: 'Espace assureur',
              title: user?.organization ?? 'Mon organisme',
              subtitle: user?.fullName,
              initials: user?.initials ?? '',
              color: color,
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
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Votre activité')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: ShortcutTile.detailedHeight,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              delegate: SliverChildListDelegate([
                for (final (icon, label, description) in _features)
                  ShortcutTile(
                    icon: icon,
                    label: label,
                    description: description,
                    color: color,
                    badge: 'Bientôt',
                    onTap: () => context.showInfo('« $label » sera disponible prochainement'),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
