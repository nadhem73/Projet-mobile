import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/data/models/bilan_result.dart';
import 'package:medilink/features/ai/data/models/evolution_point.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_evolution_controller.dart';

/// Évolution d'un test sur les bilans confirmés, avec la plage de référence en fond.
class BilanEvolutionScreen extends StatefulWidget {
  const BilanEvolutionScreen({super.key, this.initialTest});

  final String? initialTest;

  @override
  State<BilanEvolutionScreen> createState() => _BilanEvolutionScreenState();
}

class _BilanEvolutionScreenState extends State<BilanEvolutionScreen> {
  late final _controller = getIt<BilanEvolutionController>()..load(initialTest: widget.initialTest);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Évolution de mes résultats')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (c.isLoading) return const LoadingView();
          if (c.error != null) return EmptyState.error(c.error!, onRetry: c.load);
          if (c.tests.isEmpty) {
            return const EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Pas encore de courbe',
              message: 'Validez au moins un bilan pour suivre l\'évolution de vos valeurs.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              DropdownButtonFormField<String>(
                initialValue: c.selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Analyse', prefixIcon: Icon(Icons.biotech_rounded)),
                items: [for (final t in c.tests) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (t) => t == null ? null : c.select(t),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (c.points.isEmpty)
                const EmptyState(icon: Icons.info_outline_rounded, title: 'Aucune valeur numérique pour ce test')
              else ...[
                MediCard(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                  child: SizedBox(height: 260, child: _Chart(points: c.points)),
                ),
                const SizedBox(height: AppSpacing.md),
                _Legend(points: c.points),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: 'Mesures (${c.points.length})'),
                for (final p in c.points.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.event_rounded),
                    title: Text(DateFormat('d MMMM yyyy', 'fr').format(p.date)),
                    trailing: Text(
                      '${formatNumber(p.value)} ${p.unit}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _pointColor(p)),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Color _pointColor(EvolutionPoint p) {
  if ((p.max != null && p.value > p.max!) || (p.min != null && p.value < p.min!)) return AppColors.warning;
  return AppColors.success;
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points});

  final List<EvolutionPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = points.last;
    final values = <double>[
      for (final p in points) p.value,
      if (last.min != null) last.min!,
      if (last.max != null) last.max!,
    ];
    final top = values.reduce(math.max);
    final bottom = values.reduce(math.min);
    final pad = ((top - bottom).abs() * 0.2).clamp(0.1, double.infinity);
    final minY = math.max(0.0, bottom - pad);
    final maxY = top + pad;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (last.min != null || last.max != null)
              HorizontalRangeAnnotation(
                y1: last.min ?? minY,
                y2: last.max ?? maxY,
                color: AppColors.success.withValues(alpha: 0.12),
              ),
          ],
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: theme.dividerColor.withValues(alpha: 0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget:
                  (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      formatNumber(double.parse(value.toStringAsFixed(2))),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (value != i || i < 0 || i >= points.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(DateFormat('dd/MM/yy').format(points[i].date), style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems:
                (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${formatNumber(points[s.x.round()].value)} ${points[s.x.round()].unit}\n'
                      '${DateFormat('d MMM yyyy', 'fr').format(points[s.x.round()].date)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value)],
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter:
                  (spot, _, _, _) => FlDotCirclePainter(
                    radius: 5,
                    color: _pointColor(points[spot.x.round()]),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.06)),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.points});

  final List<EvolutionPoint> points;

  @override
  Widget build(BuildContext context) {
    final last = points.last;
    final ref = switch ((last.min, last.max)) {
      (final double min, final double max) => '${formatNumber(min)} – ${formatNumber(max)}',
      (null, final double max) => '< ${formatNumber(max)}',
      (final double min, null) => '> ${formatNumber(min)}',
      _ => null,
    };
    if (ref == null) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Zone de référence : $ref ${last.unit}', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
