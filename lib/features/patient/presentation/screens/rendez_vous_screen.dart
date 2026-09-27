import 'package:flutter/material.dart';
import 'package:medilab_prokit/features/appointment/data/appointment_model.dart';
import 'package:medilab_prokit/features/appointment/presentation/screens/book_appointment_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLRendezVousScreen extends StatefulWidget {
  static String tag = '/MLRendezVousScreen';

  const MLRendezVousScreen({super.key});

  @override
  MLRendezVousScreenState createState() => MLRendezVousScreenState();
}

class MLRendezVousScreenState extends State<MLRendezVousScreen> {
  int currentTab = 0;
  List<String> tabs = ['�? venir', 'Passés'];
  List<MLAppointmentData> upcoming = mlAppointmentDataList();
  late List<MLAppointmentData> past = upcoming.take(2).toList();

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
    List<MLAppointmentData> data = currentTab == 0 ? upcoming : past;

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
                  Text('Mes rendez-vous', style: boldTextStyle(size: 22)),
                ],
              ).paddingAll(16),
              8.height,
              Row(
                children: List.generate(tabs.length, (index) {
                  final bool isSelected = currentTab == index;
                  return Container(
                    margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? mlPrimaryColor : (isDark ? scaffoldDarkColor : mlColorLightGrey100),
                      borderRadius: radius(20),
                    ),
                    child: Text(
                      tabs[index],
                      style: boldTextStyle(
                        size: 14,
                        color: isSelected ? white : (isDark ? white : blackColor),
                      ),
                    ),
                  ).onTap(() {
                    setState(() {
                      currentTab = index;
                    });
                  }).expand();
                }),
              ).paddingOnly(left: 16, right: 16),
              16.height,
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final MLAppointmentData e = data[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
                        borderRadius: radius(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 64,
                                width: 64,
                                decoration: boxDecorationWithRoundedCorners(
                                  backgroundColor: mlColorDarkBlue,
                                  borderRadius: radius(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text((e.date).validate(), style: boldTextStyle(size: 24, color: white)),
                                    Text((e.month).validate().substring(0, 3), style: secondaryTextStyle(color: white, size: 11)),
                                  ],
                                ),
                              ),
                              12.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((e.department).validate(), style: boldTextStyle(size: 16)),
                                  4.height,
                                  Text((e.doctor).validate(), style: secondaryTextStyle()),
                                  4.height,
                                  Text('Patient : ${(e.patient).validate()}', style: secondaryTextStyle(size: 13)),
                                ],
                              ).expand(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentTab == 0 ? healthSuccessLight : mlColorLightGrey,
                                  borderRadius: radius(20),
                                ),
                                child: Text(
                                  currentTab == 0 ? 'Confirmé' : 'Terminé',
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: currentTab == 0 ? healthSuccessDark : medicalCharcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          12.height,
                          Divider(thickness: 0.5, height: 0.5),
                          12.height,
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: mlPrimaryColor),
                              6.width,
                              Text('09:30 AM - 10:15 AM', style: boldTextStyle(color: mlColorDarkBlue, size: 14)),
                              8.width,
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: medicalBlueUltraLight,
                                  borderRadius: radius(8),
                                ),
                                child: Text((e.service).validate(), style: secondaryTextStyle(size: 11, color: medicalBlueDark)),
                              ),
                            ],
                          ),
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
              Text('Prendre un rendez-vous', style: boldTextStyle(color: white)),
            ],
          ),
          onTap: () {
            MLBookAppointmentScreen(index: 0).launch(context);
          },
        ).paddingOnly(left: 16, right: 16, bottom: 16),
      ),
    );
  }
}
