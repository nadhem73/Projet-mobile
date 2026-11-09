import 'package:flutter/material.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/insurance/data/insurance_comparator.dart';
import 'package:medilink/features/insurance/data/insurance_explanation_service.dart';

class InsuranceComparisonScreen extends StatefulWidget {
  const InsuranceComparisonScreen({super.key, this.createService});
  final InsuranceExplanationService Function()? createService;
  @override
  State<InsuranceComparisonScreen> createState() =>
      _InsuranceComparisonScreenState();
}

class _InsuranceComparisonScreenState extends State<InsuranceComparisonScreen> {
  final budget = TextEditingController(text: '60');
  final priorities = <String>{'consultations'};
  @override
  void dispose() {
    budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = double.tryParse(budget.text.replaceAll(',', '.'));
    final validBudget =
        value != null && value.isFinite && value > 0 && value <= 10000;
    final offers =
        validBudget ? rankDemoOffers(value, priorities) : <DemoOfferScore>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Comparer des offres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: .5,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATALOGUE DE DÉMONSTRATION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comparez selon vos priorités',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Offres, tarifs et garanties fictifs. Ce classement ne vérifie pas votre éligibilité et ne constitue pas un conseil d’assurance.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: budget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Budget mensuel maximum (TND)',
                      errorText:
                          validBudget
                              ? null
                              : 'Saisissez un budget supérieur à 0 et inférieur ou égal à 10 000.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Vos priorités', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final entry in demoBenefits.entries)
                        FilterChip(
                          label: Text(entry.value),
                          selected: priorities.contains(entry.key),
                          onSelected:
                              (selected) => setState(() {
                                if (selected) {
                                  priorities.add(entry.key);
                                } else {
                                  priorities.remove(entry.key);
                                }
                              }),
                        ),
                    ],
                  ),
                  if (priorities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Choisissez au moins une priorité.'),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Résultats indicatifs',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget respecté ; score : priorités 70 %, prix 30 %.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (validBudget && priorities.isNotEmpty && offers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Aucune offre fictive ne correspond à ce budget.',
                      ),
                    ),
                  for (var i = 0; i < offers.length; i++)
                    Card(
                      margin: const EdgeInsets.only(top: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${i + 1}. ${offers[i].offer.name}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Chip(
                                  label: Text(
                                    '${offers[i].score.toStringAsFixed(0)} / 100',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${offers[i].offer.monthlyCost.toStringAsFixed(0)} TND / mois · fictif',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Priorités couvertes : ${offers[i].matches} / ${priorities.length}',
                            ),
                            Text(
                              'Inclus : ${offers[i].offer.benefits.map((b) => demoBenefits[b]).join(', ')}',
                            ),
                            if (priorities
                                .difference(offers[i].offer.benefits)
                                .isNotEmpty)
                              Text(
                                'Priorités non incluses : ${priorities.difference(offers[i].offer.benefits).map((b) => demoBenefits[b]).join(', ')}',
                              ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(140, 48),
                              ),
                              onPressed:
                                  () => showDialog<void>(
                                    context: context,
                                    builder:
                                        (_) => _DemoExplanationDialog(
                                          service: widget.createService?.call(),
                                          facts: {
                                            'task': 'compare',
                                            'offer_id': offers[i].offer.id,
                                            'budget': value,
                                            'priorities': priorities.toList(),
                                          },
                                        ),
                                  ),
                              icon: const Icon(Icons.auto_awesome_outlined),
                              label: const Text('Pourquoi cette offre ?'),
                            ),
                            Text(
                              'L’IA reçoit le budget choisi et les priorités, sans identité.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoExplanationDialog extends StatefulWidget {
  const _DemoExplanationDialog({required this.facts, this.service});
  final Map<String, Object?> facts;
  final InsuranceExplanationService? service;
  @override
  State<_DemoExplanationDialog> createState() => _DemoExplanationDialogState();
}

class _DemoExplanationDialogState extends State<_DemoExplanationDialog> {
  late final service = widget.service ?? InsuranceExplanationService();
  String? result;
  String? error;
  bool busy = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await service.explain(widget.facts);
      if (mounted) setState(() => result = value);
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pourquoi cette offre fictive ?'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (result != null) ...[
              SelectableText(result!),
              const SizedBox(height: 12),
              const Text(
                'Démonstration fictive ; l’IA peut se tromper. Vérifiez toujours les conditions réelles.',
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fermer'),
      ),
      if (error != null)
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(130, 48)),
          onPressed: busy ? null : load,
          child: const Text('Réessayer'),
        ),
    ],
  );
}
