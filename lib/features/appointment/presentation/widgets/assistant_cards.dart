import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/services/appointment_suggestion_service.dart';
import 'package:medilink/features/appointment/presentation/widgets/doctor_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Couleur et icône de chaque niveau d'urgence.
extension OrientationUrgencyStyle on OrientationUrgency {
  Color get color => switch (this) {
    OrientationUrgency.emergency => AppColors.error,
    OrientationUrgency.soon => AppColors.warning,
    OrientationUrgency.routine => AppColors.success,
  };

  IconData get icon => switch (this) {
    OrientationUrgency.emergency => Icons.emergency_rounded,
    OrientationUrgency.soon => Icons.schedule_rounded,
    OrientationUrgency.routine => Icons.event_available_rounded,
  };
}

/// Bulle de message (assistant à gauche, patient à droite).
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, required this.fromUser});

  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = fromUser ? AppColors.moduleAppointment : theme.colorScheme.surfaceContainerHighest;
    final fg = fromUser ? Colors.white : theme.colorScheme.onSurface;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(fromUser ? AppRadius.lg : 4),
              bottomRight: Radius.circular(fromUser ? 4 : AppRadius.lg),
            ),
          ),
          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
        ),
      ),
    );
  }
}

/// Résultat de l'analyse : spécialité, urgence, raisons (et bouton 190 en cas d'urgence).
class OrientationCard extends StatelessWidget {
  const OrientationCard({super.key, required this.result});

  final OrientationResult result;

  Future<void> _call190(BuildContext context) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: '190'));
    if (!ok && context.mounted) context.showError('Composez le 190 depuis votre téléphone.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = result.urgency;
    return MediCard(
      borderColor: u.color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.moduleAppointment),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Analyse de vos symptômes', style: theme.textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            result.source == OrientationSource.llm ? 'Analysé par l\'IA en ligne' : 'Analyse hors ligne (mots-clés)',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!result.isEmergency)
            InfoRow(icon: Icons.medical_services_outlined, label: 'Spécialité conseillée', value: result.specialty),
          StatusBadge(label: u.label, color: u.color, icon: u.icon),
          if (result.reasons.isNotEmpty || result.redFlags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final f in result.redFlags) _Tag(text: f, color: AppColors.error),
                for (final r in result.reasons) _Tag(text: r, color: AppColors.moduleAppointment),
              ],
            ),
          ],
          if (result.isEmergency) ...[
            const SizedBox(height: AppSpacing.md),
            MediButton(label: 'Appeler le SAMU (190)', icon: Icons.call_rounded, onPressed: () => _call190(context)),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
  );
}

/// Rendez-vous proposé par l'assistant (médecin + date).
class ProposalCard extends StatelessWidget {
  const ProposalCard({super.key, required this.proposal, this.onTapDoctor});

  final DoctorSuggestion proposal;
  final VoidCallback? onTapDoctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = proposal.doctor;
    return MediCard(
      onTap: onTapDoctor,
      child: Row(
        children: [
          MediAvatar(initials: d.initials, size: 48, color: AppColors.moduleAppointment),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.fullName, style: theme.textTheme.titleSmall),
                Text(
                  [d.specialty, if (d.city != null) d.city!, if (d.fee != null) formatFee(d.fee!)].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.event_rounded, size: 16, color: AppColors.moduleAppointment),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        toBeginningOfSentenceCase(DateFormat("EEEE d MMMM 'à' HH:mm", 'fr').format(proposal.firstSlot)),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rendez-vous réservé par l'assistant.
class BookedCard extends StatelessWidget {
  const BookedCard({super.key, required this.appointment, required this.onOpen});

  final Appointment appointment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      color: AppColors.success.withValues(alpha: 0.08),
      borderColor: AppColors.success.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rendez-vous confirmé', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success)),
                Text(appointment.doctorName, style: theme.textTheme.bodyMedium),
                Text(
                  toBeginningOfSentenceCase(DateFormat("EEEE d MMMM 'à' HH:mm", 'fr').format(appointment.dateTime)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('Voir')),
        ],
      ),
    );
  }
}

/// Trois points animés pendant que l'assistant « réfléchit ».
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder:
              (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textMuted.withValues(alpha: ((_anim.value * 3 - i) % 3) < 1 ? 1 : 0.35),
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}
