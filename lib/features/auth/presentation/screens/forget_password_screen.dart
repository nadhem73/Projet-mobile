import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/auth/presentation/components/country_picker.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/authentication_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';
import 'package:medilab_prokit/main.dart';

class MLForgetPasswordScreen extends StatefulWidget {
  static String tag = '/MLForgetPasswordScreen';

  const MLForgetPasswordScreen({super.key});

  @override
  MLForgetPasswordScreenState createState() => MLForgetPasswordScreenState();
}

class MLForgetPasswordScreenState extends State<MLForgetPasswordScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : white);
  }

  @override
  void dispose() {
    super.dispose();
    changeStatusColor(mlPrimaryColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(top: 24.0),
            decoration: boxDecorationWithRoundedCorners(backgroundColor: context.cardColor),
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  80.height,
                  Text(mlForgetPassword, style: boldTextStyle(size: 24)),
                  8.height,
                  Text(mlForgetPasswordMsg, style: secondaryTextStyle()),
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
                            borderSide: BorderSide(color: mlColorLightGrey.withValues(alpha: 0.2)),
                          ),
                        ),
                      ).expand(),
                    ],
                  ),
                  16.height,
                  AppButton(
                    width: double.infinity,
                    color: mlPrimaryColor,
                    onTap: () => MLAuthenticationScreen().launch(context),
                    child: Text('Send', style: boldTextStyle(color: white)),
                  ),
                ],
              ).paddingOnly(right: 16.0, left: 16.0),
            ),
          ),
          Positioned(
            top: 30,
            child: mlBackToPrevious(context, appStore.isDarkModeOn ? white : black),
          ),
        ],
      ),
    );
  }
}
