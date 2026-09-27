import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/widgets/purchase_button.dart';
import 'package:medilab_prokit/core/utils/app_assets.dart';
import 'package:nb_utils/nb_utils.dart';

class PurchaseMoreScreen extends StatefulWidget {
  final bool? enableAppbar;

  const PurchaseMoreScreen({super.key, this.enableAppbar = false});

  @override
  PurchaseMoreScreenState createState() => PurchaseMoreScreenState();
}

class PurchaseMoreScreenState extends State<PurchaseMoreScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Icon(Icons.arrow_back, size: 24).paddingAll(16).onTap(() {
              finish(context);
            }).visible(widget.enableAppbar!),
            SizedBox(
              width: context.width(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: boxDecorationDefault(),
                    padding: EdgeInsets.all(16),
                    child: Image.asset(mlIcMedilabLogo, height: 100),
                  ),
                  22.height,
                  Text(
                    'This is the lite version of the Medilink Tunisia App',
                    style: boldTextStyle(size: 22),
                    textAlign: TextAlign.center,
                  ),
                  16.height,
                  PurchaseButton(),
                ],
              ),
            ).paddingAll(16),
          ],
        ),
      ),
    );
  }
}
