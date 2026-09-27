import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/home/data/walkthrough_model.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';
import 'package:medilab_prokit/main.dart';

import 'package:medilab_prokit/features/home/presentation/screens/dashboard_screen.dart';

class MLWalkThroughScreen extends StatefulWidget {
  static String tag = '/MLWalkThroughScreen';

  const MLWalkThroughScreen({super.key});

  @override
  MLWalkThroughScreenState createState() => MLWalkThroughScreenState();
}

class MLWalkThroughScreenState extends State<MLWalkThroughScreen>
    with TickerProviderStateMixin {
  PageController controller = PageController();

  List<MLWalkThroughData> list = mlWalkThroughDataList();

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    init();
  }

  Future<void> init() async {
    changeStatusColor(mlPrimaryColor);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
    changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mlPrimaryColor,
      body: Stack(
        children: [
          // Animated decorative background circles
          AnimatedBuilder(
            animation: Listenable.merge([_floatAnimation, _pulseController]),
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: -60 + _floatAnimation.value,
                    left: -40,
                    child: _decorCircle(180, medicalWhite, 0.08),
                  ),
                  Positioned(
                    top: 120 - _floatAnimation.value,
                    right: -70,
                    child: _decorCircle(220, medicalTealLight, 0.12),
                  ),
                  Positioned(
                    bottom: 160 + _floatAnimation.value,
                    left: -50,
                    child: _decorCircle(
                      140 * (1 + _pulseController.value * 0.15),
                      medicalWhite,
                      0.06,
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: -30,
                    child: _decorCircle(160, careCoralLight, 0.10),
                  ),
                ],
              );
            },
          ),
          PageView(
            controller: controller,
            children: list.map(
              (e) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 3D circular illustration card
                    Container(
                      decoration: boxDecorationWithRoundedCorners(
                        boxShape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [medicalTealLight, medicalTealPrimary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(0, 20),
                            blurRadius: 40,
                          ),
                          BoxShadow(
                            color: medicalWhite.withValues(alpha: 0.2),
                            offset: const Offset(0, -6),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      height: 270,
                      width: 230,
                      child: commonCachedNetworkImage(
                        e.imagePath.validate(),
                        fit: BoxFit.contain,
                      ),
                    ).paddingSymmetric(vertical: 8),
                    48.height,
                    Text(
                      e.title.validate(),
                      style: boldTextStyle(size: 24, color: whiteColor),
                    ),
                    16.height,
                    Text(
                      e.subtitle.validate(),
                      style: secondaryTextStyle(color: medicalWhite),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ).paddingAll(16.0);
              },
            ).toList(),
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DotIndicator(pageController: controller, pages: list),
                AppButton(
                  onTap: () {
                    MLDashboardScreen().launch(context);
                  },
                  color: white,
                  elevation: 8,
                  child: Text(mlGetStarted, style: boldTextStyle(color: mlPrimaryColor)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Text(mlSkip, style: boldTextStyle(color: whiteColor)).paddingOnly(top: 8, right: 8).onTap(
              () {
                MLDashboardScreen().launch(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}
