import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/pharmacy_pharmacien_schema.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';

/// Repository pour gérer le stock des pharmacies.
///
/// Chaque pharmacie gère son propre stock indépendamment.
class StockRepository {
  StockRepository(this._database);

  final AppDatabase _database;

  /// Récupère tout le stock d'une pharmacie.
  Future<List<PharmacyStock>> getByPharmacy(int pharmacyId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ?',
      whereArgs: [pharmacyId],
      orderBy: 'updated_at DESC',
    );

    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Récupère le stock d'un médicament dans une pharmacie spécifique.
  Future<PharmacyStock?> getStockItem(int pharmacyId, int medicineId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND medicine_id = ?',
      whereArgs: [pharmacyId, medicineId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return PharmacyStock.fromMap(results.first);
  }

  /// Crée ou met à jour le stock d'un médicament.
  ///
  /// Si le stock existe déjà (même pharmacy_id + medicine_id), il est mis à jour.
  /// Sinon, un nouveau stock est créé.
  Future<int> createOrUpdate(PharmacyStock stock) async {
    final db = _database.db;

    final existing = await getStockItem(stock.pharmacyId, stock.medicineId);

    if (existing != null) {
      // Update existing stock
      final updatedStock = stock.copyWith(
        stockId: existing.stockId,
        updatedAt: DateTime.now(),
      );
      await db.update(
        PharmacyPharmacienTables.pharmacyStock,
        updatedStock.toMap(),
        where: 'stock_id = ?',
        whereArgs: [existing.stockId],
      );
      return existing.stockId!;
    } else {
      // Insert new stock
      final newStock = stock.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return await db.insert(
        PharmacyPharmacienTables.pharmacyStock,
        newStock.toMap(),
      );
    }
  }

  /// Met à jour le stock existant.
  Future<void> update(PharmacyStock stock) async {
    final db = _database.db;
    final updatedStock = stock.copyWith(updatedAt: DateTime.now());
    await db.update(
      PharmacyPharmacienTables.pharmacyStock,
      updatedStock.toMap(),
      where: 'stock_id = ?',
      whereArgs: [stock.stockId],
    );
  }

  /// Supprime un stock.
  Future<void> delete(int stockId) async {
    final db = _database.db;
    await db.delete(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'stock_id = ?',
      whereArgs: [stockId],
    );
  }

  /// Récupère les médicaments en stock d'une pharmacie.
  ///
  /// Filtre uniquement les items avec in_stock = 1.
  Future<List<PharmacyStock>> getInStockItems(int pharmacyId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND in_stock = 1',
      whereArgs: [pharmacyId],
      orderBy: 'updated_at DESC',
    );

    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Récupère les médicaments en rupture de stock.
  Future<List<PharmacyStock>> getOutOfStockItems(int pharmacyId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND in_stock = 0',
      whereArgs: [pharmacyId],
      orderBy: 'updated_at DESC',
    );

    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Récupère les médicaments avec stock faible.
  ///
  /// [threshold]: Seuil de quantité (par défaut 10).
  Future<List<PharmacyStock>> getLowStockItems(
    int pharmacyId, {
    int threshold = 10,
  }) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND in_stock = 1 AND quantity < ?',
      whereArgs: [pharmacyId, threshold],
      orderBy: 'quantity ASC',
    );

    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Récupère les médicaments qui expirent bientôt.
  ///
  /// [months]: Nombre de mois avant expiration (par défaut 6).
  Future<List<PharmacyStock>> getExpiringSoonItems(
    int pharmacyId, {
    int months = 6,
  }) async {
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month + months, now.day);

    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND expiration_date IS NOT NULL AND expiration_date <= ?',
      whereArgs: [pharmacyId, threshold.toIso8601String()],
      orderBy: 'expiration_date ASC',
    );

    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Récupère les médicaments expirés.
  Future<List<PharmacyStock>> getExpiredItems(int pharmacyId) async {
    final now = DateTime.now();

    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND expiration_date IS NOT NULL AND expiration_date < ?',
      whereArgs: [pharmacyId, now.toIso8601String()],
      orderBy: 'expiration_date ASC',
    );

    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Import en masse de stocks (pour CSV).
  ///
  /// Utilise une transaction pour de meilleures performances.
  Future<void> bulkImport(List<PharmacyStock> stocks) async {
    final db = _database.db;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final stock in stocks) {
        final stockToInsert = stock.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        batch.insert(
          PharmacyPharmacienTables.pharmacyStock,
          stockToInsert.toMap(),
        );
      }

      await batch.commit(noResult: true);
    });
  }

  /// Vérifie si un médicament est en stock dans une pharmacie.
  Future<bool> isInStock(int pharmacyId, int medicineId) async {
    final stock = await getStockItem(pharmacyId, medicineId);
    return stock != null && stock.inStock && stock.quantity > 0;
  }

  /// Récupère la liste des stocks disponibles parmi une liste d'IDs de médicaments.
  Future<List<PharmacyStock>> getInStockFromList(int pharmacyId, List<int> medicineIds) async {
    if (medicineIds.isEmpty) return [];
    final db = _database.db;
    final placeholders = List.filled(medicineIds.length, '?').join(',');
    final results = await db.query(
      PharmacyPharmacienTables.pharmacyStock,
      where: 'pharmacy_id = ? AND medicine_id IN ($placeholders) AND in_stock = 1 AND quantity > 0',
      whereArgs: [pharmacyId, ...medicineIds],
    );
    return results.map((row) => PharmacyStock.fromMap(row)).toList();
  }

  /// Compte le nombre total d'items en stock pour une pharmacie.
  Future<int> countInStock(int pharmacyId) async {
    final db = _database.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${PharmacyPharmacienTables.pharmacyStock} '
      'WHERE pharmacy_id = ? AND in_stock = 1',
      [pharmacyId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Compte le nombre total de médicaments gérés par une pharmacie.
  Future<int> countTotal(int pharmacyId) async {
    final db = _database.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${PharmacyPharmacienTables.pharmacyStock} '
      'WHERE pharmacy_id = ?',
      [pharmacyId],
    );
    return result.first['count'] as int? ?? 0;
  }
}
