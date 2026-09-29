import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';

import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLDoctorPrescriptionScreen extends StatefulWidget {
  static String tag = '/MLDoctorPrescriptionScreen';

  final String? consultationId;
  final String? patientId;
  final bool isTemplate;

  const MLDoctorPrescriptionScreen({super.key, this.consultationId, this.patientId, this.isTemplate = false});

  @override
  MLDoctorPrescriptionScreenState createState() => MLDoctorPrescriptionScreenState();
}

class MLDoctorPrescriptionScreenState extends State<MLDoctorPrescriptionScreen> {
  final List<PrescriptionItem> _items = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  String _selectedTemplate = '';
  bool _showTemplates = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    _items.add(PrescriptionItem());
    if (widget.isTemplate) {
      _loadTemplate();
    }
  }

  void _loadTemplate() {
    final templates = mlDoctorPrescriptionTemplateDataList();
    if (templates.isNotEmpty) {
      final template = templates.first;
      _selectedTemplate = template.name!;
      for (var med in template.medicines!) {
        _items.add(PrescriptionItem(medicine: med));
      }
      _instructionsController.text = template.dosageInstructions ?? '';
      _items.removeAt(0);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;

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
              _buildHeader(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientInfo(context, isDark),
                      20.height,
                      _buildTemplateSelector(context, isDark),
                      20.height,
                      _buildMedicationList(context, isDark),
                      20.height,
                      _buildAddMedication(context, isDark),
                      20.height,
                      _buildGlobalInstructions(context, isDark),
                      20.height,
                      _buildDuration(context, isDark),
                      100.height,
                    ],
                  ),
                ),
              ),
              _buildBottomActions(context, isDark),
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
          Text(widget.isTemplate ? 'Modèle d\'ordonnance' : 'Nouvelle ordonnance', style: boldTextStyle(size: 22, color: white)).expand(),
          if (!widget.isTemplate)
            TextButton.icon(
              onPressed: () {
                setState(() => _showTemplates = !_showTemplates);
              },
              icon: Icon(_showTemplates ? Icons.expand_less : Icons.expand_more, color: white, size: 18),
              label: Text(_showTemplates ? 'Masquer modèles' : 'Modèles', style: boldTextStyle(size: 12, color: white)),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(BuildContext context, bool isDark) {
    final patient = widget.patientId != null
        ? mlDoctorPatientSummaryDataList().firstWhere((p) => p.id == widget.patientId, orElse: () => mlDoctorPatientSummaryDataList().first)
        : mlDoctorPatientSummaryDataList().first;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
        borderRadius: radius(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: medicalBluePrimary.withValues(alpha: 0.12),
            backgroundImage: AssetImage(patient.avatar!),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name.validate(), style: boldTextStyle(size: 16)),
              2.height,
              Text('${patient.age} ans  •  ${patient.gender == 'F' ? 'Femme' : 'Homme'}  •  Né le ${patient.dob}', style: secondaryTextStyle(size: 12)),
            ],
          ).expand(),
          if (patient.conditions!.isNotEmpty)
            Wrap(
              spacing: 4,
              children: patient.conditions!.map((c) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: medicalTealPrimary.withValues(alpha: 0.1), borderRadius: radius(8)),
                child: Text(c, style: boldTextStyle(size: 10, color: medicalTealPrimary)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(BuildContext context, bool isDark) {
    if (!_showTemplates) return SizedBox();

    final templates = mlDoctorPrescriptionTemplateDataList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modèles d\'ordonnance', style: boldTextStyle(size: 16)),
        12.height,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templates.map((t) => Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: _selectedTemplate == t.name ? mlColorDarkBlue : (isDark ? scaffoldDarkColor : Colors.grey.shade100),
              borderRadius: radius(20),
              border: Border.all(color: _selectedTemplate == t.name ? mlColorDarkBlue : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
            ),
            child: Text(t.name.validate(), style: boldTextStyle(size: 12, color: _selectedTemplate == t.name ? white : (isDark ? white : mlColorDarkBlue))),
          ).onTap(() {
            setState(() {
              _selectedTemplate = _selectedTemplate == t.name ? '' : t.name!;
              if (_selectedTemplate.isNotEmpty) {
                _applyTemplate(t);
              }
            });
          })).toList(),
        ),
      ],
    );
  }

  void _applyTemplate(MLDoctorPrescriptionTemplateData template) {
    _items.clear();
    for (var med in template.medicines!) {
      _items.add(PrescriptionItem(medicine: med));
    }
    _instructionsController.text = template.dosageInstructions ?? '';
    _durationController.text = '';
  }

  Widget _buildMedicationList(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Médicaments', style: boldTextStyle(size: 16)),
            if (_items.isNotEmpty)
              Text('${_items.length} médicament(s)', style: secondaryTextStyle(size: 12)),
          ],
        ),
        12.height,
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildMedicationItem(context, isDark, index, item);
        }),
      ],
    );
  }

  Widget _buildMedicationItem(BuildContext context, bool isDark, int index, PrescriptionItem item) {
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
                  controller: item.medicineController,
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
              if (_items.length > 1)
                IconButton(
                  onPressed: () => setState(() => _items.removeAt(index)),
                  icon: Icon(Icons.delete_outline, color: healthError, size: 20),
                ),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(child: _buildMedField(context, 'Posologie', item.dosageController, 'ex: 1 cp', Icons.medication)),
              12.width,
              Expanded(child: _buildMedField(context, 'Fréquence', item.frequencyController, 'ex: 3x/jour', Icons.schedule)),
              12.width,
              Expanded(child: _buildMedField(context, 'Durée', item.durationController, 'ex: 7 jours', Icons.calendar_today)),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(child: _buildMedField(context, 'Moment', item.timingController, 'ex: Matin/Midi/Soir', Icons.access_time)),
              12.width,
              Expanded(child: _buildMedField(context, 'Voie', item.routeController, 'ex: Orale', Icons.medical_information)),
            ],
          ),
          8.height,
          TextField(
            controller: item.instructionsController,
            decoration: InputDecoration(
              hintText: 'Instructions particulières (optionnel)',
              hintStyle: secondaryTextStyle(size: 12),
              filled: true,
              fillColor: isDark ? black : white,
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

  Widget _buildMedField(BuildContext context, String label, TextEditingController controller, String hint, IconData icon) {
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
            fillColor: isDark ? black : white,
            border: OutlineInputBorder(borderRadius: radius(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          style: boldTextStyle(size: 13),
        ),
      ],
    );
  }

  Widget _buildAddMedication(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _items.add(PrescriptionItem())),
        icon: Icon(Icons.add, size: 18),
        label: Text('Ajouter un médicament', style: boldTextStyle(size: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: mlColorDarkBlue,
          side: BorderSide(color: mlColorDarkBlue, style: BorderStyle.solid),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius(12)),
        ),
      ),
    );
  }

  Widget _buildGlobalInstructions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions générales', style: boldTextStyle(size: 16)),
        12.height,
        TextField(
          controller: _instructionsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ex: Prendre pendant les repas. Arrêter en cas d\'effets indésirables...',
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

  Widget _buildDuration(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Durée du traitement', style: boldTextStyle(size: 16)),
        12.height,
        TextField(
          controller: _durationController,
          decoration: InputDecoration(
            hintText: 'Ex: 7 jours, 1 mois, 3 mois...',
            hintStyle: secondaryTextStyle(size: 14),
            filled: true,
            fillColor: isDark ? scaffoldDarkColor : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: radius(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.all(12),
            prefixIcon: Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? black : white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                toasty(context, 'Ordonnance sauvegardée en brouillon');
              },
              icon: Icon(Icons.save_outlined, size: 18),
              label: Text('Brouillon', style: boldTextStyle(size: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: mlColorDarkBlue,
                side: BorderSide(color: mlColorDarkBlue),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: radius(12)),
              ),
            ),
          ),
          12.width,
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _validatePrescription();
              },
              icon: Icon(Icons.check_circle, size: 18),
              label: Text('Valider et signer', style: boldTextStyle(size: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: medicalTealPrimary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: radius(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _validatePrescription() {
    if (_items.isEmpty || _items.any((i) => i.medicineController.text.trim().isEmpty)) {
      toasty(context, 'Veuillez ajouter au moins un médicament');
      return;
    }
    toasty(context, 'Ordonnance validée et signée numériquement');
    finish(context);
  }
}

class PrescriptionItem {
  final TextEditingController medicineController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;
  final TextEditingController timingController;
  final TextEditingController routeController;
  final TextEditingController instructionsController;

  PrescriptionItem({String? medicine})
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
}