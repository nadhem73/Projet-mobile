import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/lab_request.dart';
import 'package:medilink/features/doctor/data/repositories/lab_request_repository.dart';

/// Détail d'une demande de bilan, à présenter au laboratoire.
class LabRequestDetailScreen extends StatefulWidget {
  const LabRequestDetailScreen({super.key, required this.labRequestId});

  final int labRequestId;

  @override
  State<LabRequestDetailScreen> createState() => _LabRequestDetailScreenState();
}

class _LabRequestDetailScreenState extends State<LabRequestDetailScreen> {
  late final Future<LabRequest> _request = getIt<LabRequestRepository>().viewableBy(
    widget.labRequestId,
    getIt<SessionService>().requireUser,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demande de bilan')),
      body: FutureBuilder(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          final r = snapshot.data;
          if (r == null) return EmptyState.error('Demande de bilan introuvable.');
          return _content(context, r);
        },
      ),
    );
  }

  Widget _content(BuildContext context, LabRequest r) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MediCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.doctorName, style: theme.textTheme.titleMedium),
              if (r.doctorSpecialty != null) Text(r.doctorSpecialty!, style: theme.textTheme.bodySmall),
              const Divider(height: AppSpacing.xl),
              InfoRow(icon: Icons.person_outline_rounded, label: 'Patient', value: r.patientName),
              if (r.createdAt != null)
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: DateFormat('d MMMM yyyy', 'fr').format(r.createdAt!),
                ),
              InfoRow(icon: Icons.tag_rounded, label: 'N° de demande', value: '${r.id}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Analyses à réaliser (${r.tests.length})'),
        const SizedBox(height: AppSpacing.sm),
        MediCard(
          child: Column(
            children: [
              for (final t in r.tests)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(Icons.biotech_outlined, size: 20, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(t, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if ((r.note ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Note du médecin'),
          const SizedBox(height: AppSpacing.sm),
          MediCard(child: Text(r.note!)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'À présenter au laboratoire d\'analyses. Une fois les résultats reçus, '
          'scannez-les depuis « Mes bilans » pour les partager avec votre médecin.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
