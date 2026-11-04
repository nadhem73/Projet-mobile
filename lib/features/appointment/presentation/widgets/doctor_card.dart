import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';

/// Formate un tarif : 60 → « 60 DT », 45.5 → « 45,5 DT ».
String formatFee(double fee) =>
    '${fee == fee.roundToDouble() ? fee.toStringAsFixed(0) : fee.toStringAsFixed(1).replaceAll('.', ',')} DT';

/// Carte d'un médecin dans les résultats de recherche.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, required this.onTap});

  final DoctorSummary doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = doctor;
    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          MediAvatar(initials: d.initials, size: 56, color: AppColors.moduleAppointment),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.fullName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(d.specialty, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.moduleAppointment)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (d.city != null) _Info(icon: Icons.place_outlined, text: d.city!),
                    if (d.fee != null) _Info(icon: Icons.payments_outlined, text: formatFee(d.fee!)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 2),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
