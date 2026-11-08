import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/presentation/controllers/patient_record_bilans_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/range_gauge.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';

/// Un bilan du patient, ouvert par le médecin depuis son dossier médical (lecture seule) :
/// en-tête en dégradé avec la synthèse, points d'attention, puis tous les résultats
/// filtrables (tous / hors norme / normaux) avec jauge de la plage de référence.
class PatientRecordBilanScreen extends StatefulWidget {
  const PatientRecordBilanScreen({super.key, required this.patientId, required this.bilanId});

  final int patientId;
  final String bilanId;

  @override
  State<PatientRecordBilanScreen> createState() => _PatientRecordBilanScreenState();
}

enum _ResultFilter { all, abnormal, normal }

class _PatientRecordBilanScreenState extends State<PatientRecordBilanScreen> {
  late final _controller = getIt<PatientRecordBilansController>()..loadOne(widget.patientId, widget.bilanId);
  _ResultFilter _filter = _ResultFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final bilan = c.bilan;
        if (bilan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bilan')),
            body:
                c.isLoading
                    ? const LoadingView()
                    : EmptyState.error(
                      c.error ?? 'Bilan introuvable',
                      onRetry: () => c.loadOne(widget.patientId, widget.bilanId),
                    ),
          );
        }
        return Scaffold(backgroundColor: AppColors.background, body: _content(bilan));
      },
    );
  }

  Widget _content(ScanBilan bilan) {
    final theme = Theme.of(context);
    final results = bilan.resultats;
    final abnormal = results.where((r) => r.status.isOutOfRange).toList();
    final normal = results.where((r) => !r.status.isOutOfRange).toList();
    final shown = switch (_filter) {
      _ResultFilter.all => results,
      _ResultFilter.abnormal => abnormal,
      _ResultFilter.normal => normal,
    };
    final showPrevious = bilan.format == BilanFormat.ancienPatient;

    return CustomScrollView(
      slivers: [
        _HeroAppBar(bilan: bilan, abnormal: abnormal.length),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          sliver: SliverList.list(
            children: [
              if (abnormal.isNotEmpty) ...[
                _FadeSlideIn(index: 0, child: _AttentionCard(results: abnormal)),
                const SizedBox(height: AppSpacing.xl),
              ],
              _FadeSlideIn(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Résultats détaillés',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${shown.length}/${results.length}',
                      style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FadeSlideIn(
                index: 2,
                child: _FilterBar(
                  value: _filter,
                  all: results.length,
                  abnormal: abnormal.length,
                  normal: normal.length,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Column(
                  key: ValueKey(_filter),
                  children: [
                    if (shown.isEmpty)
                      _EmptyFilter(filter: _filter)
                    else
                      for (final (i, r) in shown.indexed)
                        _FadeSlideIn(
                          index: i + 3,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ResultCard(result: r, showPrevious: showPrevious),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête
// ---------------------------------------------------------------------------

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.bilan, required this.abnormal});

  final ScanBilan bilan;
  final int abnormal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = bilan.date;
    final critical = bilan.resultats.where((r) => r.status == ResultStatus.critique).length;
    final subtitle = [
      if (date != null) DateFormat('d MMMM y', 'fr').format(date),
      if (bilan.laboratoire.trim().isNotEmpty) bilan.laboratoire.trim(),
    ].join(' · ');

    return SliverAppBar(
      pinned: true,
      expandedHeight: 268,
      backgroundColor: AppColors.primaryDeep,
      foregroundColor: Colors.white,
      title: Text(bilan.typeBilan, style: const TextStyle(color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            children: [
              const Positioned(right: -40, top: -30, child: _Bubble(size: 180, opacity: 0.08)),
              const Positioned(left: -30, bottom: -60, child: _Bubble(size: 140, opacity: 0.06)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, kToolbarHeight, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.biotech_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bilan.typeBilan,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (bilan.patientName != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _GlassChip(icon: Icons.person_outline_rounded, label: bilan.patientName!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _GlassStat(
                              value: bilan.resultats.length,
                              label: 'Valeurs',
                              icon: Icons.format_list_bulleted_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _GlassStat(
                              value: abnormal,
                              label: 'Hors norme',
                              icon: Icons.error_outline_rounded,
                              alert: abnormal > 0,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _GlassStat(
                              value: critical,
                              label: 'Critiques',
                              icon: Icons.warning_amber_rounded,
                              alert: critical > 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.value, required this.label, required this.icon, this.alert = false});

  final int value;
  final String label;
  final IconData icon;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = alert ? AppColors.accentSurface : Colors.white;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: alert ? AppColors.accent.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder:
                (_, v, _) => Text(
                  '${v.round()}',
                  style: theme.textTheme.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
                ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: fg.withValues(alpha: 0.85)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Points d'attention
// ---------------------------------------------------------------------------

/// « Élevé » / « Bas » selon la position de la valeur par rapport à la plage.
({IconData icon, String label})? _direction(BilanResult r) {
  final v = r.numericValue;
  if (v == null) return null;
  if (r.referenceMax != null && v > r.referenceMax!) return (icon: Icons.arrow_upward_rounded, label: 'Élevé');
  if (r.referenceMin != null && v < r.referenceMin!) return (icon: Icons.arrow_downward_rounded, label: 'Bas');
  return null;
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.results});

  final List<BilanResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Valeurs critiques en premier.
    final sorted = [
      ...results.where((r) => r.status == ResultStatus.critique),
      ...results.where((r) => r.status != ResultStatus.critique),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high_rounded, color: AppColors.accentDark, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Points d\'attention',
                  style: theme.textTheme.titleSmall?.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  '${results.length}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final r in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 30,
                      decoration: BoxDecoration(color: r.status.color, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.testName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (r.referenceLabel != null)
                            Text(
                              'Réf. ${r.referenceLabel}${r.unite.isEmpty ? '' : ' ${r.unite}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (_direction(r) case final d?) Icon(d.icon, size: 16, color: r.status.color),
                    const SizedBox(width: 2),
                    Text(
                      r.valeur,
                      style: theme.textTheme.titleMedium?.copyWith(color: r.status.color, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtre
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.value,
    required this.all,
    required this.abnormal,
    required this.normal,
    required this.onChanged,
  });

  final _ResultFilter value;
  final int all;
  final int abnormal;
  final int normal;
  final ValueChanged<_ResultFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          _Pill(
            key: const ValueKey('results-filter-all'),
            label: 'Tous',
            count: all,
            selected: value == _ResultFilter.all,
            onTap: () => onChanged(_ResultFilter.all),
          ),
          _Pill(
            key: const ValueKey('results-filter-abnormal'),
            label: 'Hors norme',
            count: abnormal,
            color: AppColors.error,
            selected: value == _ResultFilter.abnormal,
            onTap: () => onChanged(_ResultFilter.abnormal),
          ),
          _Pill(
            key: const ValueKey('results-filter-normal'),
            label: 'Normaux',
            count: normal,
            color: AppColors.success,
            selected: value == _ResultFilter.normal,
            onTap: () => onChanged(_ResultFilter.normal),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.filter});

  final _ResultFilter filter;

  @override
  Widget build(BuildContext context) {
    final (icon, message, color) = switch (filter) {
      _ResultFilter.abnormal => (Icons.verified_rounded, 'Aucune valeur hors norme.', AppColors.success),
      _ResultFilter.normal => (Icons.info_outline_rounded, 'Aucune valeur dans les normes.', AppColors.textMuted),
      _ResultFilter.all => (Icons.science_outlined, 'Aucune valeur lue sur ce bilan.', AppColors.textMuted),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Résultat
// ---------------------------------------------------------------------------

/// Un résultat : nom, statut, valeur en grand, plage de référence avec jauge,
/// valeur antérieure et tendance (format « ancien patient »).
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.showPrevious});

  final BilanResult result;
  final bool showPrevious;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = result;
    final color = r.status.color;
    final value = r.numericValue;
    final reference = r.referenceLabel;
    final direction = _direction(r);
    final previous = r.valeurAncienne?.trim();
    final hasPrevious = showPrevious && previous != null && previous.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: r.status.isOutOfRange ? color.withValues(alpha: 0.35) : AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDeep.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // Bande de couleur du statut à gauche (pas d'IntrinsicHeight : la jauge utilise un LayoutBuilder).
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, width: 4, child: ColoredBox(color: color)),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.testName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatusBadge(
                          label: direction == null ? r.status.label : '${r.status.label} · ${direction.label}',
                          color: color,
                          icon: r.status.icon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        flex: 4,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: r.valeur,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (r.unite.isNotEmpty)
                                TextSpan(
                                  text: '  ${r.unite}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (reference != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          flex: 3,
                          child: Text(
                            'Réf. $reference',
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (value != null && r.hasRange) ...[
                    const SizedBox(height: AppSpacing.sm),
                    RangeGauge(value: value, min: r.referenceMin, max: r.referenceMax, status: r.status),
                  ],
                  if (hasPrevious) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _PreviousValue(result: r, previous: previous),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousValue extends StatelessWidget {
  const _PreviousValue({required this.result, required this.previous});

  final BilanResult result;
  final String previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = result.numericValue;
    final before = result.numericAncienne;
    final trend =
        now == null || before == null
            ? Icons.remove_rounded
            : now > before
            ? Icons.trending_up_rounded
            : now < before
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final date = result.dateAncienne?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: [
          Icon(trend, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Précédent : $previous${result.unite.isEmpty ? '' : ' ${result.unite}'}'
              '${date == null || date.isEmpty ? '' : ' ($date)'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apparition douce (fondu + léger glissement), décalée selon [index].
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + 60 * index.clamp(0, 10)),
      curve: Curves.easeOutCubic,
      builder:
          (_, v, child) =>
              Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: child,
    );
  }
}
