import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_finder_screen.dart';

/// Composant des catégories et services de pharmacie pour les patients.
/// Conforme à la charte visuelle MediLink (MediCard, SectionHeader, AppColors).
class MLPharmacyCategoriesComponent extends StatefulWidget {
  static const String tag = '/MLPharmacyCategoriesComponent';

  const MLPharmacyCategoriesComponent({super.key});

  @override
  MLPharmacyCategoriesComponentState createState() => MLPharmacyCategoriesComponentState();
}

class MLPharmacyCategoriesComponentState extends State<MLPharmacyCategoriesComponent> {
  final List<Map<String, dynamic>> _quickServices = [
    {
      'title': 'Disponibilité en pharmacie',
      'subtitle': 'Trouvez les officines proches avec vos médicaments en stock',
      'icon': Icons.location_searching_rounded,
      'color': AppColors.primary,
      'badge': 'GPS & Stock',
      'action': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyFinderScreen()),
          ),
    },
    {
      'title': 'Pharmacies de garde & de nuit',
      'subtitle': 'Trouvez les officines ouvertes maintenant et de garde 24h/24',
      'icon': Icons.nights_stay_rounded,
      'color': AppColors.success,
      'badge': '24h/24',
      'action': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyFinderScreen()),
          ),
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Antalgiques & Douleur', 'icon': Icons.healing_rounded, 'search': 'Paracétamol'},
    {'name': 'Antibiotiques', 'icon': Icons.biotech_rounded, 'search': 'Amoxicilline'},
    {'name': 'Anti-inflammatoires', 'icon': Icons.local_pharmacy_rounded, 'search': 'Ibuprofène'},
    {'name': 'Cardiovasculaire', 'icon': Icons.favorite_rounded, 'search': 'Cardio'},
    {'name': 'Gastro-entérologie', 'icon': Icons.health_and_safety_rounded, 'search': 'Spasfon'},
    {'name': 'Vitamines & Minéraux', 'icon': Icons.wb_sunny_rounded, 'search': 'Vitamine'},
  ];

  final List<Map<String, String>> _popularMeds = [
    {
      'name': 'Doliprane 1000 mg',
      'type': 'Comprimé',
      'dci': 'Paracétamol',
      'stock': 'Disponible',
      'image': 'https://www.pharmarket.com/media/fr_FR3573577/f1200xf1200/doliprane-tabs-1000mg-8-comprimes-f1200-f1200.png',
    },
    {
      'name': 'Augmentin 1g/125mg',
      'type': 'Poudre',
      'dci': 'Amoxicilline / Ac. clav.',
      'stock': 'Disponible',
      'image': 'https://vinmec-prod.s3.amazonaws.com/images/20220522_112121_044528_Amoclan.max-1800x1800.jpg',
    },
    {
      'name': 'Spasfon Lyoc',
      'type': 'Lyophilisat',
      'dci': 'Phloroglucinol',
      'stock': 'Disponible',
      'image': 'https://www.pharmashopi.com/media/catalog/product/cache/8b0cdd6e53d02a9efb92ef020a4a0487/s/p/spasfon-1373461994-1.jpg',
    },
    {
      'name': 'Clamoxyl 500 mg',
      'type': 'Gélule',
      'dci': 'Amoxicilline',
      'stock': 'Disponible',
      'image': 'https://mboapharma.cm/wp-content/uploads/2021/09/clamoxyl-500-cp.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Services Pharmacie'),
          ..._quickServices.map((service) {
            final color = service['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: MediCard(
                onTap: () {
                  final action = service['action'] as void Function(BuildContext);
                  action(context);
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(service['icon'] as IconData, color: color, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service['title'] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  service['badge'] as String,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            service['subtitle'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Catégories Thérapeutiques',
            actionLabel: 'Tout voir',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PharmacyFinderScreen()),
            ),
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: _categories.map((cat) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - AppSpacing.lg * 2 - AppSpacing.md) / 2,
                child: MediCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PharmacyFinderScreen(initialMedicine: cat['search'] as String?),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(cat['icon'] as IconData, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          cat['name'] as String,
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Médicaments Fréquemment Recherchés'),
          ..._popularMeds.map((med) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MediCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PharmacyFinderScreen(initialMedicine: med['name'])),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: AppColors.primarySurface,
                        child: med['image'] != null && med['image']!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: med['image']!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.medication_rounded, color: AppColors.primary, size: 20),
                                ),
                              )
                            : const Center(child: Icon(Icons.medication_rounded, color: AppColors.primary, size: 20)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['name']!,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${med['type']} • DCI: ${med['dci']}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        med['stock']!,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
