import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/presentation/widgets/result_status_style.dart';

/// Jauge horizontale : zone de référence en vert au centre, curseur à la
/// position de la valeur (couleur du statut).
class RangeGauge extends StatelessWidget {
  const RangeGauge({super.key, required this.value, this.min, this.max, required this.status});

  final double value;
  final double? min;
  final double? max;
  final ResultStatus status;

  /// Domaine affiché [start, end] et zone normale [low, high], en fraction 0..1.
  ({double low, double high, double position}) _layout() {
    final lo = min, hi = max;
    double start, end, low, high;
    if (lo != null && hi != null && hi > lo) {
      final margin = (hi - lo) * 0.5;
      start = lo - margin;
      end = hi + margin;
      low = lo;
      high = hi;
    } else if (hi != null) {
      start = 0;
      end = hi * 2;
      low = 0;
      high = hi;
    } else {
      start = 0;
      end = (lo ?? value) * 2;
      low = lo ?? 0;
      high = end;
    }
    final span = (end - start) == 0 ? 1 : end - start;
    double frac(double v) => ((v - start) / span).clamp(0.0, 1.0);
    return (low: frac(low), high: frac(high), position: frac(value));
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout();
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Position de la valeur dans la plage de référence',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return SizedBox(
            height: 16,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 6, decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(3))),
                Positioned(
                  left: w * layout.low,
                  width: (w * (layout.high - layout.low)).clamp(2.0, w),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: (w * layout.position - 7).clamp(0.0, w - 14),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
