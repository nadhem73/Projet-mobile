import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/patient/presentation/components/patient_space_menu.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:medilab_prokit/core/utils/ui_helpers.dart';

class MLProfileFragment extends StatefulWidget {
  static String tag = '/MLProfileFragment';

  const MLProfileFragment({super.key});

  @override
  MLProfileFragmentState createState() => MLProfileFragmentState();
}

class MLProfileFragmentState extends State<MLProfileFragment> {
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
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: mlPrimaryColor,
            pinned: true,
            leading: mlBackToPreviousIcon(context, white),
            expandedHeight: 225,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: mlColorDarkBlue,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 40.0, backgroundColor: mlColorCyan, child: Image.asset(mlIcProfilePicture)),
                    8.height,
                    Text('Kaixa Pham', style: boldTextStyle(color: white, size: 24)),
                    4.height,
                    Text('johnsmith@gmail.com', style: secondaryTextStyle(color: white, size: 16)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: MLProfileBottomComponent(),
          )

        ],
      ),
    );
  }
}
