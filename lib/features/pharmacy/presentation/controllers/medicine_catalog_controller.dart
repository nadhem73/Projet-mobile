import 'package:flutter/foundation.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/stock_repository.dart';

/// Controller pour le catalogue de médicaments du pharmacien.
/// Gère la recherche, les filtres et l'affichage avec stocks réels.
class MedicineCatalogController extends ChangeNotifier {
  MedicineCatalogController(
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
  String? _error;
  List<Medicine> _medicines = [];
  final Map<int, PharmacyStock?> _stockMap = {}; // medicineId -> stock
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedForme;
  bool? _prescriptionFilter;
  String? _stockStatusFilter; // 'in_stock', 'low_stock', 'out_of_stock', 'expiring_soon'

  // Filters disponibles
  List<String> _availableTypes = [];
  List<String> _availableFormes = [];

  int? _pharmacyId;
  String? _pharmacyName;
  bool _browseAllNational = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Medicine> get medicines => _medicines;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  String? get selectedForme => _selectedForme;
  bool? get prescriptionFilter => _prescriptionFilter;
  String? get stockStatusFilter => _stockStatusFilter;
  List<String> get availableTypes => _availableTypes;
  List<String> get availableFormes => _availableFormes;
  int? get pharmacyId => _pharmacyId;
  String? get pharmacyName => _pharmacyName;
  bool get browseAllNational => _browseAllNational;

  bool get hasFilters =>
      _selectedType != null ||
      _selectedForme != null ||
      _prescriptionFilter != null ||
      _stockStatusFilter != null ||
      _searchQuery.isNotEmpty;

  /// Retourne le stock d'un médicament.
  PharmacyStock? getStock(int medicineId) => _stockMap[medicineId];

  /// Vérifie si un médicament est en stock.
  bool isInStock(int medicineId) {
    final stock = _stockMap[medicineId];
    return stock != null && stock.inStock && stock.quantity > 0;
  }

  /// Charge le catalogue initial depuis SQLite.
  Future<void> load({String? initialFilter}) async {
    _isLoading = true;
    _error = null;
    if (initialFilter != null) {
      _stockStatusFilter = initialFilter;
    }
    notifyListeners();

    try {
      // 1. Déterminer l'officine active
      final user = _sessionService.currentUser;
      final userId = user?.userId ?? 5;

      final pharmacy = await _pharmacyRepo.getByPharmacienUserId(userId);
      if (pharmacy != null) {
        _pharmacyId = pharmacy.pharmacyId;
        _pharmacyName = pharmacy.name;
      } else {
        final all = await _pharmacyRepo.getAll();
        if (all.isNotEmpty) {
          _pharmacyId = all.first.pharmacyId;
          _pharmacyName = all.first.name;
        } else {
          _pharmacyId = 1;
          _pharmacyName = 'Pharmacie Centrale';
        }
      }

      // 2. Charger les types et formes distincts
      _availableTypes = await _medicineRepo.getAllTypes();
      _availableFormes = await _medicineRepo.getAllFormes();

      // 3. Charger les médicaments avec recherche et filtres
      await _performSearchInternal();

      _error = null;
    } catch (e, stack) {
      _error = 'Erreur de chargement: ${e.toString()}';
      debugPrint('[MedicineCatalogController] Error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recherche des médicaments.
  Future<void> search(String query) async {
    _searchQuery = query;
    await _performSearch();
  }

  /// Filtre par type.
  Future<void> filterByType(String? type) async {
    _selectedType = type;
    await _performSearch();
  }

  /// Filtre par forme.
  Future<void> filterByForme(String? forme) async {
    _selectedForme = forme;
    await _performSearch();
  }

  /// Filtre par prescription requise.
  Future<void> filterByPrescription(bool? required) async {
    _prescriptionFilter = required;
    await _performSearch();
  }

  /// Filtre par statut de stock (ex: 'in_stock', 'low_stock', 'out_of_stock', 'expiring_soon').
  Future<void> filterByStockStatus(String? status) async {
    _stockStatusFilter = status;
    await _performSearch();
  }

  /// Réinitialise tous les filtres.
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedType = null;
    _selectedForme = null;
    _prescriptionFilter = null;
    _stockStatusFilter = null;
    await _performSearch();
  }

  /// Exécute la recherche avec les filtres actuels.
  Future<void> _performSearch() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _performSearchInternal();
      _error = null;
    } catch (e, stack) {
      _error = 'Erreur de recherche: ${e.toString()}';
      debugPrint('[MedicineCatalogController] Search error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _performSearchInternal() async {
    // 1. Récupération des médicaments filtrés
    var list = await _medicineRepo.searchWithFilters(
      query: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      type: _selectedType,
      forme: _selectedForme,
      prescriptionRequired: _prescriptionFilter,
      limit: 150,
    );

    // 2. Charger le stock pour chaque médicament affiché
    if (_pharmacyId != null) {
      await _loadStockForMedicines(list);
    }

    // 3. Si en mode "Mon Officine", ne montrer que les médicaments de l'inventaire de cette pharmacie
    if (!_browseAllNational && _pharmacyId != null) {
      list = list.where((m) {
        final s = _stockMap[m.medicineId];
        return s != null;
      }).toList();
    }

    // 4. Filtrer par statut de stock si demandé
    if (_stockStatusFilter != null && _pharmacyId != null) {
      final now = DateTime.now();
      final sixMonthsFromNow = DateTime(now.year, now.month + 6, now.day);

      list = list.where((m) {
        final stock = _stockMap[m.medicineId];
        switch (_stockStatusFilter) {
          case 'in_stock':
            return stock != null && stock.inStock && stock.quantity > 0;
          case 'out_of_stock':
            return stock == null || !stock.inStock || stock.quantity == 0;
          case 'low_stock':
            return stock != null && stock.inStock && stock.quantity > 0 && stock.quantity <= 15;
          case 'expiring_soon':
            return stock != null &&
                stock.expirationDate != null &&
                stock.expirationDate!.isBefore(sixMonthsFromNow);
          default:
            return true;
        }
      }).toList();
    }

    _medicines = list;
  }

  /// Charge le stock pour les médicaments affichés.
  Future<void> _loadStockForMedicines(List<Medicine> list) async {
    for (final medicine in list) {
      if (medicine.medicineId != null && !_stockMap.containsKey(medicine.medicineId)) {
        final stock = await _stockRepo.getStockItem(_pharmacyId!, medicine.medicineId!);
        _stockMap[medicine.medicineId!] = stock;
      }
    }
  }

  /// Bascule entre "Mon Officine" (stock propre) et "Répertoire National" (ajouter un médicament).
  void toggleCatalogMode(bool showAllNational) {
    _browseAllNational = showAllNational;
    _performSearch();
  }

  /// Rafraîchit les données.
  Future<void> refresh() => _performSearch();
}
