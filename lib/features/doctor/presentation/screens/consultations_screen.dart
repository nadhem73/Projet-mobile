import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/consultation.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/controllers/consultations_controller.dart';

/// Espace médecin : rendez-vous à démarrer, consultations en cours et terminées.
class DoctorConsultationsScreen extends StatefulWidget {
  const DoctorConsultationsScreen({super.key});

  @override
  State<DoctorConsultationsScreen> createState() => _DoctorConsultationsScreenState();
}

class _DoctorConsultationsScreenState extends State<DoctorConsultationsScreen> {
  final _controller = getIt<ConsultationsController>()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(int consultationId) async {
    await context.push(DoctorRoutes.consultation(consultationId));
    await _controller.load();
  }

  Future<void> _start(AppointmentToStart appointment) async {
    final id = await _controller.start(appointment);
    if (!mounted) return;
    if (id == null) {
      context.showError(_controller.error ?? 'Impossible de démarrer la consultation');
      return;
    }
    await _open(id);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Consultations'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(tabs: [Tab(text: 'À démarrer'), Tab(text: 'En cours'), Tab(text: 'Terminées')]),
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.toStart.isEmpty && _controller.inProgress.isEmpty) {
              return const LoadingView();
            }
            if (_controller.error != null && !_controller.isStarting && _controller.closed.isEmpty) {
              return EmptyState.error(_controller.error!, onRetry: _controller.load);
            }
            return TabBarView(
              children: [
                _list(
                  _controller.toStart,
                  empty: const EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'Aucun rendez-vous en attente',
                    message: 'Les rendez-vous confirmés de vos patients apparaîtront ici.',
                  ),
                  builder:
                      (a) => _AppointmentCard(appointment: a, onStart: _controller.isStarting ? null : () => _start(a)),
                ),
                _list(
                  _controller.inProgress,
                  empty: const EmptyState(icon: Icons.medical_services_outlined, title: 'Aucune consultation en cours'),
                  builder: (c) => _ConsultationCard(consultation: c, onTap: () => _open(c.id)),
                ),
                _list(
                  _controller.closed,
                  empty: const EmptyState(icon: Icons.history_rounded, title: 'Aucune consultation terminée'),
                  builder: (c) => _ConsultationCard(consultation: c, onTap: () => _open(c.id)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list<T>(List<T> items, {required Widget empty, required Widget Function(T) builder}) {
    return RefreshIndicator(
      onRefresh: _controller.load,
      child:
          items.isEmpty
              ? ListView(children: [SizedBox(height: 360, child: empty)])
              : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => builder(items[i]),
              ),
    );
  }
}

String _initials(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
  return parts.take(2).map((p) => p[0]).join().toUpperCase();
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onStart});

  final AppointmentToStart appointment;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat("EEE d MMM 'à' HH:mm", 'fr').format(appointment.dateTime);
    final confirmed = appointment.status == AppointmentStatus.confirmed;
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediAvatar(initials: _initials(appointment.patientName), size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.patientName, style: theme.textTheme.titleMedium),
                    Text(date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                label: confirmed ? 'Confirmé' : 'En attente',
                color: confirmed ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          if ((appointment.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Motif : ${appointment.reason}', style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          MediButton(label: 'Démarrer la consultation', icon: Icons.play_arrow_rounded, onPressed: onStart),
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.consultation, required this.onTap});

  final Consultation consultation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = consultation;
    final start = c.startTime;
    return MediCard(
      onTap: onTap,
      child: Row(
        children: [
          MediAvatar(initials: _initials(c.patientName), size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.patientName, style: theme.textTheme.titleMedium),
                Text(
                  [
                    if (start != null) DateFormat("d MMM yyyy 'à' HH:mm", 'fr').format(start),
                    if ((c.diagnostic ?? c.motif ?? '').isNotEmpty) (c.diagnostic ?? c.motif)!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
