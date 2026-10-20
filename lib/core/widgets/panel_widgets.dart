import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/display_widgets.dart';

/// En-tête coloré en haut de chaque panel (patient, médecin, pharmacien, assureur).
///
/// À placer en premier élément d'un écran sans AppBar.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    required this.initials,
    this.greeting,
    this.subtitle,
    this.color,
    this.avatar,
    this.onAvatarTap,
    this.actions = const [],
    this.bottom,
  });

  /// Nom affiché en grand.
  final String title;
  final String initials;

  /// Petite ligne au-dessus du nom (ex. « Bonjour, »).
  final String? greeting;

  /// Ligne sous le nom (ex. spécialité, nom de la pharmacie).
  final String? subtitle;

  /// Couleur du rôle. Par défaut : dégradé de la marque.
  final Color? color;

  /// Remplace le cercle d'initiales (ex. photo de profil).
  final Widget? avatar;
  final VoidCallback? onAvatarTap;
  final List<Widget> actions;

  /// Contenu optionnel sous l'en-tête (ex. carte de résumé).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color;
    final gradient =
        tint == null
            ? AppColors.brandGradient
            : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(tint, Colors.black, 0.45)!, tint],
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: onAvatarTap,
                      customBorder: const CircleBorder(),
                      child:
                          avatar ??
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              initials.isEmpty ? '?' : initials,
                              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (greeting != null)
                            Text(greeting!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
                if (bottom != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: bottom!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton icône blanc pour les [PanelHeader.actions].
class PanelHeaderAction extends StatelessWidget {
  const PanelHeaderAction({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon, color: Colors.white));
  }
}

/// Tuile d'accès à une fonctionnalité dans une grille de panel.
class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.description,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? description;

  /// Texte d'un petit badge (ex. « Bientôt »).
  final String? badge;
  final VoidCallback? onTap;

  /// Hauteur conseillée dans une grille, selon la présence d'une description.
  static const double compactHeight = 112;
  static const double detailedHeight = 150;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card, side: BorderSide(color: theme.dividerColor)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  if (badge != null) StatusBadge(label: badge!, color: AppColors.accent),
                ],
              ),
              const Spacer(),
              Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
