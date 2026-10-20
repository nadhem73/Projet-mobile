import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';

/// Panel du pharmacien (point d'entrée de l'espace PHARMACIST).
///
/// Module Pharmacie (Membre 4) : remplacer les tuiles « Bientôt » par les
/// vrais écrans au fur et à mesure (ordonnances reçues, commandes, stock...).
class PharmacistDashboardScreen extends StatelessWidget {
  const PharmacistDashboardScreen({super.key});

  static const _features = [
    (Icons.receipt_long_rounded, 'Ordonnances reçues', 'Ordonnances envoyées par les patients'),
    (Icons.shopping_bag_rounded, 'Commandes', 'Préparer et suivre les commandes'),
    (Icons.medication_rounded, 'Catalogue', 'Rechercher un médicament'),
    (Icons.inventory_2_rounded, 'Stock et alertes', 'Ruptures et produits à commander'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = getIt<SessionService>().currentUser;
    final color = UserRole.pharmacist.color;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PanelHeader(
              greeting: 'Espace pharmacien',
              title: user?.organization ?? 'Ma pharmacie',
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
