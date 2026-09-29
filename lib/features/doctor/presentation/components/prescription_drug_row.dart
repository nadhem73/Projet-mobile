import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLPrescriptionDrugRow {
  final TextEditingController medicineController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;
  final TextEditingController timingController;
  final TextEditingController routeController;
  final TextEditingController instructionsController;

  MLPrescriptionDrugRow({String? medicine})
      : medicineController = TextEditingController(text: medicine ?? ''),
        dosageController = TextEditingController(),
        frequencyController = TextEditingController(),
        durationController = TextEditingController(),
        timingController = TextEditingController(),
        routeController = TextEditingController(),
        instructionsController = TextEditingController();

  void dispose() {
    medicineController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    timingController.dispose();
    routeController.dispose();
    instructionsController.dispose();
  }

  Widget build(BuildContext context, int index, VoidCallback onDelete, {bool showDelete = true}) {
    final bool isDark = appStore.isDarkModeOn;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: mlColorDarkBlue.withValues(alpha: 0.1), borderRadius: radius(6)),
                child: Text('${index + 1}', style: boldTextStyle(size: 12, color: mlColorDarkBlue)),
              ),
              12.width,
              Expanded(
                child: TextField(
                  controller: medicineController,
                  decoration: InputDecoration(
                    hintText: 'Nom du médicament (ex: Doliprane 1000mg)',
                    hintStyle: secondaryTextStyle(size: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: boldTextStyle(size: 14),
                ),
              ),
              if (showDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: healthError, size: 20),
                ),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(child: _buildField(context, 'Posologie', dosageController, 'ex: 1 cp', Icons.medication)),
              12.width,
              Expanded(child: _buildField(context, 'Fréquence', frequencyController, 'ex: 3x/jour', Icons.schedule)),
              12.width,
              Expanded(child: _buildField(context, 'Durée', durationController, 'ex: 7 jours', Icons.calendar_today)),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(child: _buildField(context, 'Moment', timingController, 'ex: Matin/Midi/Soir', Icons.access_time)),
              12.width,
              Expanded(child: _buildField(context, 'Voie', routeController, 'ex: Orale', Icons.medical_information)),
            ],
          ),
          8.height,
          TextField(
            controller: instructionsController,
            decoration: InputDecoration(
              hintText: 'Instructions particulières (optionnel)',
              hintStyle: secondaryTextStyle(size: 12),
              filled: true,
              fillColor: isDark ? scaffoldDarkColor : white,
              border: OutlineInputBorder(borderRadius: radius(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: secondaryTextStyle(size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, TextEditingController controller, String hint, IconData icon) {
    final bool isDark = appStore.isDarkModeOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            4.width,
            Text(label, style: secondaryTextStyle(size: 11)),
          ],
        ),
        4.height,
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: secondaryTextStyle(size: 12),
            filled: true,
            fillColor: isDark ? scaffoldDarkColor : white,
            border: OutlineInputBorder(borderRadius: radius(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          style: boldTextStyle(size: 13),
        ),
      ],
    );
  }
}