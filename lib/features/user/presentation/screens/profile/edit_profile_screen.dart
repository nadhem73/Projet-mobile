import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/constants/medical_specialties.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/user_profile.dart';
import 'package:medilink/features/user/presentation/controllers/profile_controller.dart';

/// Modification du profil. Revient à l'écran précédent avec `true` si enregistré.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = getIt<ProfileController>();

  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cin = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _fee = TextEditingController();
  final _biography = TextEditingController();
  final _pharmacyName = TextEditingController();

  DateTime? _dateNaissance;
  String? _specialty;
  String? _company;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _controller.load().then((_) => _fill());
  }

  void _fill() {
    final p = _controller.profile;
    if (p == null || !mounted) return;
    setState(() {
      _prenom.text = p.prenom;
      _nom.text = p.nom;
      _email.text = p.email;
      _phone.text = p.phone ?? '';
      _cin.text = p.cin ?? '';
      _dateNaissance = p.dateNaissance;
      _birthDate.text = p.dateNaissance == null ? '' : DateFormat('dd/MM/yyyy').format(p.dateNaissance!);
      _address.text = p.address ?? '';
      _city.text = p.city ?? '';
      _fee.text = p.fee?.toStringAsFixed(0) ?? '';
      _biography.text = p.biography ?? '';
      _pharmacyName.text = p.pharmacyName ?? '';
      _specialty = p.specialty;
      _company = p.company;
      _filled = true;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _prenom,
      _nom,
      _email,
      _phone,
      _cin,
      _birthDate,
      _address,
      _city,
      _fee,
      _biography,
      _pharmacyName,
    ]) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(DateTime.now().year - 25),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateNaissance = picked;
      _birthDate.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final p = _controller.profile!;
    final updated = UserProfile(
      userId: p.userId,
      role: p.role,
      nom: _nom.text,
      prenom: _prenom.text,
      email: _email.text,
      phone: _phone.text,
      createdAt: p.createdAt,
      cin: _cin.text,
      dateNaissance: _dateNaissance,
      address: _address.text,
      specialty: _specialty,
      licenseNumber: p.licenseNumber,
      biography: _biography.text,
      fee: double.tryParse(_fee.text.replaceAll(',', '.')),
      city: _city.text,
      pharmacyName: _pharmacyName.text,
      company: _company,
      agentCode: p.agentCode,
    );
    final ok = await _controller.save(updated);
    if (!mounted) return;
    if (ok) {
      context.pop(true);
    } else {
      context.showError(_controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final profile = _controller.profile;
          if (!_filled || profile == null) {
            if (_controller.error != null) return EmptyState.error(_controller.error!);
            return const LoadingView();
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MediTextField(
                        label: 'Prénom',
                        controller: _prenom,
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.required('Le prénom'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MediTextField(
                        label: 'Nom',
                        controller: _nom,
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.required('Le nom'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'Adresse e-mail',
                  controller: _email,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                MediTextField(
                  label: 'Téléphone',
                  controller: _phone,
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                ..._roleFields(profile),
                const SizedBox(height: AppSpacing.xl),
                MediButton(
                  label: 'Enregistrer',
                  icon: Icons.check_rounded,
                  isLoading: _controller.isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _roleFields(UserProfile p) {
    const gap = SizedBox(height: AppSpacing.md);
    Widget readOnly(String label, String? value, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        initialValue: value ?? '',
        enabled: false,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), helperText: 'Non modifiable'),
      ),
    );

    return switch (p.role) {
      UserRole.patient => [
        MediTextField(
          label: 'Numéro CIN',
          controller: _cin,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          validator: Validators.cin,
        ),
        gap,
        MediTextField(
          label: 'Date de naissance',
          controller: _birthDate,
          prefixIcon: Icons.cake_outlined,
          readOnly: true,
          onTap: _pickBirthDate,
        ),
        gap,
        MediTextField(label: 'Adresse', controller: _address, prefixIcon: Icons.place_outlined),
      ],
      UserRole.doctor => [
        readOnly('N° Ordre des médecins', p.licenseNumber, Icons.verified_outlined),
        DropdownButtonFormField<String>(
          initialValue: MedicalSpecialties.all.contains(_specialty) ? _specialty : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Spécialité'),
          items: [for (final s in MedicalSpecialties.all) DropdownMenuItem(value: s, child: Text(s))],
          onChanged: (v) => setState(() => _specialty = v),
          validator: (v) => v == null ? 'Choisissez votre spécialité' : null,
        ),
        gap,
        MediTextField(label: 'Ville', controller: _city, prefixIcon: Icons.location_city_rounded),
        gap,
        MediTextField(label: 'Adresse du cabinet', controller: _address, prefixIcon: Icons.place_outlined),
        gap,
        MediTextField(
          label: 'Tarif de consultation (TND)',
          controller: _fee,
          prefixIcon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.number(min: 0, max: 1000, field: 'Le tarif'),
        ),
        gap,
        MediTextField(
          label: 'Présentation',
          controller: _biography,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
      UserRole.pharmacist => [
        readOnly('N° d\'autorisation', p.licenseNumber, Icons.verified_outlined),
        MediTextField(
          label: 'Nom de la pharmacie',
          controller: _pharmacyName,
          prefixIcon: Icons.storefront_outlined,
          validator: Validators.required('Le nom de la pharmacie'),
        ),
        gap,
        MediTextField(label: 'Adresse', controller: _address, prefixIcon: Icons.place_outlined),
        gap,
        MediTextField(label: 'Ville', controller: _city, prefixIcon: Icons.location_city_rounded),
      ],
      UserRole.insurer => [
        readOnly('Matricule agent', p.agentCode, Icons.badge_outlined),
        DropdownButtonFormField<String>(
          initialValue: InsuranceCompanies.all.contains(_company) ? _company : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Organisme'),
          items: [for (final c in InsuranceCompanies.all) DropdownMenuItem(value: c, child: Text(c))],
          onChanged: (v) => setState(() => _company = v),
          validator: (v) => v == null ? 'Choisissez votre organisme' : null,
        ),
      ],
    };
  }
}
