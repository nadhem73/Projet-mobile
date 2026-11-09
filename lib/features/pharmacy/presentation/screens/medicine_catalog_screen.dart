import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/medicine_catalog_controller.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_finder_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/stock_management_screen.dart';

/// Écran du catalogue de médicaments avec recherche avancée, filtres et gestion stock.
/// Conforme à la charte visuelle MediLink (MediCard, AppColors, AppRadius).
class MedicineCatalogScreen extends StatefulWidget {
  const MedicineCatalogScreen({super.key, this.initialFilter});

  final String? initialFilter;

  @override
  State<MedicineCatalogScreen> createState() => _MedicineCatalogScreenState();
}

class _MedicineCatalogScreenState extends State<MedicineCatalogScreen> {
  late MedicineCatalogController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<MedicineCatalogController>();
    _controller.load(initialFilter: widget.initialFilter);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final name = _controller.pharmacyName;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name != null ? 'Catalogue — $name' : 'Catalogue Médicaments',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_controller.medicines.length} médicaments trouvés',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCatalogModeToggle(context),
          _buildSearchBar(context),
          _buildFiltersChips(context),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const LoadingView(message: 'Recherche dans le catalogue...');
                }

                if (_controller.error != null) {
                  return EmptyState.error(
                    _controller.error!,
                    onRetry: _controller.refresh,
                  );
                }

                if (_controller.medicines.isEmpty) {
                  return EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Aucun médicament trouvé',
                    message: 'Essayez de modifier vos critères de recherche ou de réinitialiser les filtres.',
                    actionLabel: _controller.hasFilters ? 'Réinitialiser les filtres' : null,
                    onAction: _controller.hasFilters
                        ? () {
                            _searchController.clear();
                            _controller.clearFilters();
                          }
                        : null,
                  );
                }

                return _buildMedicineList(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isNational = _controller.browseAllNational;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.button,
              border: Border.all(color: theme.dividerColor),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => _controller.toggleCatalogMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: !isNational ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Mon Officine',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: !isNational ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => _controller.toggleCatalogMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isNational ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Répertoire National (2 700+)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isNational ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par marque ou DCI (ex: Doliprane, Amox)...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _controller.search('');
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppSpacing.md),
          border: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide(color: theme.dividerColor),
          ),
        ),
        onChanged: (value) {
          _controller.search(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFiltersChips(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              if (_controller.hasFilters) ...[
                ActionChip(
                  avatar: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                  label: const Text('Réinitialiser', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  backgroundColor: AppColors.errorSurface,
                  side: const BorderSide(color: AppColors.error),
                  onPressed: () {
                    _controller.clearFilters();
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              _buildStockFilterChip('En stock', 'in_stock'),
              const SizedBox(width: AppSpacing.sm),
              _buildStockFilterChip('Stock faible', 'low_stock'),
              const SizedBox(width: AppSpacing.sm),
              _buildStockFilterChip('Rupture', 'out_of_stock'),
              const SizedBox(width: AppSpacing.sm),
              _buildStockFilterChip('Expire bientôt', 'expiring_soon'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Type', _controller.selectedType, () => _showTypeFilter(context)),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Forme', _controller.selectedForme, () => _showFormeFilter(context)),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                'Ordonnance',
                _controller.prescriptionFilter == true
                    ? 'Requise'
                    : _controller.prescriptionFilter == false
                        ? 'Libre'
                        : null,
                () => _showPrescriptionFilter(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockFilterChip(String label, String value) {
    final isSelected = _controller.stockStatusFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      onSelected: (selected) {
        _controller.filterByStockStatus(selected ? value : null);
      },
      selectedColor: AppColors.primary,
    );
  }

  Widget _buildFilterChip(String label, String? value, VoidCallback onTap) {
    final isSelected = value != null;
    return FilterChip(
      label: Text(
        value != null ? '$label: $value' : label,
        style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
    );
  }

  Widget _buildMedicineList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: _controller.medicines.length,
      itemBuilder: (context, index) {
        final medicine = _controller.medicines[index];
        return _buildMedicineCard(context, medicine);
      },
    );
  }

  Widget _buildMedicineCard(BuildContext context, Medicine medicine) {
    final theme = Theme.of(context);
    final inStock = _controller.isInStock(medicine.medicineId!);
    final stock = _controller.getStock(medicine.medicineId!);
    final quantity = stock?.quantity ?? 0;
    final isLow = inStock && quantity <= 15;

    final userRole = GetIt.I<SessionService>().currentUser?.role;
    final isPharmacist = userRole == UserRole.pharmacist;
    final displayedPrice = stock?.customPrice ?? medicine.price;

    final badgeColor = !inStock
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.success;
    final badgeBgColor = !inStock
        ? AppColors.errorSurface
        : isLow
            ? AppColors.warningSurface
            : AppColors.successSurface;

    final badgeText = isPharmacist
        ? (!inStock
            ? 'Rupture'
            : isLow
                ? 'Faible ($quantity)'
                : 'En stock ($quantity)')
        : (inStock ? 'Disponible' : 'Sur commande');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MediCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () async {
          if (isPharmacist) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockManagementScreen(medicineId: medicine.medicineId!),
              ),
            );
            if (result == true) {
              _controller.refresh();
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PharmacyFinderScreen(initialMedicine: medicine.name),
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine photo
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: medicine.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.medication_rounded, color: AppColors.primary, size: 26),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.medication_rounded, color: AppColors.primary, size: 26),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (medicine.dci != null && medicine.dci!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'DCI : ${medicine.dci}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (medicine.dosage != null || medicine.forme != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [medicine.dosage, medicine.forme].whereType<String>().join(' • '),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                      if (isPharmacist && stock?.shelfLocation != null && stock!.shelfLocation!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              stock.shelfLocation!,
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Price & Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${displayedPrice.toStringAsFixed(3)} DT',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (stock?.customPrice != null)
                  Text(
                    'Prix officine',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                if (medicine.prescriptionRequired) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Ordonnance',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    isPharmacist ? Icons.edit_rounded : Icons.search_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Type / Catégorie', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const Divider(),
          ListTile(
            title: const Text('Tous les types'),
            trailing: _controller.selectedType == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () {
              _controller.filterByType(null);
              Navigator.pop(sheetContext);
            },
          ),
          ..._controller.availableTypes.map(
            (type) => ListTile(
              title: Text(type),
              trailing: _controller.selectedType == type ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () {
                _controller.filterByType(type);
                Navigator.pop(sheetContext);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFormeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Forme pharmaceutique', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const Divider(),
          ListTile(
            title: const Text('Toutes les formes'),
            trailing: _controller.selectedForme == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () {
              _controller.filterByForme(null);
              Navigator.pop(sheetContext);
            },
          ),
          ..._controller.availableFormes.map(
            (forme) => ListTile(
              title: Text(forme),
              trailing: _controller.selectedForme == forme ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () {
                _controller.filterByForme(forme);
                Navigator.pop(sheetContext);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Prescription médicale', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const Divider(),
          ListTile(
            title: const Text('Tous'),
            trailing: _controller.prescriptionFilter == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () {
              _controller.filterByPrescription(null);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            title: const Text('Sur ordonnance uniquement'),
            trailing: _controller.prescriptionFilter == true ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () {
              _controller.filterByPrescription(true);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            title: const Text('Sans ordonnance (vente libre)'),
            trailing: _controller.prescriptionFilter == false ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () {
              _controller.filterByPrescription(false);
              Navigator.pop(sheetContext);
            },
          ),
        ],
      ),
    );
  }
}
