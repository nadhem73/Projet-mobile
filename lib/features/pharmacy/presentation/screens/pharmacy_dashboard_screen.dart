import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/pharmacy/pharmacy_module.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/pharmacy_dashboard_controller.dart';
import 'package:medilink/features/pharmacy/presentation/screens/medicine_catalog_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_profile_screen.dart';
import 'package:medilink/features/user/presentation/widgets/user_avatar.dart';

/// Tableau de bord moderne du pharmacien titulaire d'officine.
/// Aligné sur l'architecture et les composants MediLink (PanelHeader, MediCard, ShortcutTile).
class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  late PharmacyDashboardController _controller;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<PharmacyDashboardController>();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter de votre espace pharmacien ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              await GetIt.I<SessionService>().close();
              if (!mounted) return;
              context.go(AppRoutes.login);
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNavSelect(int index) async {
    setState(() => _navIndex = index);
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()),
      );
      _controller.refresh();
      if (mounted) setState(() => _navIndex = 0);
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicineCatalogScreen(initialFilter: 'low_stock')),
      );
      _controller.refresh();
      if (mounted) setState(() => _navIndex = 0);
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PharmacyProfileScreen()),
      );
      _controller.refresh();
      if (mounted) setState(() => _navIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = GetIt.I<SessionService>().currentUser;
    final color = UserRole.pharmacist.color;

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _handleNavSelect,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Officine',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store_rounded),
            label: 'Profil',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && !_controller.hasPharmacy) {
            return const LoadingView(message: 'Chargement de votre officine...');
          }

          if (_controller.error != null && !_controller.hasPharmacy) {
            return EmptyState.error(
              _controller.error!,
              onRetry: _controller.refresh,
            );
          }

          final pharmacyTitle = user?.organization ?? _controller.pharmacy?.name ?? 'Pharmacie Ennour';

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PanelHeader(
                    greeting: 'Espace pharmacien',
                    title: pharmacyTitle,
                    subtitle: user?.fullName ?? 'Pharmacien titulaire',
                    initials: user?.initials ?? 'PH',
                    color: color,
                    avatar: user == null
                        ? null
                        : UserAvatar(
                            userId: user.userId,
                            initials: user.initials,
                            size: 52,
                            onDark: true,
                          ),
                    onAvatarTap: () => context.push(AppRoutes.profile),
                    actions: [
                      const NotificationBell(onDark: true),
                      PanelHeaderAction(
                        icon: Icons.person_outline_rounded,
                        tooltip: 'Mon profil',
                        onPressed: () => context.push(AppRoutes.profile),
                      ),
                      PanelHeaderAction(
                        icon: Icons.logout_rounded,
                        tooltip: 'Déconnexion',
                        onPressed: _confirmLogout,
                      ),
                    ],
                    bottom: _buildPharmacySummary(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'État des stocks',
                      actionLabel: 'Tout voir',
                      onAction: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()),
                        );
                        _controller.refresh();
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.45,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildKpiCard(
                        context,
                        title: 'Total catalogue',
                        value: '${_controller.totalMedicinesManaged}',
                        icon: Icons.medication_rounded,
                        color: AppColors.primary,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()),
                          );
                          _controller.refresh();
                        },
                      ),
                      _buildKpiCard(
                        context,
                        title: 'En stock',
                        value: '${_controller.inStockCount}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen(initialFilter: 'in_stock')),
                          );
                          _controller.refresh();
                        },
                      ),
                      _buildKpiCard(
                        context,
                        title: 'Stock faible',
                        value: '${_controller.lowStockCount}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen(initialFilter: 'low_stock')),
                          );
                          _controller.refresh();
                        },
                      ),
                      _buildKpiCard(
                        context,
                        title: 'Expire bientôt',
                        value: '${_controller.expiringSoonCount}',
                        icon: Icons.alarm_rounded,
                        color: AppColors.error,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen(initialFilter: 'expiring_soon')),
                          );
                          _controller.refresh();
                        },
                      ),
                    ]),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(title: 'Actions rapides'),
                  ),
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
                      ShortcutTile(
                        icon: Icons.medication_rounded,
                        label: 'Catalogue national',
                        description: '2 708 médicaments référencés & prix officine',
                        color: AppColors.primary,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()),
                          );
                          _controller.refresh();
                        },
                      ),
                      ShortcutTile(
                        icon: Icons.inventory_2_rounded,
                        label: 'Gestion de stock',
                        description: 'Ajuster les quantités, seuils & péremptions',
                        color: AppColors.warning,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen(initialFilter: 'low_stock')),
                          );
                          _controller.refresh();
                        },
                      ),
                      ShortcutTile(
                        icon: Icons.storefront_rounded,
                        label: 'Fiche officine',
                        description: 'Horaires, coordonnées GPS & garde de nuit',
                        color: color,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PharmacyProfileScreen()),
                          );
                          _controller.refresh();
                        },
                      ),
                      ShortcutTile(
                        icon: Icons.share_location_rounded,
                        label: 'Recherche proximité',
                        description: 'Tester la localisation et vue patient',
                        color: AppColors.info,
                        onTap: () {
                          context.push(PharmacyRoutes.finder);
                        },
                      ),
                    ]),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPharmacySummary(BuildContext context) {
    final theme = Theme.of(context);
    final pharmacy = _controller.pharmacy;
    final isOpen = pharmacy?.isOpenToday ?? true;

    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyProfileScreen()),
          );
          _controller.refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pharmacy?.isNightPharmacy == true ? 'Pharmacie de garde' : 'Pharmacie de jour',
                            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen ? AppColors.success : AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOpen ? 'Ouvert' : 'Fermé',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy?.address ?? 'Tunis, Tunisie',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return MediCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
