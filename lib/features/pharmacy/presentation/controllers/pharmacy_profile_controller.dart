import 'package:flutter/foundation.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy.dart';
import 'package:medilink/features/pharmacy/data/repositories/pharmacy_repository.dart';

/// Controller pour le profil et les paramètres de la pharmacie.
class PharmacyProfileController extends ChangeNotifier {
  PharmacyProfileController(
    this._sessionService,
    this._pharmacyRepo,
  );

  final SessionService _sessionService;
  final PharmacyRepository _pharmacyRepo;

  // State
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Pharmacy? _pharmacy;

  // Form state
  String _name = 'Pharmacie Centrale';
  String _address = '15 Avenue Habib Bourguiba, Tunis 1000';
  String _phone = '+216 71 456 789';
  String? _email = 'pharmacien@medilink.tn';
  double _latitude = 36.8065;
  double _longitude = 10.1815;
  Map<String, String>? _openingHours;
  String? _photoUrl;
  bool _isNightPharmacy = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Pharmacy? get pharmacy => _pharmacy;

  String get name => _name;
  String get address => _address;
  String get phone => _phone;
  String? get email => _email;
  double get latitude => _latitude;
  double get longitude => _longitude;
  Map<String, String>? get openingHours => _openingHours;
  String? get photoUrl => _photoUrl;
  bool get isNightPharmacy => _isNightPharmacy;

  bool get hasPharmacy => _pharmacy != null;
  bool get canSave => _name.isNotEmpty && _address.isNotEmpty && _phone.isNotEmpty;

  /// Charge le profil de la pharmacie.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _sessionService.currentUser;
      final userId = user?.userId ?? 5;

      // 1. Charger la pharmacie
      _pharmacy = await _pharmacyRepo.getByPharmacienUserId(userId);
      if (_pharmacy == null && user?.pharmacyId != null) {
        _pharmacy = await _pharmacyRepo.getById(user!.pharmacyId!);
      }
      if (_pharmacy == null) {
        final all = await _pharmacyRepo.getAll();
        if (all.isNotEmpty) {
          _pharmacy = all.first;
        }
      }

      if (_pharmacy != null) {
        _name = _pharmacy!.name;
        _address = _pharmacy!.address;
        _phone = _pharmacy!.phone ?? '';
        _email = _pharmacy!.email;
        _latitude = _pharmacy!.latitude;
        _longitude = _pharmacy!.longitude;
        _openingHours = _pharmacy!.openingHours ?? _defaultOpeningHours;
        _photoUrl = _pharmacy!.photoUrl;
        _isNightPharmacy = _pharmacy!.isNightPharmacy;
      } else {
        _openingHours = _defaultOpeningHours;
        _isNightPharmacy = false;
      }

