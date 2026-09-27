import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:medilab_prokit/core/utils/app_strings.dart';

class MLPillHowToUseComponent extends StatefulWidget {
  static String tag = '/PillHowToUseComponent';

  const MLPillHowToUseComponent({super.key});

  @override
  MLPillHowToUseComponentState createState() => MLPillHowToUseComponentState();
}

class MLPillHowToUseComponentState extends State<MLPillHowToUseComponent> {
  List<String?> detail = <String?>[mlPillDescription, mlPillDescription, mlPillDescription];

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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How To Use', style: boldTextStyle(size: 22)),
          8.height,
          Image.asset(
            mlIcPharmacySlide2,
            height: 150,
            width: context.width(),
            fit: BoxFit.cover,
          ).cornerRadiusWithClipRRect(8.0),
          16.height,
          Text('Description', style: boldTextStyle()),
          Column(
            children: <Widget>[
              for (int i = 0; i < detail.length; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.brightness_1_rounded, size: 8).paddingTop(4.0),
                    8.width,
                    Text(detail[i].validate(), style: secondaryTextStyle(size: 16)).expand(),
                  ],
                ).paddingAll(8.0),
            ],
          ),
        ],
      ).paddingAll(16.0),
    );
  }
}
