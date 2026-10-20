import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/constants/medical_specialties.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/session/user_role_style.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/utils/validators.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/registration_data.dart';
import 'package:medilink/features/user/presentation/controllers/auth_controller.dart';
import 'package:medilink/features/user/presentation/widgets/auth_scaffold.dart';
import 'package:medilink/features/user/presentation/widgets/role_card.dart';

/// Inscription en deux étapes : choix du rôle, puis formulaire adapté au rôle.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = getIt<AuthController>();

  UserRole _selectedRole = UserRole.patient;

  /// Rôle confirmé : null tant que l'utilisateur est sur l'étape 1.
  UserRole? _role;

  // Champs communs
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Champs spécifiques
  final _cin = TextEditingController();
  final _birthDate = TextEditingController();
  final _license = TextEditingController();
  final _city = TextEditingController();
  final _pharmacyName = TextEditingController();
  final _address = TextEditingController();
  final _agentCode = TextEditingController();

  DateTime? _dateNaissance;
  String _gender = 'F';
  String? _specialty;
  String? _company;
  bool _consent = false;

  @override
  void dispose() {
    for (final c in [
      _prenom,
      _nom,
      _email,
      _phone,
      _password,
      _confirm,
      _cin,
      _birthDate,
      _license,
      _city,
      _pharmacyName,
      _address,
      _agentCode,
    ]) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _back() {
    if (_role != null) {
      setState(() => _role = null);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked == null) return;
    setState(() {
      _dateNaissance = picked;
      _birthDate.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      context.showError('Vous devez accepter les conditions d\'utilisation');
      return;
    }
    final user = await _controller.register(
      RegistrationData(
        role: _role!,
        nom: _nom.text,
        prenom: _prenom.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        cin: _cin.text,
        dateNaissance: _dateNaissance,
        gender: _gender,
        specialty: _specialty,
        city: _city.text,
        licenseNumber: _license.text,
        pharmacyName: _pharmacyName.text,
        address: _address.text,
        company: _company,
        agentCode: _agentCode.text,
      ),
    );
    if (!mounted) return;
    if (user == null) {
      context.showError(_controller.error!);
    } else {
      context.showSuccess('Bienvenue ${user.prenom}, votre compte est créé !');
      context.go(AppRoutes.homeFor(user.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    return PopScope(
      canPop: role == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _role = null);
      },
      child: AuthScaffold(
        title: role == null ? 'Créer un compte' : 'Compte ${role.label.toLowerCase()}',
        subtitle: role == null ? 'Étape 1 sur 2 — Qui êtes-vous ?' : 'Étape 2 sur 2 — Vos informations',
        onBack: _back,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: role == null ? _buildRoleStep() : _buildForm(role),
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    return Column(
      key: const ValueKey('roles'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in UserRole.values) ...[
          RoleCard(role: role, selected: role == _selectedRole, onTap: () => setState(() => _selectedRole = role)),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        MediButton(
          label: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => setState(() => _role = _selectedRole),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Déjà inscrit ?'),
            TextButton(onPressed: () => context.go(AppRoutes.login), child: const Text('Se connecter')),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(UserRole role) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        key: ValueKey(role),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(label: role.label, color: role.color, icon: role.icon),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FormSection('Informations personnelles'),
          Row(
            children: [
              Expanded(
                child: MediTextField(
                  label: 'Prénom',
                  controller: _prenom,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  validator: Validators.combine([Validators.required('Le prénom'), Validators.minLength(2)]),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MediTextField(
                  label: 'Nom',
                  controller: _nom,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  validator: Validators.combine([Validators.required('Le nom'), Validators.minLength(2)]),
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
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          MediTextField(
            label: 'Téléphone',
            hint: '22 345 678',
            controller: _phone,
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: Validators.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
          _FormSection(switch (role) {
            UserRole.patient => 'Informations patient',
            UserRole.doctor => 'Informations professionnelles',
            UserRole.pharmacist => 'Votre pharmacie',
            UserRole.insurer => 'Votre organisme',
          }),
          ..._roleFields(role),
          const SizedBox(height: AppSpacing.xl),
          const _FormSection('Sécurité'),
          MediTextField(
            label: 'Mot de passe',
            controller: _password,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            helperText: 'Au moins 8 caractères, une lettre et un chiffre',
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          MediTextField(
            label: 'Confirmer le mot de passe',
            controller: _confirm,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: Validators.confirmPassword(() => _password.text),
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'J\'accepte les conditions d\'utilisation et le traitement de mes données '
              'conformément à la loi tunisienne sur la protection des données personnelles.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: _controller,
            builder:
                (context, _) => MediButton(
                  label: 'Créer mon compte',
                  icon: Icons.check_rounded,
                  isLoading: _controller.isLoading,
                  onPressed: _submit,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _roleFields(UserRole role) {
    const gap = SizedBox(height: AppSpacing.md);
    return switch (role) {
      UserRole.patient => [
        MediTextField(
          label: 'Numéro CIN',
          controller: _cin,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
          validator: Validators.cin,
        ),
        gap,
        MediTextField(
          label: 'Date de naissance',
          controller: _birthDate,
          prefixIcon: Icons.cake_outlined,
          readOnly: true,
          onTap: _pickBirthDate,
          validator: Validators.required('La date de naissance'),
        ),
        gap,
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'F', label: Text('Femme'), icon: Icon(Icons.female_rounded)),
            ButtonSegment(value: 'M', label: Text('Homme'), icon: Icon(Icons.male_rounded)),
          ],
          selected: {_gender},
          onSelectionChanged: (s) => setState(() => _gender = s.first),
        ),
      ],
      UserRole.doctor => [
        DropdownButtonFormField<String>(
          initialValue: _specialty,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Spécialité',
            prefixIcon: Icon(Icons.medical_information_outlined, size: 20),
          ),
          items: [for (final s in MedicalSpecialties.all) DropdownMenuItem(value: s, child: Text(s))],
          onChanged: (v) => setState(() => _specialty = v),
          validator: (v) => v == null ? 'Choisissez votre spécialité' : null,
        ),
        gap,
        MediTextField(
          label: 'N° d\'inscription à l\'Ordre des médecins',
          controller: _license,
          prefixIcon: Icons.verified_outlined,
          validator: Validators.required('Le numéro d\'inscription'),
        ),
        gap,
        MediTextField(
          label: 'Ville d\'exercice',
          controller: _city,
          prefixIcon: Icons.location_city_rounded,
          textCapitalization: TextCapitalization.words,
          validator: Validators.required('La ville'),
        ),
      ],
      UserRole.pharmacist => [
        MediTextField(
          label: 'Nom de la pharmacie',
          controller: _pharmacyName,
          prefixIcon: Icons.storefront_outlined,
          textCapitalization: TextCapitalization.words,
          validator: Validators.required('Le nom de la pharmacie'),
        ),
        gap,
        MediTextField(
          label: 'N° d\'autorisation d\'exercice',
          controller: _license,
          prefixIcon: Icons.verified_outlined,
          validator: Validators.required('Le numéro d\'autorisation'),
        ),
        gap,
        MediTextField(
          label: 'Adresse',
          controller: _address,
          prefixIcon: Icons.place_outlined,
          validator: Validators.required('L\'adresse'),
        ),
        gap,
        MediTextField(
          label: 'Ville',
          controller: _city,
          prefixIcon: Icons.location_city_rounded,
          textCapitalization: TextCapitalization.words,
          validator: Validators.required('La ville'),
        ),
      ],
      UserRole.insurer => [
        DropdownButtonFormField<String>(
          initialValue: _company,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Caisse / compagnie',
            prefixIcon: Icon(Icons.business_rounded, size: 20),
          ),
          items: [for (final c in InsuranceCompanies.all) DropdownMenuItem(value: c, child: Text(c))],
          onChanged: (v) => setState(() => _company = v),
          validator: (v) => v == null ? 'Choisissez votre organisme' : null,
        ),
        gap,
        MediTextField(
          label: 'Matricule agent',
          controller: _agentCode,
          prefixIcon: Icons.badge_outlined,
          validator: Validators.required('Le matricule'),
        ),
      ],
    };
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
