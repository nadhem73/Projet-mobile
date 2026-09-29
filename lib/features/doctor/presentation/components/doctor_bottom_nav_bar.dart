import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorBottomNavigationBarWidget extends StatefulWidget {
  static String tag = '/MLDoctorBottomNavigationBarWidget';
  final Function(int)? onTap;
  final int? index;

  const MLDoctorBottomNavigationBarWidget({super.key, this.onTap, this.index});

  @override
  MLDoctorBottomNavigationBarWidgetState createState() => MLDoctorBottomNavigationBarWidgetState();
}

class MLDoctorBottomNavigationBarWidgetState extends State<MLDoctorBottomNavigationBarWidget> {
  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.calendar_month_outlined,
    Icons.medical_services_outlined,
    Icons.people_outlined,
    Icons.medication_outlined,
  ];

  final List<String> _labels = [
    'Tableau de bord',
    'Agenda',
    'Consultations',
    'Patients',
    'Ordonnances',
  ];

  final List<int> _displayOrder = [1, 2, 0, 3, 4];

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
    final isDark = appStore.isDarkModeOn;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : medicalTealPrimary.withValues(alpha: 0.15),
            offset: const Offset(0, -6),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: List.generate(_displayOrder.length, (position) {
              final screenIndex = _displayOrder[position];
              final isCenter = position == _displayOrder.length ~/ 2;
              return Expanded(
                child: Tooltip(
                  message: _labels[screenIndex],
                  child: isCenter
                      ? _buildCenterNavItem(
                          icon: _icons[screenIndex],
                          onTap: () => widget.onTap?.call(screenIndex),
                        )
                      : _buildNavItem(
                          icon: _icons[screenIndex],
                          isSelected: widget.index == screenIndex,
                          onTap: () => widget.onTap?.call(screenIndex),
                        ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [careCoralLight, careCoralPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: careCoralPrimary.withValues(alpha: 0.45),
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Icon(icon, size: 26, color: medicalWhite),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isSelected ? 11 : 8),
          decoration: BoxDecoration(
            color: isSelected ? careCoralPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: careCoralPrimary.withValues(alpha: 0.4),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected
                ? medicalWhite
                : (appStore.isDarkModeOn ? iconColorSecondaryDark : iconColorSecondary),
          ),
        ),
      ),
    );
  }
}