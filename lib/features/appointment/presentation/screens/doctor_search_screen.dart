import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_search_controller.dart';
import 'package:medilink/features/appointment/presentation/widgets/doctor_card.dart';

/// « Trouver un médecin » : recherche par nom / spécialité, filtres spécialité et ville.
class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  late final DoctorSearchController _controller = getIt<DoctorSearchController>()..load();
  final _searchText = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchText.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Attend que l'utilisateur ait fini de taper avant de chercher.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _controller.search(query: value));
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: const Text('Toutes les villes'),
                  selected: _controller.city == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final c in _controller.cities)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(c),
                    selected: _controller.city == c,
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ),
    );
    if (picked == null) return;
    picked.isEmpty ? await _controller.search(clearCity: true) : await _controller.search(city: picked);
  }

  Future<void> _clearAll() async {
    _debounce?.cancel();
    _searchText.clear();
    await _controller.clearFilters();
  }

  Future<void> _openDoctor(int doctorId) async {
    final booked = await context.push<bool>(AppointmentRoutes.doctor(doctorId));
    // Rendez-vous pris : on revient directement à l'écran précédent.
    if (booked == true && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trouver un médecin')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: TextField(
                  controller: _searchText,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Nom du médecin ou spécialité',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        _searchText.text.isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'Effacer',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchText.clear();
                                _controller.search(query: '');
                              },
                            ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Filters(controller: _controller, onPickCity: _pickCity),
              const Divider(height: 1),
              Expanded(child: _results()),
            ],
          );
        },
      ),
    );
  }

  Widget _results() {
    final c = _controller;
    if (c.isLoading && c.doctors.isEmpty) return const LoadingView();
    if (c.error != null) return EmptyState.error(c.error!, onRetry: c.load);
    if (c.doctors.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_rounded,
        title: 'Aucun médecin trouvé',
        message: c.hasFilters ? 'Essayez avec d\'autres critères.' : 'Aucun médecin disponible pour le moment.',
        actionLabel: c.hasFilters ? 'Effacer les filtres' : null,
        onAction: c.hasFilters ? _clearAll : null,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: c.doctors.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        if (i == 0) {
          final n = c.doctors.length;
          return Text(
            n == 1 ? '1 médecin' : '$n médecins',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
          );
        }
        final d = c.doctors[i - 1];
        return DoctorCard(doctor: d, onTap: () => _openDoctor(d.doctorId));
      },
    );
  }
}

/// Ligne de filtres : ville, puis une puce par spécialité.
class _Filters extends StatelessWidget {
  const _Filters({required this.controller, required this.onPickCity});

  final DoctorSearchController controller;
  final VoidCallback onPickCity;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          FilterChip(
            avatar: const Icon(Icons.place_outlined, size: 18),
            label: Text(c.city ?? 'Ville'),
            selected: c.city != null,
            showCheckmark: false,
            onSelected: (_) => onPickCity(),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Toutes'),
            selected: c.specialty == null,
            onSelected: (_) => c.search(clearSpecialty: true),
          ),
          for (final s in c.specialties) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(s),
              selected: c.specialty == s,
              onSelected: (selected) => selected ? c.search(specialty: s) : c.search(clearSpecialty: true),
            ),
          ],
        ],
      ),
    );
  }
}
