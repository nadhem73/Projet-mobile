import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/doctor/presentation/components/doctor_detail.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';

class MLDoctorDetailScreen extends StatefulWidget {
  static String tag = '/MLDoctorDetailScreen';

  const MLDoctorDetailScreen({super.key});

  @override
  MLDoctorDetailScreenState createState() => MLDoctorDetailScreenState();
}

class MLDoctorDetailScreenState extends State<MLDoctorDetailScreen> {
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
    return Scaffold(
      backgroundColor: mlPrimaryColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: context.height() * 0.45,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: mlPrimaryColor,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Image.asset(mlIcDoctorImage, fit: BoxFit.contain, width: context.width()).paddingTop(16.0),
                      mlBackToPreviousWidget(context, white).paddingOnly(left: 24, top: 24),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return Container(
                      decoration: boxDecorationWithRoundedCorners(borderRadius: radiusOnly(topRight: 12, topLeft: 12)),
                      child: MLDoctorDetailComponent(),
                    );
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
