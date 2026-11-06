import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'insurance_forms.dart';
import 'insurance_widgets.dart';

class InsuranceClaimScreen extends StatefulWidget {
  const InsuranceClaimScreen({super.key, required this.claimId});
  final int claimId;
  @override
  State<InsuranceClaimScreen> createState() => _InsuranceClaimScreenState();
}

class _InsuranceClaimScreenState extends State<InsuranceClaimScreen> {
  final repo = getIt<InsuranceRepository>();
  late Future<Map<String, Object?>> data;
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
    if (mounted) {
      setState(() {
        data = repo.claim(widget.claimId);
      });
    }
  }

  Future<void> action(Map<String, Object?> claim, String action) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DecisionForm(repo: repo, claim: claim, action: action),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Dossier #${widget.claimId}'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, Object?>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyState.error(
            'Dossier indisponible ou accès non autorisé.',
            onRetry: refresh,
          );
        }
        if (!snapshot.hasData) return const LoadingView();
        final claim = snapshot.data!;
        InsuranceDossier dossier;
        try {
          dossier = InsuranceDossier.decode(claim['document_path']);
        } on AppException catch (e) {
          return EmptyState.error(e.message, onRetry: refresh);
        }
        final patient = repo.isPatient;
        final status = claim['status'];
        final theme = Theme.of(context);
        final next = switch (status) {
          'SUBMITTED' when dossier.requestedDocuments != null =>
            patient
                ? 'À vous de compléter le dossier'
                : 'En attente du complément du patient',
          'SUBMITTED' =>
            patient
                ? 'Votre organisme doit examiner la demande'
                : 'Examinez les pièces et choisissez une décision',
          'APPROVED' =>
            'Décision enregistrée · paiement à suivre auprès de l’organisme',
          'PAID' => 'Paiement marqué comme effectué par l’organisme',
          _ => 'Demande refusée · consultez le motif ci-dessous',
        };
        return RefreshIndicator(
          onRefresh: () async {
            refresh();
            await data;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClaimCard(claim: claim, showPatient: !patient),
                      const SizedBox(height: 24),
                      InsuranceEmpty(
                        icon: Icons.route_outlined,
                        title: 'Prochaine étape',
                        text: next,
                      ),
                      if (dossier.requestedDocuments != null)
                        InsuranceEmpty(
                          icon: Icons.attach_file,
                          title: 'Pièces demandées',
                          text: dossier.requestedDocuments!,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Informations du dossier',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Date des soins : ${dossier.careDate ?? 'non renseignée'}',
                      ),
                      if (claim['consultation_id'] != null)
                        Text(
                          'Consultation associée : #${claim['consultation_id']}',
                        ),
                      if (claim['prescription_id'] != null)
                        Text(
                          'Ordonnance associée : #${claim['prescription_id']}',
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Justificatifs (${dossier.attachments.length})',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (dossier.attachments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Aucune image jointe. Une facture lisible peut faciliter l’examen.',
                          ),
                        ),
                      if (dossier.legacyPath != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Ancienne référence de document conservée. Joignez une copie de l’image pour la consulter ici.',
                          ),
                        ),
                      for (final attachment in dossier.attachments)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            leading: Image.memory(
                              attachment.bytes,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, _, _) =>
                                      const Icon(Icons.broken_image_outlined),
                            ),
                            title: Text(attachment.name),
                            trailing: const Icon(Icons.zoom_in),
                            onTap:
                                () => showDialog<void>(
                                  context: context,
                                  builder:
                                      (context) => Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    8,
                                                    8,
                                                    8,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      attachment.name,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Fermer',
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: InteractiveViewer(
                                                minScale: .5,
                                                maxScale: 5,
                                                child: Image.memory(
                                                  attachment.bytes,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (
                                                        _,
                                                        _,
                                                        _,
                                                      ) => const Padding(
                                                        padding: EdgeInsets.all(
                                                          24,
                                                        ),
                                                        child: Text(
                                                          'Image illisible. Demandez une nouvelle copie.',
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Historique du dossier',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (dossier.events.isEmpty)
                        Text(
                          'Demande déposée le ${claim['submitted_at']}. Les anciennes décisions ne disposent pas d’un historique détaillé.',
                        ),
                      for (final event in dossier.events)
                        _TimelineEvent(event: event),
                      const SizedBox(height: 24),
                      if (patient && status == 'SUBMITTED')
                        InsuranceMotion(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(160, 48),
                            ),
                            onPressed: () => action(claim, 'COMPLEMENT'),
                            icon: const Icon(Icons.add_to_photos_outlined),
                            label: const Text('Compléter mon dossier'),
                          ),
                        ),
                      if (!patient && status == 'SUBMITTED')
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (dossier.requestedDocuments == null) ...[
                              InsuranceMotion(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(140, 48),
                                  ),
                                  onPressed: () => action(claim, 'APPROVED'),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approuver'),
                                ),
                              ),
                              OutlinedButton(
                                onPressed:
                                    () => action(claim, 'DOCUMENTS_REQUESTED'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(140, 48),
                                ),
                                child: const Text('Demander des pièces'),
                              ),
                            ],
                            TextButton(
                              onPressed: () => action(claim, 'REJECTED'),
                              child: const Text('Refuser avec motif'),
                            ),
                          ],
                        ),
                      if (!patient && status == 'APPROVED')
                        InsuranceMotion(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(160, 48),
                            ),
                            onPressed: () => action(claim, 'PAID'),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Marquer comme payée'),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Suivi local partagé entre les comptes de cette installation. MediLink n’exécute aucun virement.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({required this.event});
  final Map<String, dynamic> event;
  @override
  Widget build(BuildContext context) {
    final label = switch (event['action']) {
      'SUBMITTED' => 'Demande déposée',
      'DOCUMENTS_REQUESTED' => 'Complément demandé',
      'COMPLEMENT' => 'Dossier complété',
      'APPROVED' => 'Demande approuvée',
      'REJECTED' => 'Demande refusée',
      'PAID' => 'Paiement enregistré',
      _ => 'Mise à jour',
    };
    final date = DateTime.tryParse('${event['at']}')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            event['action'] == 'REJECTED'
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${event['actor']} · ${date == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (event['amount'] != null)
                  Text('Montant retenu : ${money(event['amount'])}'),
                if (event['note'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(event['note'] as String),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionForm extends StatefulWidget {
  const _DecisionForm({
    required this.repo,
    required this.claim,
    required this.action,
  });
  final InsuranceRepository repo;
  final Map<String, Object?> claim;
  final String action;
  @override
  State<_DecisionForm> createState() => _DecisionFormState();
}

class _DecisionFormState extends State<_DecisionForm> {
  final note = TextEditingController();
  late final amount = TextEditingController(
    text: insuranceEstimate(
      widget.claim['amount'] as num,
      widget.claim['coverage_rate'] as num,
    ).toStringAsFixed(3),
  );
  List<InsuranceAttachment> attachments = [];
  bool busy = false;
  String? error;
  @override
  void dispose() {
    note.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = widget.claim['claim_id'] as int;
      switch (widget.action) {
        case 'DOCUMENTS_REQUESTED':
          await widget.repo.requestDocuments(id, note.text);
        case 'COMPLEMENT':
          await widget.repo.complementClaim(
            id,
            attachments: attachments,
            note: note.text,
          );
        default:
          final value = double.tryParse(amount.text.replaceAll(',', '.'));
          if (widget.action == 'APPROVED' && value == null) {
            throw const AppException('Saisissez un montant valide.');
          }
          await widget.repo.changeClaimStatus(
            id,
            widget.action,
            reason: note.text,
            approvedAmount: value,
          );
      }
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Impossible d’enregistrer. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.action) {
      'APPROVED' => 'Approuver la demande',
      'REJECTED' => 'Refuser la demande',
      'DOCUMENTS_REQUESTED' => 'Demander des pièces',
      'COMPLEMENT' => 'Compléter mon dossier',
      _ => 'Confirmer le paiement',
    };
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        constraints: const BoxConstraints(maxWidth: 560),
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.action == 'APPROVED') ...[
                  const Text(
                    'Vérifiez les justificatifs et le taux déclaré avant de retenir un montant.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amount,
                    enabled: !busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Montant retenu (TND)',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.action == 'PAID') ...[
                  Text(
                    'Confirmer que ${money(widget.claim['reimbursed_amount'])} ont été payés hors de MediLink. Cette action ne déclenche aucun virement.',
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: note,
                  enabled: !busy,
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: switch (widget.action) {
                      'DOCUMENTS_REQUESTED' => 'Pièces attendues et consignes',
                      'COMPLEMENT' => 'Votre réponse',
                      'PAID' => 'Référence du paiement (facultatif)',
                      _ => 'Motif de la décision',
                    },
                    helperText:
                        widget.action == 'APPROVED'
                            ? 'Obligatoire si le montant diffère de l’estimation.'
                            : null,
                  ),
                ),
                if (widget.action == 'COMPLEMENT') ...[
                  const SizedBox(height: 16),
                  InsuranceEvidencePicker(
                    repo: widget.repo,
                    attachments: attachments,
                    enabled: !busy,
                    onChanged: (value) => setState(() => attachments = value),
                  ),
                ],
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          InsuranceMotion(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
              onPressed: busy ? null : save,
              child: Text(busy ? 'Enregistrement…' : 'Confirmer'),
            ),
          ),
        ],
      ),
    );
  }
}
