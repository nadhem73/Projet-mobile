import 'package:flutter/material.dart';
import 'package:medilab_prokit/main.dart';
import 'package:medilab_prokit/core/widgets/purchase_more_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:nb_utils/nb_utils.dart';

class MLAppointmentDetailScreen extends StatefulWidget {
  static String tag = '/MLAppointmentDetailScreen';

  const MLAppointmentDetailScreen({super.key});

  @override
  MLAppointmentDetailScreenState createState() => MLAppointmentDetailScreenState();
}

class MLAppointmentDetailScreenState extends State<MLAppointmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: mlPrimaryColor,
        body: Container(
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radiusOnly(topRight: 32),
            backgroundColor: appStore.isDarkModeOn ? black : white,
          ),
          child: Column(
            children: [
              8.height,
              Row(
                children: [
                  mlBackToPreviousWidget(context, appStore.isDarkModeOn ? white : blackColor),
                  Text('Appointment Details', style: boldTextStyle(size: 22)),
                ],
              ).paddingAll(16),
              Flexible(child: PurchaseMoreScreen()),
            ],
          ),
        ),
      ),
    );
  }
}
