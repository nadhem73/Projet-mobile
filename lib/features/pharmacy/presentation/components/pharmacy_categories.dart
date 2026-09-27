import 'package:flutter/material.dart';
import 'package:medilab_prokit/main.dart';
import 'package:medilab_prokit/features/patient/data/medication_model.dart';
import 'package:medilab_prokit/core/widgets/purchase_more_screen.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:nb_utils/nb_utils.dart';

class MLPharmacyCategoriesComponent extends StatefulWidget {
  static String tag = '/MLPharmacyCategoriesComponent';

  const MLPharmacyCategoriesComponent({super.key});

  @override
  MLPharmacyCategoriesComponentState createState() => MLPharmacyCategoriesComponentState();
}

class MLPharmacyCategoriesComponentState extends State<MLPharmacyCategoriesComponent> {
  List<MLMedicationData> listOne = mlCategoryMedicineList();
  List<MLMedicationData> listTwo = mlPrescriptionMedicineDataList();

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
      height: context.height(),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radiusOnly(topRight: 32),
        backgroundColor: appStore.isDarkModeOn ? black : white,
      ),
      child: PurchaseMoreScreen().withHeight(context.height() * 0.2),
    );
  }
}
