import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/auth/presentation/components/country_picker.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/profile_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';
import 'package:medilab_prokit/main.dart';

class MLConfirmPhoneNumberScreen extends StatefulWidget {
  static String tag = '/MLConfirmPhoneNumberScreen';

  const MLConfirmPhoneNumberScreen({super.key});

  @override
  MLConfirmPhoneNumberScreenState createState() => MLConfirmPhoneNumberScreenState();
}

class MLConfirmPhoneNumberScreenState extends State<MLConfirmPhoneNumberScreen> {
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
            padding: EdgeInsets.all(16.0),
            height: context.height(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  56.height,
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    child: commonCachedNetworkImage(
                      mlIcVerifyindicator,
                      alignment: Alignment.centerLeft,
                      width: 200,
                      height: 200,
                    ),
                  ),
                  32.height,
                  Text(mlContactMsg, style: boldTextStyle(size: 24)),
                  8.height,
                  Text(mlContactSubMsg, style: secondaryTextStyle(size: 16)),
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
                  24.height,
                  AppButton(
                    width: double.infinity,
                    color: mlColorDarkBlue,
                    onTap: () => const MLUpdateProfileScreen().launch(context),
                    child: Text(mlSend, style: boldTextStyle(color: white)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: 30, child: mlBackToPrevious(context, appStore.isDarkModeOn ? white : blackColor)),
        ],
      ),
    );
  }
}
