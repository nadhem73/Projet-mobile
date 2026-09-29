import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorAgendaScreen extends StatefulWidget {
  static String tag = '/MLDoctorAgendaScreen';

  const MLDoctorAgendaScreen({super.key});

  @override
  MLDoctorAgendaScreenState createState() => MLDoctorAgendaScreenState();
}

class MLDoctorAgendaScreenState extends State<MLDoctorAgendaScreen> {
  String selectedView = 'Semaine';
  DateTime selectedDate = DateTime(2026, 9, 28);

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
    final bool isDark = appStore.isDarkModeOn;
    final agendaList = mlDoctorAgendaDataList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDark ? scaffoldDarkColor : mlPrimaryColor,
        body: Container(
          width: context.width(),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radiusOnly(topRight: 32),
            backgroundColor: isDark ? black : white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark),
              _buildViewSelector(context, isDark),
              _buildWeekCalendar(context, isDark),
              Expanded(
                child: _buildTimeSlots(context, isDark, agendaList),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: mlColorDarkBlue,
        borderRadius: radiusOnly(bottomRight: 32),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_back, color: white, size: 24).onTap(() => finish(context)),
          8.width,
          Text('Mon Agenda', style: boldTextStyle(size: 22, color: white)).expand(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: white.withValues(alpha: 0.15),
              borderRadius: radius(20),
            ),
            child: Text('Semaine 39', style: boldTextStyle(size: 12, color: white)),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(BuildContext context, bool isDark) {
    final views = ['Jour', 'Semaine', 'Mois'];
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: views.map((view) {
          final isSelected = selectedView == view;
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(view, style: boldTextStyle(size: 13, color: isSelected ? white : (isDark ? white : mlColorDarkBlue))),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedView = view),
              selectedColor: mlColorDarkBlue,
              backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: radius(20)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekCalendar(BuildContext context, bool isDark) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = startOfWeek.add(Duration(days: index));
          final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
          final isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;

          return Container(
            width: 56,
            margin: EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Text(days[index], style: secondaryTextStyle(size: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                8.height,
                GestureDetector(
                  onTap: () => setState(() => selectedDate = date),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? mlColorDarkBlue : (isToday ? mlColorDarkBlue.withValues(alpha: 0.12) : Colors.transparent),
                      borderRadius: radius(22),
                      border: isToday && !isSelected ? Border.all(color: mlColorDarkBlue, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: boldTextStyle(
                          size: 16,
                          color: isSelected ? white : (isDark ? white : mlColorDarkBlue),
                        ),
                      ),
                    ),
                  ),
                ),
                4.height,
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _hasAppointments(date) ? medicalTealPrimary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasAppointments(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return mlDoctorAgendaDataList().any((e) => e.date == dateStr);
  }

  Widget _buildTimeSlots(BuildContext context, bool isDark, List<MLDoctorAgendaData> agendaList) {
    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final dayAgenda = agendaList.where((e) => e.date == dateStr).toList();
    final timeSlots = _generateTimeSlots();

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final appointment = dayAgenda.firstWhere(
          (a) => a.startTime == slot['start'] && a.endTime == slot['end'],
          orElse: () => MLDoctorAgendaData(),
        );
        final hasAppointment = appointment.id != null;

        return Container(
          height: 60,
          margin: EdgeInsets.only(bottom: 8),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: hasAppointment ? (isDark ? mlColorDarkBlue.withValues(alpha: 0.2) : mlColorDarkBlue.withValues(alpha: 0.05)) : (isDark ? scaffoldDarkColor : Colors.grey.shade50),
            borderRadius: radius(12),
            border: Border.all(color: hasAppointment ? mlColorDarkBlue.withValues(alpha: 0.3) : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot['start']!, style: boldTextStyle(size: 12, color: isDark ? white : mlColorDarkBlue)),
                    Text(slot['end']!, style: secondaryTextStyle(size: 11, color: Colors.grey)),
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
                                color: _getStatusColor(appointment.status!),
                                shape: BoxShape.circle,
                              ),
                            ),
                            8.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(appointment.patientName.validate(), style: boldTextStyle(size: 13)),
                                Text('${appointment.type}  •  ${appointment.notes}', style: secondaryTextStyle(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        ).onTap(() {
          if (hasAppointment) {
            // Navigate to consultation detail
          } else {
            // Show new appointment dialog
          }
        });
      },
    );
  }

  List<Map<String, String>> _generateTimeSlots() {
    final slots = <Map<String, String>>[];
    for (int h = 8; h < 18; h++) {
      for (int m = 0; m < 60; m += 30) {
        final start = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        final endHour = m == 30 ? h + 1 : h;
        final endMin = m == 30 ? 0 : 30;
        final end = '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
        slots.add({'start': start, 'end': end});
      }
    }
    return slots;
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