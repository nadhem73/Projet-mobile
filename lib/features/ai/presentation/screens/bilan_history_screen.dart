import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/ai_module.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_history_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';

/// « Mes bilans » : historique paginé (scroll infini), pull-to-refresh,
/// suppression, renvoi au serveur des bilans analysés hors-ligne.
class BilanHistoryScreen extends StatefulWidget {
  const BilanHistoryScreen({super.key});

  @override
  State<BilanHistoryScreen> createState() => _BilanHistoryScreenState();
}

class _BilanHistoryScreenState extends State<BilanHistoryScreen> {
  final _controller = getIt<BilanHistoryController>()..start();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 200) _controller.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) await _controller.refresh(); // statut / valeurs modifiés entre-temps
  }

  Future<bool> _confirmDelete(BilanSummary bilan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer ce bilan ?'),
            content: Text('Le bilan « ${bilan.typeBilan} » et ses valeurs seront définitivement supprimés.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return false;
    final error = await _controller.delete(bilan.id);
    if (!mounted) return false;
    error == null ? context.showSuccess('Bilan supprimé') : context.showError(error);
    return error == null;
  }

  Future<void> _sync() async {
    final count = await _controller.syncPending();
    if (!mounted) return;
    count > 0
        ? context.showSuccess('$count bilan${count > 1 ? 's' : ''} analysé${count > 1 ? 's' : ''} par le serveur')
        : context.showError('Synchronisation impossible pour le moment.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes bilans'),
        actions: [
          IconButton(
            tooltip: 'Évolution',
            icon: const Icon(Icons.show_chart_rounded),
            onPressed: () => _open(AiRoutes.evolution),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(AiRoutes.labScan),
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scanner'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (c.isLoading && c.items.isEmpty) return const LoadingView();
          if (c.error != null && c.items.isEmpty) return EmptyState.error(c.error!, onRetry: c.refresh);
          return RefreshIndicator(
            onRefresh: c.refresh,
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
              itemCount: c.items.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) return _SyncBanner(controller: c, onSync: _sync);
                if (i == c.items.length + 1) {
                  if (c.items.isEmpty) {
                    return const SizedBox(
                      height: 420,
                      child: EmptyState(
                        icon: Icons.science_rounded,
                        title: 'Aucun bilan',
                        message: 'Scannez votre premier bilan de laboratoire pour suivre vos résultats.',
                      ),
                    );
                  }
                  return c.isLoadingMore
                      ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : const SizedBox.shrink();
                }
                final bilan = c.items[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Dismissible(
                    key: ValueKey(bilan.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(bilan),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: AppRadius.card),
                      child: const Icon(Icons.delete_rounded, color: AppColors.error),
                    ),
                    child: _BilanTile(
                      bilan: bilan,
                      onTap: () => _open(AiRoutes.bilan(bilan.id)),
                      onDelete: () => _confirmDelete(bilan),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.controller, required this.onSync});

  final BilanHistoryController controller;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final n = controller.pendingSync;
    if (n <= 0) return const SizedBox.shrink();
    final s = n > 1 ? 's' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MediCard(
        color: AppColors.infoSurface,
        borderColor: AppColors.info.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.info),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                controller.canSync
                    ? 'Réseau disponible : renvoyer $n bilan$s analysé$s hors-ligne au serveur pour une lecture plus précise ?'
                    : '$n bilan$s analysé$s sur le téléphone (non synchronisé$s).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (controller.canSync)
              controller.isSyncing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: onSync, child: const Text('Renvoyer')),
          ],
        ),
      ),
    );
  }
}

class _BilanTile extends StatelessWidget {
  const _BilanTile({required this.bilan, required this.onTap, required this.onDelete});

  final BilanSummary bilan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = bilan.date;
    final review = bilan.reviewStatus;
    final confirmed = bilan.status == BilanStatus.confirmed;
    return MediCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.accentSurface, borderRadius: AppRadius.card),
            child: const Icon(Icons.science_rounded, color: AppColors.accentDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(bilan.typeBilan, style: theme.textTheme.titleSmall)),
                    if (!bilan.synced) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Tooltip(
                        message: 'Non synchronisé',
                        child: Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                Text(
                  [
                    if (date != null) DateFormat('d MMM yyyy', 'fr').format(date),
                    '${bilan.resultCount} valeur${bilan.resultCount > 1 ? 's' : ''}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(label: bilan.status.label, color: confirmed ? AppColors.success : AppColors.warning),
                    if (review != null) StatusBadge(label: review.label, color: review.color, icon: review.icon),
                  ],
                ),
              ],
            ),
          ),
          if (bilan.abnormalCount > 0)
            Tooltip(
              message: '${bilan.abnormalCount} valeur(s) hors norme',
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.error,
                child: Text(
                  '${bilan.abnormalCount}',
                  style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          PopupMenuButton<void>(
            tooltip: 'Actions',
            itemBuilder: (_) => [PopupMenuItem(onTap: onDelete, child: const Text('Supprimer'))],
          ),
        ],
      ),
    );
  }
}
