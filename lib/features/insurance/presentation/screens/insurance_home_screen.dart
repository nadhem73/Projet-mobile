import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'insurance_forms.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_widgets.dart';

class InsuranceHomeScreen extends StatefulWidget {
  const InsuranceHomeScreen({super.key});
  @override
  State<InsuranceHomeScreen> createState() => _InsuranceHomeScreenState();
}

class _InsuranceHomeScreenState extends State<InsuranceHomeScreen> {
  final repo = getIt<InsuranceRepository>();
  final List<TextEditingController> _controllers = [];
  late Future<List<List<Map<String, Object?>>>> data;

  TextEditingController controller([String? text]) {
    final value = TextEditingController(text: text);
    _controllers.add(value);
    return value;
  }

  @override
  void dispose() {
    repo.changes.removeListener(refresh);
    for (final value in _controllers) {
      value.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    refresh();
    repo.changes.addListener(refresh);
  }

  void refresh() {
    setState(() {
      data = Future.wait([repo.patientContracts(), repo.patientClaims()]);
    });
  }

  Future<void> addContract() async {
    final company = controller();
    final policy = controller();
    final rate = controller('70');
    final form = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            constraints: const BoxConstraints(maxWidth: 480),
            title: const Text('Ajouter un contrat'),
            content: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Gardez vos informations de couverture à portée de main.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: company,
                      decoration: const InputDecoration(
                        labelText: 'Organisme (ex. CNAM)',
                      ),
                      validator: requiredText,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: policy,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de contrat',
                      ),
                      validator: requiredText,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rate,
                      decoration: const InputDecoration(
                        labelText: 'Taux estimé (%)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(
                          (v ?? '').replaceAll(',', '.'),
                        );
                        return n == null || !n.isFinite || n < 0 || n > 100
                            ? 'Saisissez un taux entre 0 et 100.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Informations déclarées par vos soins. Le taux est indicatif et doit être vérifié auprès de votre organisme.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              InsuranceMotion(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              InsuranceMotion(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 48),
                  ),
                  onPressed: () {
                    if (form.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
    );
    if (result == true) {
      try {
        await repo.addContract(
          company: company.text,
          policyNumber: policy.text,
          coverageRate: double.parse(rate.text.replaceAll(',', '.')) / 100,
        );
        if (mounted) {
          context.showSuccess('Contrat enregistré.');
          refresh();
        }
      } on AppException catch (e) {
        if (mounted) context.showError(e.message);
      }
    }
  }

  Future<void> submit(List<Map<String, Object?>> contracts) async {
    final eligible = contracts.where(contractIsUsable).toList();
    if (eligible.isEmpty) {
      context.showInfo('Ajoutez un contrat actif et en cours de validité.');
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InsuranceClaimForm(repo: repo, contracts: eligible),
    );
    if (saved == true && mounted) context.showSuccess('Demande enregistrée.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon assurance')),
    body: FutureBuilder<List<List<Map<String, Object?>>>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyState.error(
            'Impossible de charger votre assurance.',
            onRetry: refresh,
          );
        }
        if (!snapshot.hasData) return const LoadingView();
        final contracts = snapshot.data![0];
        final claims = snapshot.data![1];
        final pending =
            claims.where((claim) => claim['status'] == 'SUBMITTED').length;
        final theme = Theme.of(context);
        return RefreshIndicator(
          onRefresh: () async {
            refresh();
            await data;
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth < 380 ? 16.0 : 24.0;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(side, 12, side, 40),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InsuranceHero(
                            contractCount: contracts.length,
                            pendingCount: pending,
                          ),
                          const SizedBox(height: 32),
                          InsuranceSimulator(contracts: contracts),
                          const SizedBox(height: 32),
                          InsuranceSectionHeading(
                            eyebrow: 'Votre couverture',
                            title: 'Mes contrats',
                            description:
                                'Vos informations de couverture en un coup d’œil.',
                            action: InsuranceMotion(
                              child: TextButton.icon(
                                onPressed: addContract,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Ajouter'),
                              ),
                            ),
                          ),
                          if (contracts.isEmpty)
                            const InsuranceEmpty(
                              icon: Icons.shield_outlined,
                              title: 'Votre espace est pret',
                              text:
                                  'Aucun contrat enregistré. Ajoutez votre premier contrat.',
                            )
                          else
                            for (final contract in contracts)
                              ContractCard(contract: contract),
                          const SizedBox(height: 32),
                          InsuranceSectionHeading(
                            eyebrow: 'Suivi de vos soins',
                            title: 'Remboursements',
                            description:
                                'Retrouvez l’état de vos demandes ici.',
                            action: InsuranceMotion(
                              child: IconButton.filledTonal(
                                tooltip: 'Nouvelle demande',
                                onPressed: () => submit(contracts),
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ),
                          ),
                          if (claims.isEmpty)
                            const InsuranceEmpty(
                              icon: Icons.receipt_long_outlined,
                              title: 'Aucune demande pour le moment',
                              text:
                                  'Une fois votre contrat ajouté, vous pourrez suivre vos demandes ici.',
                            )
                          else
                            for (final claim in claims)
                              ClaimCard(
                                claim: claim,
                                onOpen:
                                    () => context.push(
                                      '/insurance/claim/${claim['claim_id']}',
                                    ),
                              ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 19,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Les taux et montants affichés sont indicatifs. Les données sont conservées sur cet appareil.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
