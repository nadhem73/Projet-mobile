import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/theme/colors.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran de détail d'une pharmacie.
///
/// Affiche les informations complètes d'une pharmacie, ses médicaments en stock avec photos, et permet d'appeler ou de naviguer.
class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({
    super.key,
    required this.pharmacy,
    this.availableMedicines,
  });

  final Pharmacy pharmacy;
  final List<String>? availableMedicines;

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  List<Medicine> _pharmacyMedicines = [];
  bool _isLoadingMedicines = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacyMedicines();
  }

  Future<void> _loadPharmacyMedicines() async {
    if (widget.pharmacy.pharmacyId == null) return;
    setState(() => _isLoadingMedicines = true);
    try {
      final appDb = GetIt.I<AppDatabase>();
      final results = await appDb.db.rawQuery('''
        SELECT m.*, COALESCE(s.custom_price, m.price) as price
        FROM medicines m
        JOIN pharmacy_stock s ON m.medicine_id = s.medicine_id
        WHERE s.pharmacy_id = ? AND s.in_stock = 1 AND s.quantity > 0
        ORDER BY m.name ASC
        LIMIT 25
      ''', [widget.pharmacy.pharmacyId]);

      if (mounted) {
        setState(() {
          _pharmacyMedicines = results.map((r) => Medicine.fromMap(r)).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingMedicines = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacy.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPharmacyCard(context, isDark),
            20.height,
            _buildContactSection(context, isDark),
            20.height,
            _buildLocationSection(context, isDark),
            if (widget.availableMedicines != null && widget.availableMedicines!.isNotEmpty) ...[
              20.height,
              _buildAvailableMedicinesSection(context, isDark),
            ],
            20.height,
            _buildPharmacyMedicinesSection(context, isDark),
            20.height,
            _buildHoursSection(context, isDark),
            30.height,
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, bool isDark) {
    final isOpen = widget.pharmacy.isOpenNow;
    final isNight = widget.pharmacy.isNightPharmacy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
        borderRadius: radius(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: mlPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: radius(12),
                ),
                child: Icon(Icons.local_pharmacy, color: mlPrimaryColor, size: 32),
              ),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pharmacy.name,
                      style: boldTextStyle(size: 18, color: isDark ? white : blackColor),
                    ),
                    4.height,
                    Text(
                      widget.pharmacy.address,
                      style: secondaryTextStyle(size: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.height,
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: (isOpen ? healthSuccess : healthError).withValues(alpha: 0.12),
                  borderRadius: radius(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isOpen ? healthSuccess : healthError,
                    ),
                    6.width,
                    Text(
                      isOpen ? 'Ouvert maintenant' : 'Fermé actuellement',
                      style: boldTextStyle(
                        size: 11,
                        color: isOpen ? healthSuccess : healthError,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                    borderRadius: radius(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.nightlight_round, size: 12, color: Colors.indigo),
                      4.width,
                      Text(
                        'Pharmacie de Nuit',
                        style: boldTextStyle(size: 11, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          16.height,
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchDirections(
                    widget.pharmacy.latitude,
                    widget.pharmacy.longitude,
                    widget.pharmacy.name,
                  ),
                  icon: const Icon(Icons.directions, color: white, size: 18),
                  label: const Text('Itinéraire GPS', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mlPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: radius(10)),
                  ),
                ),
              ),
              if (widget.pharmacy.phone != null && widget.pharmacy.phone!.isNotEmpty) ...[
                10.width,
                ElevatedButton.icon(
                  onPressed: () => _launchPhone(widget.pharmacy.phone!),
                  icon: const Icon(Icons.phone, color: white, size: 18),
                  label: const Text('Appeler', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: healthSuccess,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: radius(10)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coordonnées', style: boldTextStyle(size: 17)),
        12.height,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
            borderRadius: radius(12),
          ),
          child: Column(
            children: [
              if (widget.pharmacy.phone != null && widget.pharmacy.phone!.isNotEmpty)
                _buildContactRow(
                  Icons.phone,
                  'Téléphone',
                  widget.pharmacy.phone!,
                  () => _launchPhone(widget.pharmacy.phone!),
                ),
              if (widget.pharmacy.email != null && widget.pharmacy.email!.isNotEmpty) ...[
                if (widget.pharmacy.phone != null) const Divider(height: 16),
                _buildContactRow(
                  Icons.email,
                  'Email',
                  widget.pharmacy.email!,
                  () => _launchEmail(widget.pharmacy.email!),
                ),
              ],
              const Divider(height: 16),
              _buildContactRow(
                Icons.location_on,
                'Adresse',
                widget.pharmacy.address,
                null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: radius(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: mlPrimaryColor, size: 20),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: secondaryTextStyle(size: 11)),
                  2.height,
                  Text(value, style: boldTextStyle(size: 13)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 12, color: mlColorLightGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coordonnées GPS', style: boldTextStyle(size: 17)),
        12.height,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
            borderRadius: radius(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latitude', style: secondaryTextStyle(size: 11)),
                    2.height,
                    Text(
                      widget.pharmacy.latitude.toStringAsFixed(6),
                      style: boldTextStyle(size: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Longitude', style: secondaryTextStyle(size: 11)),
                    2.height,
                    Text(
                      widget.pharmacy.longitude.toStringAsFixed(6),
                      style: boldTextStyle(size: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableMedicinesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Médicaments recherchés disponibles', style: boldTextStyle(size: 17)),
        12.height,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: healthSuccess.withValues(alpha: 0.1),
            borderRadius: radius(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: healthSuccess, size: 20),
                  8.width,
                  Text(
                    '${widget.availableMedicines!.length} médicament(s) confirmés en stock',
                    style: boldTextStyle(size: 14, color: healthSuccess),
                  ),
                ],
              ),
              12.height,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableMedicines!.map((medicine) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: isDark ? cardBackgroundBlackDark : white,
                      borderRadius: radius(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication, size: 16, color: healthSuccess),
                        6.width,
                        Text(medicine, style: primaryTextStyle(size: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyMedicinesSection(BuildContext context, bool isDark) {
    if (_isLoadingMedicines) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: mlPrimaryColor, strokeWidth: 2),
        ),
      );
    }

    if (_pharmacyMedicines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Médicaments en stock', style: boldTextStyle(size: 17)),
            Text(
              '${_pharmacyMedicines.length} affichés',
              style: secondaryTextStyle(size: 12),
            ),
          ],
        ),
        12.height,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: math.min(12, _pharmacyMedicines.length),
          separatorBuilder: (_, __) => 8.height,
          itemBuilder: (context, index) {
            final med = _pharmacyMedicines[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
                borderRadius: radius(10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: radius(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: isDark ? Colors.white10 : Colors.white,
                      child: med.imageUrl != null && med.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: med.imageUrl!,
                              width: 44,
                              height: 44,
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
                  12.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: boldTextStyle(size: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        2.height,
                        Text(
                          [med.dosage, med.forme].whereType<String>().join(' • '),
                          style: secondaryTextStyle(size: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  8.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: boxDecorationWithRoundedCorners(
                          backgroundColor: healthSuccess.withValues(alpha: 0.12),
                          borderRadius: radius(4),
                        ),
                        child: Text(
                          'Disponible',
                          style: boldTextStyle(size: 9, color: healthSuccess),
                        ),
                      ),
                      if (med.price > 0) ...[
                        2.height,
                        Text(
                          '${med.price.toStringAsFixed(3)} TND',
                          style: boldTextStyle(size: 11, color: mlPrimaryColor),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHoursSection(BuildContext context, bool isDark) {
    if (widget.pharmacy.openingHours == null) return const SizedBox.shrink();

    final hours = widget.pharmacy.openingHours!;
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horaires d\'ouverture', style: boldTextStyle(size: 17)),
        12.height,
        Container(
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: isDark ? cardBackgroundBlackDark : mlColorLightGrey100,
            borderRadius: radius(12),
          ),
          child: Column(
            children: List.generate(days.length, (index) {
              final dayName = days[index];
              final dayKey = dayKeys[index];
              final dayHours = hours[dayKey] ?? 'Fermé';
              final isToday = DateTime.now().weekday == index + 1;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isToday ? mlPrimaryColor.withValues(alpha: 0.1) : Colors.transparent,
                  border: index < days.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(dayName, style: primaryTextStyle(size: 13)),
                        if (isToday) ...[
                          6.width,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: boxDecorationWithRoundedCorners(
                              backgroundColor: mlPrimaryColor,
                              borderRadius: radius(4),
                            ),
                            child: Text('Aujourd\'hui', style: boldTextStyle(size: 9, color: white)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      dayHours,
                      style: boldTextStyle(
                        size: 13,
                        color: dayHours == 'Fermé' ? healthError : healthSuccess,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _launchDirections(double lat, double lon, String name) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );
    final geoUrl = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(name)})');

    try {
      final launched = await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        final geoLaunched = await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
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
          toast('Impossible d\'ouvrir la navigation: $e');
        }
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      toast('Impossible d\'appeler');
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri);
    } catch (_) {
      toast('Impossible d\'ouvrir l\'application email');
    }
  }
}
