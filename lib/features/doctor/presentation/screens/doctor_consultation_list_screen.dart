import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorConsultationListScreen extends StatefulWidget {
  static String tag = '/MLDoctorConsultationListScreen';

  const MLDoctorConsultationListScreen({super.key});

  @override
  MLDoctorConsultationListState createState() => MLDoctorConsultationListState();
}

class MLDoctorConsultationListState extends State<MLDoctorConsultationListScreen> {
  String selectedFilter = 'Tous';
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
    final consultations = mlDoctorConsultationDataList();
    final filteredConsultations = _filterConsultations(consultations);

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
              _buildSearchAndFilter(context, isDark),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredConsultations.length,
                  itemBuilder: (context, index) {
                    return _buildConsultationCard(context, isDark, filteredConsultations[index]);
                  },
                ),
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
          Text('Consultations', style: boldTextStyle(size: 22, color: white)).expand(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: white.withValues(alpha: 0.15),
              borderRadius: radius(20),
            ),
            child: Text('${filteredCount()} éléments', style: boldTextStyle(size: 12, color: white)),
          ),
        ],
      ),
    );
  }

  int filteredCount() {
    return _filterConsultations(mlDoctorConsultationDataList()).length;
  }

  Widget _buildSearchAndFilter(BuildContext context, bool isDark) {
    final filters = ['Tous', 'Aujourd\'hui', 'Cette semaine', 'En cours', 'Terminés', 'Annulés'];

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
                hintText: 'Rechercher patient, motif...',
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
              children: filters.map((filter) {
                final isSelected = selectedFilter == filter;
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter, style: boldTextStyle(size: 12, color: isSelected ? white : (isDark ? white : mlColorDarkBlue))),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedFilter = filter),
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

  List<MLDoctorConsultationData> _filterConsultations(List<MLDoctorConsultationData> list) {
    var filtered = list.where((c) {
      final search = searchController.text.toLowerCase();
      final matchesSearch = search.isEmpty ||
          c.patientName!.toLowerCase().contains(search) ||
          c.chiefComplaint!.toLowerCase().contains(search) ||
          c.diagnosis!.toLowerCase().contains(search);
      return matchesSearch;
    }).toList();

    switch (selectedFilter) {
      case 'Aujourd\'hui':
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        filtered = filtered.where((c) => c.date == todayStr).toList();
        break;
      case 'Cette semaine':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(Duration(days: 6));
        filtered = filtered.where((c) {
          final date = DateTime.parse(c.date!);
          return date.isAfter(weekStart.subtract(Duration(days: 1))) && date.isBefore(weekEnd.add(Duration(days: 1)));
        }).toList();
        break;
      case 'En cours':
        filtered = filtered.where((c) => c.status == 'En cours' || c.status == 'Programmé').toList();
        break;
      case 'Terminés':
        filtered = filtered.where((c) => c.status == 'Terminé').toList();
        break;
      case 'Annulés':
        filtered = filtered.where((c) => c.status == 'Annulé').toList();
        break;
    }

    filtered.sort((a, b) => b.date!.compareTo(a.date!));
    return filtered;
  }

  Widget _buildConsultationCard(BuildContext context, bool isDark, MLDoctorConsultationData c) {
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: medicalBluePrimary.withValues(alpha: 0.12),
                child: Text(c.patientName!.substring(0, 1), style: boldTextStyle(size: 14, color: medicalBluePrimary)),
              ),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.patientName.validate(), style: boldTextStyle(size: 15)),
                  2.height,
                  Text('${c.patientAge} ans  •  ${c.patientGender == 'F' ? 'Femme' : 'Homme'}', style: secondaryTextStyle(size: 12)),
                ],
              ).expand(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: radius(12)),
                    child: Text(c.status.validate(), style: boldTextStyle(size: 11, color: statusColor)),
                  ),
                  4.height,
                  Text('${c.date}  ${c.time}', style: secondaryTextStyle(size: 11)),
                ],
              ),
            ],
          ),
          12.height,
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: mlColorDarkBlue.withValues(alpha: 0.1), borderRadius: radius(8)),
                child: Text(c.type.validate(), style: boldTextStyle(size: 11, color: mlColorDarkBlue)),
              ),
              8.width,
              if (c.prescriptionId!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medication, size: 11, color: medicalTealPrimary),
                      4.width,
                      Text('Ordonnance', style: boldTextStyle(size: 11, color: medicalTealPrimary)),
                    ],
                  ),
                ),
            ],
          ),
          10.height,
          if (c.chiefComplaint!.isNotEmpty) ...[
            Text('Motif: ', style: boldTextStyle(size: 12)),
            Text(c.chiefComplaint.validate(), style: secondaryTextStyle(size: 12)),
            8.height,
          ],
          if (c.diagnosis!.isNotEmpty) ...[
            Text('Diagnostic: ', style: boldTextStyle(size: 12)),
            Text(c.diagnosis.validate(), style: secondaryTextStyle(size: 12)),
          ],
        ],
      ),
    ).onTap(() {
      // Navigate to consultation detail
    });
  }
}