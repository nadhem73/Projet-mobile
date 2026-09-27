import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/pharmacy/data/payment_model.dart';

class MLAddPaymentListComponent extends StatefulWidget {
  const MLAddPaymentListComponent({super.key});

  @override
  MLAddPaymentListComponentState createState() => MLAddPaymentListComponentState();
}

class MLAddPaymentListComponentState extends State<MLAddPaymentListComponent> {
  List<MLPaymentData> paymentData = mlPaymentDataList();
  int? selectedIndex = 0;
  final int _radioSelected = 1;

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
    return RadioGroup<int>(
      groupValue: _radioSelected,
      onChanged: (value) {},
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        physics: ScrollPhysics(),
        itemCount: paymentData.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.0),
            padding: EdgeInsets.all(4),
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: radius(12),
              backgroundColor: context.cardColor,
              border: Border.all(color: selectedIndex == index ? mlColorBlue : mlColorLightGrey100),
            ),
            child: Row(
              children: [
                Image.asset((paymentData[index].image).validate(), fit: BoxFit.fill, width: 50, height: 50),
                Text((paymentData[index].title).validate(), style: boldTextStyle()).expand(),
                Radio<int>(
                  value: 1,
                  activeColor: selectedIndex == index ? mlColorBlue : mlColorLightGrey100,
                ),
                4.width,
              ],
            ),
          ).onTap(
            () {
              setState(
                () {
                  selectedIndex = index;
                },
              );
            },
          );
        },
      ),
    );
  }
}
