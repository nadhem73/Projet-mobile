import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/controllers/patient_consultations_controller.dart';

/// Côté patient : historique de ses consultations terminées, les plus récentes d'abord.
class PatientConsultationsScreen extends StatefulWidget {
  const PatientConsultationsScreen({super.key});

  @override
  State<PatientConsultationsScreen> createState() => _PatientConsultationsScreenState();
}

class _PatientConsultationsScreenState extends State<PatientConsultationsScreen> {
  final _controller = getIt<PatientConsultationsController>()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes consultations')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.consultations.isEmpty) return const LoadingView();
          if (_controller.error != null) return EmptyState.error(_controller.error!, onRetry: _controller.load);
          final list = _controller.consultations;
          return RefreshIndicator(
            onRefresh: _controller.load,
            child:
                list.isEmpty
                    ? ListView(
                      children: const [
                        SizedBox(
                          height: 420,
                          child: EmptyState(
                            icon: Icons.history_rounded,
                            title: 'Aucune consultation',
                            message: 'Vos consultations apparaîtront ici une fois clôturées par le médecin.',
                          ),
                        ),
                      ],
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder:
                          (context, i) => _ConsultationTile(
                            consultation: list[i],
                            onTap: () => context.push(DoctorRoutes.patientConsultation(list[i].id)),
                          ),
                    ),
          );
        },
      ),
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  const _ConsultationTile({required this.consultation, required this.onTap});

  final Consultation consultation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = consultation;
    final summary = c.diagnostic ?? c.motif;
    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: AppRadius.card),
            child: const Icon(Icons.medical_services_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.doctorName, style: theme.textTheme.titleSmall),
                if (c.doctorSpecialty != null) Text(c.doctorSpecialty!, style: theme.textTheme.bodySmall),
                if ((summary ?? '').isNotEmpty)
                  Text(summary!, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (c.startTime != null)
                  Text(DateFormat('d MMM yyyy', 'fr').format(c.startTime!), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
