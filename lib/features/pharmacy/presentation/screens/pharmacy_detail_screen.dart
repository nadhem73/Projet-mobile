import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/components/category_chip.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/components/category_product.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';

class MLOnlinePharmacyDetailScreen extends StatefulWidget {
  static String tag = '/MLOnlinePharmacyDetailScreen';
  final int? index;

  const MLOnlinePharmacyDetailScreen({super.key, this.index});

  @override
  MLOnlinePharmacyDetailScreenState createState() => MLOnlinePharmacyDetailScreenState();
}

class MLOnlinePharmacyDetailScreenState extends State<MLOnlinePharmacyDetailScreen> {
  List<Widget> data = [MLCategoryComponent(), MLCategoryProductComponent()];

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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    mlBackToPreviousWidget(context, white),
                    8.width,
                    Text('Online Pharmacy', style: boldTextStyle(color: whiteColor, size: 20)).expand(),
                    Icon(Icons.home_outlined, color: white, size: 24),
                    8.width,
                    Icon(Icons.shopping_bag_outlined, color: white, size: 24),
                  ],
                ),
                8.height,
                Row(
                  children: [
                    Text('Online Pharmacy ', style: secondaryTextStyle(size: 12, color: white.withValues(alpha: 0.4))),
                    (widget.index == 0)
                        ? Text(
                            '> Prescription Drug',
                            style: secondaryTextStyle(size: 12, color: white.withValues(alpha: 0.4)),
                          )
                        : Text(
                            '> Prescription Drug > Analgesic',
                            style: secondaryTextStyle(size: 12, color: white.withValues(alpha: 0.3)),
                          ),
                  ],
                ).paddingLeft(8.0),
              ],
            ).paddingAll(16.0),
            data[widget.index!].validate().flexible(),
          ],
        ),
      ),
    );
  }
}
