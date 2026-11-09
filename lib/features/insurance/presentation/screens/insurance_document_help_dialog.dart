import 'package:flutter/material.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/features/insurance/data/insurance_explanation_service.dart';
import 'package:medilink/features/insurance/data/insurance_repository.dart';

/// Consent is explicit because the insurer's free text may contain personal data.
class InsuranceDocumentHelpDialog extends StatefulWidget {
  const InsuranceDocumentHelpDialog({
    super.key,
    required this.repo,
    required this.claimId,
    required this.instruction,
    this.service,
  });
  final InsuranceRepository repo;
  final int claimId;
  final String instruction;
  final InsuranceExplanationService? service;
  @override
  State<InsuranceDocumentHelpDialog> createState() =>
      _InsuranceDocumentHelpDialogState();
}

class _InsuranceDocumentHelpDialogState
    extends State<InsuranceDocumentHelpDialog> {
  late final service = widget.service ?? InsuranceExplanationService();
  bool consent = false;
  bool busy = false;
  String? answer;
  String? error;
  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (!consent || busy) return;
    setState(() {
      busy = true;
      error = null;
      answer = null;
    });
    try {
      if (!widget.repo.isPatient) {
        throw const AppException('Cette action est réservée au patient.');
      }
      final claim = await widget.repo.claim(widget.claimId);
      final dossier = InsuranceDossier.decode(claim['document_path']);
      if (claim['status'] != 'SUBMITTED' ||
          dossier.withdrawn ||
          dossier.requestedDocuments != widget.instruction) {
        throw const AppException(
          'La consigne a changé. Fermez cette fenêtre et vérifiez le dossier.',
        );
      }
      if (!mounted || !widget.repo.isPatient) return;
      final response = await service.explain({
        'task': 'documents',
        'instruction': widget.instruction,
      });
      if (mounted) setState(() => answer = response);
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Impossible de charger cette consigne.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: const Text('Comprendre les pièces demandées'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ce texte sera envoyé à Groq. Il peut contenir des informations personnelles : vérifiez-le avant de continuer.',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: .4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(widget.instruction),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aucune image ni autre donnée du dossier ne sera envoyée.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: consent,
                onChanged:
                    busy
                        ? null
                        : (value) => setState(() => consent = value ?? false),
                title: const Text(
                  'J’accepte l’envoi de cette consigne à Groq.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Text(error!, style: TextStyle(color: theme.colorScheme.error)),
              if (answer != null) ...[
                const SizedBox(height: 14),
                Text('Explication', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SelectableText(answer!),
                const SizedBox(height: 12),
                const Text(
                  'Vérifiez la consigne originale ; l’IA peut se tromper.',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(130, 48)),
          onPressed: consent && !busy ? send : null,
          child: Text(busy ? 'Analyse…' : 'Expliquer'),
        ),
      ],
    );
  }
}
