import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'insurance_forms.dart';
import 'insurance_contract_form.dart';
import 'insurance_comparison_screen.dart';
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
  late Future<List<List<Map<String, Object?>>>> data;

  @override
  void dispose() {
    repo.changes.removeListener(refresh);
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

  Future<void> addContract([Map<String, Object?>? contract]) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InsuranceContractForm(repo: repo, contract: contract),
    );
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

  Future<void> manageContract(
    Map<String, Object?> contract, {
    bool delete = false,
  }) async {
    final activate = contract['status'] != 'ACTIVE';
    final label =
        delete
            ? 'Supprimer le contrat'
            : activate
            ? 'Réactiver le contrat'
            : 'Désactiver le contrat';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(label),
            content: Text(
              delete
                  ? 'Supprimer définitivement le contrat ${contract['policy_number']} sans demande liée ?'
                  : activate
                  ? 'Le contrat sera de nouveau proposé si ses dates sont valides. Cela ne vaut pas validation par l’organisme.'
                  : 'Ce contrat ne sera plus proposé pour de nouvelles demandes. Les dossiers existants et leur traitement seront conservés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      final id = contract['contract_id'] as int;
      if (delete) {
        await repo.deleteContract(id);
      } else {
        await repo.setContractActive(id, activate);
      }
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    } catch (_) {
      if (mounted) context.showError('Impossible d’enregistrer. Réessayez.');
    }
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
            claims
                .where(
                  (claim) => [
                    'SUBMITTED',
                    'WAITING_DOCUMENTS',
                    'REVIEW_COMPLEMENT',
                    'APPEAL_PENDING',
                  ].contains(insuranceClaimState(claim)),
                )
                .length;
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
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(160, 48),
                            ),
                            onPressed:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) =>
                                            const InsuranceComparisonScreen(),
                                  ),
                                ),
                            icon: const Icon(Icons.compare_arrows),
                            label: const Text('Comparer des offres fictives'),
                          ),
                          const SizedBox(height: 32),
                          InsuranceSectionHeading(
                            eyebrow: 'Votre couverture',
                            title: 'Mes contrats',
                            description:
                                'Vos informations de couverture en un coup d’œil.',
                            action: InsuranceMotion(
                              child: TextButton.icon(
                                onPressed: () => addContract(),
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
                              ContractCard(
                                contract: contract,
                                onEdit:
                                    (contract['claim_count'] as num) == 0
                                        ? () => addContract(contract)
                                        : null,
                                onDelete:
                                    (contract['claim_count'] as num) == 0
                                        ? () => manageContract(
                                          contract,
                                          delete: true,
                                        )
                                        : null,
                                onToggle: () => manageContract(contract),
                              ),
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
