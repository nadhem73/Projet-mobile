import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';

/// Conseils de prise de vue pour un OCR fiable.
class ShootingTips extends StatelessWidget {
  const ShootingTips({super.key});

  static const _tips = [
    (Icons.wb_sunny_rounded, 'Bonne lumière, sans ombre ni reflet du flash'),
    (Icons.crop_free_rounded, 'Document bien à plat, photographié de face'),
    (Icons.table_rows_rounded, 'Cadrez tout le tableau des résultats, sans le couper'),
    (Icons.blur_off_rounded, 'Image nette : attendez la mise au point avant de déclencher'),
    (Icons.description_rounded, 'Une seule page par photo'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      color: AppColors.infoSurface,
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text('Conseils de prise de vue', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (icon, text) in _tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
