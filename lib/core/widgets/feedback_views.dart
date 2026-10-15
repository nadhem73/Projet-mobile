import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';

/// Indicateur de chargement centré.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// État vide / erreur avec action optionnelle.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  factory EmptyState.error(String message, {VoidCallback? onRetry}) => EmptyState(
    icon: Icons.error_outline_rounded,
    title: 'Une erreur est survenue',
    message: message,
    actionLabel: onRetry != null ? 'Réessayer' : null,
    onAction: onRetry,
    color: AppColors.error,
  );

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: tint),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Remplace les anciens écrans « version lite » du template : fonctionnalité
/// pas encore développée par le module concerné.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, this.title = 'Bientôt disponible', this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.construction_rounded,
      title: title,
      message: message ?? 'Cette fonctionnalité est en cours de développement.',
      color: AppColors.accent,
    );
  }
}

/// Raccourcis pour afficher un message à l'utilisateur.
extension FeedbackX on BuildContext {
  void showSuccess(String message) => _snack(message, AppColors.success, Icons.check_circle_rounded);

  void showError(String message) => _snack(message, AppColors.error, Icons.error_rounded);

  void showInfo(String message) => _snack(message, AppColors.info, Icons.info_rounded);

  void _snack(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
