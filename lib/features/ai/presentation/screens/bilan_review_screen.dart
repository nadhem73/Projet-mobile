import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/ai_module.dart';
import 'package:medilink/features/ai/data/models/bilan_enums.dart';
import 'package:medilink/features/ai/data/models/doctor_option.dart';
import 'package:medilink/features/ai/data/models/scan_bilan.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_review_controller.dart';
import 'package:medilink/features/ai/presentation/widgets/bilan_header.dart';
import 'package:medilink/features/ai/presentation/widgets/doctor_picker_sheet.dart';
import 'package:medilink/features/ai/presentation/widgets/result_tile.dart';

/// Côté patient, après le scan :
/// 1. il vérifie les valeurs extraites ; 2. il corrige celles mal lues ;
/// 3. il choisit un médecin → le bilan est validé et envoyé.
///
/// Un bilan validé s'affiche en lecture seule (détail).
class BilanReviewScreen extends StatefulWidget {
  const BilanReviewScreen({super.key, required this.bilanId});

  final String bilanId;

  @override
  State<BilanReviewScreen> createState() => _BilanReviewScreenState();
}

class _BilanReviewScreenState extends State<BilanReviewScreen> {
  late final _controller = getIt<BilanReviewController>()..load(widget.bilanId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Choix du médecin → confirmation → validation + envoi.
  Future<void> _validateAndSend() async {
    final doctor = await showDoctorPicker(context, _controller);
    if (doctor == null || !mounted) return;
    final alreadyValidated = _controller.bilan?.isConfirmed ?? false;
    final ok = await _confirmDialog(
      title: 'Envoyer à ${doctor.displayName} ?',
      message:
          alreadyValidated
              ? 'Le médecin pourra consulter ce bilan et vous faire un retour.'
              : 'Le bilan sera validé tel quel (les valeurs ne seront plus modifiables), '
                  'puis envoyé à ${doctor.displayName}.',
      action: 'Envoyer',
      icon: Icons.send_rounded,
    );
    if (!ok || !mounted) return;
    await _report(_controller.confirmAndSend(doctor), success: _sentMessage(doctor));
  }

  Future<void> _validateOnly() async {
    final ok = await _confirmDialog(
      title: 'Valider sans envoyer ?',
      message: 'Les valeurs ne seront plus modifiables. Vous pourrez envoyer le bilan à un médecin plus tard.',
      action: 'Valider',
      icon: Icons.verified_rounded,
    );
    if (ok && mounted) await _report(_controller.confirm(), success: 'Bilan validé');
  }

  String _sentMessage(DoctorOption d) => 'Bilan envoyé à ${d.displayName}';

  Future<void> _report(Future<String?> action, {required String success}) async {
    final error = await action;
    if (!mounted) return;
    error == null ? context.showSuccess(success) : context.showError(error);
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String action,
    required IconData icon,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              icon: Icon(icon),
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
              ],
            ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bilan = _controller.bilan;
        return Scaffold(
          appBar: AppBar(
            title: Text(bilan == null || bilan.isConfirmed ? 'Détail du bilan' : 'Vérifier le bilan'),
            actions: [
              if (bilan != null && bilan.isConfirmed)
                IconButton(
                  tooltip: 'Évolution',
                  icon: const Icon(Icons.show_chart_rounded),
                  onPressed: () => context.push(AiRoutes.evolution),
                ),
            ],
          ),
          body: _body(bilan),
          bottomNavigationBar: bilan == null ? null : _actions(bilan),
        );
      },
    );
  }

  Widget _body(ScanBilan? bilan) {
    if (_controller.isLoading && bilan == null) return const LoadingView();
    if (_controller.error != null) {
      return EmptyState.error(_controller.error!, onRetry: () => _controller.load(widget.bilanId));
    }
    if (bilan == null) return const SizedBox.shrink();
    final editable = !_controller.isReadOnly;
    final ancien = bilan.format == BilanFormat.ancienPatient;
    final toCheck = bilan.resultats.where((r) => r.needsCheck).length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (editable) ...[const _Steps(), const SizedBox(height: AppSpacing.md)],
        BilanHeader(bilan: bilan),
        const SizedBox(height: AppSpacing.md),
        if (editable)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _Hint(
              icon: Icons.edit_note_rounded,
              color: toCheck > 0 ? AppColors.accent : AppColors.info,
              text:
                  toCheck > 0
                      ? '$toCheck valeur${toCheck > 1 ? 's' : ''} « à vérifier » : comparez avec votre document '
                          'et touchez ✎ pour corriger.'
                      : 'Comparez chaque valeur avec votre document ; touchez ✎ pour corriger une erreur de lecture.',
            ),
          ),
        if (bilan.resultats.isEmpty)
          const EmptyState(icon: Icons.search_off_rounded, title: 'Aucune valeur extraite')
        else
          for (final r in bilan.resultats)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ResultTile(
                key: ValueKey(r.id),
                result: r,
                showPrevious: ancien,
                onSave: editable ? (v) => _controller.editResult(r.id, valeur: v) : null,
              ),
            ),
      ],
    );
  }

  Widget? _actions(ScanBilan bilan) {
    if (bilan.doctorId != null) return null; // déjà envoyé : le statut s'affiche dans l'en-tête
    final busy = _controller.isSaving;
    final empty = bilan.resultats.isEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediButton(
              label: bilan.isConfirmed ? 'Envoyer à un médecin' : 'Valider et envoyer à un médecin',
              icon: Icons.send_rounded,
              isLoading: busy,
              onPressed: empty || busy ? null : _validateAndSend,
            ),
            if (!bilan.isConfirmed)
              MediButton.text(label: 'Valider sans envoyer', onPressed: empty || busy ? null : _validateOnly),
          ],
        ),
      ),
    );
  }
}

/// Rappel des 3 étapes après un scan.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    Widget step(int n, String label, IconData icon) => Expanded(
      child: Column(
        children: [
          CircleAvatar(radius: 14, backgroundColor: AppColors.primarySurface, child: Icon(icon, size: 16)),
          const SizedBox(height: AppSpacing.xs),
          Text('$n. $label', style: style, textAlign: TextAlign.center),
        ],
      ),
    );
    return Row(
      children: [
        step(1, 'Vérifier', Icons.visibility_rounded),
        step(2, 'Corriger', Icons.edit_rounded),
        step(3, 'Envoyer', Icons.send_rounded),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}
