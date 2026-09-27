import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/features/patient/data/prescription_model.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLPrescriptionScreen extends StatefulWidget {
  static String tag = '/MLPrescriptionScreen';

  const MLPrescriptionScreen({super.key});

  @override
  MLPrescriptionScreenState createState() => MLPrescriptionScreenState();
}

class MLPrescriptionScreenState extends State<MLPrescriptionScreen> {
  List<MLPrescriptionData> prescriptions = mlPrescriptionDataList();

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
    final bool isDark = appStore.isDarkModeOn;

    return SafeArea(
      child: Scaffold(
        backgroundColor: mlPrimaryColor,
        body: Container(
          width: context.width(),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radiusOnly(topRight: 32),
            backgroundColor: isDark ? black : white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.height,
              Row(
                children: [
                  Text('Mes ordonnances', style: boldTextStyle(size: 22)),
                ],
              ).paddingAll(16),
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final MLPrescriptionData e = prescriptions[index];
                    final bool isActive = e.status == 'Active';

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
                        borderRadius: radius(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: medicalTealUltraLight,
                                  borderRadius: radius(10),
                                ),
                                child: Icon(Icons.receipt_long_outlined, color: medicalTealDark, size: 22),
                              ),
                              12.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((e.doctor).validate(), style: boldTextStyle(size: 16)),
                                  2.height,
                                  Text(
                                    '${(e.specialty).validate()}  �?�  ${(e.date).validate()}',
                                    style: secondaryTextStyle(size: 12),
                                  ),
                                ],
                              ).expand(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? healthSuccessLight : mlColorLightGrey,
                                  borderRadius: radius(20),
                                ),
                                child: Text(
                                  (e.status).validate(),
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: isActive ? healthSuccessDark : medicalCharcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          12.height,
                          Divider(thickness: 0.5, height: 0.5),
                          12.height,
                          ...(e.medicines ?? []).map(
                            (med) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.medication_liquid_outlined, size: 16, color: medicalTealPrimary),
                                  8.width,
                                  Text(med, style: primaryTextStyle(size: 14)),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Voir l\'ordonnance complète', style: boldTextStyle(size: 13, color: medicalTealDark)),
                              Icon(Icons.arrow_forward_ios, size: 12, color: medicalTealPrimary),
                            ],
                          ).onTap(() {
                            toasty(context, (e.doctor).validate());
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppButton(
          height: 50,
          width: context.width(),
          color: mlColorDarkBlue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: white, size: 20),
              8.width,
              Text('Ajouter une ordonnance', style: boldTextStyle(color: white)),
            ],
          ),
          onTap: () {
            toasty(context, 'Ajouter une ordonnance');
          },
        ).paddingOnly(left: 16, right: 16, bottom: 16),
      ),
    );
  }
}
