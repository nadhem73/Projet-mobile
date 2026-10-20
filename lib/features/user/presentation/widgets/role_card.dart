import 'package:flutter/material.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_dimens.dart';

/// Carte de choix du rôle à l'inscription.
class RoleCard extends StatelessWidget {
  const RoleCard({super.key, required this.role, required this.selected, required this.onTap});

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = role.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.08) : theme.colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: selected ? color : theme.dividerColor, width: selected ? 2 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(role.icon, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.label, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        role.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? color : theme.dividerColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