      _error = null;
    } catch (e, stack) {
      _error = 'Erreur de chargement: ${e.toString()}';
      debugPrint('[PharmacyProfileController] Error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static const Map<String, String> _defaultOpeningHours = {
    'monday': '08:00-19:30',
    'tuesday': '08:00-19:30',
    'wednesday': '08:00-19:30',
    'thursday': '08:00-19:30',
    'friday': '08:00-19:30',
    'saturday': '08:00-14:00',
    'sunday': 'Fermé',
  };

  static const Map<String, String> _nightOpeningHours = {
    'monday': '19:30-08:30',
    'tuesday': '19:30-08:30',
    'wednesday': '19:30-08:30',
    'thursday': '19:30-08:30',
    'friday': '19:30-08:30',
    'saturday': '19:30-08:30',
    'sunday': '19:30-08:30',
  };

  static const Map<String, String> _alwaysOpenHours = {
    'monday': '00:00-23:59',
    'tuesday': '00:00-23:59',
    'wednesday': '00:00-23:59',
    'thursday': '00:00-23:59',
    'friday': '00:00-23:59',
    'saturday': '00:00-23:59',
    'sunday': '00:00-23:59',
  };

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    notifyListeners();
  }

  void setEmail(String? value) {
    _email = value;
    notifyListeners();
  }

  void setCoordinates(double lat, double lon) {
    _latitude = lat;
    _longitude = lon;
    notifyListeners();
  }

  void setOpeningHours(Map<String, String>? value) {
    _openingHours = value;
    _checkNightStatusFromHours();
    notifyListeners();
  }

  void setDayHours(String dayKey, String hours) {
    final current = Map<String, String>.from(_openingHours ?? _defaultOpeningHours);
    current[dayKey.toLowerCase()] = hours;
    _openingHours = current;
    _checkNightStatusFromHours();
    notifyListeners();
  }

  void applyHoursPreset(String presetKey) {
    if (presetKey == 'night') {
      _openingHours = Map<String, String>.from(_nightOpeningHours);
      _isNightPharmacy = true;
    } else if (presetKey == '24h') {
      _openingHours = Map<String, String>.from(_alwaysOpenHours);
      _isNightPharmacy = true;
    } else {
      _openingHours = Map<String, String>.from(_defaultOpeningHours);
      _isNightPharmacy = false;
    }
    notifyListeners();
  }

  void setIsNightPharmacy(bool value, {bool updateName = true}) {
    _isNightPharmacy = value;
    if (value) {
      // Si les horaires actuels sont de jour, passer en horaires de nuit
      final isCurrentlyOvernight = _hasOvernightHours();
      if (!isCurrentlyOvernight) {
        _openingHours = Map<String, String>.from(_nightOpeningHours);
      }
      if (updateName && !_name.toLowerCase().contains('nuit')) {
        _name = '$_name (de Nuit)'.trim();
      }
    } else {
      // Revenir aux horaires normaux si c'était de nuit
      final isCurrentlyOvernight = _hasOvernightHours();
      if (isCurrentlyOvernight) {
        _openingHours = Map<String, String>.from(_defaultOpeningHours);
      }
      if (updateName && _name.contains('(de Nuit)')) {
        _name = _name.replaceAll('(de Nuit)', '').replaceAll('  ', ' ').trim();
      }
    }
    notifyListeners();
  }

  bool _hasOvernightHours() {
    if (_openingHours == null) return false;
    for (final h in _openingHours!.values) {
      if (h.contains('-')) {
        final parts = h.split('-');
        if (parts.length == 2) {
          final start = parts[0].trim();
          final end = parts[1].trim();
          if (start.compareTo(end) > 0) return true; // e.g. 19:30-08:30
        }
      }
    }
    return false;
  }

  void _checkNightStatusFromHours() {
    if (_hasOvernightHours() || _name.toLowerCase().contains('nuit')) {
      _isNightPharmacy = true;
    }
  }

  void setPhotoUrl(String? value) {
    _photoUrl = value;
    notifyListeners();
  }

  /// Enregistre les modifications.
  Future<bool> save() async {
    if (!canSave) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final user = _sessionService.currentUser;
      final userId = user?.userId ?? 5;

      if (_pharmacy != null) {
        final updatedPharmacy = _pharmacy!.copyWith(
          name: _name,
          address: _address,
          phone: _phone,
          email: _email,
          latitude: _latitude,
          longitude: _longitude,
          openingHours: _openingHours,
          photoUrl: _photoUrl,
          updatedAt: DateTime.now(),
        );

        await _pharmacyRepo.update(updatedPharmacy);
        _pharmacy = await _pharmacyRepo.getById(_pharmacy!.pharmacyId!);
      } else {
        final newPid = await _pharmacyRepo.create(
          Pharmacy(
            pharmacienUserId: userId,
            name: _name,
            address: _address,
            phone: _phone,
            email: _email,
            latitude: _latitude,
            longitude: _longitude,
            openingHours: _openingHours,
            photoUrl: _photoUrl,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        _pharmacy = await _pharmacyRepo.getById(newPid);
      }

      _error = null;
      return true;
    } catch (e, stack) {
      _error = 'Erreur d\'enregistrement: ${e.toString()}';
      debugPrint('[PharmacyProfileController] Save error: $e\n$stack');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
