import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/features/home/presentation/screens/dashboard_screen.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:nb_utils/nb_utils.dart';

class MLSplashScreen extends StatefulWidget {
  const MLSplashScreen({super.key});

  @override
  MLSplashScreenState createState() => MLSplashScreenState();
}

class MLSplashScreenState extends State<MLSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _ringAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await 3.seconds.delay;
    if (!mounted) return;
    finish(context);
    MLDashboardScreen().launch(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [medicalTealPrimary, medicalTealDark, medicalBlueDark],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Breathing outer glow ring
                Container(
                  width: 320 * _ringAnimation.value,
                  height: 320 * _ringAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: medicalWhite.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 260 * _ringAnimation.value,
                  height: 260 * _ringAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: medicalWhite.withValues(
                      alpha: 0.08 * _glowAnimation.value,
                    ),
                  ),
                ),
                // Animated logo with 3D depth shadow
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.25 * _glowAnimation.value,
                            ),
                            offset: const Offset(0, 16),
                            blurRadius: 40,
                          ),
                          BoxShadow(
                            color: medicalWhite.withValues(
                              alpha: 0.3 * _glowAnimation.value,
                            ),
                            offset: const Offset(0, -4),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        mlIcMedilabLogo,
                        height: 150,
                        width: 150,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                // Loading indicator
                Positioned(
                  bottom: 80,
                  child: Opacity(
                    opacity: _glowAnimation.value,
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          medicalWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
