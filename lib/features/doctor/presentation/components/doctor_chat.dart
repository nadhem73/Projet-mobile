import 'package:flutter/material.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/patient/presentation/components/chat_list.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/chat_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';

class MLDoctorChatComponent extends StatefulWidget {
  static String tag = '/MLDoctorChatComponent';

  const MLDoctorChatComponent({super.key});

  @override
  MLDoctorChatComponentState createState() => MLDoctorChatComponentState();
}

class MLDoctorChatComponentState extends State<MLDoctorChatComponent> {
  int notificationCounter = 3;
  List<String> unreadData = <String>['Dr. Miranda Kerr', 'Dr. Heldi Kulm '];
  List<String> otherData = <String>['Dr.Stephen', 'Dr. Miranda Kerr', 'Dr. Miranda Kerr'];

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
          Text('Unread', style: boldTextStyle()),
          16.height,
          MLChatListComponent(unreadData, appStore.isDarkModeOn ? scaffoldDarkColor : mlColorGreyShade, MLChatScreen()),
          Divider(height: 32),
          Text('Other', style: boldTextStyle()),
          16.height,
          MLChatListComponent(otherData, appStore.isDarkModeOn ? scaffoldDarkColor : mlColorGreyShade, MLChatScreen()),
        ],
      ).paddingAll(16.0),
    );
  }
}
