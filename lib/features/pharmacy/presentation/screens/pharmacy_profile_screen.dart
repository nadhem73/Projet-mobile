import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/pharmacy/presentation/controllers/pharmacy_profile_controller.dart';
import 'package:medilink/features/pharmacy/presentation/widgets/map_location_picker_dialog.dart';

/// Écran d'édition du profil, des horaires et de la position GPS de l'officine.
/// Conforme aux standards d'interface MediLink (MediCard, MediButton, AppColors).
class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  late PharmacyProfileController _controller;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _initialName = '';
  String _initialAddress = '';
  String _initialPhone = '';
  String _initialEmail = '';
  double _initialLatitude = 0.0;
  double _initialLongitude = 0.0;
  bool _initialIsNight = false;
  Map<String, String>? _initialOpeningHours;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<PharmacyProfileController>();
    _controller.load().then((_) {
      if (mounted) {
        _nameController.text = _controller.name;
        _addressController.text = _controller.address;
        _phoneController.text = _controller.phone;
        _emailController.text = _controller.email ?? '';
        _syncInitialValues();
      }
    });
  }

  void _syncInitialValues() {
    _initialName = _controller.name;
    _initialAddress = _controller.address;
    _initialPhone = _controller.phone;
    _initialEmail = _controller.email ?? '';
    _initialLatitude = _controller.latitude;
    _initialLongitude = _controller.longitude;
    _initialIsNight = _controller.isNightPharmacy;
    _initialOpeningHours = Map<String, String>.from(_controller.openingHours ?? {});
    _isInitialized = true;
  }

  bool get _hasUnsavedChanges {
    if (!_isInitialized) return false;
    if (_nameController.text.trim() != _initialName.trim()) return true;
    if (_addressController.text.trim() != _initialAddress.trim()) return true;
    if (_phoneController.text.trim() != _initialPhone.trim()) return true;
    if (_emailController.text.trim() != _initialEmail.trim()) return true;
    if ((_controller.latitude - _initialLatitude).abs() > 0.00001) return true;
    if ((_controller.longitude - _initialLongitude).abs() > 0.00001) return true;
    if (_controller.isNightPharmacy != _initialIsNight) return true;

    final currentHours = _controller.openingHours ?? {};
    if (_initialOpeningHours != null) {
      if (currentHours.length != _initialOpeningHours!.length) return true;
      for (final entry in currentHours.entries) {
        if (_initialOpeningHours![entry.key] != entry.value) return true;
      }
    }
    return false;
  }

  Future<bool> _showDiscardChangesDialogIfNeeded() async {
    if (!_hasUnsavedChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter sans enregistrer ?'),
        content: const Text('Vous avez des modifications non enregistrées. Voulez-vous vraiment quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer l\'édition'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  Future<void> _handleBack() async {
    final canLeave = await _showDiscardChangesDialogIfNeeded();
    if (canLeave && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showDiscardChangesDialogIfNeeded();
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil de l\'officine'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const LoadingView(message: 'Chargement du profil de l\'officine...');
            }

            return Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _buildInfoSection(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildNightPharmacyToggle(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildContactSection(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildOpeningHoursSection(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildLocationSection(context),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Identité de l\'officine',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom de la pharmacie *',
              prefixIcon: const Icon(Icons.local_pharmacy_rounded),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Nom requis';
              return null;
            },
            onChanged: (value) => _controller.setName(value.trim()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Adresse complète *',
              prefixIcon: const Icon(Icons.location_on_rounded),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Adresse requise';
              return null;
            },
            onChanged: (value) => _controller.setAddress(value.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildNightPharmacyToggle(BuildContext context) {
    final theme = Theme.of(context);
    final isNight = _controller.isNightPharmacy;

    return MediCard(
      color: isNight ? AppColors.primarySurface : null,
      borderColor: isNight ? AppColors.primary : null,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        secondary: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isNight ? AppColors.primary.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
            color: isNight ? AppColors.primary : Colors.orange,
            size: 22,
          ),
        ),
        title: Text(
          'Pharmacie de Garde / Nuit',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isNight ? 'Garde de nuit active (19h30 - 08h30)' : 'Officine de jour standard',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        value: isNight,
        activeTrackColor: AppColors.primary,
        onChanged: (val) {
          _controller.setIsNightPharmacy(val);
          _nameController.text = _controller.name;
        },
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Coordonnées de contact',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone *',
              prefixIcon: const Icon(Icons.phone_rounded),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Téléphone requis';
              return null;
            },
            onChanged: (value) => _controller.setPhone(value.trim()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email officiel de contact',
              prefixIcon: const Icon(Icons.email_rounded),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: theme.dividerColor)),
            ),
            onChanged: (value) => _controller.setEmail(value.trim().isEmpty ? null : value.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHoursSection(BuildContext context) {
    final theme = Theme.of(context);
    final hours = _controller.openingHours ?? {};
    final days = [
      {'key': 'monday', 'label': 'Lundi'},
      {'key': 'tuesday', 'label': 'Mardi'},
      {'key': 'wednesday', 'label': 'Mercredi'},
      {'key': 'thursday', 'label': 'Jeudi'},
      {'key': 'friday', 'label': 'Vendredi'},
      {'key': 'saturday', 'label': 'Samedi'},
      {'key': 'sunday', 'label': 'Dimanche'},
    ];

    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Horaires d\'ouverture',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choisissez un modèle rapide ou modifiez jour par jour',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.wb_sunny_rounded, size: 16),
                  label: const Text('Jour (08h-19h30)', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    _controller.applyHoursPreset('day');
                    context.showSuccess('Modèle jour appliqué');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ActionChip(
                  avatar: const Icon(Icons.nights_stay_rounded, size: 16),
                  label: const Text('Nuit (19h30-08h30)', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    _controller.applyHoursPreset('night');
                    context.showSuccess('Modèle garde de nuit appliqué');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ActionChip(
                  avatar: const Icon(Icons.all_inclusive_rounded, size: 16),
                  label: const Text('24h / 24', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    _controller.applyHoursPreset('24h');
                    context.showSuccess('Modèle 24h/24 appliqué');
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ...days.map((d) {
            final key = d['key']!;
            final label = d['label']!;
            final currentVal = hours[key] ?? '08:00-19:30';
            final isClosed = currentVal.toLowerCase() == 'fermé';

            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => _showEditDayHoursDialog(context, key, label, currentVal),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(width: 90, child: Text(label, style: theme.textTheme.bodyMedium)),
                    Expanded(
                      child: Text(
                        currentVal,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isClosed ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showEditDayHoursDialog(
    BuildContext context,
    String dayKey,
    String dayLabel,
    String currentVal,
  ) async {
    String selected = currentVal;
    bool applyToAll = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Horaires : $dayLabel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Actuel : $selected', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('08:00 - 19:30', style: TextStyle(fontSize: 12)),
                          selected: selected == '08:00-19:30',
                          onSelected: (_) => setDialogState(() => selected = '08:00-19:30'),
                        ),
                        ChoiceChip(
                          label: const Text('08:00 - 14:00', style: TextStyle(fontSize: 12)),
                          selected: selected == '08:00-14:00',
                          onSelected: (_) => setDialogState(() => selected = '08:00-14:00'),
                        ),
                        ChoiceChip(
                          label: const Text('19:30 - 08:30 (Nuit)', style: TextStyle(fontSize: 12)),
                          selected: selected == '19:30-08:30',
                          onSelected: (_) => setDialogState(() => selected = '19:30-08:30'),
                        ),
                        ChoiceChip(
                          label: const Text('24h / 24', style: TextStyle(fontSize: 12)),
                          selected: selected == '00:00-23:59',
                          onSelected: (_) => setDialogState(() => selected = '00:00-23:59'),
                        ),
                        ChoiceChip(
                          label: const Text('Fermé', style: TextStyle(fontSize: 12)),
                          selected: selected == 'Fermé',
                          onSelected: (_) => setDialogState(() => selected = 'Fermé'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Appliquer à tous les jours', style: TextStyle(fontSize: 13)),
                      value: applyToAll,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setDialogState(() => applyToAll = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () {
                    if (applyToAll) {
                      const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
                      for (final k in allDays) {
                        _controller.setDayHours(k, selected);
                      }
                    } else {
                      _controller.setDayHours(dayKey, selected);
                    }
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Géolocalisation & Carte',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Latitude : ${_controller.latitude.toStringAsFixed(6)}\nLongitude : ${_controller.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Les patients utilisent ces coordonnées GPS pour localiser votre pharmacie et tracer leur itinéraire.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          MediButton(
            label: 'Choisir sur la carte OpenStreetMap',
            icon: Icons.map_rounded,
            onPressed: () async {
              final result = await MapLocationPickerDialog.show(
                context,
                initialLatitude: _controller.latitude,
                initialLongitude: _controller.longitude,
                initialAddress: _controller.address,
              );
              if (result != null) {
                _controller.setCoordinates(result.latitude, result.longitude);
                if (result.address != null && result.address!.isNotEmpty) {
                  _controller.setAddress(result.address!);
                  _addressController.text = result.address!;
                }
                if (context.mounted) {
                  context.showSuccess('Position GPS mise à jour depuis la carte');
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          MediButton.outlined(
            label: 'Utiliser ma position GPS actuelle',
            icon: Icons.my_location_rounded,
            onPressed: () async {
              try {
                final enabled = await Geolocator.isLocationServiceEnabled();
                if (!enabled && context.mounted) {
                  context.showError('Service de localisation désactivé');
                  return;
                }
                var perm = await Geolocator.checkPermission();
                if (perm == LocationPermission.denied) {
                  perm = await Geolocator.requestPermission();
                }
                if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
                  final pos = await Geolocator.getCurrentPosition();
                  _controller.setCoordinates(pos.latitude, pos.longitude);
                  if (context.mounted) {
                    context.showSuccess('Position GPS détectée');
                  }
                } else if (context.mounted) {
                  context.showError('Permission de localisation refusée');
                }
              } catch (e) {
                if (context.mounted) context.showError('Erreur GPS: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: MediButton(
          label: 'Enregistrer le profil de l\'officine',
          icon: Icons.save_rounded,
          isLoading: _controller.isSaving,
          onPressed: _controller.canSave && !_controller.isSaving
              ? () async {
                  if (_formKey.currentState!.validate()) {
                    final ok = await _controller.save();
                    if (ok && context.mounted) {
                      _syncInitialValues();
                      context.showSuccess('Profil de l\'officine mis à jour');
                      Navigator.pop(context);
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
