import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorConsultationCard extends StatelessWidget {
  final MLDoctorConsultationData consultation;
  final VoidCallback? onTap;

  const MLDoctorConsultationCard({
    super.key,
    required this.consultation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final c = consultation;

    Color statusColor;
    switch (c.status) {
      case 'Terminé':
        statusColor = medicalTealPrimary;
        break;
      case 'En cours':
        statusColor = medicalBluePrimary;
        break;
      case 'Programmé':
        statusColor = careCoralPrimary;
        break;
      case 'Annulé':
        statusColor = healthError;
        break;
      default:
        statusColor = Colors.grey;
    }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: medicalBluePrimary.withValues(alpha: 0.12),
                  child: Text(c.patientName!.substring(0, 1), style: boldTextStyle(size: 14, color: medicalBluePrimary)),
                ),
                12.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.patientName.validate(), style: boldTextStyle(size: 15)),
                    2.height,
                    Text('${c.patientAge} ans  •  ${c.patientGender == 'F' ? 'Femme' : 'Homme'}', style: secondaryTextStyle(size: 12)),
                  ],
                ).expand(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: radius(12)),
                      child: Text(c.status.validate(), style: boldTextStyle(size: 11, color: statusColor)),
                    ),
                    4.height,
                    Text('${c.date}  ${c.time}', style: secondaryTextStyle(size: 11)),
                  ],
                ),
              ],
            ),
            12.height,
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: mlColorDarkBlue.withValues(alpha: 0.1), borderRadius: radius(8)),
                  child: Text(c.type.validate(), style: boldTextStyle(size: 11, color: mlColorDarkBlue)),
                ),
                8.width,
                if (c.prescriptionId!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication, size: 11, color: medicalTealPrimary),
                        4.width,
                        Text('Ordonnance', style: boldTextStyle(size: 11, color: medicalTealPrimary)),
                      ],
                    ),
                  ),
              ],
            ),
            10.height,
            if (c.chiefComplaint!.isNotEmpty) ...[
              Text('Motif: ', style: boldTextStyle(size: 12)),
              Text(c.chiefComplaint.validate(), style: secondaryTextStyle(size: 12)),
              8.height,
            ],
            if (c.diagnosis!.isNotEmpty) ...[
              Text('Diagnostic: ', style: boldTextStyle(size: 12)),
              Text(c.diagnosis.validate(), style: secondaryTextStyle(size: 12)),
            ],
          ],
        ),
      ),
    );
  }
}