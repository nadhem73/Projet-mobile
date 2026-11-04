import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';

/// Couleurs des statuts : NORMAL vert, ANORMAL orange, CRITIQUE rouge, NON_APPLICABLE gris.
extension ResultStatusStyle on ResultStatus {
  Color get color => switch (this) {
    ResultStatus.normal => AppColors.success,
    ResultStatus.anormal => AppColors.warning,
    ResultStatus.critique => AppColors.error,
    ResultStatus.nonApplicable => AppColors.textMuted,
  };

  IconData get icon => switch (this) {
    ResultStatus.normal => Icons.check_circle_rounded,
    ResultStatus.anormal => Icons.error_outline_rounded,
    ResultStatus.critique => Icons.warning_amber_rounded,
    ResultStatus.nonApplicable => Icons.remove_circle_outline_rounded,
  };
}

extension ReviewStatusStyle on ReviewStatus {
  Color get color => switch (this) {
    ReviewStatus.enAttente => AppColors.info,
    ReviewStatus.lu => AppColors.primaryLight,
    ReviewStatus.traite => AppColors.success,
  };

  IconData get icon => switch (this) {
    ReviewStatus.enAttente => Icons.schedule_send_rounded,
    ReviewStatus.lu => Icons.mark_email_read_rounded,
    ReviewStatus.traite => Icons.task_alt_rounded,
  };
}
