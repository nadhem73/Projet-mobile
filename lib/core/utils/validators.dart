/// Validateurs de formulaires réutilisables (messages en français).
///
/// Usage : `validator: Validators.email` ou
/// `validator: Validators.combine([Validators.required('Le nom'), Validators.minLength(2)])`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _tnPhone = RegExp(r'^(\+216)?[2-9]\d{7}$');
  static final RegExp _cin = RegExp(r'^\d{8}$');

  static String? Function(String?) required([String field = 'Ce champ']) =>
      (v) => (v == null || v.trim().isEmpty) ? '$field est obligatoire' : null;

  static String? Function(String?) minLength(int min, [String field = 'Ce champ']) =>
      (v) =>
          (v != null && v.trim().isNotEmpty && v.trim().length < min)
              ? '$field doit contenir au moins $min caractères'
              : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'L\'adresse e-mail est obligatoire';
    return _email.hasMatch(v.trim()) ? null : 'Adresse e-mail invalide';
  }

  /// Numéro tunisien : 8 chiffres, préfixe +216 optionnel (espaces ignorés).
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le numéro de téléphone est obligatoire';
    return _tnPhone.hasMatch(v.replaceAll(RegExp(r'[\s.-]'), '')) ? null : 'Numéro invalide (8 chiffres)';
  }

  static String? optionalPhone(String? v) => (v == null || v.trim().isEmpty) ? null : phone(v);

  /// Carte d'identité nationale tunisienne : 8 chiffres.
  static String? cin(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le numéro CIN est obligatoire';
    return _cin.hasMatch(v.trim()) ? null : 'Le CIN contient 8 chiffres';
  }

  /// Au moins 8 caractères, une lettre et un chiffre.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est obligatoire';
    if (v.length < 8) return 'Au moins 8 caractères';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Doit contenir au moins une lettre et un chiffre';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) =>
      (v) => v != original() ? 'Les mots de passe ne correspondent pas' : null;

  static String? Function(String?) number({
    double? min,
    double? max,
    bool optional = true,
    String field = 'La valeur',
  }) => (v) {
    if (v == null || v.trim().isEmpty) return optional ? null : '$field est obligatoire';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return '$field doit être un nombre';
    if (min != null && n < min) return '$field doit être ≥ $min';
    if (max != null && n > max) return '$field doit être ≤ $max';
    return null;
  };

  static String? Function(String?) combine(List<String? Function(String?)> validators) => (v) {
    for (final validator in validators) {
      final error = validator(v);
      if (error != null) return error;
    }
    return null;
  };
}
