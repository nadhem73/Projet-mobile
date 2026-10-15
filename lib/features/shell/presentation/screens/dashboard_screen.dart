import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilink/features/shell/presentation/widgets/bottom_nav_bar.dart';
import 'package:medilink/features/shell/presentation/fragments/home_fragment.dart';
import 'package:medilink/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:medilink/features/ai/presentation/screens/lab_scan_screen.dart';
import 'package:medilink/features/user/presentation/screens/medical_record_screen.dart';
import 'package:medilink/features/doctor/presentation/screens/prescription_screen.dart';
import 'package:medilink/features/appointment/presentation/screens/rendez_vous_screen.dart';
import 'package:medilink/core/theme/colors.dart';
import 'package:medilink/core/utils/ui_helpers.dart';

class MLDashboardScreen extends StatefulWidget {
  static String tag = '/MLDashboardScreen';

  const MLDashboardScreen({super.key});

  @override
  MLDashboardScreenState createState() => MLDashboardScreenState();
}

class MLDashboardScreenState extends State<MLDashboardScreen> {
  int currentWidget = 0;
  bool showAiAssistant = false;
  List<Widget> widgets = [
    MLHomeFragment(),
    MLRendezVousScreen(),
    MLMedicalRecordScreen(),
    MLLabScanScreen(),
    MLPrescriptionScreen(),
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
    changeStatusColor(mlPrimaryColor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(

        body: showAiAssistant ? const MLAiAssistantScreen() : widgets[currentWidget],
        floatingActionButton: _chatFab(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: showBottomDrawer(),
      ),
    );
  }

  Widget _chatFab(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [medicalTealLight, medicalTealPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: medicalTealPrimary.withValues(alpha: 0.45),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() {
              showAiAssistant = true;
            });
          },
          child: const Icon(Icons.chat_bubble_rounded, color: white, size: 26),
        ),
      ),
    );
  }

  Widget showBottomDrawer() {
    return MLBottomNavigationBarWidget(
      index: currentWidget,
      onTap: (index) {
        setState(() {
          showAiAssistant = false;
          currentWidget = index;
        });
      },
    );
  }
}
