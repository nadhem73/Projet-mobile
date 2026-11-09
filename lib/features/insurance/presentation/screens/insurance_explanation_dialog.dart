import 'package:flutter/material.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/insurance/data/insurance_explanation_service.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'insurance_widgets.dart';

/// Illustrations only: these never create or modify a real insurance claim.
const _examples =
    <({String label, String status, double amount, double? accepted})>[
      (
        label: 'Pièces attendues',
        status: 'WAITING_DOCUMENTS',
        amount: 120,
        accepted: null,
      ),
      (label: 'Approuvée', status: 'APPROVED', amount: 120, accepted: 84),
      (label: 'Refusée', status: 'REJECTED', amount: 120, accepted: null),
      (label: 'Paiement indiqué', status: 'PAID', amount: 120, accepted: 84),
    ];

class InsuranceExplanationDialog extends StatefulWidget {
  const InsuranceExplanationDialog({
    super.key,
    required this.claim,
    required this.repo,
    this.service,
  });
  final Map<String, Object?> claim;
  final InsuranceRepository repo;
  final InsuranceExplanationService? service;
  @override
  State<InsuranceExplanationDialog> createState() =>
      _InsuranceExplanationDialogState();
}

class _InsuranceExplanationDialogState
    extends State<InsuranceExplanationDialog> {
  late final service = widget.service ?? InsuranceExplanationService();
  final scenarioScroll = ScrollController();
  late Map<String, Object?> facts = explanationFacts(widget.claim);
  int selected =
      0; // 0 = real dossier; remaining values are fictional examples.
  bool busy = true;
  String? result;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) send();
    });
  }

  @override
  void dispose() {
    service.dispose();
    scenarioScroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    setState(() {
      busy = true;
      error = null;
      result = null;
    });
    try {
      if (!widget.repo.isPatient) {
        throw const AppException('Cette action est réservée au patient.');
      }
      final latest = await widget.repo.claim(widget.claim['claim_id'] as int);
      if (!mounted) return;
      if (!widget.repo.isPatient) {
        throw const AppException('Cette action est réservée au patient.');
      }
      final example = selected == 0 ? null : _examples[selected - 1];
      final nextFacts =
          example == null
              ? explanationFacts(latest)
              : <String, Object?>{
                'status': example.status,
                'amount_tnd': example.amount,
                if (example.accepted != null)
                  'accepted_amount_tnd': example.accepted,
              };
      setState(() => facts = nextFacts);
      final explanation = await service.explain(nextFacts);
      if (mounted) setState(() => result = explanation);
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Dossier indisponible. Réessayez.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isExample = selected != 0;
    final status = facts['status'] as String;
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 580),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_outlined, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre dossier, éclairci',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  isExample
                      ? 'Simulation · données fictives'
                      : 'Assistant assurance · votre dossier',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!busy)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExample ? 'EXEMPLE FICTIF' : 'VOTRE DEMANDE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            status == 'PAID'
                                ? 'Marquée payée'
                                : statusLabel(status),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'Frais : ${money(facts['amount_tnd'])}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (facts['accepted_amount_tnd'] != null)
                            Text(
                              'Montant retenu : ${money(facts['accepted_amount_tnd'])}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.short_text_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce que cela signifie',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Préparation de l’explication…')),
                    ],
                  ),
                ),
              if (error != null) ...[
                Text(
                  error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: busy ? null : send,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
              if (result != null)
                SelectableText(
                  result!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              const SizedBox(height: 22),
              Divider(color: colors.outlineVariant),
              const SizedBox(height: 12),
              Text('Explorer des exemples', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Faites défiler les exemples fictifs : votre dossier ne change pas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Scrollbar(
                controller: scenarioScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: scenarioScroll,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        for (var i = 0; i <= _examples.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                i == 0 ? 'Mon dossier' : _examples[i - 1].label,
                              ),
                              selected: selected == i,
                              onSelected:
                                  busy
                                      ? null
                                      : (_) {
                                        if (selected != i) {
                                          setState(() => selected = i);
                                          send();
                                        }
                                      },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Réponse générée par IA, à vérifier auprès de votre organisme. Seuls l’état et les montants sont envoyés à Groq.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
