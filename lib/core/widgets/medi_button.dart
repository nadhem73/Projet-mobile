import 'package:flutter/material.dart';

enum MediButtonVariant { filled, outlined, text }

/// Bouton standard MediLink (pleine largeur par défaut, état de chargement).
class MediButton extends StatelessWidget {
  const MediButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = MediButtonVariant.filled,
    this.expand = true,
  });

  const MediButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = MediButtonVariant.outlined;

  const MediButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = MediButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final MediButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spinnerColor = variant == MediButtonVariant.filled ? scheme.onPrimary : scheme.primary;

    final Widget content =
        isLoading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor))
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            );

    final action = isLoading ? null : onPressed;
    final button = switch (variant) {
      MediButtonVariant.filled => FilledButton(onPressed: action, child: content),
      MediButtonVariant.outlined => OutlinedButton(onPressed: action, child: content),
      MediButtonVariant.text => TextButton(onPressed: action, child: content),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
