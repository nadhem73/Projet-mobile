import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/ai/data/models/doctor_option.dart';
import 'package:medilink/features/ai/presentation/controllers/bilan_review_controller.dart';

/// Feuille « Envoyer à un médecin » : recherche par nom ou spécialité.
/// Renvoie le médecin choisi (ou `null`).
Future<DoctorOption?> showDoctorPicker(BuildContext context, BilanReviewController controller) {
  controller
    ..filterDoctors('')
    ..loadDoctors();
  return showModalBottomSheet<DoctorOption>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder:
        (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder:
              (context, scroll) => ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final doctors = controller.doctors;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Envoyer à un médecin', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              onChanged: controller.filterDoctors,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search_rounded),
                                hintText: 'Nom ou spécialité',
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            controller.isLoadingDoctors
                                ? const LoadingView()
                                : doctors.isEmpty
                                ? const EmptyState(
                                  icon: Icons.person_search_rounded,
                                  title: 'Aucun médecin trouvé',
                                  message: 'Essayez un autre nom ou une autre spécialité.',
                                )
                                : ListView.separated(
                                  controller: scroll,
                                  itemCount: doctors.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final d = doctors[i];
                                    return ListTile(
                                      leading: MediAvatar(initials: d.initials, size: 40),
                                      title: Text(d.displayName),
                                      subtitle: Text([d.specialty, d.hospital].whereType<String>().join(' · ')),
                                      trailing: const Icon(Icons.send_rounded),
                                      onTap: () => Navigator.of(context).pop(d),
                                    );
                                  },
                                ),
                      ),
                    ],
                  );
                },
              ),
        ),
  );
}
