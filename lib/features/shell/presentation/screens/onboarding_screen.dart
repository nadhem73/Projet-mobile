import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';

/// Présentation de la plateforme au premier lancement.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.calendar_month_rounded,
      AppColors.moduleAppointment,
      'Rendez-vous en quelques secondes',
      'Trouvez un médecin par spécialité, consultez ses disponibilités et réservez votre créneau.',
    ),
    (
      Icons.folder_shared_rounded,
      AppColors.primary,
      'Votre dossier médical, toujours avec vous',
      'Allergies, groupe sanguin, traitements, ordonnances et bilans réunis au même endroit.',
    ),
    (
      Icons.health_and_safety_rounded,
      AppColors.moduleInsurance,
      'Assurance et pharmacie connectées',
      'Suivez vos remboursements et retrouvez vos médicaments à partir de vos ordonnances.',
    ),
    (
      Icons.auto_awesome_rounded,
      AppColors.accent,
      'Un assistant intelligent',
      'Analysez vos bilans et obtenez une orientation vers la bonne spécialité. Il ne remplace pas votre médecin.',
    ),
  ];

  Future<void> _finish() async {
    await getIt<SessionService>().markOnboardingDone();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(
                children: [
                  const MediLogo(size: 36),
                  const SizedBox(width: AppSpacing.sm),
                  Text('MediLink', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  if (!isLast) TextButton(onPressed: _finish, child: const Text('Passer')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (icon, color, title, text) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 56, color: color),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          text,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? theme.colorScheme.primary : theme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: MediButton(
                label: isLast ? 'Commencer' : 'Suivant',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
