import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/theme/medical_theme.dart';
import 'package:medilab_prokit/features/appointment/presentation/components/appointment_detail_list_component.dart';
import 'package:medilab_prokit/features/doctor/presentation/components/specialist_horizontal_list.dart';
import 'package:medilab_prokit/features/home/presentation/components/home_top.dart';
import 'package:medilab_prokit/features/home/presentation/components/news_and_video.dart';
import 'package:medilab_prokit/features/patient/presentation/components/medication_list.dart';

class MLHomeFragment extends StatefulWidget {
  static String tag = '/MLHomeFragment';

  const MLHomeFragment({super.key});

  @override
  MLHomeFragmentState createState() => MLHomeFragmentState();
}

class MLHomeFragmentState extends State<MLHomeFragment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topFade;
  late Animation<Offset> _topSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _topFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: MedicalThemeData.emphasizedCurve),
    );
    _topSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: MedicalThemeData.emphasizedCurve),
      ),
    );

    _controller.forward();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FadeTransition(
            opacity: _topFade,
            child: SlideTransition(
              position: _topSlide,
              child: MLHomeTopComponent(),
            ),
          ),

          _buildStatsRow(context),
          24.height,

          MLSpecialistHorizontalList(),
          8.height,

          _sectionTitle('Prochains rendez-vous'),
          MLAppointmentDetailListComponent(),

          MLMedicationComponent(),

          _sectionTitle('Actualités & conseils'),
          const MLNewsAnVideoComponent(),

          32.height,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: boldTextStyle(size: 18)).paddingOnly(
      left: 16,
      right: 16,
      top: 8,
      bottom: 4,
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      _StatData(
        label: 'Fréquence cardiaque',
        value: '72',
        unit: 'bpm',
        icon: Icons.favorite_outline,
        color: healthError,
        tint: healthErrorLight,
      ),
      _StatData(
        label: 'Poids',
        value: '68,4',
        unit: 'kg',
        icon: Icons.monitor_weight_outlined,
        color: medicalTealPrimary,
        tint: medicalTealUltraLight,
      ),
      _StatData(
        label: 'Tension',
        value: '120/80',
        unit: 'mmHg',
        icon: Icons.bloodtype_outlined,
        color: cyanAccentDark,
        tint: cyanSurface,
      ),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: shadowLight,
                      offset: const Offset(0, 4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s.icon, size: 20, color: s.color),
                    ),
                    10.height,
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: s.value,
                            style: boldTextStyle(size: 18, color: medicalBlack),
                          ),
                          TextSpan(
                            text: ' ${s.unit}',
                            style: secondaryTextStyle(
                              size: 11,
                              color: medicalDarkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    2.height,
                    Text(
                      s.label,
                      style: secondaryTextStyle(size: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    ).paddingSymmetric(horizontal: 10);
  }
}

class _StatData {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color tint;

  const _StatData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.tint,
  });
}
