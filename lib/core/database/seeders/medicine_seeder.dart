import 'package:flutter/foundation.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';
import 'package:medilink/features/pharmacy/data/services/csv_import_service.dart';
import 'package:sqflite/sqflite.dart';

/// Seeder pour le module Pharmacie.
///
/// Charge les données initiales :
/// - Médicaments depuis medicine_data_tn_with_images.csv (~2,708 médicaments)
/// - Pharmacies de test (si non existantes)
/// - Stock pour chaque pharmacie (Tunis, Ariana, Manouba)
class MedicineSeeder {
  MedicineSeeder(this.db);

  final Database db;
  final CsvImportService _csvService = CsvImportService();

  static const String medicineCsvPath = 'assets/data/medicine_data_tn_with_images.csv';
  static const String stockCsvPath = 'assets/data/stock_medicaments_tn.csv';

  /// Exécute le seeding complet du module pharmacie.
  Future<void> seed() async {
    debugPrint('[MedicineSeeder] Starting medicine catalog import...');

    // 1. Importer les médicaments
    await _seedMedicines();

    // 2. Vérifier les pharmacies de test
    await _seedPharmacies();

    // 3. Importer les données de stock
    await _seedStockData();

    debugPrint('[MedicineSeeder] Seeding completed successfully!');
  }

  /// Importe les médicaments depuis le fichier CSV ou la liste par défaut.
  Future<void> _seedMedicines() async {
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM medicines');
    final existingCount = Sqflite.firstIntValue(countResult) ?? 0;
    if (existingCount >= 2000) {
      debugPrint('[MedicineSeeder] Medicines already fully seeded ($existingCount items)');
      return;
    }
    if (existingCount > 0) {
      debugPrint('[MedicineSeeder] Upgrading from $existingCount items to full catalog of 2700+ medicines...');
      await db.delete('medicines');
    }

    List<Medicine> medicines = [];

    try {
      debugPrint('[MedicineSeeder] Importing medicines from CSV...');
      medicines = await _csvService.parseMedicinesCsvFromAsset(medicineCsvPath);
    } catch (e) {
      debugPrint('[MedicineSeeder] CSV assets unavailable: $e. Using built-in medicine seed list.');
      medicines = _getDefaultMedicines();
    }

    if (medicines.isEmpty) {
      medicines = _getDefaultMedicines();
    }

    debugPrint('[MedicineSeeder] Inserting ${medicines.length} medicines into database...');

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final med in medicines) {
        batch.insert('medicines', med.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });

