import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/stock_management_controller.dart';

/// Écran de gestion du stock et du prix d'un médicament dans l'officine.
/// Conforme à la charte visuelle MediLink (MediCard, MediButton, AppColors).
class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({
    super.key,
    required this.medicineId,
  });

  final int medicineId;

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  late StockManagementController _controller;
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<StockManagementController>();
    _controller.loadMedicine(widget.medicineId).then((_) {
      if (mounted) {
        _quantityController.text = _controller.quantity.toString();
        _locationController.text = _controller.shelfLocation;
        final p = _controller.customPrice ?? _controller.medicine?.price ?? 0.0;
        _priceController.text = p.toStringAsFixed(3);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du stock'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const LoadingView(message: 'Chargement des données de stock...');
          }

          if (_controller.error != null && _controller.medicine == null) {
            return EmptyState.error(
              _controller.error!,
              onRetry: () => _controller.loadMedicine(widget.medicineId),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _buildMedicineInfo(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPriceCard(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStockAndQuantityCard(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLocationCard(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDatesCard(context),
                      if (_controller.hasStock) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _buildDeleteButton(context),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMedicineInfo(BuildContext context) {
    if (_controller.medicine == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final medicine = _controller.medicine!;

    return MediCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: theme.dividerColor),
              ),
              child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: medicine.imageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.medication_rounded, color: AppColors.primary, size: 28),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.medication_rounded, color: AppColors.primary, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (medicine.dci != null && medicine.dci!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'DCI : ${medicine.dci}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
                if (medicine.dosage != null || medicine.forme != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [medicine.dosage, medicine.forme].whereType<String>().join(' • '),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Prix national : ${medicine.price.toStringAsFixed(3)} DT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context) {
    final theme = Theme.of(context);
    final basePrice = _controller.medicine?.price ?? 0.0;

    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.sell_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Prix de vente officine (TND)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Référence nationale : ${basePrice.toStringAsFixed(3)} DT',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              suffixText: 'DT',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              hintText: basePrice.toStringAsFixed(3),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              helperText: 'Chaque officine peut appliquer librement sa tarification locale',
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val.replaceAll(',', '.'));
              _controller.setCustomPrice(parsed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockAndQuantityCard(BuildContext context) {
    final theme = Theme.of(context);

    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Disponibilité en officine',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _controller.inStock ? 'Produit disponible en stock' : 'Rupture de stock signalée',
              style: TextStyle(
                color: _controller.inStock ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            value: _controller.inStock,
            activeTrackColor: AppColors.success,
            onChanged: (val) {
              _controller.setInStock(val);
              _quantityController.text = _controller.quantity.toString();
            },
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quantité en stock',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () {
                  _controller.decrementQuantity(1);
                  _quantityController.text = _controller.quantity.toString();
                },
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    suffixText: 'unités',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                    border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requis';
                    final qty = int.tryParse(value);
                    if (qty == null || qty < 0) return 'Invalide';
                    return null;
                  },
                  onChanged: (value) {
                    final qty = int.tryParse(value);
                    if (qty != null) {
                      _controller.setQuantity(qty);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton.filledTonal(
                onPressed: () {
                  _controller.incrementQuantity(1);
                  _quantityController.text = _controller.quantity.toString();
                },
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primarySurface,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Emplacement (Rayon / Tiroir)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Ex: Rayon A, Tiroir 3, Armoire centrale',
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
            ),
            onChanged: (val) => _controller.setShelfLocation(val),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesCard(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dates de suivi & péremption',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDateTile(
            context,
            label: 'Date d\'expiration',
            icon: Icons.alarm_rounded,
            value: _controller.expirationDate,
            color: AppColors.error,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _controller.expirationDate ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (date != null) _controller.setExpirationDate(date);
            },
          ),
          const Divider(),
          _buildDateTile(
            context,
            label: 'Date de fabrication',
            icon: Icons.precision_manufacturing_rounded,
            value: _controller.manufacturingDate,
            color: AppColors.info,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _controller.manufacturingDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                lastDate: DateTime.now(),
              );
              if (date != null) _controller.setManufacturingDate(date);
            },
          ),
          const Divider(),
          _buildDateTile(
            context,
            label: 'Dernier réapprovisionnement',
            icon: Icons.local_shipping_rounded,
            value: _controller.lastRestockDate,
            color: AppColors.success,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _controller.lastRestockDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) _controller.setLastRestockDate(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required DateTime? value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        value != null ? dateFormat.format(value) : 'Non renseignée',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
          color: value == null ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      trailing: const Icon(Icons.edit_calendar_rounded, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return MediButton.outlined(
      label: 'Retirer de mon inventaire',
      icon: Icons.delete_outline_rounded,
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Retirer de l\'inventaire ?'),
            content: const Text('Êtes-vous certain de vouloir retirer ce médicament du stock de votre officine ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Retirer'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final ok = await _controller.deleteStock();
          if (ok && context.mounted) {
            context.showSuccess('Stock retiré avec succès');
            Navigator.pop(context, true);
          }
        }
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: MediButton(
          label: 'Enregistrer les modifications',
          icon: Icons.save_rounded,
          isLoading: _controller.isSaving,
          onPressed: _controller.canSave && !_controller.isSaving
              ? () async {
                  if (_formKey.currentState!.validate()) {
                    final ok = await _controller.save();
                    if (ok && context.mounted) {
                      context.showSuccess('Modifications de stock enregistrées');
                      Navigator.pop(context, true);
                    } else if (_controller.error != null && context.mounted) {
                      context.showError(_controller.error!);
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}
