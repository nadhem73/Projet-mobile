import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/features/ai/ai_module.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/bilan_summary.dart';
import 'package:medilink/features/ai/presentation/controllers/patient_record_bilans_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/presentation/widgets/medical_file_widgets.dart';

/// Onglet « Documents » du dossier médical vu par le médecin :
/// synthèse, filtre, bilans de laboratoire scannés (module IA) et pièces jointes.
class PatientDocumentsTab extends StatefulWidget {
  const PatientDocumentsTab({super.key, required this.patientId, required this.documents});

  final int patientId;
  final List<MedicalDocument> documents;

  @override
  State<PatientDocumentsTab> createState() => _PatientDocumentsTabState();
}

enum _Filter { all, bilans, documents }

class _PatientDocumentsTabState extends State<PatientDocumentsTab> {
  late final _controller = getIt<PatientRecordBilansController>()..loadList(widget.patientId);
  _Filter _filter = _Filter.all;

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
        final bilans = c.bilans;
        final docs = widget.documents;
        final showBilans = _filter != _Filter.documents;
        final showDocs = _filter != _Filter.bilans;

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          children: [
            _FadeSlideIn(
              index: 0,
              child: _SummaryCard(
                bilans: bilans.length,
                abnormal: bilans.fold(0, (sum, b) => sum + b.abnormalCount),
                documents: docs.length,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FadeSlideIn(
              index: 1,
              child: _FilterBar(
                value: _filter,
                bilans: bilans.length,
                documents: docs.length,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder:
                  (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
              child: Column(
                key: ValueKey(_filter),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBilans) ...[
                    _SectionTitle(
                      icon: Icons.biotech_outlined,
                      title: 'Bilans de laboratoire',
                      count: bilans.length,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (c.isLoading && bilans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (c.error != null)
                      _EmptyCard(icon: Icons.lock_outline_rounded, message: c.error!, color: AppColors.error)
                    else if (bilans.isEmpty)
                      const _EmptyCard(
                        icon: Icons.science_outlined,
                        message: 'Aucun bilan scanné et validé par le patient.',
                      )
                    else
                      for (final (i, b) in bilans.indexed)
                        _FadeSlideIn(
                          index: i + 2,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _BilanCard(
                              bilan: b,
                              sentToMe: b.doctorId != null && b.doctorId == c.doctorId,
                              onTap: () => context.push(AiRoutes.patientRecordBilan(widget.patientId, b.id)),
                            ),
                          ),
                        ),
                  ],
                  if (showBilans && showDocs) const SizedBox(height: AppSpacing.lg),
                  if (showDocs) ...[
                    _SectionTitle(
                      icon: Icons.photo_library_outlined,
                      title: 'Pièces jointes',
                      count: docs.length,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (docs.isEmpty)
                      const _EmptyCard(
                        icon: Icons.folder_open_rounded,
                        message: 'Le patient n\'a ajouté aucun document (radios, comptes rendus…).',
                      )
                    else
                      _DocumentGallery(documents: docs),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Synthèse
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.bilans, required this.abnormal, required this.documents});

  final int bilans;
  final int abnormal;
  final int documents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(right: -30, top: -40, child: _Bubble(size: 140, opacity: 0.10)),
          Positioned(right: 50, bottom: -50, child: _Bubble(size: 100, opacity: 0.07)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documents médicaux',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Analyses et pièces partagées par le patient',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: _Stat(value: bilans, label: 'Bilans', icon: Icons.biotech_outlined)),
                    const _StatDivider(),
                    Expanded(
                      child: _Stat(
                        value: abnormal,
                        label: 'Hors norme',
                        icon: Icons.warning_amber_rounded,
                        highlight: abnormal > 0,
                      ),
                    ),
                    const _StatDivider(),
                    Expanded(child: _Stat(value: documents, label: 'Documents', icon: Icons.description_outlined)),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon, this.highlight = false});

  final int value;
  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Compteur animé de 0 à la valeur.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder:
              (_, v, _) => Text(
                '${v.round()}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: highlight ? AppColors.accentSurface : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: highlight ? AppColors.accentSurface : Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: highlight ? AppColors.accentSurface : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.22));
}

// ---------------------------------------------------------------------------
// Filtre
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.bilans, required this.documents, required this.onChanged});

  final _Filter value;
  final int bilans;
  final int documents;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          _FilterPill(
            key: const ValueKey('documents-filter-all'),
            label: 'Tout',
            selected: value == _Filter.all,
            onTap: () => onChanged(_Filter.all),
          ),
          _FilterPill(
            key: const ValueKey('documents-filter-bilans'),
            label: 'Bilans',
            count: bilans,
            selected: value == _Filter.bilans,
            onTap: () => onChanged(_Filter.bilans),
          ),
          _FilterPill(
            key: const ValueKey('documents-filter-documents'),
            label: 'Documents',
            count: documents,
            selected: value == _Filter.documents,
            onTap: () => onChanged(_Filter.documents),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.count});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

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
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.border,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bilans
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, required this.count, required this.color});

