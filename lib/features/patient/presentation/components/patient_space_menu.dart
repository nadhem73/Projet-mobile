import 'package:flutter/material.dart';
import 'package:medilab_prokit/main.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:nb_utils/nb_utils.dart';

class MLProfileBottomComponent extends StatefulWidget {
  static String tag = '/MLProfileBottomComponent';

  const MLProfileBottomComponent({super.key});

  @override
  MLProfileBottomComponentState createState() => MLProfileBottomComponentState();
}

class MLProfileBottomComponentState extends State<MLProfileBottomComponent> {
  List<String> data = <String>['Membership card', 'Dependents', 'Health care', 'Refer friends and family','Membership card', 'Dependents', 'Health care', 'Refer friends and family'];
  List<String> categoriesData = <String>['Prescription', 'Medical Record', 'Medical Test', 'Health Tracking','Prescription', 'Medical Record', 'Medical Test', 'Health Tracking'];
  List<Color> customColor = <Color>[medicalTealPrimary, careCoralPrimary, vitalityGreenPrimary, cyanAccentDark];

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
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radiusOnly(topRight: 32),
        backgroundColor: appStore.isDarkModeOn ? blackColor : white,
      ),
      child: Column(
        children: [
          Container(
            // margin: EdgeInsets.only(bottom: 16.0),
            padding: EdgeInsets.all(8.0),
            decoration: boxDecorationRoundedWithShadow(8, backgroundColor: context.cardColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('images/ic_theme.png', height: 24, width: 24, color: medicalTealPrimary).paddingOnly(left: 4),
                    8.width,
                    Text('DarkMode', style: primaryTextStyle()),
                  ],
                ),
                Switch(
                  value: appStore.isDarkModeOn,
                  activeThumbColor: appColorPrimary,
                  onChanged: (s) {
                    appStore.toggleDarkMode(value: s);
                  },
                )
              ],
            ),
          ).onTap(
            () {
              appStore.toggleDarkMode();
            },
          ),
          16.height,
          Column(
            children: data.map(
              (e) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16.0),
                  padding: EdgeInsets.all(12.0),
                  decoration: boxDecorationRoundedWithShadow(8, backgroundColor: context.cardColor),
                  child: Row(
                    children: [
                      Icon(Icons.tab, size: 24, color: medicalTealPrimary),
                      8.width,
                      Text(e.validate(), style: primaryTextStyle()).expand(),
                      Icon(Icons.arrow_forward_ios, color: medicalMediumGray, size: 16),
                    ],
                  ),
                ).onTap(
                  () {
                    toasty(context, e.validate());
                  },
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}
