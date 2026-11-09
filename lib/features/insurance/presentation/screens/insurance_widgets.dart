import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Champ obligatoire.' : null;
String money(Object? value) => '${(value as num).toStringAsFixed(3)} TND';
String statusLabel(Object? status) => switch (status) {
  'ACTIVE' => 'Actif',
  'EXPIRED' => 'Expiré',
  'NOT_STARTED' => 'À venir',
  'SUSPENDED' => 'Suspendu',
  'SUBMITTED' => 'À traiter',
  'WITHDRAWN' => 'Retirée',
  'WAITING_DOCUMENTS' => 'Pièces attendues',
  'REVIEW_COMPLEMENT' => 'Complément à vérifier',
  'UNREADABLE' => 'Dossier illisible',
  'APPROVED' => 'Approuvée',
  'REJECTED' => 'Refusée',
  'PAID' => 'Payée',
  _ => 'Inconnu',
};

/// Keeps the underlying Material button responsible for keyboard and semantics.
class InsuranceMotion extends StatefulWidget {
  const InsuranceMotion({super.key, required this.child});
  final Widget child;
  @override
  State<InsuranceMotion> createState() => _InsuranceMotionState();
}

class _InsuranceMotionState extends State<InsuranceMotion> {
  bool hover = false;
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit:
          (_) => setState(() {
            hover = false;
            pressed = false;
          }),
      child: Listener(
        onPointerDown: (_) => setState(() => pressed = true),
        onPointerUp: (_) => setState(() => pressed = false),
        onPointerCancel: (_) => setState(() => pressed = false),
        child: AnimatedScale(
          scale:
              reduceMotion
                  ? 1
                  : pressed
                  ? .96
                  : hover
                  ? 1.025
                  : 1,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class InsuranceHero extends StatelessWidget {
  const InsuranceHero({
    super.key,
    required this.contractCount,
    required this.pendingCount,
  });
  final int contractCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/insurance_care.png'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
              errorBuilder: _imageFallback,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryDeep.withValues(alpha: .98),
                    AppColors.primaryDeep.withValues(alpha: .82),
                    AppColors.primaryDeep.withValues(alpha: .25),
                  ],
                  stops: const [0, .52, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .2),
                    ),
                  ),
                  child: Text(
                    'MON ESPACE ASSURANCE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      letterSpacing: .9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 255),
                  child: Text(
                    'Votre santé,\nbien protégée.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      height: 1.16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 255),
                  child: Text(
                    'Vos contrats et remboursements, au même endroit.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: .88),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroPill(
                      icon: Icons.shield_outlined,
                      text:
                          '$contractCount contrat${contractCount == 1 ? '' : 's'}',
                    ),
                    _HeroPill(
                      icon: Icons.schedule_rounded,
                      text: '$pendingCount en attente',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _imageFallback(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) => const ColoredBox(color: AppColors.primaryDeep);

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class InsuranceSectionHeading extends StatelessWidget {
  const InsuranceSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.action,
  });
  final String eyebrow;
  final String title;
  final String description;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class InsuranceEmpty extends StatelessWidget {
  const InsuranceEmpty({
    super.key,
    required this.text,
    this.icon = Icons.folder_open_rounded,
    this.title,
  });
  final String text;
  final IconData icon;
  final String? title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag(this.status);
  final Object? status;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      'ACTIVE' || 'PAID' || 'APPROVED' => AppColors.success,
      'REJECTED' || 'SUSPENDED' => AppColors.error,
      'SUBMITTED' => AppColors.accentDark,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ContractCard extends StatelessWidget {
  const ContractCard({
    super.key,
    required this.contract,
    this.showPatient = false,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });
  final Map<String, Object?> contract;
  final bool showPatient;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${contract['company']}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'N° ${contract['policy_number']}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusTag(
                contract['status'] == 'ACTIVE' && !contractIsUsable(contract)
                    ? (DateTime.tryParse(
                              '${contract['start_date']}',
                            )?.isAfter(DateTime.now()) ??
                            false
                        ? 'NOT_STARTED'
                        : 'EXPIRED')
                    : contract['status'],
              ),
            ],
          ),
          if (showPatient) ...[
            const SizedBox(height: 12),
            Text(
              '${contract['prenom']} ${contract['nom']}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: .48),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Couverture déclarée : ${((contract['coverage_rate'] as num) * 100).toStringAsFixed(2)} %',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (contract['start_date'] != null || contract['end_date'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Validité : ${contract['start_date'] ?? 'début non précisé'} → ${contract['end_date'] ?? 'fin non précisée'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (onToggle != null) ...[
            const SizedBox(height: 12),
            if (contract['insurer_available'] == 0)
              Text(
                'Aucun assureur actif correspondant sur cette installation. Vérifiez le nom de l’organisme ; le traitement local sera en attente.',
                style: theme.textTheme.bodySmall,
              ),
            if (onEdit == null)
              Text(
                'Conditions conservées : un dossier est lié à ce contrat.',
                style: theme.textTheme.bodySmall,
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                  ),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: Text(
                    contract['status'] == 'ACTIVE' ? 'Désactiver' : 'Réactiver',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ClaimCard extends StatelessWidget {
  const ClaimCard({
    super.key,
    required this.claim,
    this.showPatient = false,
    this.onOpen,
  });
  final Map<String, Object?> claim;
  final bool showPatient;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = (claim['amount'] as num).toDouble();
    final estimate = amount * (claim['coverage_rate'] as num).toDouble();
    final status = insuranceClaimState(claim);
    final date = '${claim['submitted_at']}';
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demande #${claim['claim_id']}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${claim['company']} · ${claim['policy_number']}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusTag(status),
            ],
          ),
          if (showPatient) ...[
            const SizedBox(height: 10),
            Text('${claim['prenom']} ${claim['nom']}'),
          ],
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Frais déclarés : ${money(amount)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (status != 'REJECTED' && status != 'WITHDRAWN')
            Text(
              '${status == 'APPROVED' || status == 'PAID' ? 'Montant retenu' : 'Estimation indicative'} : ${money(claim['reimbursed_amount'] ?? estimate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          if ((claim['possible_duplicates'] as List?)?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'À vérifier : frais similaires aux dossiers ${(claim['possible_duplicates'] as List).map((id) => '#$id').join(', ')}. Cela ne prouve pas un doublon.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          Text(
            'Déposée le ${date.length >= 10 ? date.substring(0, 10) : date}',
            style: theme.textTheme.bodySmall,
          ),
          if (onOpen != null) ...[
            const SizedBox(height: 12),
            InsuranceMotion(
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Ouvrir le dossier'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
