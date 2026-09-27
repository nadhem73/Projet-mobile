import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/features/patient/presentation/components/chat_list.dart';
import 'package:medilab_prokit/features/home/presentation/screens/bot_screen.dart';

class MLBotSupportComponent extends StatefulWidget {
  static String tag = '/MLBotSupportComponent';

  const MLBotSupportComponent({super.key});

  @override
  MLBotSupportComponentState createState() => MLBotSupportComponentState();
}

class MLBotSupportComponentState extends State<MLBotSupportComponent> {
  List<String> botsData = <String>['Tony Bot', 'Dr. Heldi Kulm'];

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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Bots', style: boldTextStyle()),
          16.height,
          MLChatListComponent(botsData, cyanAccent, MLBotScreen()),
        ],
      ),
    );
  }
}
