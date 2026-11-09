import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/app_assets.dart';
import 'package:medilink/core/utils/ui_helpers.dart';
import 'package:medilink/features/pharmacy/pharmacy_module.dart';
import 'package:medilink/features/pharmacy/presentation/widgets/pharmacy_categories.dart';
import 'package:nb_utils/nb_utils.dart';

/// Écran principal du module Pharmacie côté patient.
/// Harmonisé avec les écrans Rendez-vous, Dossier médical et Panel patient de MediLink.
class MLOnlinePharmacyScreen extends StatefulWidget {
  static const String tag = '/MLOnlinePharmacyScreen';

  const MLOnlinePharmacyScreen({super.key});

  @override
  MLOnlinePharmacyScreenState createState() => MLOnlinePharmacyScreenState();
}

class MLOnlinePharmacyScreenState extends State<MLOnlinePharmacyScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9, initialPage: 0);
  final List<String> _slides = [
    mlIcPharmacySlide3,
    mlIcPharmacySlide1,
    mlIcPharmacySlide2,
    mlIcPharmacySlide4,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              'Pharmacies & Médicaments',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Tunis, Tunisie • Position GPS',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Recherche médicament',
            onPressed: () => context.push(PharmacyRoutes.finder),
          ),
          IconButton(
            icon: const Icon(Icons.near_me_rounded),
            tooltip: 'Trouver une pharmacie',
            onPressed: () => context.push(PharmacyRoutes.finder),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 170,
              width: context.width(),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: ClipRRect(
                      borderRadius: AppRadius.card,
                      child: commonCachedNetworkImage(
                        _slides[index].validate(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: DotIndicator(
                pageController: _pageController,
                pages: _slides,
                indicatorColor: theme.colorScheme.primary,
                unselectedIndicatorColor: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            const MLPharmacyCategoriesComponent(),
          ],
        ),
      ),
    );
  }
}
