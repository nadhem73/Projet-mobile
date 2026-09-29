import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorAgendaTimeSlot extends StatelessWidget {
  final MLDoctorAgendaData? slot;
  final String startTime;
  final String endTime;
  final VoidCallback? onTap;

  const MLDoctorAgendaTimeSlot({
    super.key,
    this.slot,
    required this.startTime,
    required this.endTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final hasAppointment = slot != null && slot!.id != null;

    return Container(
      height: 60,
      margin: EdgeInsets.only(bottom: 8),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: hasAppointment ? (isDark ? mlColorDarkBlue.withValues(alpha: 0.2) : mlColorDarkBlue.withValues(alpha: 0.05)) : (isDark ? scaffoldDarkColor : Colors.grey.shade50),
        borderRadius: radius(12),
        border: Border.all(color: hasAppointment ? mlColorDarkBlue.withValues(alpha: 0.3) : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius(12),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(startTime, style: boldTextStyle(size: 12, color: isDark ? white : mlColorDarkBlue)),
                  Text(endTime, style: secondaryTextStyle(size: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: hasAppointment
                    ? Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(slot!.status!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          8.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(slot!.patientName.validate(), style: boldTextStyle(size: 13)),
                              Text('${slot!.type}  •  ${slot!.notes}', style: secondaryTextStyle(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ).expand(),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      )
                    : Center(
                        child: Text(
                          'Disponible',
                          style: secondaryTextStyle(size: 13, color: Colors.grey),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmé':
        return medicalTealPrimary;
      case 'En attente':
        return healthWarning;
      case 'Annulé':
        return healthError;
      default:
        return Colors.grey;
    }
  }
}