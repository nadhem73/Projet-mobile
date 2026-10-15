import 'package:flutter/material.dart';
import 'package:medilink/features/appointment/data/models/doctor_model.dart';
import 'package:medilink/core/widgets/feedback_views.dart';
import 'package:medilink/core/theme/colors.dart';
import 'package:medilink/core/utils/ui_helpers.dart';
import 'package:medilink/core/utils/mock_data.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:medilink/features/appointment/presentation/widgets/schedule_picker.dart';

class MLDoctorListComponent extends StatefulWidget {
  static String tag = '/MLDoctorListComponent';

  const MLDoctorListComponent({super.key});

  @override
  MLDoctorListComponentState createState() => MLDoctorListComponentState();
}

class MLDoctorListComponentState extends State<MLDoctorListComponent> {
  List<MLDoctorData> doctorDataList = mlDoctorListDataList();
  List<String?> time = mlScheduleTimeList();
  int? selectedIndex = 0;
  String? selectedTime;

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
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctors', style: boldTextStyle(size: 24)),
                    8.height,
                    Text('Find the service you are', style: secondaryTextStyle()),
                    16.height,
                  ],
                ).expand(),
                mlRoundedIconContainer(Icons.search, mlColorBlue),
                16.width,
                mlRoundedIconContainer(Icons.calendar_view_day_outlined, mlColorBlue),
              ],
            ),
            8.height,
            ComingSoonView().withHeight(context.height() * 0.6),
          ],
        ).paddingAll(16.0),
        Container(
          color: context.cardColor,
          child: Text(
            'Schedule appointment time',
            style: boldTextStyle(color: mlColorDarkBlue, decoration: TextDecoration.underline),
          ),
        ).paddingOnly(right: 16, bottom: 72).onTap(
          () {
            showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (builder) {
                return const MLScheduleApoointmentSheet();
              },
            );
          },
        ),
      ],
    );
  }
}
