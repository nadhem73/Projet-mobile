import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/appointment/data/book_appointment_model.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/add_payment_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';

class MLBookAppointmentScreen extends StatefulWidget {
  static String tag = '/MLBookAppointmentScreen';
  final int? index;

  const MLBookAppointmentScreen({super.key, this.index});

  @override
  MLBookAppointmentScreenState createState() => MLBookAppointmentScreenState();
}

class MLBookAppointmentScreenState extends State<MLBookAppointmentScreen> {
  int currentWidget = 0;
  List<MLBookAppointmentData> data = mlBookAppointmentDataList();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    currentWidget = widget.index!;
    changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : white);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    changeStatusColor(mlPrimaryColor);
  }

  @override
  Widget build(BuildContext context) {
    final navigatorKey = GlobalObjectKey<NavigatorState>(context);
    String titleNumber = data[currentWidget].id.validate();
    String titleText = data[currentWidget].title.validate();
    double progress = data[currentWidget].progress.validate();

    return PopScope(
      key: navigatorKey,
      canPop: currentWidget == 0 || !navigatorKey.currentState!.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentWidget != 0) {
          currentWidget--;
          setState(() {});
          navigatorKey.currentState!.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Container(
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radiusOnly(topRight: 32),
                  backgroundColor: appStore.isDarkModeOn ? black : white,
                ),
                child: Column(
                  children: <Widget>[
                    8.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.arrow_back_ios,
                          color: appStore.isDarkModeOn ? white : blackColor,
                          size: 22,
                        ).onTap(
                          () {
                            currentWidget == 0
                                ? Navigator.of(context).pop()
                                : setState(
                                    () {
                                      currentWidget--;
                                      widget.index == currentWidget;
                                    },
                                  );
                          },
                        ).expand(flex: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Step $titleNumber of 4: ',
                              textAlign: TextAlign.center,
                              style: boldTextStyle(color: mlColorDarkBlue),
                            ),
                            Text(titleText, textAlign: TextAlign.center, style: boldTextStyle(color: Colors.grey)),
                          ],
                        ).expand(flex: 8),
                        Icon(Icons.home_outlined, color: blackColor, size: 24).expand(flex: 1),
                      ],
                    ).paddingAll(16.0),
                    8.height,
                    LinearProgressIndicator(
                      minHeight: 2.0,
                      backgroundColor: mlColorLightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(mlColorDarkBlue),
                      value: progress,
                    ),
                    8.height,
                    data[currentWidget].widget.validate().expand(),
                  ],
                ),
              ),
              AppButton(
                height: 50,
                width: context.width(),
                color: mlColorDarkBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Continue", style: boldTextStyle(color: white)),
                    8.width,
                    Icon(Icons.arrow_forward_ios, color: whiteColor, size: 12),
                  ],
                ),
                onTap: () {
                  setState(
                    () {
                      currentWidget++;
                    },
                  );
                  if (currentWidget > 3) {
                    setState(
                      () {
                        currentWidget--;
                      },
                    );
                    currentWidget = 0;
                    finish(context);
                    MLAddPaymentScreen().launch(context);
                  }
                },
              ).paddingOnly(right: 16, left: 16, bottom: 16)
            ],
          ),
        ),
      ),
    );
  }
}
