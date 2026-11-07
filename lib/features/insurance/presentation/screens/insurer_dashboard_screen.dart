import 'package:flutter/material.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/presentation/screens/insurance_widgets.dart';

class InsurerDashboardScreen extends StatefulWidget {
  const InsurerDashboardScreen({super.key});
  @override
  State<InsurerDashboardScreen> createState() => _InsurerDashboardScreenState();
}

class _InsurerDashboardScreenState extends State<InsurerDashboardScreen> {
  final repo = getIt<InsuranceRepository>();
  late Future<List<List<Map<String, Object?>>>> data;
  String filter = 'ALL';
  String query = '';
  @override
  void initState() {
    super.initState();
    refresh();
    repo.changes.addListener(refresh);
  }

  @override
  void dispose() {
    repo.changes.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    setState(() {
      data = Future.wait([repo.insurerContracts(), repo.insurerClaims()]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = getIt<SessionService>().requireUser;
    return Scaffold(
      body: FutureBuilder<List<List<Map<String, Object?>>>>(
        future: data,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PanelHeader(
                  greeting: 'Espace assureur',
                  title: user.organization ?? 'Mon organisme',
                  subtitle: user.fullName,
                  initials: user.initials,
                  color: AppColors.primary,
                  onAvatarTap: () => context.push(AppRoutes.profile),
                  actions: [
                    PanelHeaderAction(
                      icon: Icons.refresh,
                      tooltip: 'Actualiser',
                      onPressed: refresh,
                    ),
                    const NotificationBell(onDark: true),
                    PanelHeaderAction(
                      icon: Icons.person_outline_rounded,
                      tooltip: 'Mon profil',
                      onPressed: () => context.push(AppRoutes.profile),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 808),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child:
                          snapshot.hasError
                              ? EmptyState.error(
                                'Impossible de charger les dossiers.',
                                onRetry: refresh,
                              )
                              : !snapshot.hasData
                              ? const LoadingView()
                              : _content(
                                context,
                                snapshot.data![0],
                                snapshot.data![1],
                              ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<Map<String, Object?>> contracts,
    List<Map<String, Object?>> claims,
  ) {
    final pending =
        claims
            .where(
              (c) => [
                'SUBMITTED',
                'REVIEW_COMPLEMENT',
              ].contains(insuranceClaimState(c)),
            )
            .length;
    bool matches(Map<String, Object?> row) =>
        '${row['prenom']} ${row['nom']} ${row['policy_number']} ${row['claim_id'] ?? ''}'
            .toLowerCase()
            .contains(query.trim().toLowerCase());
    final filteredClaims =
        claims
            .where(
              (c) =>
                  (filter == 'ALL' || insuranceClaimState(c) == filter) &&
                  matches(c),
            )
            .toList();
    final filteredContracts = contracts.where(matches).toList();
    final paid = claims
        .where((c) => c['status'] == 'PAID')
        .fold<double>(
          0,
          (sum, c) => sum + ((c['reimbursed_amount'] as num?)?.toDouble() ?? 0),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsuranceSectionHeading(
          eyebrow: 'Espace professionnel',
          title: 'Votre activité',
          description: 'Une vue d’ensemble des dossiers de votre organisme.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.description_outlined),
              label: Text('${contracts.length} contrats'),
            ),
            Chip(
              avatar: const Icon(Icons.pending_actions_outlined),
              label: Text('$pending à traiter'),
            ),
            Chip(
              avatar: const Icon(Icons.payments_outlined),
              label: Text('${money(paid)} marqués payés'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Rechercher un adhérent ou un dossier',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in [
              'ALL',
              'SUBMITTED',
              'WAITING_DOCUMENTS',
              'REVIEW_COMPLEMENT',
              'WITHDRAWN',
              'APPROVED',
              'REJECTED',
              'PAID',
            ])
              ChoiceChip(
                label: Text(status == 'ALL' ? 'Toutes' : statusLabel(status)),
                selected: filter == status,
                onSelected: (_) => setState(() => filter = status),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const InsuranceSectionHeading(
          eyebrow: 'Suivi des dossiers',
          title: 'Demandes de remboursement',
          description:
              'Décisions enregistrées sur cet appareil ; aucun paiement automatique.',
        ),
        if (filteredClaims.isEmpty)
          InsuranceEmpty(
            text:
                claims.isEmpty
                    ? 'Aucune demande pour votre organisme. Les demandes des patients apparaîtront ici sur cette installation.'
                    : 'Aucune demande ne correspond à votre recherche.',
          )
        else
          for (final claim in filteredClaims)
            ClaimCard(
              claim: claim,
              showPatient: true,
              onOpen:
                  () => context.push('/insurance/claim/${claim['claim_id']}'),
            ),
        const SizedBox(height: 24),
        const InsuranceSectionHeading(
          eyebrow: 'Vos adhérents',
          title: 'Contrats de votre organisme',
          description: 'Les contrats associés à votre organisme.',
        ),
        if (filteredContracts.isEmpty)
          const InsuranceEmpty(
            text: 'Aucun contrat enregistré pour votre organisme.',
          )
        else
          for (final contract in filteredContracts)
            ContractCard(contract: contract, showPatient: true),
        const SizedBox(height: 24),
      ],
    );
  }
}
