import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorConsultationDetailScreen extends StatefulWidget {
  static String tag = '/MLDoctorConsultationDetailScreen';

  final String? consultationId;

  const MLDoctorConsultationDetailScreen({super.key, this.consultationId});

  @override
  MLDoctorConsultationDetailScreenState createState() => MLDoctorConsultationDetailScreenState();
}

class MLDoctorConsultationDetailScreenState extends State<MLDoctorConsultationDetailScreen> {
  MLDoctorConsultationData? consultation;
  final TextEditingController chiefComplaintController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController glycemiaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final list = mlDoctorConsultationDataList();
    consultation = list.firstWhere(
      (c) => c.id == widget.consultationId,
      orElse: () => list.first,
    );
    _populateFields();
  }

  void _populateFields() {
    if (consultation == null) return;
    chiefComplaintController.text = consultation!.chiefComplaint ?? '';
    diagnosisController.text = consultation!.diagnosis ?? '';
    notesController.text = consultation!.notes ?? '';
    if (consultation!.vitals != null && consultation!.vitals!.isNotEmpty) {
      for (var v in consultation!.vitals!) {
        if (v.contains('TA:')) {
          final parts = v.replaceAll('TA:', '').trim().split('/');
          if (parts.length == 2) {
            systolicController.text = parts[0].trim();
            diastolicController.text = parts[1].replaceAll('mmHg', '').trim();
          }
        } else if (v.contains('Poids:')) {
          weightController.text = v.replaceAll('Poids:', '').replaceAll('kg', '').trim();
        } else if (v.contains('Taille:')) {
          heightController.text = v.replaceAll('Taille:', '').replaceAll('cm', '').trim();
        } else if (v.contains('FC:') || v.contains('Fréquence:')) {
          heartRateController.text = v.replaceAll('FC:', '').replaceAll('Fréquence:', '').replaceAll('bpm', '').trim();
        } else if (v.contains('Température:')) {
          temperatureController.text = v.replaceAll('Température:', '').replaceAll('°C', '').trim();
        } else if (v.contains('Saturation') || v.contains('SpO2')) {
          spo2Controller.text = v.replaceAll('Saturation O2:', '').replaceAll('SpO2:', '').replaceAll('%', '').trim();
        } else if (v.contains('Glycémie') || v.contains('HbA1c')) {
          glycemiaController.text = v.replaceAll('Glycémie à jeun:', '').replaceAll('HbA1c:', '').replaceAll('g/L', '').replaceAll('%', '').trim();
        }
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    chiefComplaintController.dispose();
    diagnosisController.dispose();
    notesController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    weightController.dispose();
    heightController.dispose();
    heartRateController.dispose();
    temperatureController.dispose();
    spo2Controller.dispose();
    glycemiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final c = consultation!;

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
            children: [
              _buildHeader(context, isDark, c),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientInfo(context, isDark, c),
                      20.height,
                      _buildVitalsSection(context, isDark),
                      20.height,
                      _buildChiefComplaintSection(context, isDark),
                      20.height,
                      _buildDiagnosisSection(context, isDark),
                      20.height,
                      _buildNotesSection(context, isDark),
                      20.height,
                      _buildActions(context, isDark, c),
                      100.height,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, MLDoctorConsultationData c) {
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
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: mlColorDarkBlue,
        borderRadius: radiusOnly(bottomRight: 32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_back, color: white, size: 24).onTap(() => finish(context)),
              8.width,
              Text('Consultation', style: boldTextStyle(size: 22, color: white)).expand(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  borderRadius: radius(20),
                ),
                child: Text(c.status.validate(), style: boldTextStyle(size: 12, color: statusColor)),
              ),
            ],
          ),
          16.height,
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: mlColorCyan,
                child: Text(c.patientName!.substring(0, 1), style: boldTextStyle(size: 20, color: white)),
              ),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.patientName.validate(), style: boldTextStyle(size: 18, color: white)),
                  2.height,
                  Text('${c.patientAge} ans  •  ${c.patientGender == 'F' ? 'Femme' : 'Homme'}  •  ${c.type}', style: secondaryTextStyle(color: white.withValues(alpha: 0.7), size: 13)),
                  2.height,
                  Text('${c.date} à ${c.time}', style: secondaryTextStyle(color: white.withValues(alpha: 0.5), size: 12)),
                ],
              ).expand(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(BuildContext context, bool isDark, MLDoctorConsultationData c) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations patient', style: boldTextStyle(size: 16)),
          12.height,
          Row(
            children: [
              _infoItem(context, Icons.phone, 'Téléphone', c.patientId == 'P001' ? '06 12 34 56 78' : '06 XX XX XX XX'),
              _infoItem(context, Icons.email, 'Email', c.patientId == 'P001' ? 'kaixa.pham@email.com' : 'patient@email.com'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              4.width,
              Text(label, style: secondaryTextStyle(size: 11)),
            ],
          ),
          2.height,
          Text(value, style: boldTextStyle(size: 13)),
        ],
      ),
    );
  }

  Widget _buildVitalsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Constantes vitales', style: boldTextStyle(size: 16)),
            if (consultation!.status != 'Terminé' && consultation!.status != 'Annulé')
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 16),
                label: Text('Ajouter', style: boldTextStyle(size: 12)),
                style: TextButton.styleFrom(foregroundColor: mlColorDarkBlue),
              ),
          ],
        ),
        12.height,
        Row(
          children: [
            _vitalInput(context, 'Systolique', 'mmHg', systolicController, Icons.favorite),
            12.width,
            _vitalInput(context, 'Diastolique', 'mmHg', diastolicController, Icons.favorite_border),
            12.width,
            _vitalInput(context, 'FC', 'bpm', heartRateController, Icons.monitor_heart),
          ],
        ),
        12.height,
        Row(
          children: [
            _vitalInput(context, 'Poids', 'kg', weightController, Icons.monitor_weight),
            12.width,
            _vitalInput(context, 'Taille', 'cm', heightController, Icons.height),
            12.width,
            _vitalInput(context, 'Temp.', '°C', temperatureController, Icons.thermostat),
          ],
        ),
        12.height,
        Row(
          children: [
            _vitalInput(context, 'SpO2', '%', spo2Controller, Icons.air),
            12.width,
            _vitalInput(context, 'Glycémie', 'g/L', glycemiaController, Icons.water_drop),
          ],
        ),
      ],
    );
  }

  Widget _vitalInput(BuildContext context, String label, String unit, TextEditingController controller, IconData icon) {
    final bool isDark = appStore.isDarkModeOn;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
          borderRadius: radius(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: mlColorDarkBlue),
                4.width,
                Text(label, style: secondaryTextStyle(size: 11)),
              ],
            ),
            8.height,
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: secondaryTextStyle(size: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: boldTextStyle(size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChiefComplaintSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Motif de consultation', style: boldTextStyle(size: 16)),
        12.height,
        TextField(
          controller: chiefComplaintController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Décrire le motif de la consultation...',
            hintStyle: secondaryTextStyle(size: 14),
            filled: true,
            fillColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: radius(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diagnostic', style: boldTextStyle(size: 16)),
        12.height,
        TextField(
          controller: diagnosisController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Saisir le diagnostic...',
            hintStyle: secondaryTextStyle(size: 14),
            filled: true,
            fillColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: radius(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes / Observations', style: boldTextStyle(size: 16)),
        12.height,
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Notes cliniques, suivi, recommandations...',
            hintStyle: secondaryTextStyle(size: 14),
            filled: true,
            fillColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: radius(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, MLDoctorConsultationData c) {
    final canEdit = c.status != 'Terminé' && c.status != 'Annulé';

    return Row(
      children: [
        if (canEdit) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _saveConsultation();
              },
              icon: Icon(Icons.save, size: 18),
              label: Text('Enregistrer', style: boldTextStyle(size: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: mlColorDarkBlue,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: radius(12)),
              ),
            ),
          ),
          12.width,
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to prescription screen
            },
            icon: Icon(Icons.medication, size: 18),
            label: Text(c.prescriptionId!.isNotEmpty ? 'Voir ordonnance' : 'Créer ordonnance', style: boldTextStyle(size: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: medicalTealPrimary,
              foregroundColor: white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: radius(12)),
            ),
          ),
        ),
        if (canEdit) ...[
          12.width,
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _finishConsultation();
              },
              icon: Icon(Icons.check_circle, size: 18),
              label: Text('Terminer', style: boldTextStyle(size: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: medicalTealPrimary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: radius(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _saveConsultation() {
    toasty(context, 'Consultation enregistrée');
  }

  void _finishConsultation() {
    toasty(context, 'Consultation terminée - Redirection vers ordonnance');
  }
}