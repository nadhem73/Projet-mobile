import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorVitalSignInput extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?)? validator;

  const MLDoctorVitalSignInput({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
          borderRadius: radius(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: mlColorDarkBlue),
                4.width,
                Text(label, style: secondaryTextStyle(size: 11)),
              ],
            ),
            8.height,
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              validator: validator,
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: secondaryTextStyle(size: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: boldTextStyle(size: 16),
            ),
          ],
        ),
      ),
    );
  }
}