import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/doctor/presentation/components/doctor_bottom_nav_bar.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/doctor_agenda_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/doctor_consultation_list_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/doctor_patient_list_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/doctor_prescription_screen.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:medilab_prokit/main.dart';

class MLDoctorDashboardScreen extends StatefulWidget {
  static String tag = '/MLDoctorDashboardScreen';

  const MLDoctorDashboardScreen({super.key});

  @override
  MLDoctorDashboardScreenState createState() => MLDoctorDashboardScreenState();
}

class MLDoctorDashboardScreenState extends State<MLDoctorDashboardScreen> {
  int currentWidget = 0;
  List<Widget> widgets = [
    _DoctorDashboardHome(onNavigateToTab: (index) {}),
    MLDoctorAgendaScreen(),
    MLDoctorConsultationListScreen(),
    MLDoctorPatientListScreen(),
    MLDoctorPrescriptionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widgets[0] = _DoctorDashboardHome(onNavigateToTab: (index) {
      setState(() {
        currentWidget = index;
      });
    });

    return SafeArea(
      child: Scaffold(
        body: widgets[currentWidget],
        bottomNavigationBar: showBottomDrawer(),
      ),
    );
  }

  Widget showBottomDrawer() {
    return MLDoctorBottomNavigationBarWidget(
      index: currentWidget,
      onTap: (index) {
        setState(() {
          currentWidget = index;
        });
      },
    );
  }
}

class _DoctorDashboardHome extends StatelessWidget {
  final void Function(int) onNavigateToTab;

