import 'package:flutter/foundation.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/repositories/medicine_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/data/repositories/stock_repository.dart';

/// Controller pour le tableau de bord du pharmacien.
/// Affiche les statistiques réelles et actions rapides.
class PharmacyDashboardController extends ChangeNotifier {
  PharmacyDashboardController(
    this._sessionService,
    this._pharmacyRepo,
    this._stockRepo,
    this._medicineRepo,
  );

  final SessionService _sessionService;
  final PharmacyRepository _pharmacyRepo;
  final StockRepository _stockRepo;
  final MedicineRepository _medicineRepo;

  // State
  bool _isLoading = false;
  String? _error;
  Pharmacy? _pharmacy;
  int _totalMedicinesManaged = 0;
  int _inStockCount = 0;
  int _expiringSoonCount = 0;
  int _lowStockCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Pharmacy? get pharmacy => _pharmacy;
  int get totalMedicinesManaged => _totalMedicinesManaged;
  int get inStockCount => _inStockCount;
  int get expiringSoonCount => _expiringSoonCount;
  int get lowStockCount => _lowStockCount;

  bool get hasPharmacy => _pharmacy != null;

  /// Charge les données réelles du dashboard depuis SQLite.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _sessionService.currentUser;
      final userId = user?.userId ?? 5;

      // 1. Charger la pharmacie liée au pharmacien connecté
      _pharmacy = await _pharmacyRepo.getByPharmacienUserId(userId);

      // Si non trouvée par userId, essayer avec user.pharmacyId ou la première pharmacie en base
      if (_pharmacy == null && user?.pharmacyId != null) {
        _pharmacy = await _pharmacyRepo.getById(user!.pharmacyId!);
      }

      if (_pharmacy == null) {
        final allPharmacies = await _pharmacyRepo.getAll();
        if (allPharmacies.isNotEmpty) {
          _pharmacy = allPharmacies.first;
        } else {
          // Créer une pharmacie par défaut pour ce pharmacien
          final newPharmacyId = await _pharmacyRepo.create(
            Pharmacy(
              pharmacienUserId: userId,
              name: 'Pharmacie Centrale',
              address: '15 Avenue Habib Bourguiba, Tunis',
              phone: '+216 71 456 789',
              email: 'pharmacien@medilink.tn',
              latitude: 36.8065,
              longitude: 10.1815,
              openingHours: {
                'monday': '08:00-19:00',
                'tuesday': '08:00-19:00',
                'wednesday': '08:00-19:00',
                'thursday': '08:00-19:00',
                'friday': '08:00-19:00',
                'saturday': '08:00-14:00',
                'sunday': 'Fermé',
              },
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          _pharmacy = await _pharmacyRepo.getById(newPharmacyId);
        }
      }

      final pharmacyId = _pharmacy?.pharmacyId ?? 1;

      // 2. Calculer les statistiques réelles
      final totalCatalogCount = await _medicineRepo.count();
      final totalStockCount = await _stockRepo.countTotal(pharmacyId);
      final inStockItems = await _stockRepo.countInStock(pharmacyId);
      final lowStockList = await _stockRepo.getLowStockItems(pharmacyId, threshold: 15);
      final expiringSoonList = await _stockRepo.getExpiringSoonItems(pharmacyId, months: 6);

      _totalMedicinesManaged = totalStockCount > 0 ? totalStockCount : totalCatalogCount;
      _inStockCount = inStockItems;
      _lowStockCount = lowStockList.length;
      _expiringSoonCount = expiringSoonList.length;

      _error = null;
    } catch (e, stack) {
      _error = 'Erreur de chargement: ${e.toString()}';
      debugPrint('[PharmacyDashboardController] Error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit les données.
  Future<void> refresh() => load();
}
