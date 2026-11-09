import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';

/// Durée d'une consultation : 30 minutes au maximum (un créneau de rendez-vous).
abstract final class ConsultationDuration {
  static const max = Duration(minutes: 30);

  /// Avertissement « plus que 5 minutes ».
  static const warning = Duration(minutes: 25);

  static ConsultationTimePhase phaseOf(Duration elapsed) {
    if (elapsed >= max) return ConsultationTimePhase.over;
    if (elapsed >= warning) return ConsultationTimePhase.warning;
    return ConsultationTimePhase.normal;
  }

  /// 07:05 ; 1:02:03 au-delà d'une heure.
  static String format(Duration d) {
    final abs = d.isNegative ? Duration.zero : d;
    String two(int v) => v.toString().padLeft(2, '0');
    final h = abs.inHours;
    final m = abs.inMinutes.remainder(60);
    final s = abs.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

enum ConsultationTimePhase { normal, warning, over }

/// Bandeau « Durée de la consultation » : temps écoulé, barre vers 30 min,
/// orange à partir de 25 min, rouge (dépassement) après 30 min.
class ConsultationTimerBar extends StatelessWidget {
  const ConsultationTimerBar({super.key, required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = ConsultationDuration.phaseOf(elapsed);
    final color = switch (phase) {
      ConsultationTimePhase.normal => AppColors.primary,
      ConsultationTimePhase.warning => AppColors.warning,
      ConsultationTimePhase.over => AppColors.error,
    };
    final message = switch (phase) {
      ConsultationTimePhase.normal =>
        'Reste ${ConsultationDuration.format(ConsultationDuration.max - elapsed)} sur 30 min',
      ConsultationTimePhase.warning =>
        'Plus que ${ConsultationDuration.format(ConsultationDuration.max - elapsed)} : pensez à conclure',
      ConsultationTimePhase.over =>
        'Durée maximale dépassée de ${ConsultationDuration.format(elapsed - ConsultationDuration.max)}',
    };
    final progress = (elapsed.inSeconds / ConsultationDuration.max.inSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                phase == ConsultationTimePhase.over ? Icons.alarm_on_rounded : Icons.timer_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Durée de la consultation', style: theme.textTheme.titleSmall)),
              Text(
                ConsultationDuration.format(elapsed),
                key: const ValueKey('consultation-elapsed'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
