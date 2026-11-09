import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';
import 'package:medilink/features/pharmacy/data/services/pharmacy_voice_nlp_service.dart';

void main() {
  late PharmacyVoiceNLPService service;
  late List<PharmacyStockItem> testItems;

  setUp(() {
    service = PharmacyVoiceNLPService();

    final now = DateTime.now();
    testItems = [
      PharmacyStockItem(
        medicine: Medicine(
          medicineId: 101,
          name: 'Doliprane 1000 mg',
          dci: 'Paracétamol',
          forme: 'Comprimé',
          price: 4.200,
          prescriptionRequired: false,
          createdAt: now,
        ),
        stock: PharmacyStock(
          stockId: 1,
          pharmacyId: 1,
          medicineId: 101,
          inStock: true,
          quantity: 15,
          shelfLocation: 'Rayon A-02',
          customPrice: 4.500,
          expirationDate: now.add(const Duration(days: 300)),
          createdAt: now,
          updatedAt: now,
        ),
      ),
      PharmacyStockItem(
        medicine: Medicine(
          medicineId: 102,
          name: 'Augmentin 1 g',
          dci: 'Amoxicilline',
          forme: 'Poudre pour suspension',
          price: 18.500,
          prescriptionRequired: true,
          createdAt: now,
        ),
        stock: PharmacyStock(
          stockId: 2,
          pharmacyId: 1,
          medicineId: 102,
          inStock: false,
          quantity: 0, // Rupture
          shelfLocation: 'Rayon B-04',
          expirationDate: now.add(const Duration(days: 200)),
          createdAt: now,
          updatedAt: now,
        ),
      ),
      PharmacyStockItem(
        medicine: Medicine(
          medicineId: 103,
          name: 'Spasfon',
          dci: 'Phloroglucinol',
          forme: 'Comprimé',
          price: 3.250,
          prescriptionRequired: false,
          createdAt: now,
        ),
        stock: PharmacyStock(
          stockId: 3,
          pharmacyId: 1,
          medicineId: 103,
          inStock: true,
          quantity: 3, // Stock faible & péremption proche
          shelfLocation: 'Tiroir C-1',
          expirationDate: now.add(const Duration(days: 20)), // Expire bientôt (< 90j)
          createdAt: now,
          updatedAt: now,
        ),
      ),
      PharmacyStockItem(
        medicine: Medicine(
          medicineId: 104,
          name: 'Panadol 500 mg',
          dci: 'Paracétamol', // Générique / équivalent Doliprane
          forme: 'Comprimé',
          price: 2.800,
          prescriptionRequired: false,
          createdAt: now,
        ),
        stock: PharmacyStock(
          stockId: 4,
          pharmacyId: 1,
          medicineId: 104,
          inStock: true,
          quantity: 20,
          shelfLocation: 'Rayon A-01',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      PharmacyStockItem(
        medicine: Medicine(
          medicineId: 105,
          name: 'Doliprane 500 mg',
          dci: 'Paracétamol',
          forme: 'Comprimé',
          price: 3.100,
          prescriptionRequired: false,
          createdAt: now,
        ),
        stock: PharmacyStock(
          stockId: 5,
          pharmacyId: 1,
          medicineId: 105,
          inStock: true,
          quantity: 25,
          shelfLocation: 'Rayon A-03',
          customPrice: 3.200,
          expirationDate: now.add(const Duration(days: 350)),
          createdAt: now,
          updatedAt: now,
        ),
      ),
    ];
  });

  group('PharmacyVoiceNLPService - Intent Detection', () {
    test('Détection de stock pour Doliprane (checkStock)', () {
      final res = service.parseCommand(
        voiceInput: 'Combien de boîtes de Doliprane en stock ?',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.checkStock);
      expect(res.matchedItem?.stock.stockId, 1);
      expect(res.spokenResponse, contains('15 boîtes disponibles'));
      expect(res.spokenResponse, contains('4.500 DT'));
    });

    test('Détection d\'emplacement / rayon (locateMedicine)', () {
      final res = service.parseCommand(
        voiceInput: 'Où se trouve le Spasfon ?',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.locateMedicine);
      expect(res.matchedItem?.stock.stockId, 3);
      expect(res.spokenResponse, contains('Tiroir C-1'));
    });

    test('Décrémentation de stock avec chiffre numérique (adjustStockDecrement)', () {
      final res = service.parseCommand(
        voiceInput: 'Décrémente 2 boîtes de Doliprane',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.adjustStockDecrement);
      expect(res.quantity, 2);
      expect(res.spokenResponse, contains('décrémenté de 2'));
      expect(res.spokenResponse, contains('13 boîtes'));
    });

    test('Décrémentation avec mot en français "trois boîtes" et verbe "vendu"', () {
      final res = service.parseCommand(
        voiceInput: 'J\'ai vendu trois boîtes de Panadol',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.adjustStockDecrement);
      expect(res.quantity, 3);
      expect(res.spokenResponse, contains('décrémenté de 3'));
      expect(res.spokenResponse, contains('17 boîtes'));
    });

    test('Incrémentation de stock (adjustStockIncrement)', () {
      final res = service.parseCommand(
        voiceInput: 'Ajoute 5 boîtes de Doliprane',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.adjustStockIncrement);
      expect(res.quantity, 5);
      expect(res.spokenResponse, contains('5 boîtes ajoutées'));
      expect(res.spokenResponse, contains('Total : 20 unités'));
    });

    test('Détection de prix (checkPrice)', () {
      final res = service.parseCommand(
        voiceInput: 'Quel est le prix du Spasfon ?',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.checkPrice);
      expect(res.spokenResponse, contains('3.250 Dinars'));
    });

    test('Détection de rupture de stock générale (checkStockout)', () {
      final res = service.parseCommand(
        voiceInput: 'Quels sont les médicaments en rupture ?',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.checkStockout);
      expect(res.listResults?.length, 1);
      expect(res.listResults?.first.medicineName, 'Augmentin 1 g');
      expect(res.spokenResponse, contains('Augmentin 1 g'));
    });

    test('Détection de péremption prochaine (checkExpiry)', () {
      final res = service.parseCommand(
        voiceInput: 'Qu\'est-ce qui expire bientôt ?',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.checkExpiry);
      expect(res.listResults?.length, 1);
      expect(res.listResults?.first.medicineName, 'Spasfon');
      expect(res.spokenResponse, contains('Spasfon'));
    });

    test('Recherche de générique / substitution (findGeneric)', () {
      final res = service.parseCommand(
        voiceInput: 'Quel est le générique du Doliprane ?',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.findGeneric);
      expect(res.listResults?.first.medicineName, 'Panadol 500 mg');
      expect(res.spokenResponse, contains('Panadol 500 mg'));
    });

    test('Fuzzy matching / tolérance aux fautes de prononciation', () {
      final res = service.parseCommand(
        voiceInput: 'Combien de dolipran en stock ?', // sans 'e'
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.checkStock);
      expect(res.matchedItem?.medicineName, 'Doliprane 1000 mg');
    });

    test('Modification de prix (updatePrice)', () {
      final res = service.parseCommand(
        voiceInput: 'Change le prix du Doliprane à 5 DT',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.updatePrice);
      expect(res.newPrice, 5.0);
      expect(res.matchedItem?.stock.stockId, 1);
      expect(res.spokenResponse, contains('Prix de Doliprane 1000 mg mis à 5.000 DT'));
    });

    test('Modification de prix avec dosage et forme spécifiques (change le prix le doliprane 500mg comprime a 8 dinars)', () {
      final res = service.parseCommand(
        voiceInput: 'change le prix le doliprane 500mg comprime a 8 dinars',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.updatePrice);
      expect(res.newPrice, 8.0);
      expect(res.matchedItem?.stock.stockId, 5); // Must match 500 mg, NOT 1000 mg!
      expect(res.matchedItem?.medicineName, 'Doliprane 500 mg');
      expect(res.spokenResponse, contains('Prix de Doliprane 500 mg mis à 8.000 DT'));
    });

    test('Modification d\'emplacement (updateLocation)', () {
      final res = service.parseCommand(
        voiceInput: 'Déplace le Spasfon au Rayon B',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.updateLocation);
      expect(res.newLocation, 'Rayon B');
      expect(res.matchedItem?.stock.stockId, 3);
      expect(res.spokenResponse, contains('Spasfon placé au Rayon B'));
    });

    test('Réglage direct de la quantité en stock (setStockQuantity)', () {
      final res = service.parseCommand(
        voiceInput: 'Mets le stock de Panadol à 25',
        currentStockItems: testItems,
      );

      expect(res.intent, VoiceIntentType.setStockQuantity);
      expect(res.quantity, 25);
      expect(res.matchedItem?.stock.stockId, 4);
      expect(res.spokenResponse, contains('Stock de Panadol 500 mg réglé à 25 boîtes'));
    });
  });
}
