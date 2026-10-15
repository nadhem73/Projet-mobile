import 'package:flutter/material.dart';
import 'package:medilink/main.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:medilink/features/pharmacy/presentation/widgets/pharmacy_product.dart';

class MLCategoryProductComponent extends StatelessWidget {
  const MLCategoryProductComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radiusOnly(topRight: 32),
        backgroundColor: appStore.isDarkModeOn ? black : white,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text('Analgestic', style: boldTextStyle(size: 24)).paddingOnly(left: 16),
            10.height,
            MLPharmacyProductComponent(),
          ],
        ),
      ),
    );
  }
}
