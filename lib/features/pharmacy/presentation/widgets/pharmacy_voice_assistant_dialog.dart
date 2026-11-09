import 'package:flutter/material.dart';
import '../../../../core/session/user_role.dart';
import '../../../../core/session/user_role_style.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../data/services/pharmacy_voice_nlp_service.dart';
import '../controllers/pharmacy_voice_assistant_controller.dart';

/// Modal interactif de l'Assistant Vocal Officine
class PharmacyVoiceAssistantDialog extends StatefulWidget {
  const PharmacyVoiceAssistantDialog({
    super.key,
    required this.controller,
  });

  final PharmacyVoiceAssistantController controller;

  static Future<void> show(
    BuildContext context, {
    required PharmacyVoiceAssistantController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PharmacyVoiceAssistantDialog(controller: controller),
    );
  }

  @override
  State<PharmacyVoiceAssistantDialog> createState() =>
      _PharmacyVoiceAssistantDialogState();
}

class _PharmacyVoiceAssistantDialogState
    extends State<PharmacyVoiceAssistantDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final TextEditingController _textInputController;
  bool _showKeyboardInput = false;

  final List<String> _quickSuggestions = [
    'Combien de Doliprane en stock ?',
    'Change le prix du Doliprane à 5 DT',
    'Déplace le Spasfon au Rayon B',
    'Mets le stock de Panadol à 25',
    'Où est rangé le Spasfon ?',
    'J\'ai vendu 2 boîtes de Panadol',
    'Ajoute 5 boîtes de Doliprane',
    'Quels médicaments sont en rupture ?',
    'Qu\'est-ce qui expire bientôt ?',
    'Quel est le générique du Doliprane ?',
    'Quel est le prix du Spasfon ?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _textInputController = TextEditingController();

    widget.controller.initialize().then((_) {
      if (mounted) {
        widget.controller.startListening();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textInputController.dispose();
    widget.controller.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = UserRole.pharmacist.color;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assistant Vocal Officine',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'IA mains-libres pour votre stock',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // TTS toggle button
                        IconButton(
                          tooltip: ctrl.isTtsEnabled
                              ? 'Désactiver la voix'
                              : 'Activer la voix',
                          icon: Icon(
                            ctrl.isTtsEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: ctrl.isTtsEnabled
                                ? primaryColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: ctrl.toggleTts,
                        ),
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Main Voice Pulsing & Interaction Hub
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      children: [
                        // Pulsing Waveform Microphone
                        GestureDetector(
                          onTap: () {
                            if (ctrl.isListening) {
                              ctrl.stopListening();
                            } else {
                              ctrl.startListening();
                            }
                          },
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final wave = ctrl.isListening || ctrl.isSpeaking
                                  ? _pulseController.value
                                  : 0.0;
                              return Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ctrl.isListening
                                      ? primaryColor.withValues(alpha: 0.15 + wave * 0.15)
                                      : (ctrl.isSpeaking
                                          ? AppColors.primary.withValues(alpha: 0.15 + wave * 0.15)
                                          : theme.colorScheme.surfaceContainerHighest),
                                  boxShadow: (ctrl.isListening || ctrl.isSpeaking)
                                      ? [
                                          BoxShadow(
                                            color: (ctrl.isListening ? primaryColor : AppColors.primary)
                                                .withValues(alpha: 0.3 * wave),
                                            blurRadius: 24 * wave + 10,
                                            spreadRadius: 8 * wave,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: ctrl.isListening
                                            ? [primaryColor, primaryColor.withValues(alpha: 0.8)]
                                            : (ctrl.isSpeaking
                                                ? [AppColors.primary, AppColors.primaryLight]
                                                : [theme.colorScheme.outlineVariant, theme.colorScheme.outline]),
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      ctrl.isListening
                                          ? Icons.mic_rounded
                                          : (ctrl.isSpeaking
                                              ? Icons.graphic_eq_rounded
                                              : Icons.mic_none_rounded),
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status caption
                        Text(
                          ctrl.isListening
                              ? 'Écoute en cours... parlez'
                              : (ctrl.isSpeaking
                                  ? 'Réponse vocale en cours...'
                                  : (ctrl.isProcessing
                                      ? 'Analyse IA en cours...'
                                      : 'Appuyez sur le micro pour parler')),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ctrl.isListening
                                ? primaryColor
                                : (ctrl.isSpeaking
                                    ? AppColors.primary
                                    : theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live Transcript Bubble (if spoken or processing)
                  if (ctrl.voiceTranscript.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '"${ctrl.voiceTranscript}"',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Result Card (when an intent was processed)
                  if (ctrl.lastResult != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildResultCard(context, ctrl.lastResult!, ctrl),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error notification (if any)
                  if (ctrl.speechError != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ctrl.speechError!,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Keyboard input fallback toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggestions rapides :',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: Icon(
                            _showKeyboardInput ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                            size: 18,
                          ),
                          label: Text(_showKeyboardInput ? 'Masquer clavier' : 'Saisir texte'),
                          onPressed: () {
                            setState(() {
                              _showKeyboardInput = !_showKeyboardInput;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Text input field (if toggled)
                  if (_showKeyboardInput) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textInputController,
                              decoration: InputDecoration(
                                hintText: 'Ex: Combien de Doliprane ?',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  ctrl.processCommand(val.trim());
                                  _textInputController.clear();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(primaryColor),
                            ),
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            onPressed: () {
                              final text = _textInputController.text.trim();
                              if (text.isNotEmpty) {
                                ctrl.processCommand(text);
                                _textInputController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Quick Suggestion Chips
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickSuggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final suggestion = _quickSuggestions[i];
                        return ActionChip(
                          avatar: const Icon(Icons.touch_app_rounded, size: 14),
                          label: Text(
                            suggestion,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          onPressed: () {
                            ctrl.processCommand(suggestion);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    VoiceParseResult result,
    PharmacyVoiceAssistantController ctrl,
  ) {
    final theme = Theme.of(context);
    final primaryColor = UserRole.pharmacist.color;

    final (badgeLabel, badgeColor, badgeIcon) = switch (result.intent) {
      VoiceIntentType.checkStock => ('Stock vérifié', primaryColor, Icons.inventory_2_rounded),
      VoiceIntentType.locateMedicine => ('Emplacement', Colors.blue, Icons.place_rounded),
      VoiceIntentType.adjustStockDecrement => ('Décrémenté', Colors.orange, Icons.remove_circle_outline_rounded),
      VoiceIntentType.adjustStockIncrement => ('Incrémenté', Colors.green, Icons.add_circle_outline_rounded),
      VoiceIntentType.setStockQuantity => ('Stock réglé', Colors.indigo, Icons.edit_note_rounded),
      VoiceIntentType.updatePrice => ('Prix modifié', Colors.purple, Icons.price_change_rounded),
      VoiceIntentType.updateLocation => ('Déplacé', Colors.deepOrange, Icons.move_to_inbox_rounded),
      VoiceIntentType.checkPrice => ('Prix', Colors.purple, Icons.payments_outlined),
      VoiceIntentType.checkExpiry => ('Péremption', Colors.amber.shade800, Icons.event_busy_rounded),
      VoiceIntentType.checkStockout => ('Rupture', Colors.red, Icons.warning_amber_rounded),
      VoiceIntentType.findGeneric => ('Générique / Substitut', Colors.teal, Icons.swap_horiz_rounded),
      VoiceIntentType.unknown => ('Non compris', Colors.grey, Icons.help_outline_rounded),
    };

    return Container(
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Intent
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (result.actionDetails != null)
                Text(
                  result.actionDetails!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Spoken Response Text
          Text(
            result.spokenResponse,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),

          // Matched Medicine Thumbnail & Details
          if (result.matchedItem != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.medication_rounded, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.matchedItem!.medicineName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (result.matchedItem!.dci != null)
                          Text(
                            result.matchedItem!.dci!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${result.matchedItem!.quantity} en stock',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: result.matchedItem!.isOutOfStock
                              ? Colors.red
                              : (result.matchedItem!.isLowStock
                                  ? Colors.orange
                                  : primaryColor),
                        ),
                      ),
                      if (result.matchedItem!.shelfLocation != null)
                        Text(
                          result.matchedItem!.shelfLocation!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Undo Button (if quantity was just updated)
          if (ctrl.canUndo &&
              (result.intent == VoiceIntentType.adjustStockDecrement ||
                  result.intent == VoiceIntentType.adjustStockIncrement)) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade800),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Annuler l\'action'),
                  onPressed: ctrl.undoLastAction,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
