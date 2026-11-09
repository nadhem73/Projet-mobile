import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_availability.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_finder_repository.dart';

/// Controller pour trouver les pharmacies proches avec disponibilité des médicaments.
///
/// Utilisé par les patients pour trouver où acheter leurs médicaments avec localisation GPS en temps réel.
class PharmacyFinderController extends ChangeNotifier {
  PharmacyFinderController(this._finderRepo);

  final PharmacyFinderRepository _finderRepo;

  // State
  bool _isLoading = false;
  bool _isLocating = false;
  bool _isDisposed = false;
  String? _error;
  String _locationStatus = 'Localisation non initialisée';
  List<PharmacyAvailability> _results = [];
  List<String> _searchedMedicines = [];
  List<Medicine>? _selectedMedicines;
  String _resultFilter = 'all'; // 'all', 'open', 'night', 'full_stock'
  String _sortBy = 'distance'; // 'distance', 'availability'
  double? _userLatitude;
  double? _userLongitude;
  double _searchRadius = 10.0; // km

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // Default fallback (Tunis Centre)
  static const double defaultLat = 36.8065;
  static const double defaultLon = 10.1815;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLocating => _isLocating;
  String? get error => _error;
  String get locationStatus => _locationStatus;
  List<PharmacyAvailability> get results => _results;
  List<String> get searchedMedicines => _searchedMedicines;
  List<Medicine>? get selectedMedicines => _selectedMedicines;
  String get resultFilter => _resultFilter;
  String get sortBy => _sortBy;

  /// Résultats filtrés selon les filtres interactifs (Ouvertes, De Nuit, 100% Dispo).
  List<PharmacyAvailability> get filteredResults {
    var list = List<PharmacyAvailability>.from(_results);

    switch (_resultFilter) {
      case 'open':
        list = list.where((r) => r.pharmacy.isOpenNow).toList();
        break;
      case 'night':
        list = list.where((r) => r.pharmacy.isNightPharmacy).toList();
        break;
      case 'full_stock':
        list = list.where((r) => r.availableCount == r.totalRequested).toList();
        break;
      case 'all':
      default:
        break;
    }

    if (_sortBy == 'distance') {
      list.sort((a, b) {
        final aOpen = a.pharmacy.isOpenNow;
        final bOpen = b.pharmacy.isOpenNow;
        if (aOpen && !bOpen) return -1;
        if (!aOpen && bOpen) return 1;
        return a.distance.compareTo(b.distance);
      });
    } else {
      list.sort((a, b) => b.availabilityScore.compareTo(a.availabilityScore));
    }

    return list;
  }
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  double get searchRadius => _searchRadius;

  bool get hasResults => _results.isNotEmpty;
  bool get hasLocation => _userLatitude != null && _userLongitude != null;

  /// Acquiert la localisation GPS réelle de l'utilisateur.
  Future<bool> getCurrentLocation() async {
    _isLocating = true;
    _locationStatus = 'Recherche du signal GPS...';
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _userLatitude ??= defaultLat;
        _userLongitude ??= defaultLon;
        _locationStatus = 'GPS désactivé (Position par défaut)';
        _isLocating = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _userLatitude ??= defaultLat;
          _userLongitude ??= defaultLon;
          _locationStatus = 'Permission GPS refusée (Tunis centre)';
          _isLocating = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _userLatitude ??= defaultLat;
        _userLongitude ??= defaultLon;
        _locationStatus = 'Permission bloquée (Tunis centre)';
        _isLocating = false;
        notifyListeners();
        return false;
      }

      // 1. Tenter d'abord la dernière position connue pour une réponse immédiate
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && !_isDisposed) {
        _userLatitude = lastKnown.latitude;
        _userLongitude = lastKnown.longitude;
        _locationStatus = 'Position GPS en temps réel';
        _isLocating = false;
        notifyListeners();
        return true;
      }

      // 2. Sinon obtenir la position en direct avec timeout de 5s
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (_isDisposed) return false;
      _userLatitude = position.latitude;
      _userLongitude = position.longitude;
      _locationStatus = 'Position GPS en temps réel';
      _isLocating = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _userLatitude ??= defaultLat;
      _userLongitude ??= defaultLon;
      _locationStatus = 'Position approximative (Tunis centre)';
      _isLocating = false;
      notifyListeners();
      return false;
    }
  }

  /// Définit manuellement la localisation de l'utilisateur.
  void setUserLocation(double latitude, double longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _locationStatus = 'Position personnalisée';
    notifyListeners();
  }

  /// Définit le rayon de recherche (en km).
  void setSearchRadius(double radiusKm) {
    _searchRadius = radiusKm.clamp(1.0, 50.0);
    notifyListeners();
  }

  /// Change le filtre de résultat ('all', 'open', 'night', 'full_stock').
  void setResultFilter(String filter) {
    _resultFilter = filter;
    notifyListeners();
  }

  /// Change l'ordre de tri ('distance', 'availability').
  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  /// Recherche les pharmacies avec les médicaments demandés.
  Future<void> findPharmacies({
    required List<String> medicineNames,
    List<Medicine>? specificMedicines,
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (medicineNames.isEmpty) {
      _error = 'Veuillez saisir au moins un médicament';
      notifyListeners();
      return;
    }

    // Si aucune position n'est encore définie, tenter une détection en direct
    if (_userLatitude == null || _userLongitude == null) {
      await getCurrentLocation();
    }

    final lat = userLatitude ?? _userLatitude ?? defaultLat;
    final lon = userLongitude ?? _userLongitude ?? defaultLon;

    _isLoading = true;
    _error = null;
    _searchedMedicines = medicineNames;
    _selectedMedicines = specificMedicines;
    notifyListeners();

    try {
      _results = await _finderRepo.findNearbyPharmacies(
        medicineNames: medicineNames,
        specificMedicines: specificMedicines,
        userLatitude: lat,
        userLongitude: lon,
        radiusKm: _searchRadius,
      );

      if (_results.isEmpty) {
        _error = 'Aucune pharmacie trouvée avec ces médicaments dans un rayon de ${_searchRadius.toStringAsFixed(0)} km';
      } else {
        _error = null;
      }
    } catch (e) {
      _error = 'Erreur de recherche: ${e.toString()}';
      debugPrint('[PharmacyFinderController] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recherche les pharmacies vendant un médicament spécifique.
  Future<void> findPharmaciesWithMedicine({
    required String medicineName,
    Medicine? specificMedicine,
    double? userLatitude,
    double? userLongitude,
  }) async {
    return findPharmacies(
      medicineNames: [medicineName],
      specificMedicines: specificMedicine != null ? [specificMedicine] : null,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }

  /// Réinitialise la recherche.
  void clear() {
    _results = [];
    _searchedMedicines = [];
    _selectedMedicines = null;
    _resultFilter = 'all';
    _sortBy = 'distance';
    _error = null;
    notifyListeners();
  }

  /// Rafraîchit les résultats avec les mêmes critères.
  Future<void> refresh() async {
    if (_searchedMedicines.isEmpty) return;
    await findPharmacies(
      medicineNames: _searchedMedicines,
      specificMedicines: _selectedMedicines,
    );
  }

  /// Formate la distance pour l'affichage.
  String formatDistance(double distanceKm) {
    return _finderRepo.formatDistance(distanceKm);
  }

  /// Estime le temps de trajet à pied.
  String estimateWalkingTime(double distanceKm) {
    return _finderRepo.estimateWalkingTime(distanceKm);
  }
}
