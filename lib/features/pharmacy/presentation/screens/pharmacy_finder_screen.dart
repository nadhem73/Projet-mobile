import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:medilink/core/theme/colors.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_availability.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/pharmacy_finder_controller.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_detail_screen.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran de recherche de pharmacies pour les patients.
///
/// Détecte la position GPS réelle du patient en direct et localise les officines à proximité
/// qui ont les médicaments demandés en stock avec calcul d'itinéraire GPS en un clic.
class PharmacyFinderScreen extends StatefulWidget {
  const PharmacyFinderScreen({
    super.key,
    this.initialMedicine,
  });

  final String? initialMedicine;

  @override
  State<PharmacyFinderScreen> createState() => _PharmacyFinderScreenState();
}

class _PharmacyFinderScreenState extends State<PharmacyFinderScreen> {
  late PharmacyFinderController _controller;
  late MedicineRepository _medicineRepository;
  final TextEditingController _medicineController = TextEditingController();
  final List<String> _medicinesList = [];
  final Map<String, String?> _medicineImages = {};
  final Map<String, Medicine> _selectedMedicineObjects = {};

  // Autocomplete
  List<Medicine> _autocompleteResults = [];
  bool _isSearchingAutocomplete = false;
  bool _showAutocomplete = false;

  static const List<Map<String, String>> _popularMedicines = [
    {
      'name': 'Doliprane 1000 mg',
      'query': 'Doliprane',
      'dosage': '1000 mg',
      'image': 'https://www.pharmarket.com/media/fr_FR3573577/f1200xf1200/doliprane-tabs-1000mg-8-comprimes-f1200-f1200.png',
    },
    {
      'name': 'Augmentin (Amoclan)',
      'query': 'Amoclan',
      'dosage': '1 g / 125 mg',
      'image': 'https://vinmec-prod.s3.amazonaws.com/images/20220522_112121_044528_Amoclan.max-1800x1800.jpg',
    },
    {
      'name': 'Spasfon (Antispasm)',
      'query': 'Antispasm',
      'dosage': '80 mg',
      'image': 'https://www.pharmashopi.com/media/catalog/product/cache/8b0cdd6e53d02a9efb92ef020a4a0487/s/p/spasfon-1373461994-1.jpg',
    },
    {
      'name': 'Panadol 1g',
      'query': 'Panadol',
      'dosage': '1 g',
      'image': 'https://pharmex.ly/wp-content/uploads/2020/12/pafasfas.png',
    },
    {
      'name': 'Voltarène 100mg',
      'query': 'Voltarene',
      'dosage': '100 mg',
      'image': 'https://medicarcp.com/website/images/Products_flat/6592%20-%202.jpg',
    },
    {
      'name': 'Clamoxyl 500mg',
      'query': 'Clamoxyl',
      'dosage': '500 mg',
      'image': 'https://mboapharma.cm/wp-content/uploads/2021/09/clamoxyl-500-cp.png',
    },
    {
      'name': 'Efferalgan 500mg',
      'query': 'Efferalgan',
      'dosage': '500 mg',
      'image': 'https://www.pharmacie-randanne.com/resize/1200x1200/media/randanne/finish/img/origin/71/3400932570010-efferalgan-500mg-cpr-eff-secable16.jpg',
    },
    {
      'name': 'Flagyl 250mg',
      'query': 'Flagyl',
      'dosage': '250 mg',
      'image': 'https://www.catena.ro/assets/uploads/product_images/b291b-Flagyl-250mg-20comp.jpg',
    },
  ];

  // Catégorie de forme sélectionnée (null = toutes)
  String? _selectedFormeCategory;

