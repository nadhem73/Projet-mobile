import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/features/appointment/data/models/assistant_message.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/presentation/controllers/orientation_assistant_controller.dart';
import 'package:medilink/features/appointment/presentation/widgets/assistant_cards.dart';

/// Assistant d'orientation : le patient décrit ses symptômes, l'assistant conseille
/// une spécialité et lui propose de réserver un rendez-vous.
class OrientationAssistantScreen extends StatefulWidget {
  const OrientationAssistantScreen({super.key});

  @override
  State<OrientationAssistantScreen> createState() => _OrientationAssistantScreenState();
}

class _OrientationAssistantScreenState extends State<OrientationAssistantScreen> {
  late final OrientationAssistantController _controller = getIt<OrientationAssistantController>()..start();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Exemples proposés avant le premier message.
  static const _examples = [
    "J'ai des palpitations et je m'essouffle vite",
    "J'ai des boutons qui me grattent",
    "J'ai mal à l'oreille depuis 3 jours",
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_scrollToBottom)
      ..dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    _input.clear();
    await _controller.send(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Quel médecin consulter ?'), Text('Assistant IA', style: TextStyle(fontSize: 12))],
        ),
      ),
      body: Column(
        children: [
          const _Disclaimer(),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final c = _controller;
                final items = <Widget>[
                  for (var i = 0; i < c.messages.length; i++) ..._messageWidgets(c.messages[i]),
                  if (c.isBusy) const TypingIndicator(),
                  if (!c.isBusy) ..._quickReplies(c),
                ];
                return ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => items[i],
                );
              },
            ),
          ),
          _InputBar(controller: _input, onSend: _send, busy: _controller),
        ],
      ),
    );
  }

  List<Widget> _messageWidgets(AssistantMessage m) => [
    ChatBubble(text: m.text, fromUser: m.fromUser),
    if (m.orientation != null) OrientationCard(result: m.orientation!),
    if (m.proposal != null)
      ProposalCard(
        proposal: m.proposal!,
        onTapDoctor: () => context.push(AppointmentRoutes.doctor(m.proposal!.doctor.doctorId)),
      ),
    if (m.booked != null)
      BookedCard(appointment: m.booked!, onOpen: () => context.push(AppointmentRoutes.appointment(m.booked!.id!))),
  ];

  /// Boutons de réponse rapide sous le dernier message de l'assistant (ou exemples au début).
  List<Widget> _quickReplies(OrientationAssistantController c) {
    final last = c.messages.isEmpty ? null : c.messages.last;
    final replies =
        c.messages.length == 1
            ? _examples
            : (last != null && !last.fromUser)
            ? last.quickReplies
            : const <String>[];
    if (replies.isEmpty) return const [];
    return [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final r in replies)
            ActionChip(
              label: Text(r),
              avatar: r == OrientationAssistantController.yesReply ? const Icon(Icons.check_rounded, size: 18) : null,
              onPressed: () => _send(r),
            ),
        ],
      ),
    ];
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    color: AppColors.info.withValues(alpha: 0.08),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(OrientationResult.disclaimer, style: Theme.of(context).textTheme.bodySmall)),
      ],
    ),
  );
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend, required this.busy});

  final TextEditingController controller;
  final Future<void> Function([String?]) onSend;
  final OrientationAssistantController busy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        child: ListenableBuilder(
          listenable: busy,
          builder:
              (context, _) => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: const InputDecoration(hintText: 'Décrivez vos symptômes…'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    tooltip: 'Envoyer',
                    onPressed: busy.isBusy ? null : () => onSend(),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
