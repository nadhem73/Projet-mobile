import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/data/models/prescription.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/models/prescription_dispatch.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/prescription_dispatch_repository.dart';

/// Côté patient : envoi de l'ordonnance à la pharmacie de son choix, puis
/// suivi de sa préparation (Envoyée → Prête à retirer → Délivrée).
class PrescriptionDispatchCard extends StatefulWidget {
  const PrescriptionDispatchCard({super.key, required this.prescription});

  final Prescription prescription;

  @override
  State<PrescriptionDispatchCard> createState() => _PrescriptionDispatchCardState();
}

class _PrescriptionDispatchCardState extends State<PrescriptionDispatchCard> {
  final _repository = getIt<PrescriptionDispatchRepository>();
  late Future<PrescriptionDispatch?> _dispatch = _repository.forPrescription(widget.prescription.id);
  bool _sending = false;

  Future<void> _choosePharmacy(PrescriptionDispatch? current) async {
    final pharmacy = await PharmacyPickerSheet.show(
      context,
      prescription: widget.prescription,
      currentPharmacyId: current?.pharmacyId,
    );
    if (pharmacy == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final sent = await _repository.send(
        prescriptionId: widget.prescription.id,
        pharmacyId: pharmacy.pharmacyId!,
        user: getIt<SessionService>().requireUser,
      );
      if (!mounted) return;
      setState(() {
        _dispatch = Future.value(sent);
      });
      context.showSuccess('Ordonnance envoyée à ${pharmacy.name}');
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: _dispatch,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
        final d = snapshot.data;
        if (d == null) {
          return MediButton(
            label: 'Envoyer à une pharmacie',
            icon: Icons.local_pharmacy_outlined,
            isLoading: _sending,
            onPressed: _sending ? null : () => _choosePharmacy(null),
          );
        }
        final s = d.status;
        return MediCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(s.icon, color: s.color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(s.label, style: theme.textTheme.titleSmall?.copyWith(color: s.color))),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(d.pharmacyName, style: theme.textTheme.titleMedium),
              if (d.pharmacyAddress != null) Text(d.pharmacyAddress!, style: theme.textTheme.bodySmall),
              if (d.pharmacyPhone != null) Text(d.pharmacyPhone!, style: theme.textTheme.bodySmall),
              if (d.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Mis à jour le ${DateFormat("d MMM yyyy 'à' HH:mm", 'fr').format(d.updatedAt!)}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(switch (s) {
                DispatchStatus.sent => 'La pharmacie prépare votre ordonnance.',
                DispatchStatus.ready => 'Vos médicaments sont prêts : présentez le QR code ci-dessous en pharmacie.',
                DispatchStatus.delivered => 'Ordonnance délivrée.',
              }, style: theme.textTheme.bodySmall),
              if (d.canChangePharmacy) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _sending ? null : () => _choosePharmacy(d),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Changer de pharmacie'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Choix d'une pharmacie : recherche par nom ou adresse, avec le nombre de
/// médicaments de l'ordonnance disponibles en stock dans chacune.
class PharmacyPickerSheet extends StatefulWidget {
  const PharmacyPickerSheet({super.key, required this.prescription, this.currentPharmacyId});

  final Prescription prescription;
  final int? currentPharmacyId;

  static Future<Pharmacy?> show(BuildContext context, {required Prescription prescription, int? currentPharmacyId}) =>
      showModalBottomSheet<Pharmacy>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        builder:
            (_) => FractionallySizedBox(
              heightFactor: 0.85,
              child: PharmacyPickerSheet(prescription: prescription, currentPharmacyId: currentPharmacyId),
            ),
      );

  @override
  State<PharmacyPickerSheet> createState() => _PharmacyPickerSheetState();
}

class _PharmacyPickerSheetState extends State<PharmacyPickerSheet> {
  late final Future<(List<Pharmacy>, Map<int, int>)> _data = _load();
  final _search = TextEditingController();

  Future<(List<Pharmacy>, Map<int, int>)> _load() async {
    final pharmacies = await getIt<PharmacyRepository>().getAll();
    final availability = await getIt<PrescriptionDispatchRepository>().availabilityByPharmacy(widget.prescription.id);
    // Les mieux fournies d'abord, puis les ouvertes, puis par nom.
    pharmacies.sort((a, b) {
      final byStock = (availability[b.pharmacyId] ?? 0).compareTo(availability[a.pharmacyId] ?? 0);
      if (byStock != 0) return byStock;
      if (a.isOpenNow != b.isOpenNow) return a.isOpenNow ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return (pharmacies, availability);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.prescription.items.where((i) => i.medicamentId != null).length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Choisir une pharmacie', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'Rechercher',
                  hint: 'Nom ou adresse',
                  controller: _search,
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
                if (snapshot.hasError) return EmptyState.error('Pharmacies indisponibles.');
                final (pharmacies, availability) = snapshot.data!;
                final q = _search.text.trim().toLowerCase();
                final shown =
                    q.isEmpty
                        ? pharmacies
                        : pharmacies
                            .where((p) => p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q))
                            .toList();
                if (shown.isEmpty) {
                  return Center(child: Text('Aucune pharmacie trouvée.', style: theme.textTheme.bodyMedium));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final p = shown[i];
                    final available = availability[p.pharmacyId] ?? 0;
                    final complete = total > 0 && available >= total;
                    final isCurrent = p.pharmacyId == widget.currentPharmacyId;
                    return MediCard(
                      onTap: isCurrent ? null : () => Navigator.pop(context, p),
                      child: Row(
                        children: [
                          const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: theme.textTheme.titleSmall),
                                Text(
                                  p.address,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: [
                                    if (total > 0)
                                      _Tag(
                                        label: '$available/$total en stock',
                                        color: complete ? AppColors.success : AppColors.warning,
                                      ),
                                    _Tag(
                                      label: p.isOpenNow ? 'Ouverte' : 'Fermée',
                                      color: p.isOpenNow ? AppColors.success : AppColors.textMuted,
                                    ),
                                    if (isCurrent) const _Tag(label: 'Pharmacie actuelle', color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isCurrent) const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}
