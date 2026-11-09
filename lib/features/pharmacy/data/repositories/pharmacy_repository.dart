import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/pharmacy_pharmacien_schema.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';

/// Repository pour gérer les pharmacies (CRUD).
class PharmacyRepository {
  PharmacyRepository(this._database);

  final AppDatabase _database;

  /// Récupère la pharmacie d'un pharmacien.
  ///
  /// Un pharmacien ne peut avoir qu'une seule pharmacie (relation 1:1).
  Future<Pharmacy?> getByPharmacienUserId(int pharmacienUserId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacies,
      where: 'pharmacien_user_id = ?',
      whereArgs: [pharmacienUserId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Pharmacy.fromMap(results.first);
  }

  /// Récupère une pharmacie par son ID.
  Future<Pharmacy?> getById(int pharmacyId) async {
    final db = _database.db;
    final results = await db.query(
      PharmacyPharmacienTables.pharmacies,
      where: 'pharmacy_id = ?',
      whereArgs: [pharmacyId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Pharmacy.fromMap(results.first);
  }

  /// Récupère toutes les pharmacies.
  ///
  /// Utilisé par le Pharmacy Finder pour afficher les pharmacies sur la carte.
  Future<List<Pharmacy>> getAll() async {
    final db = _database.db;
    final results = await db.query(PharmacyPharmacienTables.pharmacies);
    return results.map((row) => Pharmacy.fromMap(row)).toList();
  }

  /// Récupère les pharmacies dans un rayon géographique.
  ///
  /// [latitude]: Latitude du point central
  /// [longitude]: Longitude du point central
  /// [radiusKm]: Rayon en kilomètres
  ///
  /// Note: Cette méthode charge toutes les pharmacies puis filtre en mémoire.
  /// Pour de meilleures performances avec beaucoup de pharmacies, utiliser une extension
  /// SQLite avec calcul de distance géographique.
  Future<List<Pharmacy>> getWithinRadius(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    final allPharmacies = await getAll();

    return allPharmacies.where((pharmacy) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        pharmacy.latitude,
        pharmacy.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Crée une nouvelle pharmacie.
  ///
  /// Utilisé lors de l'inscription d'un pharmacien.
  Future<int> create(Pharmacy pharmacy) async {
    final db = _database.db;
    final pharmacyToInsert = pharmacy.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await db.insert(
      PharmacyPharmacienTables.pharmacies,
      pharmacyToInsert.toMap(),
    );
  }

  /// Met à jour une pharmacie existante.
  Future<void> update(Pharmacy pharmacy) async {
    final db = _database.db;
    final pharmacyToUpdate = pharmacy.copyWith(updatedAt: DateTime.now());
    await db.update(
      PharmacyPharmacienTables.pharmacies,
      pharmacyToUpdate.toMap(),
      where: 'pharmacy_id = ?',
      whereArgs: [pharmacy.pharmacyId],
    );
  }

  /// Supprime une pharmacie.
  ///
  /// Supprime également tout le stock associé (CASCADE).
  Future<void> delete(int pharmacyId) async {
    final db = _database.db;
    await db.delete(
      PharmacyPharmacienTables.pharmacies,
      where: 'pharmacy_id = ?',
      whereArgs: [pharmacyId],
    );
  }

  /// Calcule la distance entre deux points GPS (formule de Haversine).
  ///
  /// Returns: Distance en kilomètres
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Rayon de la Terre en km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) => x == 0 ? 0 : _sqrtNewton(x, x / 2);
  double _sqrtNewton(double x, double guess) {
    final next = (guess + x / guess) / 2;
    return (guess - next).abs() < 0.0001 ? next : _sqrtNewton(x, next);
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0; // x == 0 && y == 0
  }

  double _atan(double x) {
    final x2 = x * x;
    return x * (1 - x2 / 3 + x2 * x2 / 5 - x2 * x2 * x2 / 7);
  }
}