  final IconData icon;
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        if (count > 0) Text('$count', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

/// Carte d'un bilan : bloc date, type, nombre de valeurs, barre normal / hors norme.
class _BilanCard extends StatelessWidget {
  const _BilanCard({required this.bilan, required this.sentToMe, required this.onTap});

  final BilanSummary bilan;
  final bool sentToMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = bilan;
    final date = b.date;
    final abnormal = b.abnormalCount;
    final total = b.resultCount;
    final accent = abnormal > 0 ? AppColors.error : AppColors.success;
    final review = b.reviewStatus;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDeep.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bloc date
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primarySurface, AppColors.primarySoft.withValues(alpha: 0.35)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      date == null ? '—' : '${date.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      date == null ? '' : DateFormat('MMM yy', 'fr').format(date).replaceAll('.', ''),
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.typeBilan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$total valeur${total > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: _Pill(
                            label: abnormal == 0 ? 'Tout est normal' : '$abnormal hors norme',
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HealthBar(total: total, abnormal: abnormal),
                    if (sentToMe && review != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(review.icon, size: 13, color: review.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Envoyé à vous · ${switch (review) {
                                ReviewStatus.enAttente => 'à lire',
                                ReviewStatus.lu => 'lu',
                                ReviewStatus.traite => 'traité',
                              }}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: review.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

/// Barre fine : part des valeurs normales (vert) et hors norme (rouge), animée.
class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.total, required this.abnormal});

  final int total;
  final int abnormal;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : (abnormal / total).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder:
          (_, t, _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (_, box) {
                  final width = box.maxWidth * t;
                  return Stack(
                    children: [
                      Container(color: AppColors.surfaceMuted),
                      Container(width: width, color: AppColors.success.withValues(alpha: 0.85)),
                      if (share > 0) Container(width: width * share, color: AppColors.error),
                    ],
                  );
                },
              ),
            ),
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pièces jointes
// ---------------------------------------------------------------------------

class _DocumentGallery extends StatelessWidget {
  const _DocumentGallery({required this.documents});

  final List<MedicalDocument> documents;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 190,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: documents.length,
      itemBuilder: (context, i) => _FadeSlideIn(index: i + 2, child: _DocumentTile(document: documents[i])),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final MedicalDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = document;
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DocumentViewerScreen(document: d))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'doctor-document-${d.id ?? d.hashCode}',
              child: Image.memory(
                d.data,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: Icon(d.category.icon, size: 42, color: AppColors.textMuted)),
              ),
            ),
            // Dégradé pour la lisibilité du titre.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.primaryDeep.withValues(alpha: 0.8)],
                  stops: const [0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(d.category.icon, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      d.category.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  if (d.createdAt != null)
                    Text(
                      DateFormat('d MMM yyyy', 'fr').format(d.createdAt!),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divers
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message, this.color = AppColors.primary});

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
      duration: Duration(milliseconds: 380 + 70 * index.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder:
          (_, v, child) =>
              Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
      child: child,
    );
  }
}
