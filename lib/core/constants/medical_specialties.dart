/// Spécialités médicales proposées à l'inscription d'un médecin et dans la
/// recherche de médecins (module Rendez-vous).
abstract final class MedicalSpecialties {
  static const List<String> all = [
    'Médecine générale',
    'Cardiologie',
    'Dermatologie',
    'Pédiatrie',
    'Gynécologie',
    'Ophtalmologie',
    'ORL',
    'Neurologie',
    'Psychiatrie',
    'Orthopédie',
    'Pneumologie',
    'Gastro-entérologie',
    'Endocrinologie',
    'Rhumatologie',
    'Urologie',
    'Néphrologie',
    'Médecine dentaire',
    'Radiologie',
  ];
}

/// Groupes sanguins acceptés par la table `medical_records`.
abstract final class BloodGroups {
  static const List<String> all = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
}

/// Caisses et compagnies d'assurance (inscription assureur, dossier médical).
abstract final class InsuranceCompanies {
  static const List<String> all = [
    'CNAM',
    'STAR',
    'COMAR',
    'GAT Assurances',
    'Maghrebia',
    'Lloyd Assurances',
    'BIAT Assurances',
    'Assurances BH',
    'AMI Assurances',
    'Autre',
  ];
}
