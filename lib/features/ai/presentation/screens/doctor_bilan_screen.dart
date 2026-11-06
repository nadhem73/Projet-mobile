import 'package:flutter/material.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/presentation/controllers/doctor_bilans_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/bilan_header.dart';
import 'package:medilink/features/ai/presentation/widgets/result_tile.dart';

/// Côté médecin : lecture d'un bilan reçu (marqué « Lu » à l'ouverture),
/// puis « Marquer comme traité » avec un commentaire pour le patient.
class DoctorBilanScreen extends StatefulWidget {
  const DoctorBilanScreen({super.key, required this.bilanId});

  final String bilanId;

  @override
  State<DoctorBilanScreen> createState() => _DoctorBilanScreenState();
}

class _DoctorBilanScreenState extends State<DoctorBilanScreen> {
  late final _controller = getIt<DoctorBilanController>()..load(widget.bilanId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markTreated() async {
    final comment = await showDialog<String>(context: context, builder: (_) => const _CommentDialog());
    if (comment == null || !mounted) return;
    final error = await _controller.markTreated(comment);
    if (!mounted) return;
    error == null ? context.showSuccess('Le patient a été prévenu') : context.showError(error);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final bilan = c.bilan;
        return Scaffold(
          appBar: AppBar(title: Text(bilan?.patientName ?? 'Bilan')),
          body:
              c.isLoading && bilan == null
                  ? const LoadingView()
                  : c.error != null
                  ? EmptyState.error(c.error!, onRetry: () => c.load(widget.bilanId))
                  : bilan == null
                  ? const SizedBox.shrink()
                  : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      BilanHeader(bilan: bilan, showPatient: true),
                      const SizedBox(height: AppSpacing.md),
                      for (final r in bilan.resultats)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ResultTile(result: r, showPrevious: bilan.format == BilanFormat.ancienPatient),
                        ),
                    ],
                  ),
          bottomNavigationBar:
              bilan == null || bilan.reviewStatus == ReviewStatus.traite
                  ? null
                  : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: MediButton(
                        label: 'Marquer comme traité',
                        icon: Icons.task_alt_rounded,
                        isLoading: c.isSaving,
                        onPressed: _markTreated,
                      ),
                    ),
                  ),
        );
      },
    );
  }
}

/// Commentaire du médecin. Le dialogue possède son [TextEditingController] et
/// ne le libère qu'à sa propre destruction : le champ reste affiché pendant
/// l'animation de fermeture, le libérer plus tôt fait planter l'écran.
class _CommentDialog extends StatefulWidget {
  const _CommentDialog();

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bilan examiné'),
      content: TextField(
        controller: _input,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Commentaire pour le patient (facultatif)',
          hintText: 'Ex. : résultats rassurants, contrôle de la glycémie dans 3 mois.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, _input.text), child: const Text('Envoyer au patient')),
      ],
    );
  }
}
