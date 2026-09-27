import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/patient/presentation/components/order_tracking.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:medilab_prokit/main.dart';

class MLOrderDetailScreen extends StatefulWidget {
  static String tag = '/MLOrderDetailScreen';

  const MLOrderDetailScreen({super.key});

  @override
  MLOrderDetailScreenState createState() => MLOrderDetailScreenState();
}

class MLOrderDetailScreenState extends State<MLOrderDetailScreen> {
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
        body: Column(
          children: [
            8.height,
            Row(
              children: [
                mlBackToPreviousWidget(context, white),
                8.width,
                Text('Order Detail', style: boldTextStyle(size: 22, color: white)).expand(),
                Icon(Icons.info_outline, color: white, size: 22),
                8.width,
              ],
            ).paddingAll(16.0),
            8.height,
            Container(
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radiusOnly(topRight: 32),
                backgroundColor: appStore.isDarkModeOn ? black : white,
              ),
              child: MLOrderTrackingDetailComponent(),
            ).expand(),
          ],
        ),
      ),
    );
  }
}
