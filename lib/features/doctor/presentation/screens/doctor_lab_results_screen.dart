import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:medilab_prokit/features/patient/data/lab_scan_model.dart';

class MLDoctorLabResultsScreen extends StatefulWidget {
  static String tag = '/MLDoctorLabResultsScreen';

  final String? patientId;

  const MLDoctorLabResultsScreen({super.key, this.patientId});

  @override
  MLDoctorLabResultsScreenState createState() => MLDoctorLabResultsScreenState();
}

class MLDoctorLabResultsScreenState extends State<MLDoctorLabResultsScreen> {
  String selectedCategory = 'Tous';
  final TextEditingController searchController = TextEditingController();

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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;
    final labs = mlLabScanDataList();
    final filteredLabs = _filterLabs(labs);

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
              _buildHeader(context, isDark, filteredLabs),
              _buildSearchAndFilter(context, isDark),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredLabs.length,
                  itemBuilder: (context, index) {
                    return _buildLabCard(context, isDark, filteredLabs[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, List<MLLabScanData> filteredLabs) {
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
          Text('Bilans & Résultats', style: boldTextStyle(size: 22, color: white)).expand(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: white.withValues(alpha: 0.15),
              borderRadius: radius(20),
            ),
            child: Text('${filteredLabs.length} résultats', style: boldTextStyle(size: 12, color: white)),
          ),
        ],
      ),
    );
  }

  List<MLLabScanData> _filterLabs(List<MLLabScanData> list) {
    var filtered = list.where((l) {
      final search = searchController.text.toLowerCase();
      return search.isEmpty || l.title!.toLowerCase().contains(search);
    }).toList();

    return filtered;
  }

  Widget _buildSearchAndFilter(BuildContext context, bool isDark) {
    final categories = ['Tous', 'Hématologie', 'Biochimie', 'Immunologie', 'Microbiologie'];

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade100,
              borderRadius: radius(12),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un bilan...',
                hintStyle: secondaryTextStyle(size: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          12.height,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat, style: boldTextStyle(size: 12, color: isSelected ? white : (isDark ? white : mlColorDarkBlue))),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedCategory = cat),
                    selectedColor: mlColorDarkBlue,
                    backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: radius(20)),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabCard(BuildContext context, bool isDark, MLLabScanData lab) {
    Color statusColor;
    switch (lab.status) {
      case 'Analysé':
        statusColor = medicalTealPrimary;
        break;
      case 'En attente':
        statusColor = healthWarning;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(16),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: mlColorDarkBlue.withValues(alpha: 0.1), borderRadius: radius(10)),
                child: Icon(Icons.biotech, color: mlColorDarkBlue, size: 22),
              ),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lab.title.validate(), style: boldTextStyle(size: 15)),
                  2.height,
                  Text('Prescrit le ${lab.date}', style: secondaryTextStyle(size: 12)),
                ],
              ).expand(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: radius(12)),
                    child: Text(lab.status.validate(), style: boldTextStyle(size: 11, color: statusColor)),
                  ),
                  4.height,
                  Icon(Icons.picture_as_pdf, size: 22, color: healthError),
                ],
              ),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    toasty(context, 'Ouverture du PDF...');
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Voir résultats', style: boldTextStyle(size: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mlColorDarkBlue,
                    side: BorderSide(color: mlColorDarkBlue),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: radius(10)),
                  ),
                ),
              ),
              12.width,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    toasty(context, 'Téléchargement...');
                  },
                  icon: Icon(Icons.download, size: 16),
                  label: Text('Télécharger', style: boldTextStyle(size: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: medicalTealPrimary,
                    side: BorderSide(color: medicalTealPrimary),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: radius(10)),
                  ),
                ),
              ),
              12.width,
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    toasty(context, 'Partage au patient...');
                  },
                  icon: Icon(Icons.share, size: 16),
                  label: Text('Partager', style: boldTextStyle(size: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: medicalTealPrimary,
                    foregroundColor: white,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: radius(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).onTap(() {
      // Navigate to lab detail
    });
  }
}