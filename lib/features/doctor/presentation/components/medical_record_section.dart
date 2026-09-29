import 'package:flutter/material.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLMedicalRecordSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;
  final bool expandable;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MLMedicalRecordSection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    this.expandable = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: radius(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            12.width,
            Text(title, style: boldTextStyle(size: 16)).expand(),
            if (trailing != null) trailing!,
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ).onTap(onTap),
        if (expandable) ...[
          12.height,
          ...items.map((item) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
              borderRadius: radius(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: radius(8)),
                  child: Icon(Icons.chevron_right, color: color, size: 20),
                ),
                12.width,
                Text(item, style: boldTextStyle(size: 13)).expand(),
              ],
            ),
          )),
        ],
      ],
    );
  }
}