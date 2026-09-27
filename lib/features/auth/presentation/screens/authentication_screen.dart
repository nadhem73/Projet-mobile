import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';
import 'package:medilab_prokit/main.dart';
import 'package:otp_text_field/otp_text_field.dart' as otp;
import 'package:otp_text_field/style.dart';

import 'package:medilab_prokit/features/auth/presentation/screens/login_screen.dart';

class MLAuthenticationScreen extends StatefulWidget {
  static String tag = '/MLAuthenticationScreen';

  const MLAuthenticationScreen({super.key});

  @override
  MLAuthenticationScreenState createState() => MLAuthenticationScreenState();
}

class MLAuthenticationScreenState extends State<MLAuthenticationScreen> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double buttonOpacity = 1.0;
  double buttonHeight = 50.0;
  double containerOpacity = 0.0;
  String? phoneNumber = '+34 409 5446 54664';

  Duration get duration => controller.duration! * controller.value;

  bool get expired => duration.inSeconds == 0;
  int endTime = DateTime.now().millisecond + 1000 * 30;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    );
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void dispose() {
    super.dispose();
    changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(top: 24.0),
            height: context.height(),
            decoration: boxDecorationWithRoundedCorners(backgroundColor: context.cardColor),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  64.height,
                  Text(mlEnterCode, style: boldTextStyle(size: 24)),
                  8.height,
                  RichTextWidget(list: [
                    TextSpan(text: mlAuthenticationMsg, style: secondaryTextStyle()),
                    TextSpan(text: phoneNumber!, style: boldTextStyle(color: mlColorDarkBlue)),
                  ]),
                  16.height,
                  otpField(),
                  24.height,
                  Row(
                    children: [
                      Text(mlHaveNoCode, style: primaryTextStyle()),
                      8.width,
                      Text(
                        'Re-send',
                        style: boldTextStyle(color: mlColorDarkBlue, decoration: TextDecoration.underline),
                      ),
                      Text('01:58', textAlign: TextAlign.right).expand()
                    ],
                  ),
                  24.height,
                  SizedBox(
                    height: buttonHeight,
                    child: AppButton(
                      width: double.infinity,
                      color: mlColorDarkBlue,
                      onTap: () {
                        setState(() {
                          buttonOpacity = 0.0;
                          buttonHeight = 0.0;
                          containerOpacity = 1.0;
                        });
                      },
                      child: Text(mlDone, style: boldTextStyle(color: white)),
                    ),
                  ).opacity(opacity: buttonOpacity),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Divider(height: 0.5),
                      32.height,
                      Text(mlAddPassword, style: boldTextStyle(size: 20)),
                      8.height,
                      AppTextField(
                        textFieldType: TextFieldType.PASSWORD,
                        decoration: InputDecoration(
                          labelText: mlPassword,
                          labelStyle: secondaryTextStyle(size: 16),
                          prefixIcon: Icon(Icons.lock_outline, size: 20, color: appStore.isDarkModeOn ? white : black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: mlColorLightGrey.withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                      16.height,
                      AppTextField(
                        textFieldType: TextFieldType.PASSWORD,
                        decoration: InputDecoration(
                          labelText: mlReenterPassword,
                          labelStyle: secondaryTextStyle(size: 16),
                          prefixIcon: Icon(Icons.lock_outline, size: 20, color: appStore.isDarkModeOn ? white : black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: mlColorLightGrey.withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                      32.height,
                      AppButton(
                        width: double.infinity,
                        color: mlColorDarkBlue,
                        onTap: () {
                          finish(context);
                          finish(context);
                          MLLoginScreen().launch(context);
                        },
                        child: Text(mlDone, style: boldTextStyle(color: white)),
                      ),
                    ],
                  ).opacity(opacity: containerOpacity),
                ],
              ).paddingAll(16.0),
            ),
          ),
          Positioned(top: 30, child: mlBackToPrevious(context, appStore.isDarkModeOn ? white : black)),
        ],
      ),
    );
  }

  Widget otpField() {
    return Wrap(
      children: <Widget>[
        otp.OTPTextField(
          length: 6,
          width: double.infinity,
          fieldWidth: 35,
          style: boldTextStyle(size: 24),
          textFieldAlignment: MainAxisAlignment.spaceBetween,
          fieldStyle: FieldStyle.underline,
          onCompleted: (pin) {},
        ),
      ],
    );
  }

}
