import 'package:flutter/material.dart';
import 'package:medilink/core/constants/medical_specialties.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';
import 'insurance_widgets.dart';

/// Reusable create/update form. Repository rules also protect direct callers.
class InsuranceContractForm extends StatefulWidget {
  const InsuranceContractForm({super.key, required this.repo, this.contract});
  final InsuranceRepository repo;
  final Map<String, Object?>? contract;
  @override
  State<InsuranceContractForm> createState() => _InsuranceContractFormState();
}

class _InsuranceContractFormState extends State<InsuranceContractForm> {
  final form = GlobalKey<FormState>();
  late final companies = widget.repo.availableInsurerCompanies();
  late final company = TextEditingController(
    text: widget.contract?['company'] as String?,
  );
  late final policy = TextEditingController(
    text: widget.contract?['policy_number'] as String?,
  );
  late final rate = TextEditingController(
    text:
        (((widget.contract?['coverage_rate'] as num?) ?? .7) * 100).toString(),
  );
  late final start = TextEditingController(
    text: widget.contract?['start_date'] as String?,
  );
  late final end = TextEditingController(
    text: widget.contract?['end_date'] as String?,
  );
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final controller in [company, policy, rate, start, end]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // Match shared names without changing the shared catalogue or profile.
      final name =
          InsuranceCompanies.all
              .where(
                (n) => n.toLowerCase() == company.text.trim().toLowerCase(),
              )
              .firstOrNull ??
          company.text.trim();
      if (name == 'Autre') {
        throw const AppException(
          'Indiquez le nom exact de votre organisme plutôt que « Autre ».',
        );
      }
      if (widget.contract == null) {
        await widget.repo.addContract(
          company: name,
          policyNumber: policy.text,
          coverageRate: double.parse(rate.text.replaceAll(',', '.')) / 100,
          startDate: DateTime.tryParse(start.text.trim()),
          endDate: DateTime.tryParse(end.text.trim()),
        );
      } else {
        await widget.repo.updateContract(
          widget.contract!['contract_id'] as int,
          company: name,
          policyNumber: policy.text,
          coverageRate: double.parse(rate.text.replaceAll(',', '.')) / 100,
          startDate: DateTime.tryParse(start.text.trim()),
          endDate: DateTime.tryParse(end.text.trim()),
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
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      constraints: const BoxConstraints(maxWidth: 480),
      title: Text(
        widget.contract == null ? 'Ajouter un contrat' : 'Modifier le contrat',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: company,
                  enabled: !busy,
                  validator: requiredText,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Organisme (ex. CNAM)',
                    helperText:
                        'Nom identique à celui de votre organisme dans MediLink.',
                    helperMaxLines: 2,
                  ),
                ),
                FutureBuilder<List<String>>(
                  future: companies,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Liste des assureurs indisponible : vérifiez le nom avant de continuer.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final names = snapshot.data!;
                    final name = company.text.trim().toLowerCase();
                    final found = names.any(
                      (n) => n.trim().toLowerCase() == name,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (names.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Assureurs actifs sur cet appareil :',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final n in names)
                                ActionChip(
                                  label: Text(n),
                                  onPressed:
                                      busy
                                          ? null
                                          : () =>
                                              setState(() => company.text = n),
                                ),
                            ],
                          ),
                        ],
                        if (name.isNotEmpty && !found)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Aucun assureur actif ne correspond sur cet appareil. La demande peut être enregistrée, mais aucun assureur correspondant ne pourra la traiter ici.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: policy,
                  enabled: !busy,
                  validator: requiredText,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de contrat',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: rate,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Taux estimé (%)',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return n == null || !n.isFinite || n < 0 || n > 100
                        ? 'Saisissez un taux entre 0 et 100.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: start,
                  enabled: !busy,
                  validator: validateInsuranceDate,
                  decoration: const InputDecoration(
                    labelText: 'Début de validité (facultatif)',
                    hintText: 'AAAA-MM-JJ',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: end,
                  enabled: !busy,
                  validator: validateInsuranceDate,
                  decoration: const InputDecoration(
                    labelText: 'Fin de validité (facultatif)',
                    hintText: 'AAAA-MM-JJ',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Informations déclarées, à vérifier auprès de votre organisme. Après une première demande, ces conditions sont conservées pour protéger l’historique.',
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
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
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        InsuranceMotion(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
            onPressed: busy ? null : save,
            child: Text(busy ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
      ],
    ),
  );
}

String? validateInsuranceDate(String? input) {
  if (input == null || input.trim().isEmpty) return null;
  final date = DateTime.tryParse(input.trim());
  return date == null ||
          date.year < 1900 ||
          date.toIso8601String().substring(0, 10) != input.trim()
      ? 'Utilisez AAAA-MM-JJ, par exemple 2026-01-31.'
      : null;
}
