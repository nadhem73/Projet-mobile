import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorPatientListScreen extends StatefulWidget {
  static String tag = '/MLDoctorPatientListScreen';

  const MLDoctorPatientListScreen({super.key});

  @override
  MLDoctorPatientListScreenState createState() => MLDoctorPatientListScreenState();
}

class MLDoctorPatientListScreenState extends State<MLDoctorPatientListScreen> {
  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'Tous';

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
    final patients = mlDoctorPatientSummaryDataList();
    final filteredPatients = _filterPatients(patients);

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
              _buildHeader(context, isDark, filteredPatients),
              _buildSearchAndFilter(context, isDark),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    return _buildPatientCard(context, isDark, filteredPatients[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, List filteredPatients) {
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
          Text('Mes patients', style: boldTextStyle(size: 22, color: white)).expand(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: white.withValues(alpha: 0.15),
              borderRadius: radius(20),
            ),
            child: Text('${filteredPatients.length} patients', style: boldTextStyle(size: 12, color: white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, bool isDark) {
    final filters = ['Tous', 'RDV à venir', 'Pathologie chronique', 'Sans RDV'];

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
                hintText: 'Rechercher un patient...',
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

  List<MLDoctorPatientSummaryData> _filterPatients(List<MLDoctorPatientSummaryData> list) {
    var filtered = list.where((p) {
      final search = searchController.text.toLowerCase();
      final matchesSearch = search.isEmpty ||
          p.name!.toLowerCase().contains(search) ||
          p.phone!.contains(search) ||
          p.email!.toLowerCase().contains(search);
      return matchesSearch;
    }).toList();

    switch (selectedFilter) {
      case 'RDV à venir':
        filtered = filtered.where((p) => p.nextAppointment!.isNotEmpty).toList();
        break;
      case 'Pathologie chronique':
        filtered = filtered.where((p) => p.conditions!.isNotEmpty).toList();
        break;
      case 'Sans RDV':
        filtered = filtered.where((p) => p.nextAppointment!.isEmpty).toList();
        break;
    }

    return filtered;
  }

  Widget _buildPatientCard(BuildContext context, bool isDark, MLDoctorPatientSummaryData p) {
    final hasConditions = p.conditions!.isNotEmpty;
    final hasUpcoming = p.nextAppointment!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: medicalBluePrimary.withValues(alpha: 0.12),
            backgroundImage: AssetImage(p.avatar!),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.name.validate(), style: boldTextStyle(size: 15)),
                  8.width,
                  if (hasUpcoming)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: careCoralPrimary.withValues(alpha: 0.12), borderRadius: radius(4)),
                      child: Text('RDV ${_formatDate(p.nextAppointment!)}', style: boldTextStyle(size: 10, color: careCoralPrimary)),
                    ),
                ],
              ),
              4.height,
              Text('${p.age} ans  •  ${p.gender == 'F' ? 'Femme' : 'Homme'}  •  Dernière visite: ${_formatDate(p.lastVisit!)}', style: secondaryTextStyle(size: 12)),
              4.height,
              if (hasConditions)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.conditions!.map((c) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
                    child: Text(c, style: boldTextStyle(size: 10, color: medicalTealPrimary)),
                  )).toList(),
                ),
            ],
          ).expand(),
          Column(
            children: [
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              4.height,
              if (p.activeMedications!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: vitalityGreenPrimary.withValues(alpha: 0.1), borderRadius: radius(4)),
                  child: Text('${p.activeMedications!.length} médoc(s)', style: boldTextStyle(size: 9, color: vitalityGreenPrimary)),
                ),
            ],
          ),
        ],
      ),
    ).onTap(() {
      // Navigate to patient medical record
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}