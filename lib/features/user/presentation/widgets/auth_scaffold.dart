import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/medi_logo.dart';

/// Mise en page commune des écrans d'authentification : bandeau de marque
/// en haut, formulaire sur une feuille arrondie qui le recouvre légèrement.
///
/// Toute la page défile (en-tête compris) : rien ne déborde sur les petits
/// écrans ou quand le clavier est ouvert.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child, this.onBack});

  final String title;
  final String subtitle;
  final Widget child;

  /// Affiche une flèche retour si renseigné.
  final VoidCallback? onBack;

  /// Hauteur dont la feuille recouvre le bandeau.
  static const double _overlap = AppRadius.xl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl + _overlap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (onBack != null) ...[
                              IconButton(
                                tooltip: 'Retour',
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            const MediLogo(size: 40, onDark: true),
                            const SizedBox(width: AppSpacing.sm),
                            Text('MediLink', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(title, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              // La feuille remonte sur le bandeau (le fond du Scaffold a la même
              // couleur, la page reste donc unie sous le formulaire).
              Transform.translate(
                offset: const Offset(0, -_overlap),
                // Material (et non Container) : les ListTile / InkWell du formulaire
                // dessinent leurs effets de toucher sur ce fond.
                child: Material(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: AppRadius.sheet,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
                    child: SafeArea(top: false, child: child),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
