/// Médicament du dataset PostgreSQL (table `medicament`), reçu de l'API.
class Medicament {
  const Medicament({required this.id, required this.name, this.dosage, this.forme, this.dci, this.presentation});

  final int id;
  final String name;
  final String? dosage;
  final String? forme;

  /// Dénomination commune internationale (ex. « paracétamol »).
  final String? dci;

  /// Ex. « Boîte de 20 comprimés ».
  final String? presentation;

  /// Ligne secondaire affichée dans les résultats de recherche.
  String get details => [dosage, forme, dci].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  factory Medicament.fromJson(Map<String, dynamic> json) => Medicament(
    id: (json['medicament_id'] ?? json['id']) as int,
    name: json['name'] as String,
    dosage: json['dosage'] as String?,
    forme: json['forme'] as String?,
    dci: json['dci'] as String?,
    presentation: json['presentation'] as String?,
  );
}
