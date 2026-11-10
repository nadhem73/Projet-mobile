import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/doctor/data/models/medicament.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';

/// Recherche des médicaments prescriptibles dans le catalogue local
/// (table `medicines` de la base, alimentée par le module Pharmacie).
class MedicamentCatalog {
  MedicamentCatalog(this._medicines);

  final MedicineRepository _medicines;

  /// Médicaments dont le nom, la DCI, le dosage ou la forme contient [query]
  /// (au moins 2 caractères).
  Future<List<Medicament>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final found = await _medicines.search(q);
      return [
        for (final m in found)
          if (m.medicineId != null)
            Medicament(
              id: m.medicineId!,
              name: m.name,
              dosage: m.dosage,
              forme: m.forme,
              dci: m.dci,
              presentation: m.presentation,
            ),
      ];
    } catch (e) {
      throw AppException('Catalogue des médicaments indisponible.', cause: e);
    }
  }
}
