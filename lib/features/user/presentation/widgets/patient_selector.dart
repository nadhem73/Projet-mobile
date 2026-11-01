import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/dependent.dart';
import 'package:medilink/features/user/data/repositories/dependent_repository.dart';
import 'package:medilink/features/user/user_module.dart';

/// Étape « Pour qui est ce rendez-vous ? » du parcours de réservation
/// (module Rendez-vous) : le patient connecté ou l'un de ses proches.
///
/// [onChanged] reçoit null pour « moi-même », sinon le proche choisi.
class MLPatientComponent extends StatefulWidget {
  const MLPatientComponent({super.key, this.onChanged});

  final ValueChanged<Dependent?>? onChanged;

  @override
  State<MLPatientComponent> createState() => _MLPatientComponentState();
}

class _MLPatientComponentState extends State<MLPatientComponent> {
  final _session = getIt<SessionService>();
  List<Dependent> _dependents = [];

  /// null = moi-même.
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = _session.currentUser?.patientId;
    if (patientId == null) return;
    final list = await getIt<DependentRepository>().forPatient(patientId);
    if (mounted) setState(() => _dependents = list);
  }

  void _select(Dependent? d) {
    setState(() => _selectedId = d?.id);
    widget.onChanged?.call(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _session.currentUser;

    Widget option({required String initials, required String name, required String detail, Dependent? dependent}) {
      final selected = _selectedId == dependent?.id;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: MediCard(
          onTap: () => _select(dependent),
          borderColor: selected ? theme.colorScheme.primary : null,
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.06) : null,
          child: Row(
            children: [
              MediAvatar(initials: initials, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    Text(detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? theme.colorScheme.primary : theme.dividerColor,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pour qui est ce rendez-vous ?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Vous pouvez réserver pour vous ou pour un proche.', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          option(initials: user?.initials ?? '', name: 'Moi-même', detail: user?.fullName ?? ''),
          for (final d in _dependents)
            option(
              initials: d.initials,
              name: d.fullName,
              detail: [d.relation.label, if (d.age != null) '${d.age} ans'].join(' · '),
              dependent: d,
            ),
          OutlinedButton.icon(
            onPressed: () async {
              await context.push(UserRoutes.dependents);
              _load();
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Ajouter un proche'),
          ),
        ],
      ),
    );
  }
}