  /// Carte des catégories de formes → mots-clés LIKE pour SQLite.
  static const Map<String, ({String label, String emoji, List<String> keywords})> _formeCategories = {
    'comprimes': (
      label: 'Comprimés',
      emoji: '💊',
      keywords: ['comprime', 'comprim'],
    ),
    'gelules': (
      label: 'Gélules',
      emoji: '💉',
      keywords: ['gelule', 'capsule'],
    ),
    'injectable': (
      label: 'Injectable',
      emoji: '🩸',
      keywords: ['injectable', 'perfusion', 'suspension inject'],
    ),
    'sirop': (
      label: 'Sirop / Buvable',
      emoji: '🥤',
      keywords: ['sirop', 'buvable', 'solution buvable', 'suspension buva'],
    ),
    'creme': (
      label: 'Crème / Gel',
      emoji: '🧴',
      keywords: ['creme', 'gel', 'pommade', 'lotion', 'lait derm'],
    ),
    'collyre': (
      label: 'Gouttes / Collyre',
      emoji: '👁️',
      keywords: ['collyre', 'gouttes', 'ophtalmique'],
    ),
    'suppositoire': (
      label: 'Suppositoires',
      emoji: '🌡️',
      keywords: ['suppositoire', 'rectale'],
    ),
    'inhalation': (
      label: 'Inhalation / Spray',
      emoji: '🌬️',
      keywords: ['inhalation', 'aerosol', 'spray', 'spray nasal', 'spray solution'],
    ),
    'poudre': (
      label: 'Poudre / Granules',
      emoji: '🧂',
      keywords: ['poudre', 'granule', 'lyophilisat'],
    ),
  };

  List<String> get _selectedFormeKeywords {
    if (_selectedFormeCategory == null) return [];
    return List<String>.from(_formeCategories[_selectedFormeCategory]?.keywords ?? []);
  }

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<PharmacyFinderController>();
    _medicineRepository = GetIt.I<MedicineRepository>();

