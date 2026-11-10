import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/pharmacy/data/models/prescription_dispatch.dart';
import 'package:medilink/features/pharmacy/data/repositories/prescription_dispatch_repository.dart';

/// Côté pharmacien : ordonnances envoyées par les patients à cette pharmacie,
/// à préparer puis à délivrer.
class ReceivedPrescriptionsScreen extends StatefulWidget {
  const ReceivedPrescriptionsScreen({super.key, required this.pharmacyId});

  final int pharmacyId;

  @override
  State<ReceivedPrescriptionsScreen> createState() => _ReceivedPrescriptionsScreenState();
}

class _ReceivedPrescriptionsScreenState extends State<ReceivedPrescriptionsScreen> {
  final _repository = getIt<PrescriptionDispatchRepository>();
  late Future<List<PrescriptionDispatch>> _dispatches = _repository.forPharmacy(widget.pharmacyId);
  int? _busyId;

  Future<void> _reload() async {
    final next = _repository.forPharmacy(widget.pharmacyId);
    setState(() {
      _dispatches = next;
    });
    await next;
  }

  Future<void> _advance(PrescriptionDispatch d) async {
    setState(() => _busyId = d.id);
    try {
      final updated = await _repository.advance(d.id, pharmacyId: widget.pharmacyId);
      if (!mounted) return;
      context.showSuccess('Ordonnance de ${d.patientName} : ${updated.status.label.toLowerCase()}');
      await _reload();
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordonnances reçues')),
      body: FutureBuilder(
        future: _dispatches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) return const LoadingView();
          if (snapshot.hasError) return EmptyState.error('Ordonnances indisponibles.', onRetry: _reload);
          final list = snapshot.data ?? const [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
                  SizedBox(height: AppSpacing.md),
                  Center(child: Text('Aucune ordonnance reçue pour le moment.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder:
                  (context, i) => _DispatchCard(
                    dispatch: list[i],
                    busy: _busyId == list[i].id,
                    onOpen: () => context.push(DoctorRoutes.prescription(list[i].prescriptionId)),
                    onAdvance: () => _advance(list[i]),
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  const _DispatchCard({required this.dispatch, required this.busy, required this.onOpen, required this.onAdvance});

  final PrescriptionDispatch dispatch;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dispatch;
    final s = d.status;
    final next = s.next;
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(d.patientName, style: theme.textTheme.titleMedium)),
              StatusBadge(label: s.label, color: s.color, icon: s.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${d.doctorName} · ${d.itemCount} médicament${d.itemCount > 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          if (d.sentAt != null)
            Text(
              'Reçue le ${DateFormat("d MMM yyyy 'à' HH:mm", 'fr').format(d.sentAt!)}',
              style: theme.textTheme.labelSmall,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Voir l\'ordonnance'),
            ),
          ),
          // Action principale en pleine largeur (tient sur les petits écrans).
          if (next != null)
            FilledButton.icon(
              onPressed: busy ? null : onAdvance,
              icon:
                  busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(next.icon),
              label: Text(next == DispatchStatus.ready ? 'Marquer prête' : 'Marquer délivrée'),
            ),
        ],
      ),
    );
  }
}
