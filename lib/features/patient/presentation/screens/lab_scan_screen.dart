import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/features/patient/data/lab_scan_model.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLLabScanScreen extends StatefulWidget {
  static String tag = '/MLLabScanScreen';

  const MLLabScanScreen({super.key});

  @override
  MLLabScanScreenState createState() => MLLabScanScreenState();
}

class MLLabScanScreenState extends State<MLLabScanScreen> {
  List<MLLabScanData> scans = mlLabScanDataList();

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
                  Text('Scanner un bilan', style: boldTextStyle(size: 22)),
                ],
              ).paddingAll(16),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: context.width(),
                        padding: EdgeInsets.all(24),
                        decoration: boxDecorationWithRoundedCorners(
                          backgroundColor: isDark ? scaffoldDarkColor : medicalTealUltraLight,
                          borderRadius: radius(20),
                          border: Border.all(color: medicalTealPrimary.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: medicalTealPrimary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.document_scanner_outlined, size: 48, color: medicalTealDark),
                            ),
                            16.height,
                            Text('Bilan de laboratoire', style: boldTextStyle(size: 18)),
                            6.height,
                            Text(
                              'Prenez en photo de votre bilan pour en extraire\nautomatiquement les résultats (OCR)',
                              textAlign: TextAlign.center,
                              style: secondaryTextStyle(size: 13),
                            ),
                            20.height,
                            Row(
                              children: [
                                AppButton(
                                  height: 44,
                                  color: medicalTealPrimary,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: white, size: 18),
                                      8.width,
                                      Text('Scanner', style: boldTextStyle(color: white, size: 14)),
                                    ],
                                  ),
                                  onTap: () {
                                    toasty(context, 'Ouverture de l\'appareil photo');
                                  },
                                ).expand(),
                                12.width,
                                AppButton(
                                  height: 44,
                                  color: isDark ? medicalDarkElevated : white,
                                  elevation: 0.0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library_outlined, color: medicalTealDark, size: 18),
                                      8.width,
                                      Text('Galerie', style: boldTextStyle(color: medicalTealDark, size: 14)),
                                    ],
                                  ),
                                  onTap: () {
                                    toasty(context, 'Sélection depuis la galerie');
                                  },
                                ).expand(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      24.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mes bilans scannés', style: boldTextStyle(size: 18)),
                          Text('${scans.length} résultats', style: secondaryTextStyle(size: 14)),
                        ],
                      ),
                      12.height,
                      ...scans.map(
                        (e) => Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(14),
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
                            borderRadius: radius(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: medicalBlueUltraLight,
                                  borderRadius: radius(10),
                                ),
                                child: Icon(Icons.description_outlined, color: medicalBlueDark, size: 22),
                              ),
                              12.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((e.title).validate(), style: boldTextStyle(size: 15)),
                                  4.height,
                                  Text((e.date).validate(), style: secondaryTextStyle(size: 12)),
                                ],
                              ).expand(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: e.status == 'Analisé' ? healthSuccessLight : healthWarningLight,
                                  borderRadius: radius(20),
                                ),
                                child: Text(
                                  (e.status).validate(),
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: e.status == 'Analisé' ? healthSuccessDark : healthWarningDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).onTap(() {
                          toasty(context, (e.title).validate());
                        }),
                      ),
                      8.height,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
