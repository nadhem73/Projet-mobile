import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Détail d'une ordonnance (patient, médecin, pharmacien, assureur), avec un
/// QR code à présenter en pharmacie.
class PrescriptionDetailScreen extends StatefulWidget {
  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  final int prescriptionId;

  /// Contenu du QR code lu par la pharmacie.
  static String qrData(int prescriptionId) => 'MEDILINK-RX:$prescriptionId';

  @override
  State<PrescriptionDetailScreen> createState() => _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  late final Future<Prescription> _prescription = getIt<PrescriptionRepository>().viewableBy(
    widget.prescriptionId,
    getIt<SessionService>().requireUser,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordonnance')),
      body: FutureBuilder(
        future: _prescription,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          final p = snapshot.data;
          if (p == null) return EmptyState.error('Ordonnance introuvable.');
          return _content(context, p);
        },
      ),
    );
  }

  Widget _content(BuildContext context, Prescription p) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MediCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.doctorName, style: theme.textTheme.titleMedium),
              if (p.doctorSpecialty != null) Text(p.doctorSpecialty!, style: theme.textTheme.bodySmall),
              const Divider(height: AppSpacing.xl),
              InfoRow(icon: Icons.person_outline_rounded, label: 'Patient', value: p.patientName),
              if (p.createdAt != null)
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: DateFormat('d MMMM yyyy', 'fr').format(p.createdAt!),
                ),
              InfoRow(icon: Icons.tag_rounded, label: 'N° d\'ordonnance', value: '${p.id}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Traitement (${p.items.length})'),
        const SizedBox(height: AppSpacing.sm),
        for (final item in p.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: MediCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medication_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [item.medicamentName, item.dosage].whereType<String>().join(' '),
                          style: theme.textTheme.titleSmall,
                        ),
                        if (item.forme != null || item.voieAdministration != null)
                          Text(
                            [item.forme, item.voieAdministration].whereType<String>().join(' · voie '),
                            style: theme.textTheme.bodySmall,
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(item.posologie ?? '', style: theme.textTheme.bodyMedium),
                        Text('Pendant ${item.dureeTraitement ?? '-'}', style: theme.textTheme.bodySmall),
                        if ((item.instruction ?? '').isNotEmpty)
                          Text(
                            item.instruction!,
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if ((p.note ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Note du médecin'),
          const SizedBox(height: AppSpacing.sm),
          MediCard(child: Text(p.note!)),
        ],
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Colors.white,
                child: QrImageView(data: PrescriptionDetailScreen.qrData(p.id), size: 180),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('À présenter en pharmacie', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
