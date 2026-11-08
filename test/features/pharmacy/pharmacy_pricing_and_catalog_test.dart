import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_finder_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/stock_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('Pharmacy Module - Custom Prices & Isolated Catalog', () {
    late AppDatabase appDb;
    late MedicineRepository medicineRepo;
    late PharmacyRepository pharmacyRepo;
    late StockRepository stockRepo;
    late PharmacyFinderRepository finderRepo;

    setUp(() async {
      appDb = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath, seed: false);
      medicineRepo = MedicineRepository(appDb);
      pharmacyRepo = PharmacyRepository(appDb);
      stockRepo = StockRepository(appDb);
      finderRepo = PharmacyFinderRepository(pharmacyRepo, medicineRepo, stockRepo);

      // Create test user and two test pharmacies
      await appDb.db.insert('users', {
        'id': 100,
        'nom': 'Mansouri',
        'prenom': 'Hela',
        'email': 'ph1@test.tn',
        'password_hash': 'hash',
        'role': 'PHARMACIST',
        'status': 'ACTIVE',
      });
      await appDb.db.insert('users', {
        'id': 101,
        'nom': 'Karray',
        'prenom': 'Slim',
        'email': 'ph2@test.tn',
        'password_hash': 'hash',
        'role': 'PHARMACIST',
        'status': 'ACTIVE',
      });

      await pharmacyRepo.create(
        Pharmacy(
          pharmacyId: 1,
          name: 'Pharmacie Centrale',
          address: 'Avenue Habib Bourguiba, Tunis',
          phone: '+216 71 000 001',
          latitude: 36.8000,
          longitude: 10.1800,
          pharmacienUserId: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await pharmacyRepo.create(
        Pharmacy(
          pharmacyId: 2,
          name: 'Pharmacie de Nuit',
          address: 'Avenue de la Liberté, Tunis',
          phone: '+216 71 000 002',
          latitude: 36.8100,
          longitude: 10.1800,
          pharmacienUserId: 101,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create Doliprane 1000 mg in medicines table (national base price: 3.200 DT)
      await appDb.db.insert('medicines', {
        'medicine_id': 1,
        'name': 'Doliprane',
        'dosage': '1000 mg',
        'forme': 'Comprimé',
        'price': 3.200,
        'prescription_required': 0,
      });
    });

    tearDown(() async {
      await appDb.close();
    });

    test('Chaque pharmacie peut fixer son propre prix de vente personnalisé', () async {
      // Pharmacie 1 sets custom price to 3.500 DT
      await stockRepo.createOrUpdate(
        PharmacyStock(
          pharmacyId: 1,
          medicineId: 1,
          inStock: true,
          quantity: 25,
          customPrice: 3.500,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Pharmacie 2 sets custom price to 3.800 DT
      await stockRepo.createOrUpdate(
        PharmacyStock(
          pharmacyId: 2,
          medicineId: 1,
          inStock: true,
          quantity: 15,
          customPrice: 3.800,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final stock1 = await stockRepo.getStockItem(1, 1);
      final stock2 = await stockRepo.getStockItem(2, 1);

      expect(stock1?.customPrice, 3.500);
      expect(stock2?.customPrice, 3.800);
      expect(stock1?.effectivePrice(3.200), 3.500);
      expect(stock2?.effectivePrice(3.200), 3.800);
    });

    test('La recherche patient affiche le prix spécifique de chaque pharmacie', () async {
      // Stock with different prices
      await stockRepo.createOrUpdate(
        PharmacyStock(
          pharmacyId: 1,
          medicineId: 1,
          inStock: true,
          quantity: 20,
          customPrice: 3.500,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await stockRepo.createOrUpdate(
        PharmacyStock(
          pharmacyId: 2,
          medicineId: 1,
          inStock: true,
          quantity: 10,
          customPrice: 3.800,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final doliprane = (await medicineRepo.getById(1))!;
      final results = await finderRepo.findNearbyPharmacies(
        medicineNames: ['Doliprane 1000 mg'],
        specificMedicines: [doliprane],
        userLatitude: 36.8000,
        userLongitude: 10.1800,
      );

      expect(results.length, 2);

      final r1 = results.firstWhere((r) => r.pharmacy.pharmacyId == 1);
      final r2 = results.firstWhere((r) => r.pharmacy.pharmacyId == 2);

      // Verify custom prices are returned for each pharmacy
      expect(r1.availableMedicineDetails.first.price, 3.500);
      expect(r2.availableMedicineDetails.first.price, 3.800);
    });

    test('Le prix national de base est utilisé en repli si aucun custom_price n\'est fixé', () async {
      await stockRepo.createOrUpdate(
        PharmacyStock(
          pharmacyId: 1,
          medicineId: 1,
          inStock: true,
          quantity: 5,
          customPrice: null, // Pas de prix personnalisé fixé
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final stock = await stockRepo.getStockItem(1, 1);
      expect(stock?.customPrice, isNull);
      expect(stock?.effectivePrice(3.200), 3.200);

      final doliprane = (await medicineRepo.getById(1))!;
      final results = await finderRepo.findNearbyPharmacies(
        medicineNames: ['Doliprane 1000 mg'],
        specificMedicines: [doliprane],
        userLatitude: 36.8000,
        userLongitude: 10.1800,
      );

      expect(results.first.availableMedicineDetails.first.price, 3.200);
    });
  });
}
