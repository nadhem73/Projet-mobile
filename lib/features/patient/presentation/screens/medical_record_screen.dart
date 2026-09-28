import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLMedicalRecordScreen extends StatefulWidget {
  static String tag = '/MLMedicalRecordScreen';

  const MLMedicalRecordScreen({super.key});

  @override
  MLMedicalRecordScreenState createState() => MLMedicalRecordScreenState();
}

class MLMedicalRecordScreenState extends State<MLMedicalRecordScreen> {
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
                  Text('Dossier médical', style: boldTextStyle(size: 22)),
                ],
              ).paddingAll(16),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: boxDecorationWithRoundedCorners(
                          backgroundColor: mlColorDarkBlue,
                          borderRadius: radius(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: mlColorCyan,
                              child: Image.asset('assets/images/ml_profile_Image.png', fit: BoxFit.cover),
                            ),
                            12.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kaixa Pham', style: boldTextStyle(size: 18, color: white)),
                                4.height,
                                Text('29 ans  �?�  Groupe O+', style: secondaryTextStyle(color: white.withValues(alpha: 0.7), size: 13)),
                                2.height,
                                Text('Née le 21/09/1995', style: secondaryTextStyle(color: white.withValues(alpha: 0.5), size: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      24.height,
                      Text('Constantes vitales', style: boldTextStyle(size: 18)),
                      12.height,
                      Row(
                        children: [
                          _vitalTile(context, 'Tension', '120/80', 'mmHg', Icons.favorite_outline, healthError),
                          12.width,
                          _vitalTile(context, 'Poids', '68', 'kg', Icons.monitor_weight_outlined, medicalBluePrimary),
                        ],
                      ),
                      12.height,
                      Row(
                        children: [
                          _vitalTile(context, 'Glycémie', '0.92', 'g/L', Icons.water_drop_outlined, medicalTealPrimary),
                          12.width,
                          _vitalTile(context, 'Fréquence', '72', 'bpm', Icons.favorite_outline, careCoralPrimary),
                        ],
                      ),
                      24.height,
                      Text('Sections du dossier', style: boldTextStyle(size: 18)),
                      12.height,
                      _sectionTile(context, Icons.history_edu_outlined, 'Antécédents médicaux', 'Diabète de type 2 (2019)', medicalBluePrimary),
                      _sectionTile(context, Icons.warning_amber_outlined, 'Allergies', 'Pénicilline, arachides', healthWarning),
                      _sectionTile(context, Icons.medication_outlined, 'Traitements en cours', '2 traitements actifs', medicalTealPrimary),
                      _sectionTile(context, Icons.folder_outlined, 'Documents & comptes rendus', '5 documents', careCoralPrimary),
                      24.height,
                      Text('Historique des consultations', style: boldTextStyle(size: 18)),
                      12.height,
                      ...mlAppointmentDataList().take(3).map(
                            (e) => Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(12),
                              decoration: boxDecorationWithRoundedCorners(
                                backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
                                borderRadius: radius(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: medicalTealUltraLight,
                                      borderRadius: radius(8),
                                    ),
                                    child: Icon(Icons.medical_services_outlined, color: medicalTealDark, size: 20),
                                  ),
                                  12.width,
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text((e.department).validate(), style: boldTextStyle(size: 14)),
                                      2.height,
                                      Text('${(e.doctor).validate()}  �?�  ${e.date} ${e.month}', style: secondaryTextStyle(size: 12)),
                                    ],
                                  ).expand(),
                                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                      16.height,
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

  Widget _vitalTile(BuildContext context, String label, String value, String unit, IconData icon, Color color) {
    final bool isDark = appStore.isDarkModeOn;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: secondaryTextStyle(size: 12)),
              2.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: boldTextStyle(size: 20)),
                  4.width,
                  Text(unit, style: secondaryTextStyle(size: 11)).paddingOnly(bottom: 3),
                ],
              ),
            ],
          ),
        ],
      ),
    ).expand();
  }

  Widget _sectionTile(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final bool isDark = appStore.isDarkModeOn;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: radius(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: boldTextStyle(size: 14)),
              2.height,
              Text(subtitle, style: secondaryTextStyle(size: 12)),
            ],
          ).expand(),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    ).onTap(() {
      toasty(context, title);
    });
  }
}