    // Initialisation avec détection de la position GPS en temps réel
    _controller.getCurrentLocation().then((_) {
      if (widget.initialMedicine != null && widget.initialMedicine!.trim().isNotEmpty && mounted) {
        final name = widget.initialMedicine!.trim();
        if (!_medicinesList.contains(name)) {
          setState(() {
            _medicinesList.add(name);
          });
        }
        _controller.findPharmacies(medicineNames: [name]);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  /// Ouvre Google Maps ou l'application GPS par défaut avec le tracé d'itinéraire.
  Future<void> _launchDirections(double lat, double lon, String name) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );
    final geoUrl = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(name)})');

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final geoLaunched = await launchUrl(
          geoUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!geoLaunched) {
          await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
        }
      }
    } catch (_) {
      try {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
        } catch (e) {
          toast('Impossible d\'ouvrir la carte: $e');
        }
      }
    }
  }

  /// Lance l'appel téléphonique vers l'officine.
  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      toast('Impossible d\'appeler');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trouver une pharmacie',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Localisation GPS & Itinéraire en direct',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const LoadingView(
              message: 'Recherche des pharmacies les plus proches et calcul des stocks...',
            );
          }

          if (!_controller.hasResults && _controller.searchedMedicines.isEmpty) {
            return _buildSearchForm(context, theme.brightness == Brightness.dark);
          }

          if (_controller.error != null && !_controller.hasResults) {
            return _buildErrorView(context, theme.brightness == Brightness.dark);
          }

          return _buildResultsList(context, theme.brightness == Brightness.dark);
        },
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, bool isDark) {
    final hasCoords = _controller.hasLocation;
    final lat = _controller.userLatitude;
    final lon = _controller.userLongitude;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
        borderRadius: radius(12),
        border: Border.all(
          color: mlPrimaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: mlPrimaryColor.withValues(alpha: 0.12),
              borderRadius: radius(8),
            ),
            child: _controller.isLocating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: mlPrimaryColor),
                  )
                : Icon(Icons.my_location, color: mlPrimaryColor, size: 20),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _controller.locationStatus,
                      style: boldTextStyle(size: 13, color: isDark ? white : blackColor),
                    ).expand(),
                    if (hasCoords)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: boxDecorationWithRoundedCorners(
                          backgroundColor: healthSuccess.withValues(alpha: 0.12),
                          borderRadius: radius(4),
                        ),
                        child: Text(
                          'GPS Actif',
                          style: boldTextStyle(size: 10, color: healthSuccess),
                        ),
                      ),
                  ],
                ),
                2.height,
                Text(
                  hasCoords
                      ? 'Lat: ${lat!.toStringAsFixed(4)} • Lon: ${lon!.toStringAsFixed(4)}'
                      : 'Appuyez pour activer votre GPS',
                  style: secondaryTextStyle(size: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualiser ma position GPS',
            icon: Icon(Icons.refresh, color: mlPrimaryColor, size: 20),
            onPressed: () async {
              final ok = await _controller.getCurrentLocation();
              if (ok) {
                toast('Position GPS mise à jour');
              } else {
                toast(_controller.locationStatus);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String text) async {
    final query = text.trim();
    if (query.length < 2 && _selectedFormeCategory == null) {
      if (mounted) {
        setState(() {
          _autocompleteResults = [];
          _showAutocomplete = false;
        });
      }
      return;
    }

    setState(() {
      _isSearchingAutocomplete = true;
      _showAutocomplete = true;
    });

    try {
      final results = await _medicineRepository.search(
        query,
        formeKeywords: _selectedFormeKeywords,
      );
      if (mounted && _medicineController.text.trim() == query) {
        setState(() {
          _autocompleteResults = results.take(8).toList();
          _isSearchingAutocomplete = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearchingAutocomplete = false;
        });
      }
    }
  }

  void _selectAutocompleteMedicine(Medicine medicine) {
    final displayTitle = medicine.dosage != null && medicine.dosage!.isNotEmpty
        ? '${medicine.name} ${medicine.dosage}'
        : medicine.name;
    if (!_medicinesList.contains(displayTitle)) {
      setState(() {
        _medicinesList.add(displayTitle);
        _selectedMedicineObjects[displayTitle] = medicine;
        if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty) {
          _medicineImages[displayTitle] = medicine.imageUrl;
        }
        _medicineController.clear();
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _addPopularMedicine(Map<String, String> item) {
    final query = item['query']!;
    final image = item['image'];
    if (!_medicinesList.contains(query)) {
      setState(() {
        _medicinesList.add(query);
        if (image != null && image.isNotEmpty) {
          _medicineImages[query] = image;
        }
      });
    }
  }

  void _addMedicine(String medicine) {
    final trimmed = medicine.trim();
    if (trimmed.isNotEmpty && !_medicinesList.contains(trimmed)) {
      setState(() {
        _medicinesList.add(trimmed);
        _medicineController.clear();
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildSearchForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationCard(context, isDark),
          16.height,
          Text('Médicaments recherchés', style: boldTextStyle(size: 16)),
          6.height,
          Text(
            'Ajoutez les médicaments prescrits ou nécessaires :',
            style: secondaryTextStyle(size: 12),
          ),
          12.height,

          // FILTRES PAR TYPE / FORME GALÉNIQUE
          Text('Type de médicament :', style: secondaryTextStyle(size: 12)),
          8.height,
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Chip "Tous"
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFormeCategory = null;
                    });
                    if (_medicineController.text.trim().length >= 2) {
                      _onSearchChanged(_medicineController.text);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: _selectedFormeCategory == null
                          ? mlPrimaryColor
                          : (isDark ? cardBackgroundBlackDark : mlColorLightGrey100),
                      borderRadius: radius(20),
                      border: Border.all(
                        color: _selectedFormeCategory == null
                            ? mlPrimaryColor
                            : (isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                    child: Text(
                      '🔍 Tous',
                      style: boldTextStyle(
                        size: 12,
                        color: _selectedFormeCategory == null ? white : (isDark ? white : blackColor),
                      ),
                    ),
                  ),
                ),
                // Chips dynamiques par catégorie
                ..._formeCategories.entries.map((entry) {
                  final cat = entry.value;
                  final isSelected = _selectedFormeCategory == entry.key;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFormeCategory = isSelected ? null : entry.key;
                      });
                      _onSearchChanged(_medicineController.text);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: isSelected
                            ? mlPrimaryColor
                            : (isDark ? cardBackgroundBlackDark : mlColorLightGrey100),
                        borderRadius: radius(20),
                        border: Border.all(
                          color: isSelected
                              ? mlPrimaryColor
                              : (isDark ? Colors.white24 : Colors.black12),
                        ),
                      ),
                      child: Text(
                        '${cat.emoji} ${cat.label}',
                        style: boldTextStyle(
                          size: 12,
                          color: isSelected ? white : (isDark ? white : blackColor),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          12.height,

          // BARRE DE RECHERCHE AVEC AUTO-COMPLÉTION
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _medicineController,
                  style: primaryTextStyle(),
                  decoration: InputDecoration(
                    hintText: 'Ex: Doliprane, Augmentin...',
                    hintStyle: secondaryTextStyle(),
                    prefixIcon: Icon(Icons.medication, color: mlPrimaryColor),
                    suffixIcon: _medicineController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _medicineController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
                    border: OutlineInputBorder(
                      borderRadius: radius(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _addMedicine,
                ),
              ),
              10.width,
              Container(
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: mlPrimaryColor,
                  borderRadius: radius(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: white),
                  onPressed: () => _addMedicine(_medicineController.text),
                ),
              ),
            ],
          ),

          // LISTE DÉROULANTE DE SUGGESTIONS AVEC PHOTOS (SOUS LA BARRE DE RECHERCHE)
          if (_showAutocomplete) ...[
            6.height,
            Container(
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: isDark ? cardBackgroundBlackDark : white,
                borderRadius: radius(12),
                border: Border.all(color: mlPrimaryColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSearchingAutocomplete
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: mlPrimaryColor),
                          ),
                          10.width,
                          Text('Recherche du médicament...', style: secondaryTextStyle(size: 12)),
                        ],
                      ),
                    )
                  : _autocompleteResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: textSecondaryColorGlobal),
                              8.width,
                              Expanded(
                                child: Text(
                                  'Appuyez sur "+" pour ajouter "${_medicineController.text}"',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _autocompleteResults.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                          ),
                          itemBuilder: (context, index) {
                            final med = _autocompleteResults[index];
                            final hasImg = med.imageUrl != null && med.imageUrl!.isNotEmpty;
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: radius(8),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  color: Colors.white,
                                  child: hasImg
                                      ? CachedNetworkImage(
                                          imageUrl: med.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Center(
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 1.5, color: mlPrimaryColor),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => Icon(Icons.medication, color: mlPrimaryColor, size: 22),
                                        )
                                      : Icon(Icons.medication, color: mlPrimaryColor, size: 22),
                                ),
                              ),
                              title: Text(
                                med.name,
                                style: boldTextStyle(size: 13, color: isDark ? white : blackColor),
                              ),
                              subtitle: Text(
                                [
                                  if (med.dosage != null && med.dosage!.isNotEmpty) med.dosage!,
                                  if (med.forme != null && med.forme!.isNotEmpty) med.forme!,
                                ].join(' • '),
                                style: secondaryTextStyle(size: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (med.price > 0)
                                    Text(
                                      '${med.price.toStringAsFixed(2)} DT',
                                      style: boldTextStyle(size: 11, color: mlPrimaryColor),
                                    ),
                                  8.width,
                                  Icon(Icons.add_circle, color: mlPrimaryColor, size: 22),
                                ],
                              ),
                              onTap: () => _selectAutocompleteMedicine(med),
                            );
                          },
                        ),
            ),
          ],

          // MÉDICAMENTS SÉLECTIONNÉS AVEC PHOTOS
          if (_medicinesList.isNotEmpty) ...[
            14.height,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medicinesList.map((medicineName) {
                final img = _medicineImages[medicineName];
                final hasImg = img != null && img.isNotEmpty;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: mlPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: radius(20),
                    border: Border.all(color: mlPrimaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: radius(12),
                        child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          child: hasImg
                              ? CachedNetworkImage(
                                  imageUrl: img,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Icon(Icons.medication, size: 14, color: mlPrimaryColor),
                                  errorWidget: (_, __, ___) => Icon(Icons.medication, size: 14, color: mlPrimaryColor),
                                )
                              : Icon(Icons.medication, size: 14, color: mlPrimaryColor),
                        ),
                      ),
                      8.width,
                      Text(medicineName, style: boldTextStyle(size: 12, color: mlPrimaryColor)),
                      6.width,
                      InkWell(
                        onTap: () {
                          setState(() {
                            _medicinesList.remove(medicineName);
                            _medicineImages.remove(medicineName);
                            _selectedMedicineObjects.remove(medicineName);
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: mlPrimaryColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // SUGGESTIONS FRÉQUENTES AVEC PHOTOS
          16.height,
          Text('Médicaments fréquents à sélectionner :', style: secondaryTextStyle(size: 12)),
          10.height,
          SizedBox(
            height: 98,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _popularMedicines.length,
              itemBuilder: (context, index) {
                final item = _popularMedicines[index];
                final isAdded = _medicinesList.contains(item['query']);
                return Container(
                  width: 125,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: isAdded
                        ? mlPrimaryColor.withValues(alpha: 0.14)
                        : (isDark ? cardBackgroundBlackDark : mlColorLightGrey100),
                    borderRadius: radius(12),
                    border: Border.all(
                      color: isAdded
                          ? mlPrimaryColor
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isAdded ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: radius(6),
                        child: Container(
                          width: 38,
                          height: 38,
                          color: Colors.white,
                          child: CachedNetworkImage(
                            imageUrl: item['image']!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(Icons.medication, size: 18, color: mlPrimaryColor),
                            errorWidget: (_, __, ___) => Icon(Icons.medication, size: 18, color: mlPrimaryColor),
                          ),
                        ),
                      ),
                      4.height,
                      Text(
                        item['name']!,
                        style: boldTextStyle(
                          size: 11,
                          color: isAdded ? mlPrimaryColor : (isDark ? white : blackColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      2.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAdded ? Icons.check_circle : Icons.add_circle_outline,
                            size: 13,
                            color: isAdded ? mlPrimaryColor : textSecondaryColorGlobal,
                          ),
                          3.width,
                          Text(
                            isAdded ? 'Choisi' : 'Ajouter',
                            style: secondaryTextStyle(
                              size: 10,
                              color: isAdded ? mlPrimaryColor : textSecondaryColorGlobal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).onTap(() {
                  if (isAdded) {
                    setState(() {
                      _medicinesList.remove(item['query']);
                      _medicineImages.remove(item['query']);
                      _selectedMedicineObjects.remove(item['query']);
                    });
                  } else {
                    _addPopularMedicine(item);
                  }
                });
              },
            ),
          ),
          24.height,
          Text('Rayon maximal de recherche', style: boldTextStyle(size: 16)),
          12.height,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
              borderRadius: radius(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.near_me, color: mlPrimaryColor, size: 18),
                        8.width,
                        Text('Distance maximale autour de vous', style: secondaryTextStyle(size: 13)),
                      ],
                    ),
                    Text(
                      '${_controller.searchRadius.toInt()} km',
                      style: boldTextStyle(size: 16, color: mlPrimaryColor),
                    ),
                  ],
                ),
                Slider(
                  value: _controller.searchRadius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: mlPrimaryColor,
                  onChanged: (value) => _controller.setSearchRadius(value),
                ),
              ],
            ),
          ),
          32.height,
          AppButton(
            width: context.width(),
            color: mlPrimaryColor,
            enabled: _medicinesList.isNotEmpty,
            onTap: () {
              if (_medicinesList.isNotEmpty) {
                final specificMedicines = _medicinesList
                    .map((name) => _selectedMedicineObjects[name])
                    .whereType<Medicine>()
                    .toList();
                _controller.findPharmacies(
                  medicineNames: _medicinesList,
                  specificMedicines: specificMedicines.isNotEmpty ? specificMedicines : null,
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, color: white, size: 20),
                8.width,
                Text('Localiser les pharmacies proches', style: boldTextStyle(color: white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: healthError),
          16.height,
          Text(_controller.error!, style: secondaryTextStyle(), textAlign: TextAlign.center),
          24.height,
          AppButton(
            text: 'Nouvelle recherche',
            onTap: () {
              _controller.clear();
              setState(() {
                _medicinesList.clear();
                _selectedMedicineObjects.clear();
              });
            },
            color: mlPrimaryColor,
          ),
        ],
      ).paddingAll(16),
    );
  }

  Widget _buildResultsList(BuildContext context, bool isDark) {
    final filtered = _controller.filteredResults;
    final total = _controller.results.length;
    final openCount = _controller.results.where((r) => r.pharmacy.isOpenNow).length;
    final nightCount = _controller.results.where((r) => r.pharmacy.isNightPharmacy).length;
    final fullStockCount = _controller.results.where((r) => r.availableCount == r.totalRequested).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildLocationCard(context, isDark),
        ),

        // BARRE DE FILTRES DES RÉSULTATS PHARMACIES
        Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildResultFilterChip(
                label: 'Toutes ($total)',
                filter: 'all',
                isDark: isDark,
              ),
              8.width,
              _buildResultFilterChip(
                label: '🟢 Ouvertes ($openCount)',
                filter: 'open',
                isDark: isDark,
              ),
              8.width,
              _buildResultFilterChip(
                label: '🌙 De Nuit ($nightCount)',
                filter: 'night',
                isDark: isDark,
              ),
              8.width,
              _buildResultFilterChip(
                label: '✅ 100% Dispo ($fullStockCount)',
                filter: 'full_stock',
                isDark: isDark,
              ),
            ],
          ),
        ),

        // BARRE D'ÉTAT & TRI & RECOMMENCER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.local_pharmacy, color: mlPrimaryColor, size: 20),
              8.width,
              Text(
                '${filtered.length} sur $total',
                style: boldTextStyle(size: 13),
              ),
              const Spacer(),
              // BOUTON DE TRI PROXIMITÉ / DISPONIBILITÉ
              GestureDetector(
                onTap: () {
                  final newSort = _controller.sortBy == 'distance' ? 'availability' : 'distance';
                  _controller.setSortBy(newSort);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: mlPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: radius(8),
                    border: Border.all(color: mlPrimaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _controller.sortBy == 'distance' ? Icons.near_me : Icons.check_circle_outline,
                        size: 13,
                        color: mlPrimaryColor,
                      ),
                      4.width,
                      Text(
                        _controller.sortBy == 'distance' ? 'Proximité' : 'Disponibilité',
                        style: boldTextStyle(size: 11, color: mlPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              8.width,
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Recommencer'),
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _medicinesList.clear();
                    _selectedMedicineObjects.clear();
                  });
                },
                style: TextButton.styleFrom(foregroundColor: mlPrimaryColor),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey),
                      12.height,
                      Text(
                        total > 0
                            ? 'Aucune pharmacie ne correspond au filtre actif'
                            : 'Aucune pharmacie trouvée avec ces médicaments',
                        style: secondaryTextStyle(),
                        textAlign: TextAlign.center,
                      ),
                      if (total > 0) ...[
                        16.height,
                        AppButton(
                          text: 'Afficher toutes les pharmacies ($total)',
                          color: mlPrimaryColor,
                          onTap: () => _controller.setResultFilter('all'),
                        ),
                      ],
                    ],
                  ).paddingAll(16),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final result = filtered[index];
                    return _buildPharmacyCard(context, isDark, result, index + 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResultFilterChip({
    required String label,
    required String filter,
    required bool isDark,
  }) {
    final isSelected = _controller.resultFilter == filter;
    return GestureDetector(
      onTap: () => _controller.setResultFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isSelected
              ? mlPrimaryColor
              : (isDark ? cardBackgroundBlackDark : mlColorLightGrey100),
          borderRadius: radius(20),
          border: Border.all(
            color: isSelected ? mlPrimaryColor : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: boldTextStyle(
              size: 11,
              color: isSelected ? white : (isDark ? white : blackColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(
    BuildContext context,
    bool isDark,
    PharmacyAvailability availability,
    int rank,
  ) {
    final pharmacy = availability.pharmacy;
    final availableCount = availability.availableCount;
    final totalCount = availability.totalRequested;
    final distance = _controller.formatDistance(availability.distance);
    final walkingTime = _controller.estimateWalkingTime(availability.distance);

    final bool isAllAvailable = availableCount == totalCount;
    final bool isOpen = pharmacy.isOpenNow;
    final bool isNight = pharmacy.isNightPharmacy;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? cardBackgroundBlackDark : white,
        borderRadius: radius(14),
        border: Border.all(
          color: isOpen
              ? (isNight ? Colors.indigo.withValues(alpha: 0.6) : healthSuccess.withValues(alpha: 0.6))
              : (isDark ? Colors.white12 : mlColorLightGrey),
          width: isOpen ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            leading: Container(
              width: 44,
              height: 44,
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: isOpen
                    ? (isNight ? Colors.indigo : healthSuccess)
                    : Colors.grey.shade400,
                borderRadius: radius(22),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: boldTextStyle(color: white, size: 15),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    pharmacy.name,
                    style: boldTextStyle(size: 14, color: isDark ? white : blackColor),
                  ),
                ),
                if (isNight) ...[
                  4.width,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                      borderRadius: radius(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.nightlight_round, size: 11, color: Colors.indigo),
                        2.width,
                        Text('De Nuit', style: boldTextStyle(size: 10, color: Colors.indigo)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                5.height,
                // STATUT OUVERT / FERMÉ & HORAIRES
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: (isOpen ? healthSuccess : healthError).withValues(alpha: 0.12),
                        borderRadius: radius(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: isOpen ? healthSuccess : healthError,
                          ),
                          4.width,
                          Text(
                            isOpen ? (isNight ? 'Ouvert de Nuit' : 'Ouvert') : 'Fermé',
                            style: boldTextStyle(
                              size: 10,
                              color: isOpen ? healthSuccess : healthError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    8.width,
                    Icon(Icons.access_time, size: 12, color: textSecondaryColorGlobal),
                    3.width,
                    Expanded(
                      child: Text(
                        pharmacy.todayHoursDisplay,
                        style: secondaryTextStyle(size: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                6.height,
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: isDark ? white : blackColor),
                    4.width,
                    Text(distance, style: secondaryTextStyle(size: 12)),
                    10.width,
                    Icon(Icons.directions_walk, size: 14, color: isDark ? white : blackColor),
                    4.width,
                    Text(walkingTime, style: secondaryTextStyle(size: 12)),
                  ],
                ),
                6.height,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: isAllAvailable
                        ? healthSuccess.withValues(alpha: 0.12)
                        : healthWarning.withValues(alpha: 0.12),
                    borderRadius: radius(6),
                  ),
                  child: Text(
                    '$availableCount/$totalCount médicaments disponibles',
                    style: boldTextStyle(
                      size: 11,
                      color: isAllAvailable ? healthSuccess : healthWarning,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: isDark ? white : blackColor),
            onTap: () {
              PharmacyDetailScreen(
                pharmacy: availability.pharmacy,
                availableMedicines: availability.availableMedicines,
              ).launch(context);
            },
          ),

          // Médicaments disponibles avec photos
          if (availability.availableMedicines.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: healthSuccess),
                      4.width,
                      Text('Disponibles en officine :', style: boldTextStyle(size: 12, color: healthSuccess)),
                    ],
                  ),
                  8.height,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availability.availableMedicineDetails.isNotEmpty
                        ? availability.availableMedicineDetails.map((medInfo) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: boxDecorationWithRoundedCorners(
                                backgroundColor: isDark
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : healthSuccess.withValues(alpha: 0.08),
                                borderRadius: radius(8),
                                border: Border.all(
                                  color: healthSuccess.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: radius(4),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                      child: (medInfo.imageUrl != null && medInfo.imageUrl!.isNotEmpty)
                                          ? CachedNetworkImage(
                                              imageUrl: medInfo.imageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Icon(Icons.medication, size: 14, color: healthSuccess),
                                              errorWidget: (_, __, ___) => Icon(Icons.medication, size: 14, color: healthSuccess),
                                            )
                                          : Icon(Icons.medication, size: 14, color: healthSuccess),
                                    ),
                                  ),
                                  6.width,
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        medInfo.displayTitle,
                                        style: boldTextStyle(size: 11, color: isDark ? white : blackColor),
                                      ),
                                      if (medInfo.price != null && medInfo.price! > 0)
                                        Text(
                                          '${medInfo.price!.toStringAsFixed(3)} DT',
                                          style: secondaryTextStyle(size: 10, color: healthSuccess),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        : availability.availableMedicines.map((med) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: boxDecorationWithRoundedCorners(
                                backgroundColor: healthSuccess.withValues(alpha: 0.1),
                                borderRadius: radius(6),
                              ),
                              child: Text(med, style: secondaryTextStyle(size: 11, color: healthSuccess)),
                            );
                          }).toList(),
                  ),
                ],
              ),
            ),
          ],
          if (availability.unavailableMedicines.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Non disponibles : ', style: boldTextStyle(size: 11, color: healthError)),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: availability.unavailableMedicines.map((med) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: healthError.withValues(alpha: 0.1),
                            borderRadius: radius(4),
                          ),
                          child: Text(med, style: secondaryTextStyle(size: 10, color: healthError)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // BARRE D'ACTIONS : GPS ITINÉRAIRE & APPEL DIRECT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : mlColorLightGrey100,
              borderRadius: radiusOnly(bottomLeft: 14, bottomRight: 14),
            ),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: isDark ? Colors.grey : textSecondaryColorGlobal),
                4.width,
                Expanded(
                  child: Text(
                    pharmacy.address,
                    style: secondaryTextStyle(size: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                8.width,
                if (pharmacy.phone != null && pharmacy.phone!.isNotEmpty) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _launchPhone(pharmacy.phone!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: healthSuccess.withValues(alpha: 0.12),
                        borderRadius: radius(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: healthSuccess),
                          4.width,
                          Text('Appeler', style: boldTextStyle(size: 11, color: healthSuccess)),
                        ],
                      ),
                    ),
                  ),
                  8.width,
                ],
                // BOUTON ITINÉRAIRE GPS
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _launchDirections(pharmacy.latitude, pharmacy.longitude, pharmacy.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: mlPrimaryColor,
                      borderRadius: radius(8),
                      boxShadow: [
                        BoxShadow(
                          color: mlPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation, size: 14, color: white),
                        6.width,
                        Text('Itinéraire GPS', style: boldTextStyle(size: 12, color: white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
