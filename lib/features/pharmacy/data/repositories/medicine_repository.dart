import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/pharmacy_pharmacien_schema.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';

/// Repository pour gérer le catalogue de médicaments.
///
/// Le catalogue est global et partagé par toutes les pharmacies.
class MedicineRepository {
  MedicineRepository(this._database);

  final AppDatabase _database;

  /// Recherche des médicaments par nom.
  ///
  /// Recherche insensible à la casse avec LIKE.
  Future<List<Medicine>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];

    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'name ASC',
      limit: 100,
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Recherche des médicaments par DCI (Dénomination Commune Internationale).
  Future<List<Medicine>> searchByDCI(String dci) async {
    if (dci.trim().isEmpty) return [];

    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'LOWER(dci) LIKE ?',
      whereArgs: ['%${dci.toLowerCase()}%'],
      orderBy: 'name ASC',
      limit: 100,
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Recherche combinée nom ou DCI, avec filtre optionnel de forme galénique.
  ///
  /// [formeKeywords] : liste de mots-clés LIKE dans la colonne `forme`
  /// (ex: ['comprim', 'gelule']). Si vide, aucun filtre de forme n'est appliqué.
  Future<List<Medicine>> search(String query, {List<String> formeKeywords = const []}) async {
    if (query.trim().isEmpty && formeKeywords.isEmpty) return [];

    final db = _database.db;
    final q = query.trim().toLowerCase();

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (q.isNotEmpty) {
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      for (final token in tokens) {
        whereParts.add(
          r"(LOWER(name) LIKE ? OR LOWER(COALESCE(dci, '')) LIKE ? OR LOWER(COALESCE(dosage, '')) LIKE ? OR LOWER(COALESCE(forme, '')) LIKE ?)",
        );
        whereArgs.addAll(['%$token%', '%$token%', '%$token%', '%$token%']);
      }
    }

    if (formeKeywords.isNotEmpty) {
      final formeClauses = formeKeywords.map((_) => 'LOWER(forme) LIKE ?').join(' OR ');
      whereParts.add('($formeClauses)');
      for (final kw in formeKeywords) {
        whereArgs.add('%${kw.toLowerCase()}%');
      }
    }

    final firstWord = q.split(RegExp(r'\s+')).firstWhere((w) => w.isNotEmpty, orElse: () => q);
    final escapedWord = firstWord.replaceAll("'", "''");
    final orderByClause = q.isNotEmpty
        ? "CASE WHEN LOWER(name) = '$escapedWord' THEN 1 WHEN LOWER(name) LIKE '$escapedWord%' THEN 2 ELSE 3 END, name ASC, price ASC"
        : 'name ASC';

    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderByClause,
      limit: 100,
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Filtre les médicaments par type (catégorie).
  Future<List<Medicine>> filterByType(String type) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Filtre les médicaments par forme (Comprimés, Gélules, etc.).
  Future<List<Medicine>> filterByForme(String forme) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'forme = ?',
      whereArgs: [forme],
      orderBy: 'name ASC',
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Filtre les médicaments nécessitant une prescription.
  Future<List<Medicine>> filterByPrescriptionRequired(bool required) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'prescription_required = ?',
      whereArgs: [required ? 1 : 0],
      orderBy: 'name ASC',
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Récupère un médicament par son ID.
  Future<Medicine?> getById(int medicineId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'medicine_id = ?',
      whereArgs: [medicineId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Medicine.fromMap(results.first);
  }

  /// Récupère plusieurs médicaments par leurs IDs.
  Future<List<Medicine>> getByIds(List<int> medicineIds) async {
    if (medicineIds.isEmpty) return [];

    final db = _database.db;
    final placeholders = List.filled(medicineIds.length, '?').join(',');
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: 'medicine_id IN ($placeholders)',
      whereArgs: medicineIds,
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Récupère tous les médicaments (paginé).
  ///
  /// [offset]: Position de départ
  /// [limit]: Nombre de résultats
  Future<List<Medicine>> getAll({int offset = 0, int limit = 50}) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  /// Compte le nombre total de médicaments dans le catalogue.
  Future<int> count() async {
    final db = _database.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${PharmacyPharmacienTables.medicines}',
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Récupère tous les types (catégories) uniques.
  ///
  /// Utilisé pour le filtre par catégorie dans l'UI.
  Future<List<String>> getAllTypes() async {
    final db = _database.db;
    final results = await db.rawQuery(
      'SELECT DISTINCT type FROM ${PharmacyPharmacienTables.medicines} '
      'WHERE type IS NOT NULL ORDER BY type ASC',
    );

    return results
        .map((row) => row['type'] as String)
        .where((type) => type.isNotEmpty)
        .toList();
  }

  /// Récupère toutes les formes uniques.
  ///
  /// Utilisé pour le filtre par forme dans l'UI.
  Future<List<String>> getAllFormes() async {
    final db = _database.db;
    final results = await db.rawQuery(
      'SELECT DISTINCT forme FROM ${PharmacyPharmacienTables.medicines} '
      'WHERE forme IS NOT NULL ORDER BY forme ASC',
    );

    return results
        .map((row) => row['forme'] as String)
        .where((forme) => forme.isNotEmpty)
        .toList();
  }

  /// Recherche avancée avec filtres multiples.
  Future<List<Medicine>> searchWithFilters({
    String? query,
    String? type,
    String? forme,
    bool? prescriptionRequired,
    int limit = 100,
  }) async {
    final db = _database.db;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      conditions.add('(LOWER(name) LIKE ? OR LOWER(dci) LIKE ?)');
      final searchTerm = '%${query.toLowerCase()}%';
      args.addAll([searchTerm, searchTerm]);
    }

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }

    if (forme != null) {
      conditions.add('forme = ?');
      args.add(forme);
    }

    if (prescriptionRequired != null) {
      conditions.add('prescription_required = ?');
      args.add(prescriptionRequired ? 1 : 0);
    }

    final whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    final results = await db.query(
      PharmacyPharmacienTables.medicines,
      where: whereClause,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
      limit: limit,
    );

    return results.map((row) => Medicine.fromMap(row)).toList();
  }
}
