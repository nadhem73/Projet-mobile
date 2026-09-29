import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/auth/presentation/components/country_picker.dart';
import 'package:medilab_prokit/features/auth/presentation/components/social_account_button.dart';
import 'package:medilab_prokit/features/home/presentation/screens/dashboard_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/forget_password_screen.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/registration_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';
import 'package:medilab_prokit/main.dart';

class MLLoginScreen extends StatefulWidget {
  static String tag = '/MLLoginScreen';

  const MLLoginScreen({super.key});

  @override
  MLLoginScreenState createState() => MLLoginScreenState();
}

class MLLoginScreenState extends State<MLLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _floatController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardSlideAnimation = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _controller.forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 18).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
    init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    changeStatusColor(mlPrimaryColor);
  }

  void _showRoleSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: radius(16)),
        title: Text('Choisir le rôle', style: boldTextStyle(size: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: medicalBluePrimary, size: 28),
              title: Text('Patient', style: boldTextStyle(size: 16)),
              subtitle: Text('Accès aux rendez-vous, dossier médical, ordonnances', style: secondaryTextStyle(size: 12)),
              onTap: () {
                finish(context);
                MLDashboardScreen().launch(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: medicalTealPrimary, size: 28),
              title: Text('Médecin', style: boldTextStyle(size: 16)),
              subtitle: Text('Agenda, consultations, dossiers patients, ordonnances', style: secondaryTextStyle(size: 12)),
              onTap: () {
                finish(context);
                MLDoctorDashboardScreen().launch(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mlPrimaryColor,
      body: Stack(
        children: [
          // Gradient + floating decor header
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [medicalTealPrimary, medicalTealDark, medicalBlueDark],
              ),
            ),
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: -40 + _floatAnimation.value,
                      right: -30,
                      child: _decorCircle(140, medicalWhite, 0.08),
                    ),
                    Positioned(
                      top: 150 - _floatAnimation.value,
                      left: -40,
                      child: _decorCircle(110, medicalTealLight, 0.15),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 250),
            height: context.height(),
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: radiusOnly(topRight: 32),
              backgroundColor: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, -8),
                  blurRadius: 32,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _cardSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _cardSlideAnimation.value),
                  child: child,
                );
              },
              child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  60.height,
                  Text(mlLoginTitle, style: secondaryTextStyle(size: 16)),
                  16.height,
                  Row(
                    children: [
                      MLCountryPickerComponent(),
                      16.width,
                      AppTextField(
                        textFieldType: TextFieldType.PHONE,
                        decoration: InputDecoration(
                          labelText: mlPhoneNumber,
                          labelStyle: secondaryTextStyle(size: 16),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: mlColorLightGrey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ).expand(),
                    ],
                  ),
                  16.height,
                  AppTextField(
                    textFieldType: TextFieldType.PASSWORD,
                    decoration: InputDecoration(
                      labelText: mlPassword,
                      labelStyle: secondaryTextStyle(size: 16),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: appStore.isDarkModeOn ? white : black,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: mlColorLightGrey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  8.height,
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      mlForgetPasswordQuestion,
                      style: secondaryTextStyle(size: 16),
                    ).onTap(() {
                      MLForgetPasswordScreen().launch(context);
                    }),
                  ),
                  24.height,
                  AppButton(
                    color: mlPrimaryColor,
                    width: double.infinity,
                    onTap: () {
                      _showRoleSelectionDialog(context);
                    },
                    child: Text(mlLogin, style: boldTextStyle(color: white)),
                  ),
                  22.height,
                  Text(
                    mlLoginWith,
                    style: secondaryTextStyle(size: 16),
                  ).center(),
                  22.height,
                  MLSocialAccountsComponent(),
                  22.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mlDontHaveAccount, style: primaryTextStyle()),
                      8.width,
                      Text(
                        mlRegister,
                        style: boldTextStyle(
                          color: mlColorBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ).onTap(() {
                        MLRegistrationScreen().launch(context);
                      }),
                    ],
                  ),
                  32.height,
                ],
              ).paddingOnly(left: 16, right: 16),
              ),
            ),
          ),
          FadeTransition(
            opacity: _logoFadeAnimation,
            child: Container(
              margin: EdgeInsets.only(top: 75),
              width: context.width(),
              child: commonCachedNetworkImage(
                mlIcRegisterIndicator,
                alignment: Alignment.center,
                width: 200,
                height: 200,
              ),
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
