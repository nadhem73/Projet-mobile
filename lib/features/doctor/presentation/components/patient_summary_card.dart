import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorPatientSummaryCard extends StatelessWidget {
  final MLDoctorPatientSummaryData patient;
  final VoidCallback? onTap;

  const MLDoctorPatientSummaryCard({
    super.key,
    required this.patient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final p = patient;

    final hasConditions = p.conditions!.isNotEmpty;
    final hasUpcoming = p.nextAppointment!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: medicalBluePrimary.withValues(alpha: 0.12),
              backgroundImage: AssetImage(p.avatar!),
            ),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.name.validate(), style: boldTextStyle(size: 15)),
                    8.width,
                    if (hasUpcoming)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: careCoralPrimary.withValues(alpha: 0.12), borderRadius: radius(4)),
                        child: Text('RDV ${_formatDate(p.nextAppointment!)}', style: boldTextStyle(size: 10, color: careCoralPrimary)),
                      ),
                  ],
                ),
                4.height,
                Text('${p.age} ans  •  ${p.gender == 'F' ? 'Femme' : 'Homme'}  •  Dernière visite: ${_formatDate(p.lastVisit!)}', style: secondaryTextStyle(size: 12)),
                4.height,
                if (hasConditions)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: p.conditions!.map((c) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
                      child: Text(c, style: boldTextStyle(size: 10, color: medicalTealPrimary)),
                    )).toList(),
                  ),
              ],
            ).expand(),
            Column(
              children: [
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                4.height,
                if (p.activeMedications!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: vitalityGreenPrimary.withValues(alpha: 0.1), borderRadius: radius(4)),
                    child: Text('${p.activeMedications!.length} médoc(s)', style: boldTextStyle(size: 9, color: vitalityGreenPrimary)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}