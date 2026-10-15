import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/widgets/medi_logo.dart';

/// Écran de démarrage : affiche le logo puis redirige selon la session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), _redirect);
  }

  void _redirect() {
    if (!mounted) return;
    final session = getIt<SessionService>();
    final user = session.currentUser;
    if (user != null) {
      context.go(user.isDoctor ? AppRoutes.doctorHome : AppRoutes.patientHome);
    } else {
      context.go(session.onboardingDone ? AppRoutes.login : AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(fade),
                  child: const MediLogo(size: 96, showWordmark: true, onDark: true),
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre santé, connectée.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