    debugPrint('[MedicineSeeder] ✓ ${medicines.length} medicines imported successfully');
  }

  /// Vérifie et insère des pharmacies de test si aucune n'existe.
  Future<void> _seedPharmacies() async {
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM pharmacies');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count > 0) {
      debugPrint('[MedicineSeeder] Sample pharmacies already exist ($count found)');
      return;
    }

    // Récupérer un utilisateur pharmacien existant
    final users = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['PHARMACIEN'],
      limit: 1,
    );

    int pUserId = 5;
    if (users.isNotEmpty) {
      pUserId = users.first['id'] as int;
    }

    final samplePharmacies = [
      Pharmacy(
        pharmacyId: 1,
        pharmacienUserId: pUserId,
        name: 'Pharmacie Centrale de Tunis',
        address: '15 Avenue Habib Bourguiba, Tunis 1000',
        latitude: 36.8008,
        longitude: 10.1800,
        phone: '+216 71 320 450',
        email: 'contact@pharmacie-centrale.tn',
        openingHours: {
          'monday': '08:00-19:30',
          'tuesday': '08:00-19:30',
          'wednesday': '08:00-19:30',
          'thursday': '08:00-19:30',
          'friday': '08:00-19:30',
          'saturday': '08:00-14:00',
          'sunday': 'Fermé',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final pharmacy in samplePharmacies) {
        batch.insert('pharmacies', pharmacy.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });

    debugPrint('[MedicineSeeder] ✓ Sample pharmacies verified and saved');
  }

  /// Importe les données de stock pour toutes les pharmacies (Tunis, Ariana, Manouba).
  Future<void> _seedStockData() async {
    final pharmacies = await db.query('pharmacies', orderBy: 'pharmacy_id ASC');
    if (pharmacies.isEmpty) return;

    final medCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM medicines');
    final totalMedicines = Sqflite.firstIntValue(medCountResult) ?? 0;
    if (totalMedicines == 0) return;

    final stockCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM pharmacy_stock');
    final existingStock = Sqflite.firstIntValue(stockCountResult) ?? 0;
    
    // Si toutes les pharmacies ont déjà l'intégralité du catalogue (2708 items)
    if (totalMedicines > 100 && existingStock >= (pharmacies.length * (totalMedicines - 100))) {
      debugPrint('[MedicineSeeder] Stock already fully seeded ($existingStock items)');
      return;
    }

    if (existingStock > 0) {
      debugPrint('[MedicineSeeder] Upgrading stock to cover all $totalMedicines medicines for all ${pharmacies.length} pharmacies...');
      await db.delete('pharmacy_stock');
    }

    final pharmacyId = pharmacies.first['pharmacy_id'] as int;

    // Récupérer les identifiants réels des médicaments en base pour respecter la clé étrangère
    final medRows = await db.query('medicines', columns: ['medicine_id'], orderBy: 'medicine_id ASC');
    final medicineIds = medRows.map((r) => r['medicine_id'] as int).toList();
    if (medicineIds.isEmpty) return;

    List<PharmacyStock> stockItems = [];
    try {
      stockItems = await _csvService.parseStockCsvFromAsset(stockCsvPath, pharmacyId);
    } catch (e) {
      debugPrint('[MedicineSeeder] CSV stock import failed: $e. Generating default stock.');
    }

    // Déduplication et liaison avec les IDs réels des médicaments
    final uniqueStocks = <int, PharmacyStock>{};
    for (int i = 0; i < stockItems.length && i < medicineIds.length; i++) {
      final realMedId = medicineIds[i];
      uniqueStocks[realMedId] = stockItems[i].copyWith(
        pharmacyId: pharmacyId,
        medicineId: realMedId,
      );
    }

    // Compléter le stock initial pour couvrir TOUS les médicaments réels
    for (int idx = 0; idx < medicineIds.length; idx++) {
      final medId = medicineIds[idx];
      if (!uniqueStocks.containsKey(medId)) {
        // Forte disponibilité pour les essentiels (90%), normale pour les autres (80%)
        final isHighDemand = (idx % 12 == 0) || (idx >= 895 && idx <= 925) || (idx >= 1914 && idx <= 1920) || (idx >= 2596 && idx <= 2602);
        final inStock = isHighDemand ? (idx % 10 != 0) : (idx % 5 != 0);
        final qty = inStock ? (((idx * 7) % 80) + 10) : 0;

        uniqueStocks[medId] = PharmacyStock(
          pharmacyId: pharmacyId,
          medicineId: medId,
          inStock: inStock,
          quantity: qty,
          shelfLocation: 'Rayon ${(idx % 8) + 1} - Étagère ${(idx % 4) + 1}',
          expirationDate: DateTime.now().add(Duration(days: ((idx * 37) % 700) + 60)),
          manufacturingDate: DateTime.now().subtract(Duration(days: ((idx * 23) % 400) + 60)),
          lastRestockDate: DateTime.now().subtract(Duration(days: (idx % 30) + 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    debugPrint('[MedicineSeeder] Inserting ${uniqueStocks.length} stock items for primary pharmacy $pharmacyId...');

    // Insertion pour la pharmacie 1 (Pharmacie Centrale)
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final stock in uniqueStocks.values) {
        batch.insert('pharmacy_stock', stock.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });

    // Insertion du stock pour TOUTES les autres pharmacies (Tunis, Ariana, Manouba)
    // Distribution réaliste : ~55% en stock, ~25% équivalents génériques, ~20% rupture
    for (var pIdx = 1; pIdx < pharmacies.length; pIdx++) {
      final pid = pharmacies[pIdx]['pharmacy_id'] as int;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var idx = 0; idx < medicineIds.length; idx++) {
          final medId = medicineIds[idx];
          final isDoliprane = idx >= 895 && idx <= 925;
          final isAdol = idx >= 37 && idx <= 40;
          final isPanadol = idx >= 1914 && idx <= 1918;
          final isAmoclan = idx >= 149 && idx <= 152;
          final isClamoxyl = idx >= 589 && idx <= 591;

          bool isAvailable;
          if (isDoliprane) {
            // Doliprane disponible dans ~55% des officines (pid pairs ou multiples de 3)
            isAvailable = (pid % 2 == 0) || (pid % 3 == 0);
          } else if (isAdol) {
            // Adol disponible en alternance (notamment quand Doliprane est en rupture)
            isAvailable = (pid % 2 != 0) || (pid % 5 == 0);
          } else if (isPanadol) {
            // Panadol disponible dans ~45% des officines
            isAvailable = (pid % 3 != 0) && (pid % 2 == 0);
          } else if (isAmoclan) {
            isAvailable = (pid % 2 == 0) || (pid % 5 == 0);
          } else if (isClamoxyl) {
            isAvailable = (pid % 2 != 0) || (pid % 3 == 0);
          } else {
            // Autres médicaments : ~55% de disponibilité
            isAvailable = ((medId * 7 + pid * 13) % 10) < 6;
          }

          final qty = isAvailable ? (((medId * 5 + pid * 17) % 65) + 8) : 0;
          final expDays = ((medId * 23 + pid * 31) % 800) + 90;
          final mfgDays = ((medId * 11 + pid * 19) % 365) + 30;

          batch.insert(
            'pharmacy_stock',
            {
              'pharmacy_id': pid,
              'medicine_id': medId,
              'in_stock': isAvailable ? 1 : 0,
              'quantity': qty,
              'shelf_location': 'Rayon ${(medId % 8) + 1} - Étagère ${(pid % 4) + 1}',
              'expiration_date': DateTime.now().add(Duration(days: expDays)).toIso8601String().split('T').first,
              'manufacturing_date': DateTime.now().subtract(Duration(days: mfgDays)).toIso8601String().split('T').first,
              'last_restock_date': DateTime.now().subtract(Duration(days: (medId % 25) + 1)).toIso8601String().split('T').first,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    }

    debugPrint('[MedicineSeeder] ✓ Complete multi-pharmacy stock populated for all ${pharmacies.length} pharmacies ($totalMedicines items each)');
  }

  /// Médicaments tunisiens par défaut si le CSV n'est pas disponible.
  List<Medicine> _getDefaultMedicines() {
    return [
      Medicine(
        name: 'Doliprane 1000 mg',
        dosage: '1000 mg',
        forme: 'Comprimé',
        presentation: 'B/8',
        price: 3.250,
        remboursement: 2.100,
        dci: 'Paracétamol',
        type: 'Antalgique / Antipyrétique',
        prescriptionRequired: false,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Augmentin 1 g / 125 mg',
        dosage: '1 g / 125 mg',
        forme: 'Poudre pour suspension',
        presentation: 'B/14',
        price: 18.450,
        remboursement: 12.900,
        dci: 'Amoxicilline + Acide clavulanique',
        type: 'Antibiotique',
        prescriptionRequired: true,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Spasfon',
        dosage: '80 mg',
        forme: 'Comprimé enrobé',
        presentation: 'B/30',
        price: 5.800,
        remboursement: 3.500,
        dci: 'Phloroglucinol',
        type: 'Antispasmodique',
        prescriptionRequired: false,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Voltarène 50 mg',
        dosage: '50 mg',
        forme: 'Comprimé gastro-résistant',
        presentation: 'B/30',
        price: 7.900,
        remboursement: 4.800,
        dci: 'Diclofénac',
        type: 'Anti-inflammatoire non stéroïdien',
        prescriptionRequired: true,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Efferalgan 500 mg',
        dosage: '500 mg',
        forme: 'Comprimé effervescent',
        presentation: 'B/16',
        price: 2.950,
        remboursement: 1.800,
        dci: 'Paracétamol',
        type: 'Antalgique / Antipyrétique',
        prescriptionRequired: false,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Clamoxyl 500 mg',
        dosage: '500 mg',
        forme: 'Gélule',
        presentation: 'B/12',
        price: 6.400,
        remboursement: 4.200,
        dci: 'Amoxicilline',
        type: 'Antibiotique',
        prescriptionRequired: true,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Tahor 20 mg',
        dosage: '20 mg',
        forme: 'Comprimé pelliculé',
        presentation: 'B/30',
        price: 28.500,
        remboursement: 19.800,
        dci: 'Atorvastatine',
        type: 'Hypolipémiant',
        prescriptionRequired: true,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Inexium 20 mg',
        dosage: '20 mg',
        forme: 'Comprimé gastro-résistant',
        presentation: 'B/28',
        price: 24.300,
        remboursement: 16.500,
        dci: 'Ésoméprazole',
        type: 'Anti-ulcéreux',
        prescriptionRequired: true,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Ventoline 100 µg',
        dosage: '100 µg/dose',
        forme: 'Suspension pour inhalation',
        presentation: 'Flacon 200 doses',
        price: 8.750,
        remboursement: 6.100,
        dci: 'Salbutamol',
        type: 'Bronchodilatateur',
        prescriptionRequired: true,
        createdAt: DateTime.now(),
      ),
      Medicine(
        name: 'Panadol Extra',
        dosage: '500 mg / 65 mg',
        forme: 'Comprimé',
        presentation: 'B/24',
        price: 4.600,
        remboursement: null,
        dci: 'Paracétamol + Caféine',
        type: 'Antalgique',
        prescriptionRequired: false,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
