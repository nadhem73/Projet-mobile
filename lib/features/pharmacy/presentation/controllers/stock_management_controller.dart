import 'package:flutter/foundation.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/stock_repository.dart';

/// Controller pour la gestion du stock d'un médicament.
class StockManagementController extends ChangeNotifier {
  StockManagementController(
    this._sessionService,
    this._pharmacyRepo,
    this._medicineRepo,
    this._stockRepo,
  );

  final SessionService _sessionService;
  final PharmacyRepository _pharmacyRepo;
  final MedicineRepository _medicineRepo;
  final StockRepository _stockRepo;

  // State
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Medicine? _medicine;
  PharmacyStock? _stock;
  int? _pharmacyId;

  // Form state
  bool _inStock = true;
  int _quantity = 0;
  String _shelfLocation = '';
  double? _customPrice;
  DateTime? _expirationDate;
  DateTime? _manufacturingDate;
  DateTime? _lastRestockDate;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Medicine? get medicine => _medicine;
  PharmacyStock? get stock => _stock;

  bool get inStock => _inStock;
  int get quantity => _quantity;
  String get shelfLocation => _shelfLocation;
  double? get customPrice => _customPrice;
  DateTime? get expirationDate => _expirationDate;
  DateTime? get manufacturingDate => _manufacturingDate;
  DateTime? get lastRestockDate => _lastRestockDate;

  bool get hasStock => _stock != null;
  bool get canSave => _quantity >= 0;

  /// Charge les données pour un médicament.
  Future<void> loadMedicine(int medicineId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _sessionService.currentUser;
      final userId = user?.userId ?? 5;

      // 1. Récupérer la pharmacie
      Pharmacy? pharmacy = await _pharmacyRepo.getByPharmacienUserId(userId);
      if (pharmacy == null && user?.pharmacyId != null) {
        pharmacy = await _pharmacyRepo.getById(user!.pharmacyId!);
      }
      if (pharmacy == null) {
        final all = await _pharmacyRepo.getAll();
        if (all.isNotEmpty) {
          pharmacy = all.first;
        } else {
          final newPid = await _pharmacyRepo.create(
            Pharmacy(
              pharmacienUserId: userId,
              name: 'Pharmacie Centrale',
              address: '15 Avenue Habib Bourguiba, Tunis',
              phone: '+216 71 456 789',
              latitude: 36.8065,
              longitude: 10.1815,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          pharmacy = await _pharmacyRepo.getById(newPid);
        }
      }

      _pharmacyId = pharmacy?.pharmacyId ?? 1;

      // 2. Charger le médicament
      _medicine = await _medicineRepo.getById(medicineId);
      if (_medicine == null) {
        // Fallback: chercher par ID ou premier médicament disponible
        final allMeds = await _medicineRepo.getAll(limit: 5);
        if (allMeds.isNotEmpty) {
          _medicine = allMeds.first;
        } else {
          throw Exception('Médicament #$medicineId introuvable');
        }
      }

      // 3. Charger le stock existant
      _stock = await _stockRepo.getStockItem(_pharmacyId!, _medicine!.medicineId!);

      // Initialiser le formulaire
      if (_stock != null) {
        _inStock = _stock!.inStock;
        _quantity = _stock!.quantity;
        _shelfLocation = _stock!.shelfLocation ?? '';
        _customPrice = _stock!.customPrice ?? _medicine!.price;
        _expirationDate = _stock!.expirationDate;
        _manufacturingDate = _stock!.manufacturingDate;
        _lastRestockDate = _stock!.lastRestockDate;
      } else {
        // Valeurs par défaut pour nouveau stock
        _inStock = true;
        _quantity = 10;
        _shelfLocation = 'Rayon 1';
        _customPrice = _medicine!.price;
        _expirationDate = DateTime.now().add(const Duration(days: 365));
        _manufacturingDate = DateTime.now().subtract(const Duration(days: 90));
        _lastRestockDate = DateTime.now();
      }

      _error = null;
    } catch (e, stack) {
      _error = 'Erreur de chargement: ${e.toString()}';
      debugPrint('[StockManagementController] Error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour le prix de vente personnalisé de l'officine.
  void setCustomPrice(double? price) {
    _customPrice = price;
    notifyListeners();
  }

  /// Met à jour l'état "en stock".
  void setInStock(bool value) {
    _inStock = value;
    if (!value && _quantity > 0) {
      // Si on marque en rupture, garder la quantité ou la mettre à 0 au choix
    } else if (value && _quantity == 0) {
      _quantity = 1;
    }
    notifyListeners();
  }

  /// Met à jour la quantité.
  void setQuantity(int value) {
    _quantity = value.clamp(0, 999999);
    _inStock = _quantity > 0;
    notifyListeners();
  }

  /// Incrémente la quantité.
  void incrementQuantity([int step = 1]) {
    setQuantity(_quantity + step);
  }

  /// Décrémente la quantité.
  void decrementQuantity([int step = 1]) {
    setQuantity(_quantity - step);
  }

  /// Met à jour l'emplacement.
  void setShelfLocation(String value) {
    _shelfLocation = value;
    notifyListeners();
  }

  /// Met à jour la date d'expiration.
  void setExpirationDate(DateTime? date) {
    _expirationDate = date;
    notifyListeners();
  }

  /// Met à jour la date de fabrication.
  void setManufacturingDate(DateTime? date) {
    _manufacturingDate = date;
    notifyListeners();
  }

  /// Met à jour la date de réapprovisionnement.
  void setLastRestockDate(DateTime? date) {
    _lastRestockDate = date;
    notifyListeners();
  }

  /// Enregistre le stock.
  Future<bool> save() async {
    if (_medicine == null || _pharmacyId == null) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final stockToSave = PharmacyStock(
        stockId: _stock?.stockId,
        pharmacyId: _pharmacyId!,
        medicineId: _medicine!.medicineId!,
        inStock: _inStock && _quantity > 0,
        quantity: _quantity,
        shelfLocation: _shelfLocation.isEmpty ? null : _shelfLocation,
        customPrice: _customPrice,
        expirationDate: _expirationDate,
        manufacturingDate: _manufacturingDate,
        lastRestockDate: _lastRestockDate ?? DateTime.now(),
        createdAt: _stock?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _stockRepo.createOrUpdate(stockToSave);

      // Recharger le stock
      _stock = await _stockRepo.getStockItem(_pharmacyId!, _medicine!.medicineId!);

      _error = null;
      return true;
    } catch (e, stack) {
      _error = 'Erreur d\'enregistrement: ${e.toString()}';
      debugPrint('[StockManagementController] Save error: $e\n$stack');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Supprime le stock.
  Future<bool> deleteStock() async {
    if (_stock == null || _stock!.stockId == null) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _stockRepo.delete(_stock!.stockId!);
      _stock = null;
      _quantity = 0;
      _inStock = false;
      _error = null;
      return true;
    } catch (e, stack) {
      _error = 'Erreur de suppression: ${e.toString()}';
      debugPrint('[StockManagementController] Delete error: $e\n$stack');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
