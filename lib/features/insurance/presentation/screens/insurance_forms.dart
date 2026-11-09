import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'package:medilink/features/insurance/data/invoice_ocr.dart';
import 'package:medilink/features/user/presentation/widgets/image_picking.dart';
import 'insurance_widgets.dart';

class InsuranceSimulator extends StatefulWidget {
  const InsuranceSimulator({super.key, required this.contracts});
  final List<Map<String, Object?>> contracts;
  @override
  State<InsuranceSimulator> createState() => _InsuranceSimulatorState();
}

class _InsuranceSimulatorState extends State<InsuranceSimulator> {
  final amount = TextEditingController();
  int? selected;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contracts = widget.contracts.where(contractIsUsable).toList();
    final contract =
        contracts.where((c) => c['contract_id'] == selected).firstOrNull ??
        contracts.firstOrNull;
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    final valid =
        value != null && value.isFinite && value >= 0 && value <= 10000000;
    final estimate =
        valid && contract != null
            ? insuranceEstimate(value, contract['coverage_rate'] as num)
            : null;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(
          Icons.calculate_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Simuler mon reste à charge'),
        subtitle: const Text('Préparer mon budget de soins'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          if (contract == null)
            const Text('Ajoutez un contrat actif pour utiliser le simulateur.')
          else ...[
            DropdownButtonFormField<int>(
              key: ValueKey(contract['contract_id']),
              initialValue: contract['contract_id'] as int,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Contrat à simuler'),
              items: [
                for (final c in contracts)
                  DropdownMenuItem(
                    value: c['contract_id'] as int,
                    child: Text(
                      '${c['company']} · ${c['policy_number']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => setState(() => selected = id),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Budget des soins (TND)',
                errorText:
                    amount.text.isNotEmpty && !valid
                        ? 'Montant entre 0 et 10 000 000.'
                        : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (estimate != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Remboursement estimé : ${money(estimate)}'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reste à charge estimé : ${money(insuranceEstimate(value!, 1) - estimate)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Simulation à partir du taux déclaré. Les plafonds, exclusions et règles de votre organisme ne sont pas pris en compte. Aucune demande n’est créée.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable selection for a new dossier and for later supporting evidence.
class InsuranceEvidencePicker extends StatefulWidget {
  const InsuranceEvidencePicker({
    super.key,
    required this.repo,
    required this.attachments,
    required this.onChanged,
    this.enabled = true,
  });
  final InsuranceRepository repo;
  final List<InsuranceAttachment> attachments;
  final ValueChanged<List<InsuranceAttachment>> onChanged;
  final bool enabled;
  @override
  State<InsuranceEvidencePicker> createState() =>
      _InsuranceEvidencePickerState();
}

class _InsuranceEvidencePickerState extends State<InsuranceEvidencePicker> {
  String? error;
  bool picking = false;
  Future<void> pick(bool medical) async {
    setState(() {
      picking = true;
      error = null;
    });
    try {
      InsuranceAttachment? attachment;
      if (medical) {
        final docs = await widget.repo.patientDocuments();
        if (!mounted) return;
        attachment = await showDialog<InsuranceAttachment>(
          context: context,
          builder:
              (context) => SimpleDialog(
                title: const Text('Mon dossier médical'),
                children:
                    docs.isEmpty
                        ? [
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aucun document enregistré dans votre dossier.',
                            ),
                          ),
                        ]
                        : [
                          for (final doc in docs)
                            SimpleDialogOption(
                              onPressed:
                                  () => Navigator.pop(
                                    context,
                                    InsuranceAttachment(
                                      name: doc.title,
                                      bytes: doc.data,
                                    ),
                                  ),
                              child: Text(doc.title),
                            ),
                        ],
              ),
        );
      } else {
        final choice = await pickImage(
          context,
          title: 'Ajouter un justificatif',
          maxWidth: 2000,
          quality: 88,
        );
        if (choice is PickedImage) {
          attachment = InsuranceAttachment(
            name: 'Justificatif ${widget.attachments.length + 1}',
            bytes: choice.bytes,
          );
        }
      }
      if (!mounted || attachment == null) return;
      attachment.validate();
      final all = [...widget.attachments, attachment];
      if (all.length > 5 ||
          all.fold<int>(0, (n, a) => n + a.bytes.length) > 6 * 1024 * 1024) {
        throw const AppException('Maximum : 5 images et 6 Mo par dossier.');
      }
      widget.onChanged(all);
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error =
                  'Impossible de lire cette image. Réessayez avec une autre photo.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Justificatifs', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      const Text(
        'Facture lisible, ordonnance si nécessaire. 3 Mo par image, 6 Mo par dossier.',
        style: TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          InsuranceMotion(
            child: OutlinedButton.icon(
              onPressed: !widget.enabled || picking ? null : () => pick(false),
              style: OutlinedButton.styleFrom(minimumSize: const Size(120, 44)),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Photo / galerie'),
            ),
          ),
          TextButton.icon(
            onPressed: !widget.enabled || picking ? null : () => pick(true),
            icon: const Icon(Icons.folder_shared_outlined),
            label: const Text('Mon dossier médical'),
          ),
        ],
      ),
      if (picking) const LinearProgressIndicator(),
      for (final (i, a) in widget.attachments.indexed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              a.bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
            ),
          ),
          title: Text(a.name),
          trailing: IconButton(
            tooltip: 'Retirer ${a.name}',
            onPressed:
                !widget.enabled
                    ? null
                    : () =>
                        widget.onChanged([...widget.attachments]..removeAt(i)),
            icon: const Icon(Icons.close),
          ),
        ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );
}

class InsuranceClaimForm extends StatefulWidget {
  const InsuranceClaimForm({
    super.key,
    required this.repo,
    required this.contracts,
  });
  final InsuranceRepository repo;
  final List<Map<String, Object?>> contracts;
  @override
  State<InsuranceClaimForm> createState() => _InsuranceClaimFormState();
}

class _InsuranceClaimFormState extends State<InsuranceClaimForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final dateText = TextEditingController();
  late int contractId = widget.contracts.first['contract_id'] as int;
  late final links = widget.repo.patientCareLinks();
  String? link;
  DateTime? date;
  List<InsuranceAttachment> attachments = [];
  bool busy = false, scanning = false, scanned = false, reviewed = false;
  String? error, hint;
  @override
  void dispose() {
    amount.dispose();
    dateText.dispose();
    super.dispose();
  }

  Future<void> scan() async {
    setState(() {
      scanning = true;
      error = null;
      hint = null;
    });
    try {
      final text = await recognizeInvoice(attachments.first.bytes);
      final suggestion = InvoiceSuggestions.fromText(text);
      if (!mounted) return;
      setState(() {
        if (suggestion.amount != null) {
          amount.text = suggestion.amount!.toStringAsFixed(3);
        }
        if (suggestion.date != null) {
          date = suggestion.date;
          dateText.text = DateFormat('dd/MM/yyyy').format(date!);
        }
        scanned = suggestion.amount != null || suggestion.date != null;
        reviewed = false;
        hint =
            scanned
                ? 'Champs proposés depuis la première image. Comparez-les à votre facture avant de confirmer.'
                : 'Aucun total ou date fiable détecté. Vous pouvez les saisir manuellement.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error =
                  'Lecture automatique indisponible. Vous pouvez saisir les informations manuellement.',
        );
      }
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (scanned && !reviewed) {
      setState(() => error = 'Vérifiez et confirmez les champs proposés.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final parts = link?.split(':');
      await widget.repo.submitClaim(
        contractId: contractId,
        amount: double.parse(amount.text.replaceAll(',', '.')),
        careDate: date,
        attachments: attachments,
        consultationId:
            parts?.first == 'consultation' ? int.parse(parts![1]) : null,
        prescriptionId:
            parts?.first == 'prescription' ? int.parse(parts![1]) : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error =
                  'Enregistrement impossible. Vos informations restent dans ce formulaire.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy && !scanning,
    child: AlertDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: const Text('Demander un remboursement'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Préparez votre dossier. Les pièces jointes seront visibles par votre organisme sur cet appareil.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: contractId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Contrat'),
                  items: [
                    for (final c in widget.contracts)
                      DropdownMenuItem(
                        value: c['contract_id'] as int,
                        child: Text(
                          '${c['company']} · ${c['policy_number']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged:
                      busy || scanning
                          ? null
                          : (id) => setState(() => contractId = id!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amount,
                  enabled: !busy && !scanning,
                  decoration: const InputDecoration(
                    labelText: 'Montant des soins (TND)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return n == null || !n.isFinite || n <= 0 || n > 10000000
                        ? 'Saisissez un montant valide.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateText,
                  readOnly: true,
                  enabled: !busy && !scanning,
                  decoration: const InputDecoration(
                    labelText: 'Date des soins (facultatif)',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: () async {
                    final chosen = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (chosen != null && mounted) {
                      setState(() {
                        date = chosen;
                        dateText.text = DateFormat('dd/MM/yyyy').format(chosen);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, Object?>>>(
                  future: links,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Les soins associés sont indisponibles. Vous pouvez continuer sans lien.',
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Associer un soin (facultatif)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Aucun'),
                          ),
                          for (final c in snapshot.data!)
                            DropdownMenuItem(
                              value: '${c['kind']}:${c['id']}',
                              child: Text(
                                '${c['kind'] == 'prescription' ? 'Ordonnance' : 'Consultation'} #${c['id']} · ${('${c['date']}').split(' ').first}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged:
                            busy || scanning
                                ? null
                                : (v) =>
                                    setState(() => link = v == '' ? null : v),
                      ),
                    );
                  },
                ),
                InsuranceEvidencePicker(
                  repo: widget.repo,
                  attachments: attachments,
                  enabled: !busy && !scanning,
                  onChanged:
                      (value) => setState(() {
                        attachments = value;
                        reviewed = false;
                      }),
                ),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: busy || scanning ? null : scan,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(
                      scanning
                          ? 'Lecture en cours…'
                          : 'Lire la facture (1re image)',
                    ),
                  ),
                  const Text(
                    'Lecture locale, sans envoi de la photo à un serveur.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                if (scanning) const LinearProgressIndicator(),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(hint!),
                  ),
                if (scanned)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('J’ai vérifié le montant et la date.'),
                    value: reviewed,
                    onChanged:
                        busy || scanning
                            ? null
                            : (v) => setState(() => reviewed = v!),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Vous pouvez déposer sans photo et compléter plus tard. Aucun envoi à un portail externe ni paiement automatique.',
                  style: TextStyle(fontSize: 12),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy || scanning ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        InsuranceMotion(
          child: FilledButton(
            onPressed: busy || scanning ? null : save,
            style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
            child: Text(busy ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
      ],
    ),
  );
}
