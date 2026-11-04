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
import 'package:medilink/features/ai/presentation/controllers/doctor_bilans_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';

/// Côté médecin : bilans envoyés par les patients.
class DoctorBilansScreen extends StatefulWidget {
  const DoctorBilansScreen({super.key});

  @override
  State<DoctorBilansScreen> createState() => _DoctorBilansScreenState();
}

class _DoctorBilansScreenState extends State<DoctorBilansScreen> {
  final _controller = getIt<DoctorBilansController>()..refresh();
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

  Future<void> _open(BilanSummary bilan) async {
    await context.push(AiRoutes.doctorBilan(bilan.id));
    if (mounted) await _controller.refresh(); // statut « Lu » / « Traité » mis à jour
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilans reçus')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    for (final (label, status) in const [
                      ('Tous', null),
                      ('En attente', ReviewStatus.enAttente),
                      ('Lus', ReviewStatus.lu),
                      ('Traités', ReviewStatus.traite),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: c.filter == status,
                          onSelected: (_) => c.setFilter(status),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _list(c)),
            ],
          );
        },
      ),
    );
  }

  Widget _list(DoctorBilansController c) {
    if (c.isLoading && c.items.isEmpty) return const LoadingView();
    if (c.error != null && c.items.isEmpty) return EmptyState.error(c.error!, onRetry: c.refresh);
    return RefreshIndicator(
      onRefresh: c.refresh,
      child:
          c.items.isEmpty
              ? ListView(
                children: const [
                  SizedBox(
                    height: 420,
                    child: EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'Aucun bilan',
                      message: 'Les bilans que vos patients vous envoient apparaîtront ici.',
                    ),
                  ),
                ],
              )
              : ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: c.items.length + (c.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  if (i >= c.items.length) return const Center(child: CircularProgressIndicator());
                  return _Tile(bilan: c.items[i], onTap: () => _open(c.items[i]));
                },
              ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.bilan, required this.onTap});

  final BilanSummary bilan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final review = bilan.reviewStatus;
    final date = bilan.date;
    final unread = review == ReviewStatus.enAttente;
    final name = bilan.patientName ?? 'Patient';
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();
    return MediCard(
      onTap: onTap,
      borderColor: unread ? AppColors.info.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MediAvatar(initials: initials, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w700 : null)),
                Text(
                  [
                    bilan.typeBilan,
                    if (date != null) DateFormat('d MMM yyyy', 'fr').format(date),
                    '${bilan.resultCount} valeur${bilan.resultCount > 1 ? 's' : ''}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                if (review != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(label: review.label, color: review.color, icon: review.icon),
                ],
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
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
