import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';

/// Affichage en lecture seule d'un dossier médical.
///
/// Réutilisable par les autres modules, ex. dans l'espace médecin :
/// ```dart
/// final record = await getIt<MedicalRecordRepository>().forPatient(patientId);
/// MedicalRecordView(record: record)
/// ```
class MedicalRecordView extends StatelessWidget {
  const MedicalRecordView({super.key, required this.record, this.age});

  final MedicalRecord record;

  /// Âge du patient, affiché à côté du sexe si connu.
  final int? age;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = [record.genderLabel, if (age != null) '$age ans'].whereType<String>().join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (identity.isNotEmpty) ...[
          Text(identity, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.bloodtype_rounded,
                label: 'Groupe',
                value: record.bloodGroup,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                icon: Icons.height_rounded,
                label: 'Taille',
                value: _format(record.height, 'cm'),
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                icon: Icons.monitor_weight_rounded,
                label: 'Poids',
                value: _format(record.weight, 'kg'),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                icon: Icons.speed_rounded,
                label: 'IMC',
                value: record.bmi?.toStringAsFixed(1),
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        if (record.bmiLabel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'IMC : ${record.bmiLabel}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: Icons.warning_amber_rounded,
          title: 'Allergies',
          color: AppColors.error,
          child: _ChipList(items: record.allergyList, empty: 'Aucune allergie connue', color: AppColors.error),
        ),
        _Section(
          icon: Icons.monitor_heart_rounded,
          title: 'Maladies chroniques',
          color: AppColors.warning,
          child: _ChipList(
            items: record.chronicDiseaseList,
            empty: 'Aucune maladie chronique',
            color: AppColors.warning,
          ),
        ),
        _Section(
          icon: Icons.medication_rounded,
          title: 'Traitement en cours',
          color: AppColors.primary,
          child: _Text(record.currentTreatment, empty: 'Aucun traitement en cours'),
        ),
        _Section(
          icon: Icons.healing_rounded,
          title: 'Antécédents chirurgicaux',
          color: AppColors.moduleInsurance,
          child: _Text(record.surgicalHistory, empty: 'Aucun antécédent chirurgical'),
        ),
        _Section(
          icon: Icons.family_restroom_rounded,
          title: 'Antécédents familiaux',
          color: AppColors.moduleAppointment,
          child: _Text(record.familyHistory, empty: 'Aucun antécédent familial connu'),
        ),
        _Section(
          icon: Icons.contact_phone_rounded,
          title: 'Contact d\'urgence',
          color: AppColors.info,
          child: _Text(
            [record.emergencyContactName, record.emergencyContactPhone].whereType<String>().join(' — '),
            empty: 'Aucun contact renseigné',
          ),
        ),
        _Section(
          icon: Icons.health_and_safety_rounded,
          title: 'Assurance maladie',
          color: AppColors.moduleInsurance,
          child: _Text(
            [
              record.insuranceCompany,
              if (record.insuranceNumber != null) 'N° ${record.insuranceNumber}',
            ].whereType<String>().join(' — '),
            empty: 'Aucune assurance renseignée',
          ),
        ),
        if (record.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Mis à jour le ${DateFormat('d MMMM yyyy à HH:mm', 'fr').format(record.updatedAt!)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  static String? _format(double? value, String unit) {
    if (value == null) return null;
    final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$text $unit';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: AppRadius.card),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value ?? '—', style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.color, required this.child});

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MediCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  const _ChipList({required this.items, required this.empty, required this.color});

  final List<String> items;
  final String empty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Text(null, empty: empty);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [for (final item in items) StatusBadge(label: item, color: color)],
    );
  }
}

class _Text extends StatelessWidget {
  const _Text(this.value, {required this.empty});

  final String? value;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = value == null || value!.trim().isEmpty;
    return Text(
      isEmpty ? empty : value!,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isEmpty ? theme.colorScheme.onSurfaceVariant : null,
        fontStyle: isEmpty ? FontStyle.italic : null,
      ),
    );
  }
}