  const _DoctorDashboardHome({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final agendaList = mlDoctorAgendaDataList().where((e) => e.date == '2026-09-28').toList();
    final consultationList = mlDoctorConsultationDataList().where((e) => e.status == 'Programmé' || e.status == 'En cours').toList();
    mlDoctorPatientSummaryDataList();

    return Scaffold(
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(context, isDark),
                    24.height,
                    _buildTodayAgenda(context, isDark, agendaList),
                    24.height,
                    _buildUpcomingConsultations(context, isDark, consultationList),
                    24.height,
                    _buildQuickActions(context, isDark),
                    100.height,
                  ],
                ),
              ),
            ),
          ],
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
          CircleAvatar(
            radius: 28,
            backgroundColor: mlColorCyan,
            child: Image.asset('assets/images/ml_profile_Image.png', fit: BoxFit.cover),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. Stephen Chew', style: boldTextStyle(size: 20, color: white)),
              2.height,
              Text('Médecine Générale', style: secondaryTextStyle(color: white.withValues(alpha: 0.7), size: 13)),
            ],
          ).expand(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: white.withValues(alpha: 0.15),
              borderRadius: radius(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: medicalTealPrimary, size: 8),
                6.width,
                Text('En ligne', style: boldTextStyle(size: 12, color: white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final stats = [
      {'label': 'RDV aujourd\'hui', 'value': '8', 'icon': Icons.calendar_today, 'color': medicalBluePrimary},
      {'label': 'Consultations', 'value': '3', 'icon': Icons.medical_services, 'color': medicalTealPrimary},
      {'label': 'Patients', 'value': '10', 'icon': Icons.people, 'color': careCoralPrimary},
      {'label': 'Ordonnances', 'value': '5', 'icon': Icons.medication, 'color': vitalityGreenPrimary},
    ];

    return Row(
      children: stats.map((stat) {
        return Container(
          margin: EdgeInsets.only(right: 12),
          padding: EdgeInsets.all(12),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
            borderRadius: radius(12),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: (stat['color'] as Color).withValues(alpha: 0.12), borderRadius: radius(8)),
                child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
              ),
              8.height,
              Text(stat['value'] as String, style: boldTextStyle(size: 20)),
              2.height,
              Text(stat['label'] as String, style: secondaryTextStyle(size: 11), textAlign: TextAlign.center),
            ],
          ),
        ).expand();
      }).toList(),
    );
  }

  Widget _buildTodayAgenda(BuildContext context, bool isDark, List agendaList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Agenda du jour', style: boldTextStyle(size: 18)),
            TextButton(
              onPressed: () {
                onNavigateToTab(1);
              },
              child: Text('Voir tout', style: boldTextStyle(size: 13, color: mlColorDarkBlue)),
            ),
          ],
        ),
        12.height,
        ...agendaList.map((e) => _buildAgendaItem(context, isDark, e)),
      ],
    );
  }

  Widget _buildAgendaItem(BuildContext context, bool isDark, MLDoctorAgendaData e) {
    Color statusColor;
    switch (e.status) {
      case 'Confirmé':
        statusColor = medicalTealPrimary;
        break;
      case 'En attente':
        statusColor = healthWarning;
        break;
      case 'Annulé':
        statusColor = healthError;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(color: statusColor, borderRadius: radius(2)),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${e.startTime} - ${e.endTime}', style: boldTextStyle(size: 13)),
                  8.width,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: radius(4)),
                    child: Text(e.status.validate(), style: boldTextStyle(size: 10, color: statusColor)),
                  ),
                ],
              ),
              4.height,
              Text(e.patientName.validate(), style: boldTextStyle(size: 14)),
              2.height,
              Text('${e.type}  •  ${e.notes}', style: secondaryTextStyle(size: 12)),
            ],
          ).expand(),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    ).onTap(() {
      // Navigate to consultation detail
    });
  }

  Widget _buildUpcomingConsultations(BuildContext context, bool isDark, List consultationList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Consultations à venir', style: boldTextStyle(size: 18)),
            TextButton(
              onPressed: () {
                onNavigateToTab(2);
              },
              child: Text('Voir tout', style: boldTextStyle(size: 13, color: mlColorDarkBlue)),
            ),
          ],
        ),
        12.height,
        ...consultationList.map((e) => _buildConsultationCard(context, isDark, e)),
      ],
    );
  }

  Widget _buildConsultationCard(BuildContext context, bool isDark, MLDoctorConsultationData e) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: medicalBluePrimary.withValues(alpha: 0.12),
            child: Text(e.patientName.validate()[0], style: boldTextStyle(size: 16, color: medicalBluePrimary)),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(e.patientName.validate(), style: boldTextStyle(size: 14)),
                  8.width,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: medicalBluePrimary.withValues(alpha: 0.12), borderRadius: radius(4)),
                    child: Text(e.type.validate(), style: boldTextStyle(size: 10, color: medicalBluePrimary)),
                  ),
                ],
              ),
              4.height,
              Text('${e.date} à ${e.time}', style: secondaryTextStyle(size: 12)),
              2.height,
              Text(e.chiefComplaint.validate(), style: secondaryTextStyle(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ).expand(),
          Column(
            children: [
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              4.height,
              Text(e.status.validate(), style: boldTextStyle(size: 11, color: medicalTealPrimary)),
            ],
          ),
        ],
      ),
    ).onTap(() {
      // Navigate to consultation detail
    });
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      {'label': 'Nouvelle consultation', 'icon': Icons.add_circle_outline, 'color': medicalBluePrimary, 'index': 2},
      {'label': 'Gérer l\'agenda', 'icon': Icons.calendar_month, 'color': medicalTealPrimary, 'index': 1},
      {'label': 'Mes patients', 'icon': Icons.people_outline, 'color': careCoralPrimary, 'index': 3},
      {'label': 'Nouvelle ordonnance', 'icon': Icons.description_outlined, 'color': vitalityGreenPrimary, 'index': 4},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: boldTextStyle(size: 18)),
        12.height,
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Container(
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
                borderRadius: radius(12),
                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: (action['color'] as Color).withValues(alpha: 0.12), borderRadius: radius(12)),
                    child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                  ),
                  10.height,
                  Text(action['label'] as String, style: boldTextStyle(size: 13), textAlign: TextAlign.center),
                ],
              ),
            ).onTap(() {
              onNavigateToTab(action['index'] as int);
            });
          },
        ),
      ],
    );
  }
}