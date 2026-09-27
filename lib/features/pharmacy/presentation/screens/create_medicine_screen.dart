import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/components/create_medicine.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:medilab_prokit/main.dart';

class MLCreateNewMedicine extends StatefulWidget {
  static String tag = '/MLCreateNewMedicine';

  const MLCreateNewMedicine({super.key});

  @override
  MLCreateNewMedicineState createState() => MLCreateNewMedicineState();
}

class MLCreateNewMedicineState extends State<MLCreateNewMedicine> {
  List<String?> medicineImage = <String?>[mlIcMediFive, mlIcMediTwo, mlIcMediThree, mlIcMediFour];
  List<String?> time = <String?>['08:30 am', '15:30 am', '20:30 am', ''];
  List<String?> day = <String?>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Container(
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radiusOnly(topRight: 32),
                backgroundColor: appStore.isDarkModeOn ? black : white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  8.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      mlBackToPreviousIcon(context, appStore.isDarkModeOn ? white : blackColor),
                      8.width,
                      Text('Create New Medicine', style: boldTextStyle(size: 20)).expand(),
                    ],
                  ).paddingAll(16.0),
                  8.height,
                  MLCreateMedicineComponent().flexible(),
                ],
              ),
            ),
            AppButton(
              width: context.width(),
              color: mlPrimaryColor,
              child: Text('Save', textAlign: TextAlign.center, style: boldTextStyle(color: whiteColor)),
              onTap: () {
                finish(context);
              },
            ).paddingOnly(right: 16, left: 16, bottom: 16),
          ],
        ),
      ),
    );
  }
}
