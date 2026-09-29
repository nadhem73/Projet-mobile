import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorPatientMedicalRecordScreen extends StatefulWidget {
  static String tag = '/MLDoctorPatientMedicalRecordScreen';

  final String? patientId;

  const MLDoctorPatientMedicalRecordScreen({super.key, this.patientId});

  @override
  MLDoctorPatientMedicalRecordScreenState createState() => MLDoctorPatientMedicalRecordScreenState();
}

class MLDoctorPatientMedicalRecordScreenState extends State<MLDoctorPatientMedicalRecordScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MLDoctorMedicalRecordData? medicalRecord;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    init();
  }

  Future<void> init() async {
    medicalRecord = mlDoctorMedicalRecordData();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final r = medicalRecord!;

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
              _buildHeader(context, isDark, r),
              _buildTabBar(context, isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, isDark, r),
                    _buildHistoryTab(context, isDark, r),
                    _buildLabsTab(context, isDark, r),
                    _buildPrescriptionsTab(context, isDark, r),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
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
              Text('Dossier médical', style: boldTextStyle(size: 22, color: white)).expand(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: white.withValues(alpha: 0.15),
                  borderRadius: radius(20),
                ),
                child: Text('Médecin traitant', style: boldTextStyle(size: 12, color: white)),
              ),
            ],
          ),
          16.height,
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: mlColorCyan,
                backgroundImage: AssetImage('assets/images/ml_profile_Image.png'),
              ),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.patientName.validate(), style: boldTextStyle(size: 20, color: white)),
                  4.height,
                  Text('${r.patientAge} ans  •  ${r.patientGender == 'F' ? 'Femme' : 'Homme'}  •  Groupe ${r.bloodType}', style: secondaryTextStyle(color: white.withValues(alpha: 0.7), size: 13)),
                ],
              ).expand(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _quickVital(context, 'TA', r.vitals!['Tension artérielle'] ?? '', medicalTealPrimary),
                  _quickVital(context, 'Poids', r.vitals!['Poids'] ?? '', medicalBluePrimary),
                  _quickVital(context, 'Glycémie', r.vitals!['Glycémie à jeun'] ?? '', careCoralPrimary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickVital(BuildContext context, String label, String value, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: radius(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: boldTextStyle(size: 11, color: color)),
          Text(value, style: boldTextStyle(size: 11, color: white)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? black : white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: mlColorDarkBlue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: mlColorDarkBlue,
        indicatorWeight: 3,
        labelStyle: boldTextStyle(size: 13),
        unselectedLabelStyle: boldTextStyle(size: 13),
        tabs: [
          Tab(text: 'Vue d\'ensemble'),
          Tab(text: 'Antécédents'),
          Tab(text: 'Bilans / Labo'),
          Tab(text: 'Ordonnances'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(context, isDark, 'Constantes vitales', Icons.monitor_heart, _buildVitalsGrid(context, isDark, r)),
          20.height,
          _buildSection(context, isDark, 'Antécédents médicaux', Icons.history_edu, _buildListItems(context, isDark, r.medicalHistory!)),
          20.height,
          _buildSection(context, isDark, 'Allergies', Icons.warning_amber, _buildListItems(context, isDark, r.allergies!)),
          20.height,
          _buildSection(context, isDark, 'Traitements en cours', Icons.medication, _buildListItems(context, isDark, r.currentMedications!)),
          20.height,
          _buildSection(context, isDark, 'Documents', Icons.folder, _buildListItems(context, isDark, r.documents!)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(context, isDark, 'Historique des consultations', Icons.medical_services, _buildConsultationHistory(context, isDark, r)),
          20.height,
          _buildSection(context, isDark, 'Antécédents médicaux détaillés', Icons.history_edu, _buildDetailedHistory(context, isDark, r)),
        ],
      ),
    );
  }

  Widget _buildLabsTab(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(context, isDark, 'Résultats de laboratoire', Icons.biotech, _buildLabResults(context, isDark, r)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(context, isDark, 'Ordonnances actuelles et passées', Icons.description, _buildPrescriptionList(context, isDark, r)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, bool isDark, String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: mlColorDarkBlue, size: 20),
            8.width,
            Text(title, style: boldTextStyle(size: 18)),
          ],
        ),
        12.height,
        child,
      ],
    );
  }

  Widget _buildVitalsGrid(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    final vitals = r.vitals!.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: vitals.length,
      itemBuilder: (context, index) {
        final entry = vitals[index];
        return Container(
          padding: EdgeInsets.all(12),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
            borderRadius: radius(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: secondaryTextStyle(size: 12)),
              4.height,
              Text(entry.value, style: boldTextStyle(size: 16)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListItems(BuildContext context, bool isDark, List<String> items) {
    return Column(
      children: items.map((item) => Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
          borderRadius: radius(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: mlColorDarkBlue.withValues(alpha: 0.1), borderRadius: radius(8)),
              child: Icon(Icons.chevron_right, color: mlColorDarkBlue, size: 20),
            ),
            12.width,
            Text(item, style: boldTextStyle(size: 13)).expand(),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildConsultationHistory(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return Column(
      children: r.consultationHistory!.map((c) => Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(12),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
          borderRadius: radius(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
              child: Icon(Icons.medical_services, color: medicalTealPrimary, size: 20),
            ),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.department.validate(), style: boldTextStyle(size: 14)),
                2.height,
                Text('${c.doctor}  •  ${c.date} ${c.month}', style: secondaryTextStyle(size: 12)),
                Text('${c.service}  •  ${c.patient}', style: secondaryTextStyle(size: 11, color: Colors.grey)),
              ],
            ).expand(),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildDetailedHistory(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return _buildListItems(context, isDark, r.medicalHistory!);
  }

  Widget _buildLabResults(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return Column(
      children: r.labResults!.map((lab) => Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(12),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
          borderRadius: radius(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(lab.status!).withValues(alpha: 0.1),
                borderRadius: radius(8),
              ),
              child: Icon(Icons.science, color: _getStatusColor(lab.status!), size: 20),
            ),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lab.title.validate(), style: boldTextStyle(size: 14)),
                2.height,
                Text('${lab.date}  •  ${lab.status}', style: secondaryTextStyle(size: 12)),
              ],
            ).expand(),
            Icon(Icons.picture_as_pdf, size: 20, color: healthError),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPrescriptionList(BuildContext context, bool isDark, MLDoctorMedicalRecordData r) {
    return Column(
      children: r.prescriptions!.map((rx) => Container(
        margin: EdgeInsets.only(bottom: 10),
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
                  child: Icon(Icons.medication, color: medicalTealPrimary, size: 20),
                ),
                12.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${rx.doctor}  •  ${rx.specialty}', style: boldTextStyle(size: 14)),
                    2.height,
                    Text('${rx.date}  •  ${rx.status}', style: secondaryTextStyle(size: 12)),
                  ],
                ).expand(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRxStatusColor(rx.status!).withValues(alpha: 0.1),
                    borderRadius: radius(12),
                  ),
                  child: Text(rx.status.validate(), style: boldTextStyle(size: 11, color: _getRxStatusColor(rx.status!))),
                ),
              ],
            ),
            12.height,
            Padding(
              padding: EdgeInsets.only(left: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rx.medicines!.map((med) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.grey),
                      8.width,
                      Text(med, style: secondaryTextStyle(size: 12)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Analysé':
        return medicalTealPrimary;
      case 'En attente':
        return healthWarning;
      default:
        return Colors.grey;
    }
  }

  Color _getRxStatusColor(String status) {
    switch (status) {
      case 'Active':
        return medicalTealPrimary;
      case 'Terminée':
        return medicalBluePrimary;
      default:
        return Colors.grey;
    }
  }
}