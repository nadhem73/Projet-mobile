import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/lab_request.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/doctor/data/repositories/lab_request_repository.dart';
import 'package:medilink/features/doctor/data/repositories/prescription_repository.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/widgets/lab_request_tile.dart';
import 'package:medilink/features/doctor/presentation/widgets/prescription_tile.dart';

/// Ordonnances et demandes de bilan issues des consultations clôturées d'un
/// patient. Affiché dans l'onglet « Documents » du dossier médical, côté
/// patient comme côté médecin.
class ConsultationDocumentsSection extends StatefulWidget {
  const ConsultationDocumentsSection({super.key, required this.patientId, this.showPrescriptionHint = false});

  final int patientId;

  /// Côté patient : rappelle qu'une ordonnance peut être envoyée à une pharmacie.
  final bool showPrescriptionHint;

  @override
  State<ConsultationDocumentsSection> createState() => _ConsultationDocumentsSectionState();
}

class _ConsultationDocumentsSectionState extends State<ConsultationDocumentsSection> {
  late Future<(List<Prescription>, List<LabRequest>)> _data = _load();

  Future<(List<Prescription>, List<LabRequest>)> _load() async => (
    await getIt<PrescriptionRepository>().forPatient(widget.patientId),
    await getIt<LabRequestRepository>().forPatient(widget.patientId),
  );

  @override
  void didUpdateWidget(ConsultationDocumentsSection old) {
    super.didUpdateWidget(old);
    if (old.patientId != widget.patientId) _data = _load();
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) {
      setState(() {
        _data = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Ordonnances et bilans indisponibles.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          );
        }
        final (prescriptions, labRequests) = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Ordonnances (${prescriptions.length})'),
            if (widget.showPrescriptionHint && prescriptions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Ouvrez une ordonnance pour l\'envoyer à la pharmacie de votre choix.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (prescriptions.isEmpty)
              Text('Aucune ordonnance pour le moment.', style: theme.textTheme.bodyMedium)
            else
              for (final p in prescriptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PrescriptionTile(
                    prescription: p,
                    showPatient: false,
                    showDoctor: true,
                    onTap: () => _open(DoctorRoutes.prescription(p.id)),
                  ),
                ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: 'Bilans demandés (${labRequests.length})'),
            const SizedBox(height: AppSpacing.sm),
            if (labRequests.isEmpty)
              Text('Aucune demande de bilan pour le moment.', style: theme.textTheme.bodyMedium)
            else
              for (final r in labRequests)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LabRequestTile(
                    request: r,
                    showDoctor: true,
                    onTap: () => _open(DoctorRoutes.labRequest(r.id)),
                  ),
                ),
          ],
        );
      },
    );
  }
}
